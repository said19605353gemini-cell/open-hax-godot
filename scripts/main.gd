extends Control

@onready var view_auth: Control = %ViewAuth
@onready var view_lobby: Control = %ViewLobby
@onready var view_room: Control = %ViewRoom
@onready var topbar_score: Control = %TopbarScore
@onready var score_lbl: Label = %ScoreLbl
@onready var timer_lbl: Label = %TimerLbl
@onready var fps_hud: Label = %FpsHud

@onready var auth_nick: LineEdit = %AuthNick
@onready var auth_avatar: LineEdit = %AuthAvatar
@onready var auth_country: OptionButton = %AuthCountry
@onready var auth_stats: Label = %AuthStats

@onready var join_ip: LineEdit = %JoinIp
@onready var join_port: LineEdit = %JoinPort
@onready var create_name: LineEdit = %CreateName
@onready var create_type: OptionButton = %CreateType
@onready var create_stadium: OptionButton = %CreateStadium
@onready var create_bots: OptionButton = %CreateBots
@onready var create_botdiff: OptionButton = %CreateBotDiff
@onready var create_physics: OptionButton = %CreatePhysics
@onready var create_powerup: OptionButton = %CreatePowerup
@onready var create_fps: SpinBox = %CreateFps

@onready var pitch_container: Control = %PitchContainer
@onready var chat_log: RichTextLabel = %ChatLog
@onready var chat_input: LineEdit = %ChatInput
@onready var pause_overlay: Control = %PauseOverlay
@onready var goal_banner: Label = %GoalBanner
@onready var settings_modal: Control = %SettingsModal
@onready var teams_modal: Control = %TeamsModal

@onready var set_fps: SpinBox = %SetFps
@onready var set_room_fps: SpinBox = %SetRoomFps
@onready var set_grass: OptionButton = %SetGrass
@onready var set_perfboost: CheckBox = %SetPerfBoost
@onready var set_sound: CheckBox = %SetSound
@onready var lang_select: OptionButton = %LangSelect
@onready var global_chat_log: RichTextLabel = %GlobalChatLog
@onready var global_chat_input: LineEdit = %GlobalChatInput
@onready var rooms_list: ItemList = %RoomsList
@onready var leaderboard_lbl: Label = %LeaderboardLbl
@onready var lobby_status: Label = %LobbyStatus

var world: MatchWorld
var pitch_view: PitchView
var _active_room_code := ""
var _poll_accum := 0.0

func _ready() -> void:
	world = MatchWorld.new()
	add_child(world)

	pitch_view = PitchView.new()
	pitch_container.add_child(pitch_view)
	world.pitch_view = pitch_view

	world.scoreboard_changed.connect(_on_scoreboard)
	world.goal_scored.connect(_on_goal)
	world.chat_message.connect(_on_chat_msg)
	FirebaseService.rooms_loaded.connect(_on_firebase_rooms)
	FirebaseService.chat_loaded.connect(_on_firebase_chat)
	FirebaseService.leaderboard_loaded.connect(_on_firebase_leaderboard)

	_populate_options()
	_sync_settings_to_ui()
	_switch_screen("auth")
	FirebaseService.fetch_leaderboard()

func _populate_options() -> void:
	for c in ["TR", "AZ", "DE", "FR", "GB", "US", "ES", "IT", "BR", "RU", "SA", "JP", "KR", "GL"]:
		auth_country.add_item(c)
	for l in ["tr", "en", "de", "fr", "es", "az", "ru"]:
		lang_select.add_item(l.to_upper())
	for st_id in ["classic", "big", "huge", "futsal", "tiny", "long", "arena_3v3", "mini_fast", "hbs_classic", "hbs_big", "hbs_huge"]:
		create_stadium.add_item(st_id)
	for bd in GameData.BOT_DIFFICULTIES:
		create_botdiff.add_item(bd)
	create_botdiff.selected = 2
	for ph in ["openhax", "classic_hax", "pro_control", "turbo", "futsal", "real_soccer", "ice_hockey", "pinball", "heavy_tank"]:
		create_physics.add_item(ph)
	for pu in ["none", "hawk", "fire", "speed", "magnet", "giant", "all"]:
		create_powerup.add_item(pu)
	for gr in GameData.GRASS_THEMES:
		set_grass.add_item(gr)
	for t in ["Çevrimdışı (Bot)", "2 Kişilik Yerel", "Online Host (LAN/IP)"]:
		create_type.add_item(t)
	for bp in ["1blue", "2v2", "5v5", "none"]:
		create_bots.add_item(bp)

func _sync_settings_to_ui() -> void:
	auth_nick.text = GameData.settings.get("nickname", "Oyuncu")
	auth_avatar.text = GameData.settings.get("avatar", ":)")
	set_fps.value = int(GameData.settings.get("fps_limit", 60))
	set_room_fps.value = int(GameData.settings.get("room_max_fps", 0))
	set_perfboost.button_pressed = bool(GameData.settings.get("perf_boost", false))
	set_sound.button_pressed = bool(GameData.settings.get("master_sound", true))
	auth_stats.text = "⚽ Goller: %d  ·  🏆 Galibiyet: %d" % [GameData.profile["goals"], GameData.profile["wins"]]

func _process(delta: float) -> void:
	fps_hud.text = "%d FPS (%s)" % [Engine.get_frames_per_second(), GameData.get_effective_fps_label()]
	_poll_accum += delta
	if _poll_accum >= 5.0:
		_poll_accum = 0.0
		if view_lobby.visible:
			FirebaseService.fetch_rooms()
			FirebaseService.fetch_global_chat()
		elif view_room.visible and not _active_room_code.is_empty():
			FirebaseService.publish_room({
				"code": _active_room_code,
				"name": world.room_name,
				"hostName": GameData.settings.get("nickname", "Oyuncu"),
				"stadium": world.stadium.get("id", "classic"),
				"players": world.players.filter(func(p): return not p["is_bot"]).size(),
				"bots": world.players.filter(func(p): return p["is_bot"]).size(),
				"country": GameData.settings.get("country", "TR")
			})
	if view_room.visible and not world.stadium.is_empty():
		var sw := float(world.stadium["w"])
		var sh := float(world.stadium["h"])
		var av := pitch_container.size
		if av.x > 10 and av.y > 10:
			var sc := minf(av.x / sw, av.y / sh)
			pitch_view.scale = Vector2(sc, sc)
			pitch_view.position = (av - Vector2(sw, sh) * sc) * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if not view_room.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if get_viewport().gui_get_focus_owner() is LineEdit:
			return
		if event.keycode == KEY_P:
			world.paused = not world.paused
			pause_overlay.visible = world.paused
		elif event.keycode == KEY_R:
			world.reset_match()
			pause_overlay.visible = false
		elif event.keycode == KEY_ESCAPE:
			if settings_modal.visible:
				settings_modal.visible = false
			else:
				teams_modal.visible = not teams_modal.visible

func _switch_screen(scr: String) -> void:
	view_auth.visible = scr == "auth"
	view_lobby.visible = scr == "lobby"
	view_room.visible = scr == "room"
	topbar_score.visible = scr == "room"
	pause_overlay.visible = false
	goal_banner.visible = false
	if scr == "lobby":
		FirebaseService.fetch_rooms()
		FirebaseService.fetch_global_chat()
		FirebaseService.fetch_leaderboard()

func _on_btn_auth_enter_pressed() -> void:
	var n := GameData.censor_text(auth_nick.text.strip_edges())
	if n.is_empty():
		n = "Oyuncu"
	GameData.settings["nickname"] = n
	GameData.settings["avatar"] = auth_avatar.text.strip_edges() if not auth_avatar.text.strip_edges().is_empty() else ":)"
	GameData.settings["country"] = auth_country.get_item_text(auth_country.selected)
	GameData.save_settings()
	_switch_screen("lobby")

func _on_btn_create_room_pressed() -> void:
	var kind_idx := create_type.selected
	var kind := "offline" if kind_idx == 0 else ("local2p" if kind_idx == 1 else "host")
	if kind == "host" and not OS.has_feature("web"):
		var chk: Dictionary = await FirebaseService.can_create_room(GameData.settings.get("nickname", "Oyuncu"))
		if not bool(chk.get("ok", true)):
			lobby_status.text = "Aynı IP/kişi en fazla 3 aktif oda açabilir (%d/3)!" % int(chk.get("count", 3))
			return
	var st_id := create_stadium.get_item_text(create_stadium.selected)
	var bdiff := create_botdiff.get_item_text(create_botdiff.selected)
	var phys := create_physics.get_item_text(create_physics.selected)
	var pu := create_powerup.get_item_text(create_powerup.selected)
	var bp := create_bots.get_item_text(create_bots.selected)
	GameData.settings["bot_difficulty"] = bdiff
	GameData.settings["physics_profile"] = phys
	GameData.settings["stadium"] = st_id
	GameData.settings["room_max_fps"] = int(create_fps.value)
	GameData.save_settings()
	if kind == "host":
		if OS.has_feature("web"):
			_on_chat_msg("Sistem", "Web tarayıcıda P2P Host yerine Çevrimdışı Bot / 2 Kişilik Yerel mod açıldı (ENet yalnızca Masaüstü sürümde çalışır).", true)
			kind = "offline"
		else:
			var peer := ENetMultiplayerPeer.new()
			peer.create_server(7777, 16)
			multiplayer.multiplayer_peer = peer
	world.start_room(kind, create_name.text, st_id, bp, 5, 180, pu)
	if kind == "host":
		_active_room_code = "GD" + str(randi_range(1000, 9999))
		FirebaseService.publish_room({
			"code": _active_room_code,
			"name": world.room_name,
			"hostName": GameData.settings.get("nickname", "Oyuncu"),
			"stadium": st_id,
			"players": 1,
			"bots": world.players.filter(func(p): return p["is_bot"]).size(),
			"country": GameData.settings.get("country", "TR")
		})
	else:
		_active_room_code = ""
	chat_log.clear()
	_switch_screen("room")

func _on_btn_join_ip_pressed() -> void:
	if OS.has_feature("web"):
		return
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(join_ip.text.strip_edges(), int(join_port.text))
	if err == OK:
		multiplayer.multiplayer_peer = peer
		world.start_room("client", "Uzak Oda", "classic", "none", 5, 180, "none")
		_switch_screen("room")

func _on_btn_leave_pressed() -> void:
	if not _active_room_code.is_empty():
		FirebaseService.remove_room(_active_room_code)
		_active_room_code = ""
	world.stop_room()
	GameData.settings["room_max_fps"] = 0
	GameData.apply_fps_limit()
	_switch_screen("lobby")

func _on_scoreboard(r: int, b: int, sec: int, p: bool) -> void:
	score_lbl.text = "%d  -  %d" % [r, b]
	@warning_ignore("integer_division")
	var m := sec / 60
	var s := sec % 60
	timer_lbl.text = "%02d:%02d" % [m, s]
	pause_overlay.visible = p

func _on_goal(team: String) -> void:
	goal_banner.text = GameData.tr_key("goal_red" if team == "red" else "goal_blue")
	goal_banner.visible = true
	FirebaseService.save_cloud_profile(
		GameData.settings.get("nickname", "Oyuncu"),
		GameData.settings.get("country", "TR"),
		int(GameData.profile["goals"]),
		int(GameData.profile["wins"]),
		int(GameData.profile["play_seconds"])
	)
	await get_tree().create_timer(1.5).timeout
	goal_banner.visible = false

func _on_btn_global_send_pressed() -> void:
	var txt := global_chat_input.text.strip_edges()
	if txt.is_empty():
		return
	global_chat_input.clear()
	FirebaseService.send_global_chat(
		GameData.settings.get("nickname", "Oyuncu"),
		txt,
		GameData.settings.get("country", "TR")
	)

func _on_firebase_rooms(rooms: Array) -> void:
	rooms_list.clear()
	if rooms.is_empty():
		rooms_list.add_item("Henüz açık Firebase odası yok.")
		return
	for r in rooms:
		rooms_list.add_item("[%s] %s | %s | %s (%d+%d Bot)" % [
			str(r.get("country", "TR")),
			str(r.get("name", "Oda")),
			str(r.get("hostName", "?")),
			str(r.get("stadium", "classic")),
			int(r.get("players", 1)),
			int(r.get("bots", 0))
		])

func _on_firebase_chat(rows: Array) -> void:
	global_chat_log.clear()
	for m in rows:
		global_chat_log.append_text("[b][%s] %s:[/b] %s\n" % [
			str(m.get("country", "TR")),
			str(m.get("author", "Oyuncu")),
			str(m.get("text", ""))
		])

func _on_firebase_leaderboard(players: Array) -> void:
	if players.is_empty():
		leaderboard_lbl.text = "Henüz liderlik verisi yok."
		return
	var lines := []
	for i in range(mini(5, players.size())):
		var p: Dictionary = players[i]
		lines.append("%d. [%s] %s (%d Gol)" % [i + 1, str(p.get("country", "TR")), str(p.get("username", "?")), int(p.get("goals", 0))])
	leaderboard_lbl.text = "\n".join(lines)

func _on_chat_msg(author: String, text: String, is_sys: bool) -> void:
	var safe_a := author if is_sys else GameData.censor_text(author)
	var safe_t := GameData.censor_text(text)
	chat_log.append_text("[b]%s:[/b] %s\n" % [safe_a, safe_t])

func _on_chat_send_pressed() -> void:
	var msg := chat_input.text.strip_edges()
	if msg.is_empty():
		return
	chat_input.clear()
	_on_chat_msg(GameData.settings["nickname"], msg, false)

func _on_btn_add_red_bot() -> void: world.add_bot("red")
func _on_btn_add_blue_bot() -> void: world.add_bot("blue")
func _on_btn_rem_bot() -> void: world.remove_last_bot()
func _on_btn_clear_bots() -> void: world.clear_bots()
func _on_btn_pause_pressed() -> void:
	world.paused = not world.paused
	pause_overlay.visible = world.paused
func _on_btn_reset_pressed() -> void:
	world.reset_match()
	pause_overlay.visible = false
func _on_btn_settings_pressed() -> void:
	settings_modal.visible = not settings_modal.visible
func _on_btn_teams_pressed() -> void:
	teams_modal.visible = not teams_modal.visible
func _on_btn_apply_settings_pressed() -> void:
	GameData.settings["fps_limit"] = int(set_fps.value)
	GameData.settings["room_max_fps"] = int(set_room_fps.value)
	GameData.settings["grass_detail"] = set_grass.get_item_text(set_grass.selected)
	GameData.settings["perf_boost"] = set_perfboost.button_pressed
	GameData.settings["master_sound"] = set_sound.button_pressed
	GameData.settings["lang"] = lang_select.get_item_text(lang_select.selected).to_lower()
	GameData.save_settings()
	settings_modal.visible = false
