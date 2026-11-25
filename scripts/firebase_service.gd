extends Node

# İkinci Firebase Realtime Database açtığında URL'yi buraya yapıştırabilirsin:
var firebase_url := "https://haxturko-default-rtdb.europe-west1.firebasedatabase.app"
const ROOM_PREFIX := "godot_rooms"
const CHAT_NODE := "godot_global_chat"
const PROFILE_NODE := "godot_profiles"
const ROOM_TTL_MS := 22000

signal rooms_loaded(rooms: Array)
signal chat_loaded(messages: Array)
signal leaderboard_loaded(players: Array)

var cached_owner_hash := ""
var last_rooms: Array = []

func _http_request(url: String, method: int = HTTPClient.METHOD_GET, body_dict: Dictionary = {}) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := ["Content-Type: application/json"]
	var payload := JSON.stringify(body_dict) if not body_dict.is_empty() else ""
	var err := http.request(url, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "data": null}
	var res: Array = await http.request_completed
	http.queue_free()
	var code: int = res[1]
	var text: String = (res[3] as PackedByteArray).get_string_from_utf8()
	if code < 200 or code >= 300:
		return {"ok": false, "code": code, "data": null}
	var parsed = JSON.parse_string(text)
	return {"ok": true, "code": code, "data": parsed}

func get_owner_hash() -> String:
	if not cached_owner_hash.is_empty():
		return cached_owner_hash
	var res := await _http_request("https://api.ipify.org?format=json")
	if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY and res["data"].has("ip"):
		var ip: String = str(res["data"]["ip"])
		cached_owner_hash = "ip_" + str(absi(ip.hash()))
		return cached_owner_hash
	cached_owner_hash = "cid_" + str(absi((GameData.settings.get("nickname", "p") + str(OS.get_unique_id())).hash()))
	return cached_owner_hash

func fetch_rooms() -> Array:
	if firebase_url.is_empty():
		return []
	var url := "%s/%s.json" % [firebase_url.rstrip("/"), ROOM_PREFIX]
	var res := await _http_request(url)
	var now := Time.get_unix_time_from_system() * 1000.0
	var out: Array = []
	if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY:
		var dict: Dictionary = res["data"]
		for k in dict.keys():
			var r = dict[k]
			if typeof(r) != TYPE_DICTIONARY:
				continue
			var upd := float(r.get("updatedAt", 0))
			if now - upd <= ROOM_TTL_MS:
				out.append(r)
			else:
				remove_room(str(r.get("code", k)))
	last_rooms = out
	emit_signal("rooms_loaded", out)
	return out

func can_create_room(host_name: String) -> Dictionary:
	var owner_h := await get_owner_hash()
	var rooms := await fetch_rooms()
	var count := 0
	for r in rooms:
		if str(r.get("ownerHash", "")) == owner_h or str(r.get("hostName", "")).to_lower() == host_name.to_lower():
			count += 1
	return {"ok": count < 3, "count": count, "limit": 3}

func publish_room(room: Dictionary) -> void:
	if firebase_url.is_empty():
		return
	var owner_h := await get_owner_hash()
	var payload := room.duplicate()
	payload["ownerHash"] = owner_h
	payload["updatedAt"] = int(Time.get_unix_time_from_system() * 1000.0)
	var code := str(room.get("code", "ROOM"))
	var url := "%s/%s/%s.json" % [firebase_url.rstrip("/"), ROOM_PREFIX, code.uri_encode()]
	await _http_request(url, HTTPClient.METHOD_PUT, payload)

func remove_room(code: String) -> void:
	if firebase_url.is_empty() or code.is_empty():
		return
	var url := "%s/%s/%s.json" % [firebase_url.rstrip("/"), ROOM_PREFIX, code.uri_encode()]
	await _http_request(url, HTTPClient.METHOD_DELETE)

func fetch_global_chat() -> Array:
	if firebase_url.is_empty():
		return []
	var url := "%s/%s.json?orderBy=\"$key\"&limitToLast=30" % [firebase_url.rstrip("/"), CHAT_NODE]
	var res := await _http_request(url)
	var rows: Array = []
	if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY:
		for k in res["data"].keys():
			var m = res["data"][k]
			if typeof(m) == TYPE_DICTIONARY and m.has("text"):
				rows.append(m)
		rows.sort_custom(func(a, b): return float(a.get("ts", 0)) < float(b.get("ts", 0)))
	emit_signal("chat_loaded", rows)
	return rows

func send_global_chat(author: String, text: String, country: String) -> void:
	if firebase_url.is_empty():
		return
	var url := "%s/%s.json" % [firebase_url.rstrip("/"), CHAT_NODE]
	var payload := {
		"author": GameData.censor_text(author.substr(0, 20)),
		"text": GameData.censor_text(text.substr(0, 160)),
		"country": country,
		"ts": int(Time.get_unix_time_from_system() * 1000.0)
	}
	await _http_request(url, HTTPClient.METHOD_POST, payload)
	await fetch_global_chat()

func save_cloud_profile(username: String, country: String, goals: int, wins: int, play_sec: int) -> void:
	if firebase_url.is_empty() or username.is_empty():
		return
	var key := username.to_lower().uri_encode()
	var url := "%s/%s/%s.json" % [firebase_url.rstrip("/"), PROFILE_NODE, key]
	await _http_request(url, HTTPClient.METHOD_PUT, {
		"username": username,
		"country": country,
		"goals": goals,
		"wins": wins,
		"playSeconds": play_sec
	})

func fetch_leaderboard() -> Array:
	if firebase_url.is_empty():
		return []
	var url := "%s/%s.json" % [firebase_url.rstrip("/"), PROFILE_NODE]
	var res := await _http_request(url)
	var out: Array = []
	if res["ok"] and typeof(res["data"]) == TYPE_DICTIONARY:
		for k in res["data"].keys():
			var p = res["data"][k]
			if typeof(p) == TYPE_DICTIONARY and p.has("username"):
				out.append(p)
		out.sort_custom(func(a, b): return int(a.get("goals", 0)) > int(b.get("goals", 0)))
	emit_signal("leaderboard_loaded", out.slice(0, 10))
	return out.slice(0, 10)
