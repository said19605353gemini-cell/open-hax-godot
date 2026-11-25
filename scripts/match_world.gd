extends Node
class_name MatchWorld

signal scoreboard_changed(red: int, blue: int, seconds: int, paused: bool)
signal goal_scored(team: String)
signal chat_message(author: String, text: String, is_system: bool)
signal roster_changed

var pitch_view: PitchView
var audio_fx: AudioFX

var active := false
var paused := false
var room_kind := "offline" # offline | local2p | host | client
var room_name := "OpenHax Godot Oda"
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
var enabled_powerups: Array = []
var field_powerup = null
var ball_fire_type := ""
var next_powerup_tick := 240
var goal_pending := false
var goal_reset_ticks := 0
var teams_locked := false
var my_id := "host"

func _ready() -> void:
	stadium = GameData.get_stadium(GameData.settings.get("stadium", "classic"))
	audio_fx = AudioFX.new()
	add_child(audio_fx)

func start_room(kind: String, rname: String, st_id: String, bot_preset: String, p_limit: int, t_limit: int, pu_mode: String) -> void:
	room_kind = kind
	room_name = GameData.censor_text(rname)
	stadium = GameData.get_stadium(st_id)
	score_limit = p_limit
	time_limit = t_limit
	enabled_powerups = []
	if pu_mode == "all":
		enabled_powerups = GameData.POWERUP_TYPES.duplicate()
	elif pu_mode != "none" and not pu_mode.is_empty():
		enabled_powerups = [pu_mode]

	players.clear()
	bot_counter = 1
	my_id = "host"
	players.append(_make_player("host", GameData.settings["nickname"], GameData.settings["avatar"], "red", false, true))

	if kind == "local2p":
		players.append(_make_player("local2", "Oyuncu 2", ":(", "blue", false, false))
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
	emit_signal("roster_changed")

func stop_room() -> void:
	active = false
	paused = false
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer = null

func _make_player(pid: String, pname: String, pav: String, team: String, is_bot: bool, is_admin: bool) -> Dictionary:
	return {
		"id": pid,
		"name": pname,
		"avatar": pav,
		"team": team,
		"is_bot": is_bot,
		"is_admin": is_admin,
		"pos": Vector2.ZERO,
		"vel": Vector2.ZERO,
		"radius": 15.0,
		"kick_armed": false,
		"prev_kick": false,
		"next_kick_tick": 0,
		"powerup": "",
		"powerup_ticks": 0
	}

func add_bot(team: String) -> void:
	var prefix := "Bot-K" if team == "red" else "Bot-M"
	var bname := "%s%d" % [prefix, bot_counter]
	var bid := "bot-%d" % bot_counter
	bot_counter += 1
	players.append(_make_player(bid, bname, "AI", team, true, false))
	_place_single_player(players[-1])
	emit_signal("roster_changed")
	emit_signal("chat_message", "Sistem", "%s (%s) oyuna eklendi." % [bname, team], true)

func remove_last_bot(team_filter: String = "") -> void:
	for i in range(players.size() - 1, -1, -1):
		if players[i]["is_bot"] and (team_filter.is_empty() or players[i]["team"] == team_filter):
			var removed: String = players[i]["name"]
			players.remove_at(i)
			emit_signal("roster_changed")
			emit_signal("chat_message", "Sistem", "%s oyundan çıkarıldı." % removed, true)
			return

func clear_bots() -> void:
	players = players.filter(func(p): return not p["is_bot"])
	emit_signal("roster_changed")

func reset_match() -> void:
	score_red = 0
	score_blue = 0
	match_seconds = 0
	tick = 0
	tick_in_sec = 0
	paused = false
	goal_pending = false
	field_powerup = null
	ball_fire_type = ""
	next_powerup_tick = 240
	reset_positions()
	emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)

func reset_positions() -> void:
	var px := float(stadium["px"])
	var py := float(stadium["py"])
	var pw := float(stadium["pw"])
	var ph := float(stadium["ph"])
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5
	ball["pos"] = Vector2(cx, cy)
	ball["vel"] = Vector2.ZERO
	trail.clear()
	ball_fire_type = ""

	var reds := players.filter(func(p): return p["team"] == "red")
	var blues := players.filter(func(p): return p["team"] == "blue")
	for i in range(reds.size()):
		var off_y := (float(i) - float(reds.size() - 1) * 0.5) * 44.0
		reds[i]["pos"] = Vector2(cx - 110.0 - float(i % 2) * 55.0, clampf(cy + off_y, py + 24.0, py + ph - 24.0))
		reds[i]["vel"] = Vector2.ZERO
	for i in range(blues.size()):
		var off_y := (float(i) - float(blues.size() - 1) * 0.5) * 44.0
		blues[i]["pos"] = Vector2(cx + 110.0 + float(i % 2) * 55.0, clampf(cy + off_y, py + 24.0, py + ph - 24.0))
		blues[i]["vel"] = Vector2.ZERO

func _place_single_player(p: Dictionary) -> void:
	var px := float(stadium["px"])
	var py := float(stadium["py"])
	var pw := float(stadium["pw"])
	var ph := float(stadium["ph"])
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5
	if p["team"] == "red":
		p["pos"] = Vector2(cx - 120.0, cy)
	elif p["team"] == "blue":
		p["pos"] = Vector2(cx + 120.0, cy)
	p["vel"] = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if not active or paused:
		_sync_view()
		return

	if room_kind == "client":
		_sync_view()
		return

	tick += 1
	if not goal_pending:
		tick_in_sec += 1
		if tick_in_sec >= 60:
			tick_in_sec = 0
			match_seconds += 1
			emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)
			if time_limit > 0 and match_seconds >= time_limit and score_red != score_blue:
				reset_match()
				return

	_step_physics()
	_sync_view()

func _step_physics() -> void:
	var phys := GameData.get_physics_params(GameData.settings.get("physics_profile", "openhax"))
	var px := float(stadium["px"])
	var py := float(stadium["py"])
	var pw := float(stadium["pw"])
	var ph := float(stadium["ph"])
	var gh := float(stadium["gh"])
	var gd := float(stadium["gd"])
	var cy := py + ph * 0.5

	# Powerups spawn
	if enabled_powerups.size() > 0 and field_powerup == null and tick >= next_powerup_tick:
		var tname: String = enabled_powerups[randi() % enabled_powerups.size()]
		field_powerup = {
			"pos": Vector2(px + pw * (0.25 + randf() * 0.5), py + ph * (0.2 + randf() * 0.6)),
			"type": tname
		}
		next_powerup_tick = tick + 420

	var red_bots := players.filter(func(p): return p["is_bot"] and p["team"] == "red")
	var blue_bots := players.filter(func(p): return p["is_bot"] and p["team"] == "blue")
	var bot_diff: String = GameData.settings.get("bot_difficulty", "medium")

	for p in players:
		if p["team"] == "spec":
			continue
		if int(p["powerup_ticks"]) > 0:
			p["powerup_ticks"] -= 1
			if int(p["powerup_ticks"]) <= 0:
				p["powerup"] = ""
				p["radius"] = 15.0

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

		if kick_down and not bool(p["prev_kick"]):
			p["kick_armed"] = true
		elif not kick_down:
			p["kick_armed"] = false
		p["prev_kick"] = kick_down

		if move.length() > 1.0:
			move = move.normalized()
		var p_acc := float(phys["k_accel"]) if kick_down else float(phys["accel"])
		var p_max := float(phys["p_max"]) * speed_scale
		if p["powerup"] == "speed":
			p_acc *= 1.45
			p_max *= 1.4

		var vel: Vector2 = p["vel"] + move * p_acc
		vel *= float(phys["p_damp"])
		if vel.length() > p_max:
			vel = vel.normalized() * p_max
		p["vel"] = vel
		var pos: Vector2 = p["pos"] + vel
		pos.x = clampf(pos.x, 15.0, float(stadium["w"]) - 15.0)
		pos.y = clampf(pos.y, 15.0, float(stadium["h"]) - 15.0)
		p["pos"] = pos

		# Powerup pickup
		if field_powerup != null and pos.distance_to(field_powerup["pos"]) <= float(p["radius"]) + 12.0:
			p["powerup"] = field_powerup["type"]
			p["powerup_ticks"] = 480
			p["radius"] = 22.0 if p["powerup"] == "giant" else 15.0
			emit_signal("chat_message", "Sistem", "%s güç aldı: %s!" % [p["name"], p["powerup"]], true)
			field_powerup = null

		# Magnet pull
		if p["powerup"] == "magnet" and pos.distance_to(ball["pos"]) < 140.0:
			var pull := (pos - (ball["pos"] as Vector2)).normalized() * 0.22
			ball["vel"] = (ball["vel"] as Vector2) + pull

	# Player-Player collisions
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
	var bvel: Vector2 = (ball["vel"] as Vector2) * float(phys["b_damp"])
	if bvel.length() > float(phys["b_max"]):
		bvel = bvel.normalized() * float(phys["b_max"])
	ball["vel"] = bvel
	ball["pos"] = (ball["pos"] as Vector2) + bvel

	trail.append(ball["pos"])
	if trail.size() > 14:
		trail.pop_front()

	# Player-Ball collisions & kick
	for p in players:
		if p["team"] == "spec": continue
		var d := (ball["pos"] as Vector2) - (p["pos"] as Vector2)
		var min_d := float(p["radius"]) + float(ball["radius"])
		var dist := d.length()
		if dist > 0.001 and dist < min_d:
			var n := d / dist
			ball["pos"] = (p["pos"] as Vector2) + n * min_d
			var rel := (ball["vel"] as Vector2) - (p["vel"] as Vector2)
			var vn := rel.dot(n)
			if vn < 0.0:
				var imp := -(1.0 + float(phys["pb_rest"])) * vn
				ball["vel"] = (ball["vel"] as Vector2) + n * imp * 0.75
		if bool(p["kick_armed"]) and dist <= min_d + 6.0 and tick >= int(p["next_kick_tick"]):
			var n := d.normalized() if dist > 0.001 else Vector2.RIGHT
			var kpow := float(phys["k_imp"])
			if p["powerup"] == "fire":
				kpow *= 1.55
				ball_fire_type = "fire"
			elif p["powerup"] == "hawk":
				kpow *= 1.4
				ball_fire_type = "hawk"
			ball["vel"] = (ball["vel"] as Vector2) + n * kpow
			p["kick_armed"] = false
			p["next_kick_tick"] = tick + 12
			audio_fx.play_kick()

	# Ball-Post collisions
	for post in stadium["posts"]:
		var d := (ball["pos"] as Vector2) - (post as Vector2)
		var min_d := 8.0 + float(ball["radius"])
		var dist := d.length()
		if dist > 0.001 and dist < min_d:
			var n := d / dist
			ball["pos"] = (post as Vector2) + n * min_d
			var vn := (ball["vel"] as Vector2).dot(n)
			if vn < 0.0:
				ball["vel"] = (ball["vel"] as Vector2) - n * (1.8 * vn)
				audio_fx.play_post()

	# Ball walls & Goals
	var bpos: Vector2 = ball["pos"]
	var br := float(ball["radius"])
	var in_goal_y := absf(bpos.y - cy) < gh - br
	var bw_rest := float(phys["bw_rest"])

	if bpos.y - br < py:
		bpos.y = py + br
		ball["vel"].y = absf(ball["vel"].y) * bw_rest
	elif bpos.y + br > py + ph:
		bpos.y = py + ph - br
		ball["vel"].y = -absf(ball["vel"].y) * bw_rest

	if not in_goal_y:
		if bpos.x - br < px:
			bpos.x = px + br
			ball["vel"].x = absf(ball["vel"].x) * bw_rest
		elif bpos.x + br > px + pw:
			bpos.x = px + pw - br
			ball["vel"].x = -absf(ball["vel"].x) * bw_rest
	else:
		# Goal net bounds
		if bpos.x < px - gd + br:
			bpos.x = px - gd + br
			ball["vel"].x = absf(ball["vel"].x) * 0.25
		elif bpos.x > px + pw + gd - br:
			bpos.x = px + pw + gd - br
			ball["vel"].x = -absf(ball["vel"].x) * 0.25

		if not goal_pending:
			if bpos.x + br < px:
				_trigger_goal("blue", bpos)
			elif bpos.x - br > px + pw:
				_trigger_goal("red", bpos)

	ball["pos"] = bpos

	if goal_pending:
		goal_reset_ticks -= 1
		if goal_reset_ticks <= 0:
			goal_pending = false
			if score_limit > 0 and (score_red >= score_limit or score_blue >= score_limit):
				reset_match()
			else:
				reset_positions()

	# Particles
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["pos"] += particles[i]["vel"]
		particles[i]["life"] -= 1
		if int(particles[i]["life"]) <= 0:
			particles.remove_at(i)

func _trigger_goal(team: String, pos: Vector2) -> void:
	goal_pending = true
	goal_reset_ticks = 95
	if team == "red":
		score_red += 1
	else:
		score_blue += 1
	GameData.profile["goals"] += 1
	GameData.save_profile()
	audio_fx.play_goal()
	emit_signal("scoreboard_changed", score_red, score_blue, match_seconds, paused)
	emit_signal("goal_scored", team)
	if bool(GameData.settings.get("particles", true)):
		var col := Color("#ef4444") if team == "red" else Color("#3b82f6")
		for _i in range(28):
			var ang := randf() * TAU
			var spd := 1.5 + randf() * 4.5
			particles.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "r": 2.0 + randf() * 3.0, "col": col, "life": 45})

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
	pitch_view.queue_redraw()
