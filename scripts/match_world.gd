extends Node
class_name MatchWorld

signal scoreboard_changed(red: int, blue: int, seconds: int, paused: bool)
signal goal_scored(team: String, scorer_name: String, assist_name: String)
signal match_ended(winner_team: String)
signal chat_message(author: String, text: String, is_system: bool)
signal roster_changed
signal auth_rejected(reason: String)

const SUBSTEPS := 2
const MAX_PLAYERS_CAP := 14

var pitch_view: PitchView
var audio_fx: AudioFX

var active := false
var paused := false
var room_kind := "offline" # offline | local2p | host | client
var room_code := ""
var room_name := "OpenHax Godot Oda"
var room_password := ""
var max_players := 10
var score_limit := 5
var time_limit := 180
var score_red := 0
var score_blue := 0
var match_seconds := 0
var tick := 0
var tick_in_sec := 0
var bot_counter := 1

var stadium: Dictionary = {}
var players: Array = []
var ball: Dictionary = {"pos": Vector2(430, 230), "vel": Vector2.ZERO, "radius": 10.0}
var trail: Array = []
var particles: Array = []
var powerup_mode := "none"
var field_powerup = null
var ball_fire_type := ""
var ball_fire_ticks := 0
var next_powerup_tick := 240
var goal_pending := false
var goal_reset_ticks := 0
var match_ended_pending := false
var match_ended_ticks := 0
var teams_locked := false
var room_locked := false
var my_id := "host"
var last_ping_ms := 0
var _ping_timer := 0.0
var _last_input_bits := -1
var _input_keepalive := 0

# Goal / Assist / Save tracking
var last_touch_id := ""
var assist_touch_id := ""
var last_touch_tick := 0
var last_save_tick := -200

# Remote client inputs & pending ping timestamps
var _remote_inputs: Dictionary = {} # peer_id_str -> int bitmask
var _ping_sent_ms: Dictionary = {}

func _ready() -> void:
	stadium = GameData.get_stadium(GameData.settings.get("stadium", "classic"))
	audio_fx = AudioFX.new()
	add_child(audio_fx)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_room(
	kind: String,
	rname: String,
	st_id: String,
	bot_preset: String,
	p_limit: int,
	t_limit: int,
	pu_mode: String,
	r_pass: String = "",
	m_players: int = 10,
	r_code: String = ""
) -> void:
	room_kind = kind
	room_name = GameData.censor_text(rname)
	room_password = r_pass
	max_players = clampi(m_players, 2, MAX_PLAYERS_CAP)
	room_code = r_code if not r_code.is_empty() else str(randi_range(100000, 999999))
	stadium = GameData.get_stadium(st_id)
	score_limit = p_limit
	time_limit = t_limit
	powerup_mode = pu_mode
	teams_locked = false
	room_locked = false
	_remote_inputs.clear()

	players.clear()
	bot_counter = 1
	if kind == "client":
		my_id = str(multiplayer.get_unique_id())
		active = true
		return

	my_id = "host"
	var host_p := _make_player(
		"host",
		GameData.settings["nickname"],
		GameData.settings["avatar"],
		"red",
		false,
		true,
		GameData.settings.get("country", "TR")
	)
	players.append(host_p)

	if kind == "local2p":
		players.append(_make_player("local2", "Oyuncu 2", ":(", "blue", false, false, GameData.settings.get("country", "TR")))
	elif bot_preset == "1blue":
		add_bot("blue")
	elif bot_preset == "2v2":
		add_bot("red")
		add_bot("blue")
		add_bot("blue")
	elif bot_preset == "5v5":
		for _i in range(4):
			add_bot("red")
		for _j in range(5):
			add_bot("blue")

	reset_match()
	active = true
	audio_fx.play_game_start()
	emit_signal("roster_changed")

func stop_room() -> void:
	active = false
	paused = false
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null
	_remote_inputs.clear()
	players.clear()

func _make_player(pid: String, pname: String, pav: String, team: String, is_bot: bool, is_admin: bool, country: String = "TR") -> Dictionary:
	return {
		"id": pid,
		"name": pname,
		"avatar": pav,
		"country": country,
		"team": team,
		"is_bot": is_bot,
		"is_admin": is_admin,
		"pos": Vector2.ZERO,
		"vel": Vector2.ZERO,
		"radius": 15.0,
		"kick_armed": false,
		"prev_kick": false,
		"next_kick_tick": 0,
		"kick_flash_ticks": 0,
		"powerup": "",
		"powerup_ticks": 0,
		"ping": 0,
		"avoid_side": 0.0,
		"custom_color": ""
	}

func _get_enabled_powerups() -> Array:
	if powerup_mode == "none" or powerup_mode.is_empty():
		return []
	if powerup_mode == "all":
		var out: Array = []
		for t in GameData.POWERUP_TYPES:
			if bool(GameData.powerups_enabled.get(t, true)):
				out.append(t)
		return out
	return [powerup_mode] if bool(GameData.powerups_enabled.get(powerup_mode, true)) else []

func add_bot(team: String) -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "add_bot", {"team": team})
		return
	if players.size() >= MAX_PLAYERS_CAP:
		emit_signal("chat_message", "Sistem", "Maksimum oyuncu/bot sınırına (14) ulaşıldı.", true)
		return
	var prefix := "Bot-K" if team == "red" else "Bot-M"
	var bname := "%s%d" % [prefix, bot_counter]
	var bid := "bot-%d" % bot_counter
	bot_counter += 1
	players.append(_make_player(bid, bname, "AI", team, true, false, "AI"))
	_place_single_player(players[-1])
	emit_signal("roster_changed")
	_broadcast_sys_chat("%s (%s) oyuna eklendi." % [bname, team])

func remove_last_bot(team_filter: String = "") -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "remove_bot", {"team": team_filter})
		return
	for i in range(players.size() - 1, -1, -1):
		if players[i]["is_bot"] and (team_filter.is_empty() or players[i]["team"] == team_filter):
			var removed: String = players[i]["name"]
			players.remove_at(i)
			emit_signal("roster_changed")
			_broadcast_sys_chat("%s oyundan çıkarıldı." % removed)
			return

func clear_bots() -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "clear_bots", {})
		return
	players = players.filter(func(p): return not p["is_bot"])
	emit_signal("roster_changed")
	_broadcast_sys_chat("Tüm botlar temizlendi.")

func set_stadium_id(st_id: String) -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "set_stadium", {"id": st_id})
		return
	GameData.settings["stadium"] = st_id
	stadium = GameData.get_stadium(st_id)
	reset_positions()
	_broadcast_sys_chat("Stadyum değiştirildi: %s" % stadium["label"])

func auto_balance_teams() -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "auto_balance", {})
		return
	var active_p := players.filter(func(p): return p["team"] != "spec")
	for i in range(active_p.size()):
		active_p[i]["team"] = "red" if (i % 2 == 0) else "blue"
	reset_positions()
	emit_signal("roster_changed")
	_broadcast_sys_chat("Takımlar otomatik dengelendi.")

func randomize_teams() -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "randomize_teams", {})
		return
	var active_p := players.filter(func(p): return p["team"] != "spec")
	active_p.shuffle()
	for i in range(active_p.size()):
		active_p[i]["team"] = "red" if (i % 2 == 0) else "blue"
	reset_positions()
	emit_signal("roster_changed")
	_broadcast_sys_chat("Takımlar rastgele karıştırıldı.")

func request_team_change(target_id: String, new_team: String) -> void:
	if room_kind == "client":
		if target_id == my_id:
			_rpc_request_team.rpc_id(1, new_team)
		else:
			_rpc_admin_cmd.rpc_id(1, "set_team", {"id": target_id, "team": new_team})
		return
	if teams_locked and target_id == my_id and not is_local_admin():
		emit_signal("chat_message", "Sistem", "Takımlar kilitli!", true)
		return
	for p in players:
		if p["id"] == target_id:
			p["team"] = new_team
			_place_single_player(p)
			emit_signal("roster_changed")
			return

func toggle_admin(target_id: String) -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "toggle_admin", {"id": target_id})
		return
	for p in players:
		if p["id"] == target_id and not p["is_bot"]:
			p["is_admin"] = not bool(p["is_admin"])
			emit_signal("roster_changed")
			_broadcast_sys_chat("%s admin yetkisi %s." % [p["name"], "verildi" if p["is_admin"] else "alındı"])
			return

func kick_player(target_id: String) -> void:
	if target_id == "host":
		return
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "kick", {"id": target_id})
		return
	for i in range(players.size()):
		if players[i]["id"] == target_id:
			var pname: String = players[i]["name"]
			var is_b: bool = players[i]["is_bot"]
			players.remove_at(i)
			if not is_b and room_kind == "host" and multiplayer.has_multiplayer_peer():
				var pid := int(target_id)
				if pid > 1:
					_rpc_kicked.rpc_id(pid, "Odadan atıldınız.")
					multiplayer.multiplayer_peer.disconnect_peer(pid)
			emit_signal("roster_changed")
			_broadcast_sys_chat("%s odadan atıldı." % pname)
			return

func is_local_admin() -> bool:
	for p in players:
		if p["id"] == my_id:
			return bool(p["is_admin"])
	return room_kind != "client"

func send_room_chat(raw_text: String) -> void:
	var txt := raw_text.strip_edges()
	if txt.is_empty():
		return
	# Chat commands: /color #hex, /renk #hex, /avatar <str>, /nick <name>, /isim <name>
	if txt.begins_with("/"):
		var parts := txt.split(" ", false, 1)
		var cmd := parts[0].to_lower()
		var arg := parts[1].strip_edges() if parts.size() > 1 else ""
		if cmd in ["/color", "/renk"] and arg.begins_with("#") and (arg.length() == 7 or arg.length() == 4):
			for p in players:
				if p["id"] == my_id:
					p["custom_color"] = arg
			emit_signal("chat_message", "Sistem", "Takım rengi güncellendi: %s" % arg, true)
			return
		elif cmd == "/avatar" and not arg.is_empty():
			var av := arg.substr(0, 2)
			GameData.settings["avatar"] = av
			GameData.save_settings()
			for p in players:
				if p["id"] == my_id:
					p["avatar"] = av
			emit_signal("chat_message", "Sistem", "Avatar güncellendi: %s" % av, true)
			return
		elif cmd in ["/nick", "/isim"] and arg.length() >= 2:
			var nn := GameData.censor_text(arg.substr(0, 20))
			GameData.settings["nickname"] = nn
			GameData.save_settings()
			for p in players:
				if p["id"] == my_id:
					p["name"] = nn
			emit_signal("roster_changed")
			emit_signal("chat_message", "Sistem", "Kullanıcı adı güncellendi: %s" % nn, true)
			return

	var clean := GameData.censor_text(txt.substr(0, 160))
	var author: String = str(GameData.settings.get("nickname", "Oyuncu"))
	if room_kind == "client":
		_rpc_chat.rpc_id(1, author, clean, false)
	elif room_kind == "host":
		emit_signal("chat_message", author, clean, false)
		_rpc_chat.rpc(author, clean, false)
	else:
		emit_signal("chat_message", author, clean, false)

func _broadcast_sys_chat(text: String) -> void:
	emit_signal("chat_message", "Sistem", text, true)
	if room_kind == "host" and multiplayer.has_multiplayer_peer():
		_rpc_chat.rpc("Sistem", text, true)

func reset_match() -> void:
	if room_kind == "client":
		_rpc_admin_cmd.rpc_id(1, "reset_match", {})
		return
	score_red = 0
	score_blue = 0
	match_seconds = 0
	tick = 0
	tick_in_sec = 0
	paused = false
	goal_pending = false
	match_ended_pending = false
	field_powerup = null
	ball_fire_type = ""
	ball_fire_ticks = 0
	next_powerup_tick = 240
	last_touch_id = ""
	assist_touch_id = ""
	reset_positions()
	audio_fx.play_game_start()
	emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)

func reset_positions() -> void:
	var cy := float(stadium["py"]) + float(stadium["ph"]) * 0.5
	var cx := float(stadium["px"]) + float(stadium["pw"]) * 0.5
	ball["pos"] = Vector2(cx, cy)
	ball["vel"] = Vector2.ZERO
	trail.clear()
	ball_fire_type = ""
	ball_fire_ticks = 0

	var red_list := players.filter(func(p): return p["team"] == "red")
	var blue_list := players.filter(func(p): return p["team"] == "blue")
	for i in range(red_list.size()):
		red_list[i]["pos"] = Vector2(float(stadium["px"]) + float(stadium["pw"]) * 0.25, cy + (i - (red_list.size() - 1) * 0.5) * 44.0)
		red_list[i]["vel"] = Vector2.ZERO
	for j in range(blue_list.size()):
		blue_list[j]["pos"] = Vector2(float(stadium["px"]) + float(stadium["pw"]) * 0.75, cy + (j - (blue_list.size() - 1) * 0.5) * 44.0)
		blue_list[j]["vel"] = Vector2.ZERO

func _place_single_player(p: Dictionary) -> void:
	var cy := float(stadium["py"]) + float(stadium["ph"]) * 0.5
	if p["team"] == "red":
		p["pos"] = Vector2(float(stadium["px"]) + float(stadium["pw"]) * 0.22, cy)
	elif p["team"] == "blue":
		p["pos"] = Vector2(float(stadium["px"]) + float(stadium["pw"]) * 0.78, cy)
	p["vel"] = Vector2.ZERO

func _get_local_input_bits() -> int:
	var bits := 0
	if Input.is_action_pressed("move_up"): bits |= 1
	if Input.is_action_pressed("move_down"): bits |= 2
	if Input.is_action_pressed("move_left"): bits |= 4
	if Input.is_action_pressed("move_right"): bits |= 8
	if Input.is_action_pressed("kick"): bits |= 16
	return bits

func _bits_to_input(bits: int) -> Dictionary:
	var mv := Vector2.ZERO
	if (bits & 1) != 0: mv.y -= 1.0
	if (bits & 2) != 0: mv.y += 1.0
	if (bits & 4) != 0: mv.x -= 1.0
	if (bits & 8) != 0: mv.x += 1.0
	if mv.length() > 1.0:
		mv = mv.normalized()
	return {"move": mv, "kick": (bits & 16) != 0}

func _physics_process(delta: float) -> void:
	if not active:
		return

	if room_kind in ["host", "client"] and multiplayer.has_multiplayer_peer():
		_ping_timer += delta
		if _ping_timer >= 2.0:
			_ping_timer = 0.0
			var now := Time.get_ticks_msec()
			if room_kind == "client":
				_ping_sent_ms["1"] = now
				_rpc_ping.rpc_id(1, now)
			else:
				for pid in multiplayer.get_peers():
					_ping_sent_ms[str(pid)] = now
					_rpc_ping.rpc_id(pid, now)

	if room_kind == "client":
		var bits := _get_local_input_bits()
		_input_keepalive += 1
		if bits != _last_input_bits or _input_keepalive >= 6:
			_last_input_bits = bits
			_input_keepalive = 0
			if multiplayer.has_multiplayer_peer():
				_rpc_client_input.rpc_id(1, bits)
		_sync_view()
		return

	if paused:
		_sync_view()
		return

	if match_ended_pending:
		match_ended_ticks -= 1
		if match_ended_ticks <= 0:
			match_ended_pending = false
			reset_match()
		_sync_view()
		if room_kind == "host" and multiplayer.has_multiplayer_peer():
			_broadcast_snapshot()
		return

	tick += 1
	tick_in_sec += 1
	if tick_in_sec >= 60:
		tick_in_sec = 0
		match_seconds += 1
		GameData.profile["play_seconds"] += 1
		emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)
		if time_limit > 0 and match_seconds >= time_limit and score_red != score_blue and not goal_pending:
			_trigger_match_end("red" if score_red > score_blue else "blue")

	_step_physics()
	_sync_view()
	if room_kind == "host" and multiplayer.has_multiplayer_peer():
		_broadcast_snapshot()

func _resolve_circle_static_disc(pos: Vector2, vel: Vector2, r: float, center: Vector2, cr: float, bcoef: float) -> Dictionary:
	var d := pos - center
	var min_d := r + cr
	var dist_sq := d.length_squared()
	if dist_sq >= min_d * min_d:
		return {"pos": pos, "vel": vel, "hit": false}
	var dist := sqrt(dist_sq)
	var n := d / dist if dist > 0.0001 else Vector2.RIGHT
	var new_pos := center + n * min_d
	var vn := vel.dot(n)
	var new_vel := vel
	if vn < 0.0:
		new_vel = vel - n * ((1.0 + bcoef) * vn)
	return {"pos": new_pos, "vel": new_vel, "hit": true}

func _resolve_circle_segment(pos: Vector2, vel: Vector2, r: float, seg_a: Vector2, seg_b: Vector2, bcoef: float) -> Dictionary:
	var ab := seg_b - seg_a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return {"pos": pos, "vel": vel, "hit": false}
	var t := clampf((pos - seg_a).dot(ab) / len_sq, 0.0, 1.0)
	var closest := seg_a + ab * t
	var d := pos - closest
	var dist_sq := d.length_squared()
	if dist_sq >= r * r:
		return {"pos": pos, "vel": vel, "hit": false}
	var dist := sqrt(dist_sq)
	var n := d / dist if dist > 0.0001 else Vector2(-ab.y, ab.x).normalized()
	var new_pos := closest + n * r
	var vn := vel.dot(n)
	var new_vel := vel
	if vn < 0.0:
		new_vel = vel - n * ((1.0 + bcoef) * vn)
	return {"pos": new_pos, "vel": new_vel, "hit": true}

func _step_physics() -> void:
	var phys := GameData.get_physics_params(GameData.settings.get("physics_profile", "openhax"))
	var hz := clampf(float(GameData.settings.get("physics_hz", 60)), 30.0, 500.0)
	var dt_scale := 60.0 / hz
	var sub_dt := dt_scale / float(SUBSTEPS)

	var px := float(stadium["px"])
	var py := float(stadium["py"])
	var pw := float(stadium["pw"])
	var ph := float(stadium["ph"])
	var gh := float(stadium["gh"])
	var gd := float(stadium["gd"])
	var cy := py + ph * 0.5
	var post_r := float(stadium.get("post_r", 7.5))
	var post_bcoef := float(stadium.get("post_bcoef", 0.75))

	if ball_fire_ticks > 0:
		ball_fire_ticks -= 1
		if ball_fire_ticks <= 0:
			ball_fire_type = ""

	# Powerups spawn (margin=70, initial 4s=240 ticks, respawn 9s=540 ticks)
	var active_pu := _get_enabled_powerups()
	if active_pu.size() > 0 and field_powerup == null and tick >= next_powerup_tick:
		var tname: String = active_pu[randi() % active_pu.size()]
		var margin := 70.0
		field_powerup = {
			"pos": Vector2(
				randf_range(px + margin, maxf(px + margin + 10.0, px + pw - margin)),
				randf_range(py + margin, maxf(py + margin + 10.0, py + ph - margin))
			),
			"type": tname
		}
		next_powerup_tick = tick + 540

	var red_bots := players.filter(func(p): return p["is_bot"] and p["team"] == "red")
	var blue_bots := players.filter(func(p): return p["is_bot"] and p["team"] == "blue")
	var bot_diff: String = GameData.settings.get("bot_difficulty", "medium")

	# Prepare inputs once per tick
	var p_inputs: Dictionary = {}
	for p in players:
		if int(p["kick_flash_ticks"]) > 0:
			p["kick_flash_ticks"] = int(p["kick_flash_ticks"]) - 1
		if int(p["powerup_ticks"]) > 0:
			p["powerup_ticks"] = int(p["powerup_ticks"]) - 1
			if int(p["powerup_ticks"]) <= 0:
				p["powerup"] = ""
				p["radius"] = 15.0
		if p["team"] == "spec":
			continue

		var move := Vector2.ZERO
		var kick_down := false
		var speed_scale := 1.0

		if p["is_bot"]:
			var tlist := red_bots if p["team"] == "red" else blue_bots
			var bidx := tlist.find(p)
			var dec := BotAI.compute_input(p, maxi(0, bidx), tlist.size(), players, ball, stadium, bot_diff, tick)
			move = dec["move"]
			kick_down = dec["kick"]
			speed_scale = dec["speed_scale"]
		elif p["id"] == my_id:
			move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			kick_down = Input.is_action_pressed("kick")
		elif p["id"] == "local2":
			if Input.is_key_pressed(KEY_LEFT): move.x -= 1.0
			if Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
			if Input.is_key_pressed(KEY_UP): move.y -= 1.0
			if Input.is_key_pressed(KEY_DOWN): move.y += 1.0
			kick_down = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_0)
		elif _remote_inputs.has(p["id"]):
			var dec_r := _bits_to_input(int(_remote_inputs[p["id"]]))
			move = dec_r["move"]
			kick_down = dec_r["kick"]

		if kick_down and not bool(p["prev_kick"]):
			p["kick_armed"] = true
		elif not kick_down:
			p["kick_armed"] = false
		p["prev_kick"] = kick_down

		if move.length() > 1.0:
			move = move.normalized()
		p_inputs[p["id"]] = {"move": move, "kick": kick_down, "speed_scale": speed_scale}

	var p_invmass := float(phys["p_invmass"])
	var b_invmass := float(phys["b_invmass"])
	var p_damp := pow(float(phys["p_damp"]), sub_dt)
	var b_damp := pow(float(phys["b_damp"]), sub_dt)
	var pw_rest := float(phys.get("pw_rest", 0.0))
	var bw_rest := float(phys["bw_rest"])

	for _sub in range(SUBSTEPS):
		for p in players:
			if p["team"] == "spec":
				continue
			var inp: Dictionary = p_inputs.get(p["id"], {"move": Vector2.ZERO, "kick": false, "speed_scale": 1.0})
			var move: Vector2 = inp["move"]
			var kick_down: bool = inp["kick"]
			var speed_scale: float = inp["speed_scale"]

			var p_acc := (float(phys["k_accel"]) if kick_down else float(phys["accel"])) * sub_dt
			var p_max := float(phys["p_max"]) * speed_scale
			if p["powerup"] == "speed":
				p_acc *= 1.55
				p_max *= 1.55

			var vel: Vector2 = p["vel"]
			if move.length_squared() > 0.001:
				var spd := vel.length()
				if spd > 0.01 and move.dot(vel / spd) < -0.4:
					p_acc *= 1.25
				vel += move * p_acc
			vel *= p_damp
			if vel.length() > p_max:
				vel = vel.normalized() * p_max
			p["vel"] = vel
			var pos: Vector2 = p["pos"] + vel * sub_dt

			var pr := float(p["radius"])
			if pos.x - pr < 0.0:
				pos.x = pr
				p["vel"].x = absf(p["vel"].x) * pw_rest
			elif pos.x + pr > float(stadium["w"]):
				pos.x = float(stadium["w"]) - pr
				p["vel"].x = -absf(p["vel"].x) * pw_rest
			if pos.y - pr < 0.0:
				pos.y = pr
				p["vel"].y = absf(p["vel"].y) * pw_rest
			elif pos.y + pr > float(stadium["h"]):
				pos.y = float(stadium["h"]) - pr
				p["vel"].y = -absf(p["vel"].y) * pw_rest
			p["pos"] = pos

			# Player-post & Player-segment collisions
			for post in stadium["posts"]:
				var res_pp := _resolve_circle_static_disc(p["pos"], p["vel"], pr, post, post_r, post_bcoef)
				p["pos"] = res_pp["pos"]
				p["vel"] = res_pp["vel"]
			for seg in stadium.get("segments", []):
				if seg["mask"] == "both" or seg["mask"] == "player":
					var res_ps := _resolve_circle_segment(p["pos"], p["vel"], pr, seg["a"], seg["b"], float(seg["bcoef"]))
					p["pos"] = res_ps["pos"]
					p["vel"] = res_ps["vel"]

			# Powerup pickup (8s = 480 ticks)
			if field_powerup != null and (p["pos"] as Vector2).distance_to(field_powerup["pos"]) <= pr + 12.0:
				p["powerup"] = field_powerup["type"]
				p["powerup_ticks"] = 480
				p["radius"] = 20.0 if p["powerup"] == "giant" else 15.0
				_broadcast_sys_chat("%s güç aldı: %s!" % [p["name"], p["powerup"]])
				field_powerup = null

			# Magnet pull (10..110 px, 0.14 * sub_dt)
			if p["powerup"] == "magnet":
				var md := (p["pos"] as Vector2).distance_to(ball["pos"])
				if md > 10.0 and md < 110.0:
					var pull := ((p["pos"] as Vector2) - (ball["pos"] as Vector2)).normalized() * (0.14 * sub_dt)
					ball["vel"] = (ball["vel"] as Vector2) + pull

		# Player-Player collisions with invMass
		for i in range(players.size()):
			if players[i]["team"] == "spec": continue
			for j in range(i + 1, players.size()):
				if players[j]["team"] == "spec": continue
				var d := (players[j]["pos"] as Vector2) - (players[i]["pos"] as Vector2)
				var min_d := float(players[i]["radius"]) + float(players[j]["radius"])
				var dist := d.length()
				if dist > 0.001 and dist < min_d:
					var n := d / dist
					var pen := (min_d - dist) * 0.5
					players[i]["pos"] = (players[i]["pos"] as Vector2) - n * pen
					players[j]["pos"] = (players[j]["pos"] as Vector2) + n * pen
					var rel := (players[j]["vel"] as Vector2) - (players[i]["vel"] as Vector2)
					var vn := rel.dot(n)
					if vn < 0.0:
						var imp := -(1.0 + float(phys["p_rest"])) * vn * 0.5
						players[i]["vel"] = (players[i]["vel"] as Vector2) - n * imp
						players[j]["vel"] = (players[j]["vel"] as Vector2) + n * imp

		# Ball movement
		var bvel: Vector2 = (ball["vel"] as Vector2) * b_damp
		var b_max := float(phys["b_max"]) * (1.65 if not ball_fire_type.is_empty() else 1.0)
		if bvel.length() > b_max:
			bvel = bvel.normalized() * b_max
		ball["vel"] = bvel
		ball["pos"] = (ball["pos"] as Vector2) + bvel * sub_dt

		# Player-Ball collisions & kick with invMass + Save detection
		for p in players:
			if p["team"] == "spec": continue
			var d := (ball["pos"] as Vector2) - (p["pos"] as Vector2)
			var min_d := float(p["radius"]) + float(ball["radius"])
			var dist := d.length()
			if dist > 0.001 and dist < min_d:
				var n := d / dist
				var inv_sum := p_invmass + b_invmass
				var pen := min_d - dist
				p["pos"] = (p["pos"] as Vector2) - n * (pen * p_invmass / inv_sum)
				ball["pos"] = (ball["pos"] as Vector2) + n * (pen * b_invmass / inv_sum)
				var rel := (ball["vel"] as Vector2) - (p["vel"] as Vector2)
				var vn := rel.dot(n)
				if vn < 0.0:
					var old_bvx: float = ball["vel"].x
					var imp := -(1.0 + float(phys["pb_rest"])) * vn / inv_sum
					p["vel"] = (p["vel"] as Vector2) - n * (imp * p_invmass)
					ball["vel"] = (ball["vel"] as Vector2) + n * (imp * b_invmass)
					_record_touch(p["id"], old_bvx, ball["vel"].x, p["team"])

			if bool(p["kick_armed"]) and dist <= min_d + 6.0 and tick >= int(p["next_kick_tick"]):
				var n := d.normalized() if dist > 0.001 else Vector2.RIGHT
				var kpow := float(phys["k_imp"])
				if p["powerup"] == "fire":
					kpow *= 1.55
					ball_fire_type = "fire"
					ball_fire_ticks = 150
				elif p["powerup"] == "hawk":
					kpow *= 1.95
					ball_fire_type = "hawk"
					ball_fire_ticks = 150
				var old_bvx2: float = ball["vel"].x
				ball["vel"] = (ball["vel"] as Vector2) + n * kpow
				p["kick_armed"] = false
				p["next_kick_tick"] = tick + 12
				p["kick_flash_ticks"] = 8
				_record_touch(p["id"], old_bvx2, ball["vel"].x, p["team"])
				audio_fx.play_kick()

		# Ball-Post & Ball-Segment collisions
		var br := float(ball["radius"])
		for post in stadium["posts"]:
			var res_bp := _resolve_circle_static_disc(ball["pos"], ball["vel"], br, post, post_r, post_bcoef)
			if res_bp["hit"]:
				ball["pos"] = res_bp["pos"]
				ball["vel"] = res_bp["vel"]
				audio_fx.play_post()
		for seg in stadium.get("segments", []):
			if seg["mask"] == "both" or seg["mask"] == "ball":
				var res_bs := _resolve_circle_segment(ball["pos"], ball["vel"], br, seg["a"], seg["b"], float(seg["bcoef"]))
				if res_bs["hit"]:
					ball["pos"] = res_bs["pos"]
					ball["vel"] = res_bs["vel"]

		# Ball goal check
		var bpos: Vector2 = ball["pos"]
		var in_goal_y := absf(bpos.y - cy) < gh - br
		if in_goal_y and not goal_pending and not match_ended_pending:
			if bpos.x + br < px:
				_trigger_goal("blue", bpos)
			elif bpos.x - br > px + pw:
				_trigger_goal("red", bpos)

	# Trail (only when speed > 2.4, max 10 points)
	if (ball["vel"] as Vector2).length() > 2.4:
		trail.append(ball["pos"])
		if trail.size() > 10:
			trail.pop_front()
	elif trail.size() > 0:
		trail.pop_front()

	if goal_pending:
		goal_reset_ticks -= 1
		if goal_reset_ticks <= 0:
			goal_pending = false
			if score_limit > 0 and (score_red >= score_limit or score_blue >= score_limit):
				_trigger_match_end("red" if score_red >= score_limit else "blue")
			else:
				reset_positions()

	# Particles
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["pos"] += particles[i]["vel"]
		particles[i]["life"] -= 1
		if int(particles[i]["life"]) <= 0:
			particles.remove_at(i)

func _record_touch(pid: String, old_vx: float, new_vx: float, team: String) -> void:
	if pid != last_touch_id:
		if tick - last_touch_tick <= 360:
			assist_touch_id = last_touch_id
		else:
			assist_touch_id = ""
	last_touch_id = pid
	last_touch_tick = tick

	# Save detection
	var cy := float(stadium["py"]) + float(stadium["ph"]) * 0.5
	var gh := float(stadium["gh"])
	var bpos: Vector2 = ball["pos"]
	if absf(bpos.y - cy) <= gh + 48.0 and tick - last_save_tick > 90:
		var is_red_save := team == "red" and bpos.x < float(stadium["px"]) + 110.0 and old_vx < -2.1 and new_vx > old_vx + 1.2
		var is_blue_save := team == "blue" and bpos.x > float(stadium["px"]) + float(stadium["pw"]) - 110.0 and old_vx > 2.1 and new_vx < old_vx - 1.2
		if is_red_save or is_blue_save:
			last_save_tick = tick
			audio_fx.play_save_oh()
			var sname := _get_player_name(pid)
			_broadcast_sys_chat("🧤 Kurtarış: %s!" % sname)
			if pid == my_id:
				GameData.profile["saves"] += 1
				GameData.save_profile()

func _get_player_name(pid: String) -> String:
	for p in players:
		if p["id"] == pid:
			return str(p["name"])
	return ""

func _trigger_goal(team: String, pos: Vector2) -> void:
	goal_pending = true
	goal_reset_ticks = 95
	if team == "red":
		score_red += 1
	else:
		score_blue += 1

	var scorer := _get_player_name(last_touch_id)
	var assist := ""
	if not assist_touch_id.is_empty() and assist_touch_id != last_touch_id:
		assist = _get_player_name(assist_touch_id)

	if last_touch_id == my_id:
		GameData.profile["goals"] += 1
		GameData.save_profile()
	elif assist_touch_id == my_id:
		GameData.profile["assists"] += 1
		GameData.save_profile()

	audio_fx.play_goal()
	emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)
	emit_signal("goal_scored", team, scorer, assist)
	if bool(GameData.settings.get("particles", true)):
		var col := Color("#ef4444") if team == "red" else Color("#3b82f6")
		for _i in range(28):
			var ang := randf() * TAU
			var spd := 1.5 + randf() * 4.5
			particles.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "r": 2.0 + randf() * 3.0, "col": col, "life": 45})

func _trigger_match_end(winner_team: String) -> void:
	match_ended_pending = true
	match_ended_ticks = 210 # 3.5 seconds
	audio_fx.play_game_end()
	for p in players:
		if p["id"] == my_id:
			GameData.profile["matches"] += 1
			if p["team"] == winner_team:
				GameData.profile["wins"] += 1
			GameData.save_profile()
			break
	emit_signal("match_ended", winner_team)
	_broadcast_sys_chat("🏆 Maç Bitti! Kazanan: %s (%d - %d)" % [("Kırmızı" if winner_team == "red" else "Mavi"), score_red, score_blue])

func _sync_view() -> void:
	if pitch_view == null:
		return
	pitch_view.stadium = stadium
	pitch_view.players = players
	pitch_view.ball = ball
	pitch_view.trail = trail
	pitch_view.particles = particles
	pitch_view.field_powerup = field_powerup
	pitch_view.ball_fire_type = ball_fire_type
	pitch_view.my_player_id = my_id
	pitch_view.my_ping_ms = last_ping_ms
	pitch_view.queue_redraw()

# ============================================================================
# ENET MULTIPLAYER RPCs
# ============================================================================

func _on_peer_connected(_id: int) -> void:
	pass

func _on_peer_disconnected(id: int) -> void:
	var sid := str(id)
	_remote_inputs.erase(sid)
	for i in range(players.size()):
		if players[i]["id"] == sid:
			var pname: String = players[i]["name"]
			players.remove_at(i)
			emit_signal("roster_changed")
			_broadcast_sys_chat("%s odadan ayrıldı." % pname)
			break

func _on_connected_to_server() -> void:
	my_id = str(multiplayer.get_unique_id())
	_rpc_join_handshake.rpc_id(
		1,
		str(GameData.settings.get("nickname", "Oyuncu")),
		str(GameData.settings.get("avatar", ":)")),
		str(GameData.settings.get("country", "TR")),
		room_password
	)

func _on_connection_failed() -> void:
	emit_signal("auth_rejected", "Sunucuya bağlanılamadı.")

func _on_server_disconnected() -> void:
	emit_signal("auth_rejected", "Host bağlantısı koptu.")
	stop_room()

@rpc("any_peer", "reliable")
func _rpc_join_handshake(pname: String, pav: String, country: String, pw: String) -> void:
	if not multiplayer.is_server():
		return
	var sid := str(multiplayer.get_remote_sender_id())
	if room_locked:
		_rpc_auth_error.rpc_id(int(sid), "Oda girişi kilitli.")
		return
	if not room_password.is_empty() and pw != room_password:
		_rpc_auth_error.rpc_id(int(sid), "Oda şifresi hatalı.")
		return
	if players.size() >= max_players:
		_rpc_auth_error.rpc_id(int(sid), "Oda dolu.")
		return
	var red_c := players.filter(func(p): return p["team"] == "red").size()
	var blue_c := players.filter(func(p): return p["team"] == "blue").size()
	var team := "red" if red_c <= blue_c else "blue"
	var np := _make_player(sid, GameData.censor_text(pname.substr(0, 20)), pav.substr(0, 2), team, false, false, country)
	players.append(np)
	_place_single_player(np)
	_rpc_welcome.rpc_id(int(sid), sid, room_name, str(stadium["id"]), score_limit, time_limit, powerup_mode)
	emit_signal("roster_changed")
	_broadcast_sys_chat("%s odaya katıldı." % np["name"])

@rpc("authority", "reliable")
func _rpc_welcome(assigned_id: String, rname: String, st_id: String, s_lim: int, t_lim: int, pu: String) -> void:
	my_id = assigned_id
	room_name = rname
	stadium = GameData.get_stadium(st_id)
	score_limit = s_lim
	time_limit = t_lim
	powerup_mode = pu
	emit_signal("roster_changed")

@rpc("authority", "reliable")
func _rpc_auth_error(reason: String) -> void:
	emit_signal("auth_rejected", reason)
	stop_room()

@rpc("authority", "reliable")
func _rpc_kicked(reason: String) -> void:
	emit_signal("auth_rejected", reason)
	stop_room()

@rpc("any_peer", "unreliable_ordered")
func _rpc_client_input(bits: int) -> void:
	if not multiplayer.is_server():
		return
	_remote_inputs[str(multiplayer.get_remote_sender_id())] = bits

func _broadcast_snapshot() -> void:
	var snap := {
		"st": stadium["id"],
		"sr": score_red,
		"sb": score_blue,
		"sec": match_seconds,
		"p": paused,
		"lk": teams_locked,
		"rl": room_locked,
		"pu": field_powerup,
		"bf": ball_fire_type,
		"bx": ball["pos"].x,
		"by": ball["pos"].y,
		"bvx": ball["vel"].x,
		"bvy": ball["vel"].y,
		"pl": []
	}
	for p in players:
		snap["pl"].append({
			"id": p["id"],
			"n": p["name"],
			"a": p["avatar"],
			"c": p["country"],
			"t": p["team"],
			"b": p["is_bot"],
			"ad": p["is_admin"],
			"x": p["pos"].x,
			"y": p["pos"].y,
			"vx": p["vel"].x,
			"vy": p["vel"].y,
			"r": p["radius"],
			"pu": p["powerup"],
			"kf": p["kick_flash_ticks"],
			"pg": p["ping"],
			"cc": p.get("custom_color", "")
		})
	_rpc_snapshot.rpc(snap)

@rpc("authority", "unreliable_ordered")
func _rpc_snapshot(snap: Dictionary) -> void:
	if multiplayer.is_server():
		return
	var st_id: String = str(snap.get("st", "classic"))
	if stadium.get("id", "") != st_id:
		stadium = GameData.get_stadium(st_id)
	var old_sr := score_red
	var old_sb := score_blue
	score_red = int(snap.get("sr", 0))
	score_blue = int(snap.get("sb", 0))
	match_seconds = int(snap.get("sec", 0))
	paused = bool(snap.get("p", false))
	teams_locked = bool(snap.get("lk", false))
	room_locked = bool(snap.get("rl", false))
	field_powerup = snap.get("pu", null)
	ball_fire_type = str(snap.get("bf", ""))
	ball["pos"] = Vector2(float(snap.get("bx", 430.0)), float(snap.get("by", 230.0)))
	ball["vel"] = Vector2(float(snap.get("bvx", 0.0)), float(snap.get("bvy", 0.0)))

	var new_players: Array = []
	for pd in snap.get("pl", []):
		var np := _make_player(pd["id"], pd["n"], pd["a"], pd["t"], pd["b"], pd["ad"], pd.get("c", "TR"))
		np["pos"] = Vector2(float(pd["x"]), float(pd["y"]))
		np["vel"] = Vector2(float(pd["vx"]), float(pd["vy"]))
		np["radius"] = float(pd["r"])
		np["powerup"] = str(pd["pu"])
		np["kick_flash_ticks"] = int(pd.get("kf", 0))
		np["ping"] = int(pd.get("pg", 0))
		np["custom_color"] = str(pd.get("cc", ""))
		new_players.append(np)
	var count_changed := new_players.size() != players.size()
	players = new_players
	if count_changed:
		emit_signal("roster_changed")
	if score_red != old_sr or score_blue != old_sb:
		audio_fx.play_goal()
	emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)

@rpc("any_peer", "reliable")
func _rpc_chat(author: String, text: String, is_sys: bool) -> void:
	if multiplayer.is_server():
		emit_signal("chat_message", author, text, is_sys)
		_rpc_chat.rpc(author, text, is_sys)
	else:
		emit_signal("chat_message", author, text, is_sys)

@rpc("any_peer", "reliable")
func _rpc_request_team(new_team: String) -> void:
	if not multiplayer.is_server() or teams_locked:
		return
	var sid := str(multiplayer.get_remote_sender_id())
	request_team_change(sid, new_team)

@rpc("any_peer", "reliable")
func _rpc_admin_cmd(cmd: String, args: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sid := str(multiplayer.get_remote_sender_id())
	var sender_admin := false
	for p in players:
		if p["id"] == sid:
			sender_admin = bool(p["is_admin"])
			break
	if not sender_admin:
		return
	match cmd:
		"add_bot": add_bot(str(args.get("team", "blue")))
		"remove_bot": remove_last_bot(str(args.get("team", "")))
		"clear_bots": clear_bots()
		"set_stadium": set_stadium_id(str(args.get("id", "classic")))
		"set_team": request_team_change(str(args.get("id", "")), str(args.get("team", "spec")))
		"toggle_admin": toggle_admin(str(args.get("id", "")))
		"kick": kick_player(str(args.get("id", "")))
		"reset_match": reset_match()
		"auto_balance": auto_balance_teams()
		"randomize_teams": randomize_teams()
		"toggle_pause":
			paused = not paused
			emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)

@rpc("any_peer", "unreliable")
func _rpc_ping(client_ts: int) -> void:
	var sender := multiplayer.get_remote_sender_id()
	_rpc_pong.rpc_id(sender, client_ts)

@rpc("any_peer", "unreliable")
func _rpc_pong(orig_ts: int) -> void:
	var rtt := maxi(1, Time.get_ticks_msec() - orig_ts)
	var sender := str(multiplayer.get_remote_sender_id())
	if room_kind == "client":
		last_ping_ms = rtt
	else:
		for p in players:
			if p["id"] == sender:
				p["ping"] = rtt
				break
