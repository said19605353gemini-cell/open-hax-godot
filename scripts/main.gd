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
var _last_global_chat_ms := 0
var _last_room_chat_ms := 0
var _cached_rooms: Array = []

# Dynamic UI controls
var _user_pill: Label
var _btn_mute: Button
var _auth_pass: LineEdit
var _auth_err_lbl: Label
var _lobby_search: LineEdit
var _join_pass: LineEdit
var _create_pass: LineEdit
var _create_score_lim: OptionButton
var _create_time_lim: OptionButton
var _create_max_p: SpinBox
var _room_botdiff: OptionButton
var _room_stadium: OptionButton
var _room_physics: OptionButton
var _room_code_lbl: Label

# Modals
var _profile_modal: Dictionary = {}
var _debug_modal: Dictionary = {}
var _powerups_modal: Dictionary = {}
var _teams_cols: Dictionary = {}
var _teams_lock_btn: Button
var _room_lock_btn: Button

# Extra Settings controls
var _set_vol: HSlider
var _set_ball_style: OptionButton
var _set_ball_trail: CheckBox
var _set_nets: CheckBox
var _set_shadows: CheckBox
var _set_particles: CheckBox
var _set_kick_flash: CheckBox
var _set_avatars: CheckBox
var _set_custom_colors: CheckBox
var _set_fps_hud: CheckBox
var _set_pause_blur: CheckBox
var _set_preset: OptionButton
var _set_phys_profile: OptionButton
var _set_phys_hz: SpinBox
var _set_custom_phys: CheckBox
var _set_ctrl_sl: HSlider
var _set_damp_sl: HSlider
var _set_kick_sl: HSlider
var _set_spd_sl: HSlider
var _set_wall_sl: HSlider

const ALL_STADIUMS := [
	"classic", "big", "huge", "futsal", "tiny", "long", "arena_3v3", "mini_fast",
	"wide_wing", "penalty_box", "hbs_classic", "hbs_easy", "hbs_small",
	"hbs_rounded", "hbs_big", "hbs_big_easy", "hbs_huge"
]

const ALL_PHYSICS := [
	"openhax", "classic_hax", "classic_hax_v2", "pro_control", "pro_control_v2", "pro_control_v3",
	"futsal", "big_arena", "turbo", "turbo_v2", "low_gravity", "real_soccer", "real_soccer_v2",
	"ice_hockey", "pinball", "heavy_tank"
]

func _ready() -> void:
	world = MatchWorld.new()
	add_child(world)

	pitch_view = PitchView.new()
	pitch_container.add_child(pitch_view)
	world.pitch_view = pitch_view

	world.scoreboard_changed.connect(_on_scoreboard)
	world.goal_scored.connect(_on_goal)
	world.match_ended.connect(_on_match_ended)
	world.chat_message.connect(_on_chat_msg)
	world.roster_changed.connect(_refresh_teams_modal)
	world.auth_rejected.connect(_on_auth_rejected)

	FirebaseService.rooms_loaded.connect(_on_firebase_rooms)
	FirebaseService.chat_loaded.connect(_on_firebase_chat)
	FirebaseService.leaderboard_loaded.connect(_on_firebase_leaderboard)

	_build_extra_ui()
	_populate_options()
	_sync_settings_to_ui()
	_apply_language_ui()
	_switch_screen("auth")
	FirebaseService.fetch_leaderboard()
	GameData.log_debug("INFO", "OpenHaxGodot 4.7.2 başlatıldı.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bool(GameData.settings.get("pause_on_blur", false)):
		if view_room.visible and world.active and not world.paused and world.room_kind != "client":
			world.paused = true
			pause_overlay.visible = true

func _build_extra_ui() -> void:
	# 1. TopBar additions
	var top_hbox := $RootVBox/TopBar/HBox
	_user_pill = Label.new()
	_user_pill.text = "🌱 Oyuncu :)"
	top_hbox.add_child(_user_pill)
	top_hbox.move_child(_user_pill, 1)

	var btn_prof := Button.new()
	btn_prof.text = "👤 Profil"
	btn_prof.pressed.connect(_open_profile_modal)
	top_hbox.add_child(btn_prof)

	_btn_mute = Button.new()
	_btn_mute.text = "🔊 Ses: Açık"
	_btn_mute.pressed.connect(_toggle_mute)
	top_hbox.add_child(_btn_mute)

	var btn_dbg := Button.new()
	btn_dbg.text = "🛠 Debug"
	btn_dbg.pressed.connect(_open_debug_modal)
	top_hbox.add_child(btn_dbg)

	lang_select.item_selected.connect(_on_lang_selected)

	# 2. AuthCard additions (avatar quick-picks, password, member button, error label)
	var auth_vbox := $RootVBox/ViewAuth/Card/VBox
	var av_row := HBoxContainer.new()
	for av in [":)", "10", "★", "🔥", "⚽"]:
		var b := Button.new()
		b.text = av
		b.pressed.connect(func(): auth_avatar.text = av)
		av_row.add_child(b)
	auth_vbox.add_child(av_row)
	auth_vbox.move_child(av_row, auth_avatar.get_index() + 1)

	_auth_pass = LineEdit.new()
	_auth_pass.placeholder_text = "Üye Şifresi (Misafir için boş bırak)"
	_auth_pass.secret = true
	auth_vbox.add_child(_auth_pass)
	auth_vbox.move_child(_auth_pass, auth_country.get_index() + 1)

	var btn_member := Button.new()
	btn_member.text = "🔐 Üye Girişi / Kayıt"
	btn_member.pressed.connect(_on_btn_member_auth_pressed)
	auth_vbox.add_child(btn_member)
	auth_vbox.move_child(btn_member, _auth_pass.get_index() + 1)

	_auth_err_lbl = Label.new()
	_auth_err_lbl.modulate = Color("#f87171")
	_auth_err_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	auth_vbox.add_child(_auth_err_lbl)

	# 3. JoinCard additions (search filter, room password, double-click join)
	var join_vbox := $RootVBox/ViewLobby/Grid/JoinCard/VBox
	_lobby_search = LineEdit.new()
	_lobby_search.placeholder_text = "🔍 Oda ara..."
	_lobby_search.text_changed.connect(func(_t): _render_rooms_list())
	join_vbox.add_child(_lobby_search)
	join_vbox.move_child(_lobby_search, 1)

	_join_pass = LineEdit.new()
	_join_pass.placeholder_text = "Oda Şifresi (varsa)"
	_join_pass.secret = true
	join_vbox.add_child(_join_pass)
	join_vbox.move_child(_join_pass, join_port.get_index() + 1)

	rooms_list.item_activated.connect(_on_room_double_clicked)

	# 4. CreateCard additions (score limit, time limit, max players, password)
	var create_vbox := $RootVBox/ViewLobby/Grid/CreateCard/VBox
	var lim_row := HBoxContainer.new()
	_create_score_lim = OptionButton.new()
	for sl in [0, 3, 5, 7, 10]:
		_create_score_lim.add_item("Gol: %s" % ("∞" if sl == 0 else str(sl)), sl)
	_create_score_lim.selected = 2
	lim_row.add_child(_create_score_lim)

	_create_time_lim = OptionButton.new()
	for tl in [0, 120, 180, 300, 420, 600]:
		_create_time_lim.add_item("Süre: %s" % ("∞" if tl == 0 else "%ddk" % (tl / 60)), tl)
	_create_time_lim.selected = 2
	lim_row.add_child(_create_time_lim)

	_create_max_p = SpinBox.new()
	_create_max_p.min_value = 2
	_create_max_p.max_value = 14
	_create_max_p.value = 10
	_create_max_p.prefix = "Max:"
	lim_row.add_child(_create_max_p)
	create_vbox.add_child(lim_row)
	create_vbox.move_child(lim_row, create_fps.get_index() + 1)

	_create_pass = LineEdit.new()
	_create_pass.placeholder_text = "Oda Şifresi (isteğe bağlı)"
	_create_pass.secret = true
	create_vbox.add_child(_create_pass)
	create_vbox.move_child(_create_pass, lim_row.get_index() + 1)

	# 5. RoomBar additions (quick teams, bot diff, stadium, physics, room code)
	var room_bar := $RootVBox/ViewRoom/RoomBar
	_room_code_lbl = Label.new()
	_room_code_lbl.text = ""
	room_bar.add_child(_room_code_lbl)

	var btn_qr := Button.new()
	btn_qr.text = "🔴"
	btn_qr.tooltip_text = "Kırmızı Takıma Geç"
	btn_qr.pressed.connect(func(): world.request_team_change(world.my_id, "red"))
	room_bar.add_child(btn_qr)

	var btn_qs := Button.new()
	btn_qs.text = "⚪"
	btn_qs.tooltip_text = "İzleyiciye Geç"
	btn_qs.pressed.connect(func(): world.request_team_change(world.my_id, "spec"))
	room_bar.add_child(btn_qs)

	var btn_qb := Button.new()
	btn_qb.text = "🔵"
	btn_qb.tooltip_text = "Mavi Takıma Geç"
	btn_qb.pressed.connect(func(): world.request_team_change(world.my_id, "blue"))
	room_bar.add_child(btn_qb)

	_room_botdiff = OptionButton.new()
	for bd in GameData.BOT_DIFFICULTIES:
		_room_botdiff.add_item("Bot: " + bd)
	_room_botdiff.item_selected.connect(func(idx: int):
		GameData.settings["bot_difficulty"] = GameData.BOT_DIFFICULTIES[idx]
		GameData.save_settings()
	)
	room_bar.add_child(_room_botdiff)

	_room_stadium = OptionButton.new()
	for st_id in ALL_STADIUMS:
		_room_stadium.add_item(st_id)
	_room_stadium.item_selected.connect(func(idx: int):
		world.set_stadium_id(ALL_STADIUMS[idx])
	)
	room_bar.add_child(_room_stadium)

	_room_physics = OptionButton.new()
	for ph in ALL_PHYSICS:
		_room_physics.add_item(ph)
	_room_physics.item_selected.connect(func(idx: int):
		GameData.settings["physics_profile"] = ALL_PHYSICS[idx]
		GameData.save_settings()
	)
	room_bar.add_child(_room_physics)

	# PauseOverlay Settings button
	var pause_hbox := $RootVBox/ViewRoom/PitchContainer/PauseOverlay/PauseCard/VBox/HBox
	var btn_pset := Button.new()
	btn_pset.text = "⚙ Ayarlar"
	btn_pset.pressed.connect(_on_btn_settings_pressed)
	pause_hbox.add_child(btn_pset)

	# 6. Build 5-tab SettingsModal inside existing SettingsModal/Panel/VBox
	_upgrade_settings_modal()

	# 7. Build 3-column TeamsModal inside existing TeamsModal/Panel/VBox
	_upgrade_teams_modal()

	# 8. Build Profile, Debug, Powerups Modals
	_profile_modal = UIModals.build_profile_modal(self)
	_profile_modal["search_btn"].pressed.connect(_on_profile_search_pressed)
	_debug_modal = UIModals.build_debug_modal(self)
	_powerups_modal = UIModals.build_powerups_modal(self)

func _upgrade_settings_modal() -> void:
	var panel: PanelContainer = $SettingsModal/Panel
	panel.custom_minimum_size = Vector2(540, 440)
	var vbox: VBoxContainer = $SettingsModal/Panel/VBox

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)
	vbox.move_child(tabs, 1)

	# Tab 1: Ses
	var t_ses := VBoxContainer.new()
	t_ses.name = "Ses"
	tabs.add_child(t_ses)
	set_sound.get_parent().remove_child(set_sound)
	t_ses.add_child(set_sound)
	var v_lbl := Label.new()
	v_lbl.text = "Ses Seviyesi (0% - 100%):"
	t_ses.add_child(v_lbl)
	_set_vol = HSlider.new()
	_set_vol.min_value = 0.0
	_set_vol.max_value = 1.0
	_set_vol.step = 0.05
	t_ses.add_child(_set_vol)

	# Tab 2: Video
	var t_vid := VBoxContainer.new()
	t_vid.name = "Video"
	tabs.add_child(t_vid)
	for n in [set_fps, set_room_fps, set_grass, set_perfboost]:
		n.get_parent().remove_child(n)
		t_vid.add_child(n)
	_set_ball_style = OptionButton.new()
	_set_ball_style.add_item("soccer")
	_set_ball_style.add_item("classic")
	t_vid.add_child(_set_ball_style)
	_set_ball_trail = CheckBox.new()
	_set_ball_trail.text = "Top İzi (Ball Trail)"
	t_vid.add_child(_set_ball_trail)
	_set_nets = CheckBox.new()
	_set_nets.text = "Kale Fileleri (Goal Nets)"
	t_vid.add_child(_set_nets)
	_set_shadows = CheckBox.new()
	_set_shadows.text = "Gölgeler (Shadows)"
	t_vid.add_child(_set_shadows)
	_set_particles = CheckBox.new()
	_set_particles.text = "Gol Parçacıkları (Particles)"
	t_vid.add_child(_set_particles)
	_set_kick_flash = CheckBox.new()
	_set_kick_flash.text = "Şut Parlaması (Kick Flash)"
	t_vid.add_child(_set_kick_flash)
	_set_avatars = CheckBox.new()
	_set_avatars.text = "Oyuncu Avatarlarını Göster"
	t_vid.add_child(_set_avatars)
	_set_custom_colors = CheckBox.new()
	_set_custom_colors.text = "Özel Takım Renkleri (/color)"
	t_vid.add_child(_set_custom_colors)
	_set_fps_hud = CheckBox.new()
	_set_fps_hud.text = "Saha Üstü FPS/Ping HUD"
	t_vid.add_child(_set_fps_hud)

	# Tab 3: Girdi
	var t_inp := VBoxContainer.new()
	t_inp.name = "Girdi"
	tabs.add_child(t_inp)
	_set_pause_blur = CheckBox.new()
	_set_pause_blur.text = "Pencere Odak Dışına Çıkınca Duraklat"
	t_inp.add_child(_set_pause_blur)
	var help := Label.new()
	help.text = "Kontroller:\n• Hareket: WASD veya Ok Tuşları\n• Şut / Pas: Space veya X\n• Duraklat: P | Sıfırla: R | Takımlar: ESC\n• 2 Kişilik Yerel: Ok Tuşları + Enter / Num0\n• Sohbet Komutları: /color #hex, /avatar XX, /nick Ad"
	t_inp.add_child(help)

	# Tab 4: Çeşitli
	var t_misc := VBoxContainer.new()
	t_misc.name = "Çeşitli"
	tabs.add_child(t_misc)
	var pr_lbl := Label.new()
	pr_lbl.text = "Hızlı Performans Ön Ayarı:"
	t_misc.add_child(pr_lbl)
	_set_preset = OptionButton.new()
	for p in ["default", "ultra_hd", "balanced", "pro_control", "max_perf", "power_saver"]:
		_set_preset.add_item(p)
	_set_preset.item_selected.connect(func(idx: int):
		GameData.apply_perf_preset(_set_preset.get_item_text(idx))
		_sync_settings_to_ui()
	)
	t_misc.add_child(_set_preset)

	# Tab 5: Fizik (Admin)
	var t_phy := VBoxContainer.new()
	t_phy.name = "Fizik"
	tabs.add_child(t_phy)
	_set_phys_profile = OptionButton.new()
	for ph in ALL_PHYSICS:
		_set_phys_profile.add_item(ph)
	t_phy.add_child(_set_phys_profile)
	_set_phys_hz = SpinBox.new()
	_set_phys_hz.min_value = 30
	_set_phys_hz.max_value = 500
	_set_phys_hz.step = 10
	_set_phys_hz.prefix = "Physics Hz:"
	t_phy.add_child(_set_phys_hz)
	_set_custom_phys = CheckBox.new()
	_set_custom_phys.text = "Özel Fizik Ayarlarını Etkinleştir"
	t_phy.add_child(_set_custom_phys)

	_set_ctrl_sl = _add_labeled_slider(t_phy, "Top Kontrolü (20-100%)", 20.0, 100.0, 1.0)
	_set_damp_sl = _add_labeled_slider(t_phy, "Top Sürtünmesi (0.975-0.996)", 0.975, 0.996, 0.001)
	_set_kick_sl = _add_labeled_slider(t_phy, "Şut Gücü (3.5-8.5)", 3.5, 8.5, 0.1)
	_set_spd_sl = _add_labeled_slider(t_phy, "Oyuncu Hızı (2.8-5.5)", 2.8, 5.5, 0.05)
	_set_wall_sl = _add_labeled_slider(t_phy, "Duvar Sekmesi (0.40-0.95)", 0.40, 0.95, 0.01)

func _add_labeled_slider(parent: Control, title: String, mn: float, mx: float, stp: float) -> HSlider:
	var l := Label.new()
	l.text = title
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = stp
	parent.add_child(s)
	return s

func _upgrade_teams_modal() -> void:
	var panel: PanelContainer = $TeamsModal/Panel
	panel.custom_minimum_size = Vector2(720, 440)
	var vbox: VBoxContainer = $TeamsModal/Panel/VBox

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 10)
	vbox.add_child(cols)
	vbox.move_child(cols, 1)

	for t in [["red", "🔴 Kırmızı (Katıl)"], ["spec", "⚪ İzleyici (Katıl)"], ["blue", "🔵 Mavi (Katıl)"]]:
		var cv := VBoxContainer.new()
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hdr_btn := Button.new()
		hdr_btn.text = t[1]
		var team_key: String = t[0]
		hdr_btn.pressed.connect(func(): world.request_team_change(world.my_id, team_key))
		cv.add_child(hdr_btn)
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(scroll)
		var list_vb := VBoxContainer.new()
		list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list_vb)
		cols.add_child(cv)
		_teams_cols[team_key] = list_vb

	var admin_row := HBoxContainer.new()
	vbox.add_child(admin_row)
	vbox.move_child(admin_row, 2)

	var b_auto := Button.new()
	b_auto.text = "Auto"
	b_auto.pressed.connect(func(): world.auto_balance_teams())
	admin_row.add_child(b_auto)

	var b_rand := Button.new()
	b_rand.text = "Rand"
	b_rand.pressed.connect(func(): world.randomize_teams())
	admin_row.add_child(b_rand)

	_teams_lock_btn = Button.new()
	_teams_lock_btn.text = "🔓 Takımlar Açık"
	_teams_lock_btn.pressed.connect(func():
		world.teams_locked = not world.teams_locked
		_refresh_teams_modal()
	)
	admin_row.add_child(_teams_lock_btn)

	_room_lock_btn = Button.new()
	_room_lock_btn.text = "🔓 Oda Açık"
	_room_lock_btn.pressed.connect(func():
		world.room_locked = not world.room_locked
		_refresh_teams_modal()
	)
	admin_row.add_child(_room_lock_btn)

	var b_rb := Button.new()
	b_rb.text = "-K Bot"
	b_rb.pressed.connect(func(): world.remove_last_bot("red"))
	admin_row.add_child(b_rb)

	var b_bb := Button.new()
	b_bb.text = "-M Bot"
	b_bb.pressed.connect(func(): world.remove_last_bot("blue"))
	admin_row.add_child(b_bb)

	var b_pu := Button.new()
	b_pu.text = "⚡ Süper Güçler"
	b_pu.pressed.connect(func(): _powerups_modal["root"].visible = true)
	admin_row.add_child(b_pu)

func _refresh_teams_modal() -> void:
	if _teams_cols.is_empty():
		return
	for k in _teams_cols.keys():
		var vb: VBoxContainer = _teams_cols[k]
		for ch in vb.get_children():
			ch.queue_free()
	var is_adm := world.is_local_admin()
	if _teams_lock_btn:
		_teams_lock_btn.text = "🔒 Takımlar Kilitli" if world.teams_locked else "🔓 Takımlar Açık"
	if _room_lock_btn:
		_room_lock_btn.text = "🔒 Oda Kilitli" if world.room_locked else "🔓 Oda Açık"

	for p in world.players:
		var t: String = str(p.get("team", "spec"))
		if not _teams_cols.has(t):
			continue
		var row := HBoxContainer.new()
		var lbl := Label.new()
		var star := "★ " if bool(p.get("is_admin", false)) else ""
		var ping_s := (" %dms" % int(p.get("ping", 0))) if int(p.get("ping", 0)) > 0 else ""
		lbl.text = "%s[%s] %s%s" % [star, str(p.get("country", "TR")), str(p.get("name", "?")), ping_s]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		if is_adm:
			var pid: String = str(p["id"])
			for mv in [["K", "red"], ["İ", "spec"], ["M", "blue"]]:
				if mv[1] != t:
					var b := Button.new()
					b.text = mv[0]
					var nt: String = mv[1]
					b.pressed.connect(func(): world.request_team_change(pid, nt))
					row.add_child(b)
			if not bool(p.get("is_bot", false)) and pid != "host":
				var ba := Button.new()
				ba.text = "★"
				ba.pressed.connect(func(): world.toggle_admin(pid))
				row.add_child(ba)
			if pid != "host":
				var bk := Button.new()
				bk.text = "✕"
				bk.pressed.connect(func(): world.kick_player(pid))
				row.add_child(bk)
		_teams_cols[t].add_child(row)

func _populate_options() -> void:
	for c in GameData.COUNTRIES:
		auth_country.add_item(c)
	for l in ["tr", "en", "de", "fr", "es", "az", "ru"]:
		lang_select.add_item(l.to_upper())
	for st_id in ALL_STADIUMS:
		create_stadium.add_item(st_id)
	for bd in GameData.BOT_DIFFICULTIES:
		create_botdiff.add_item(bd)
	create_botdiff.selected = 2
	for ph in ALL_PHYSICS:
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
	var badge := GameData.get_time_badge(int(GameData.profile.get("play_seconds", 0)))
	if _user_pill:
		_user_pill.text = "%s %s (%s)" % [badge["icon"], GameData.settings.get("nickname", "Oyuncu"), GameData.settings.get("avatar", ":)")]
	if _btn_mute:
		_btn_mute.text = "🔊 Ses: Açık" if bool(GameData.settings.get("master_sound", true)) else "🔇 Ses: Kapalı"
	if _set_vol:
		_set_vol.value = float(GameData.settings.get("sound_volume", 0.65))
		_set_ball_style.selected = 0 if GameData.settings.get("ball_style", "soccer") == "soccer" else 1
		_set_ball_trail.button_pressed = bool(GameData.settings.get("ball_trail", true))
		_set_nets.button_pressed = bool(GameData.settings.get("show_goal_nets", true))
		_set_shadows.button_pressed = bool(GameData.settings.get("shadows", true))
		_set_particles.button_pressed = bool(GameData.settings.get("particles", true))
		_set_kick_flash.button_pressed = bool(GameData.settings.get("kick_flash", true))
		_set_avatars.button_pressed = bool(GameData.settings.get("show_avatars", true))
		_set_custom_colors.button_pressed = bool(GameData.settings.get("custom_team_colors", true))
		_set_fps_hud.button_pressed = bool(GameData.settings.get("show_fps_hud", true))
		_set_pause_blur.button_pressed = bool(GameData.settings.get("pause_on_blur", false))
		_set_phys_hz.value = int(GameData.settings.get("physics_hz", 60))
		_set_custom_phys.button_pressed = bool(GameData.settings.get("custom_physics_enabled", false))
		_set_ctrl_sl.value = float(GameData.settings.get("custom_ball_control", 90.0))
		_set_damp_sl.value = float(GameData.settings.get("custom_ball_damping", 0.9915))
		_set_kick_sl.value = float(GameData.settings.get("custom_kick_power", 5.4))
		_set_spd_sl.value = float(GameData.settings.get("custom_player_speed", 3.33))
		_set_wall_sl.value = float(GameData.settings.get("custom_wall_bounce", 0.78))
		var pi := ALL_PHYSICS.find(GameData.settings.get("physics_profile", "openhax"))
		if pi >= 0: _set_phys_profile.selected = pi
	var gi := GameData.GRASS_THEMES.find(GameData.settings.get("grass_detail", "hd_stadium"))
	if gi >= 0: set_grass.selected = gi
	auth_stats.text = "%s %s · ⚽ %d · 🧤 %d · 🎯 %d · 🏆 %d" % [
		badge["icon"], badge["label"],
		int(GameData.profile.get("goals", 0)),
		int(GameData.profile.get("saves", 0)),
		int(GameData.profile.get("assists", 0)),
		int(GameData.profile.get("wins", 0))
	]

func _on_lang_selected(idx: int) -> void:
	GameData.settings["lang"] = lang_select.get_item_text(idx).to_lower()
	GameData.save_settings()
	_apply_language_ui()

func _apply_language_ui() -> void:
	$RootVBox/ViewAuth/Card/VBox/Title.text = GameData.tr_key("title")
	$RootVBox/ViewAuth/Card/VBox/BtnAuthEnter.text = GameData.tr_key("guest")
	$RootVBox/ViewLobby/Grid/CreateCard/VBox/BtnCreateRoom.text = GameData.tr_key("create_btn")
	$RootVBox/ViewRoom/RoomBar/BtnPause.text = GameData.tr_key("pause")
	$RootVBox/ViewRoom/RoomBar/BtnReset.text = GameData.tr_key("reset")
	$RootVBox/ViewRoom/RoomBar/BtnTeams.text = GameData.tr_key("teams")
	$RootVBox/ViewRoom/RoomBar/BtnLeave.text = GameData.tr_key("leave")
	chat_input.placeholder_text = GameData.tr_key("chat_ph")

func _toggle_mute() -> void:
	GameData.settings["master_sound"] = not bool(GameData.settings.get("master_sound", true))
	GameData.save_settings()
	_sync_settings_to_ui()

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
				if teams_modal.visible:
					_refresh_teams_modal()

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
	_auth_err_lbl.text = ""
	var n := GameData.censor_text(auth_nick.text.strip_edges())
	if n.is_empty():
		n = "Oyuncu"
	var locked := await FirebaseService.check_member_locked(n)
	if locked:
		_auth_err_lbl.text = "Bu kullanıcı adı üyeye ait! Şifrenizle 'Üye Girişi / Kayıt' kullanın."
		return
	GameData.settings["nickname"] = n
	GameData.settings["avatar"] = auth_avatar.text.strip_edges() if not auth_avatar.text.strip_edges().is_empty() else ":)"
	GameData.settings["country"] = auth_country.get_item_text(auth_country.selected)
	GameData.settings["is_member"] = false
	GameData.save_settings()
	_sync_settings_to_ui()
	_switch_screen("lobby")

func _on_btn_member_auth_pressed() -> void:
	_auth_err_lbl.text = "Kontrol ediliyor..."
	var n := GameData.censor_text(auth_nick.text.strip_edges())
	var c := auth_country.get_item_text(auth_country.selected)
	var res := await FirebaseService.auth_member(n, _auth_pass.text, c)
	if not bool(res.get("ok", false)):
		_auth_err_lbl.text = str(res.get("error", "Giriş hatası."))
		return
	var prof: Dictionary = res.get("profile", {})
	GameData.settings["nickname"] = str(prof.get("username", n))
	GameData.settings["avatar"] = auth_avatar.text.strip_edges() if not auth_avatar.text.strip_edges().is_empty() else ":)"
	GameData.settings["country"] = c
	GameData.settings["is_member"] = true
	GameData.profile["goals"] = int(prof.get("goals", GameData.profile["goals"]))
	GameData.profile["saves"] = int(prof.get("saves", GameData.profile["saves"]))
	GameData.profile["assists"] = int(prof.get("assists", GameData.profile["assists"]))
	GameData.profile["wins"] = int(prof.get("wins", GameData.profile["wins"]))
	GameData.profile["matches"] = int(prof.get("matches", GameData.profile["matches"]))
	GameData.profile["play_seconds"] = int(prof.get("playSeconds", GameData.profile["play_seconds"]))
	GameData.save_settings()
	GameData.save_profile()
	_auth_err_lbl.text = ""
	_sync_settings_to_ui()
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
	var s_lim := _create_score_lim.get_item_id(_create_score_lim.selected)
	var t_lim := _create_time_lim.get_item_id(_create_time_lim.selected)
	var m_p := int(_create_max_p.value)
	var r_pw := _create_pass.text

	GameData.settings["bot_difficulty"] = bdiff
	GameData.settings["physics_profile"] = phys
	GameData.settings["stadium"] = st_id
	GameData.settings["fav_stadium"] = st_id
	GameData.settings["fav_mode"] = phys
	GameData.settings["room_max_fps"] = int(create_fps.value)
	GameData.save_settings()

	if kind == "host":
		if OS.has_feature("web"):
			_on_chat_msg("Sistem", "Web tarayıcıda P2P Host yerine Çevrimdışı Bot / 2 Kişilik Yerel mod açıldı (ENet yalnızca Masaüstü sürümde çalışır).", true)
			kind = "offline"
		else:
			var peer := ENetMultiplayerPeer.new()
			peer.create_server(7777, m_p)
			multiplayer.multiplayer_peer = peer

	world.start_room(kind, create_name.text, st_id, bp, s_lim, t_lim, pu, r_pw, m_p)
	_room_code_lbl.text = "Kod: " + world.room_code
	var si := ALL_STADIUMS.find(st_id)
	if si >= 0: _room_stadium.selected = si
	var phi := ALL_PHYSICS.find(phys)
	if phi >= 0: _room_physics.selected = phi
	var bdi := GameData.BOT_DIFFICULTIES.find(bdiff)
	if bdi >= 0: _room_botdiff.selected = bdi

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
		lobby_status.text = "Web tarayıcıda ENet IP bağlantısı desteklenmez (Masaüstü sürümünü kullanın)."
		return
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(join_ip.text.strip_edges(), int(join_port.text))
	if err == OK:
		multiplayer.multiplayer_peer = peer
		world.room_password = _join_pass.text
		world.start_room("client", "Uzak Oda", "classic", "none", 5, 180, "none", _join_pass.text)
		chat_log.clear()
		_switch_screen("room")
	else:
		lobby_status.text = "Bağlantı hatası: " + str(err)

func _on_room_double_clicked(idx: int) -> void:
	if idx < 0 or idx >= _cached_rooms.size():
		return
	var r: Dictionary = _cached_rooms[idx]
	lobby_status.text = "Seçilen oda: %s (Host: %s) — Masaüstünde IP ile bağlanın." % [str(r.get("name", "")), str(r.get("hostName", ""))]

func _on_auth_rejected(reason: String) -> void:
	lobby_status.text = reason
	_switch_screen("lobby")

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

func _on_goal(team: String, scorer: String, assist: String) -> void:
	var msg := GameData.tr_key("goal_red" if team == "red" else "goal_blue")
	if not scorer.is_empty():
		msg += "\n⚽ %s" % scorer
		if not assist.is_empty():
			msg += " (Asist: %s)" % assist
	goal_banner.text = msg
	goal_banner.visible = true
	_save_cloud_stats()
	await get_tree().create_timer(1.8).timeout
	goal_banner.visible = false

func _on_match_ended(winner_team: String) -> void:
	goal_banner.text = "🏆 MAÇ BİTTİ!\nKAZANAN: %s (%d - %d)" % [("KIRMIZI" if winner_team == "red" else "MAVİ"), world.score_red, world.score_blue]
	goal_banner.visible = true
	_save_cloud_stats()
	await get_tree().create_timer(3.2).timeout
	goal_banner.visible = false

func _save_cloud_stats() -> void:
	FirebaseService.save_cloud_profile(
		GameData.settings.get("nickname", "Oyuncu"),
		GameData.settings.get("country", "TR"),
		int(GameData.profile["goals"]),
		int(GameData.profile["wins"]),
		int(GameData.profile["play_seconds"]),
		int(GameData.profile.get("saves", 0)),
		int(GameData.profile.get("assists", 0)),
		int(GameData.profile.get("matches", 0))
	)
	_sync_settings_to_ui()

func _on_btn_global_send_pressed() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_global_chat_ms < 1400:
		return
	var txt := global_chat_input.text.strip_edges()
	if txt.is_empty():
		return
	_last_global_chat_ms = now
	global_chat_input.clear()
	FirebaseService.send_global_chat(
		GameData.settings.get("nickname", "Oyuncu"),
		txt,
		GameData.settings.get("country", "TR"),
		int(GameData.profile.get("play_seconds", 0))
	)

func _on_firebase_rooms(rooms: Array) -> void:
	_cached_rooms = rooms
	_render_rooms_list()

func _render_rooms_list() -> void:
	rooms_list.clear()
	var q := _lobby_search.text.strip_edges().to_lower() if _lobby_search else ""
	var shown := 0
	for r in _cached_rooms:
		var rn := str(r.get("name", "Oda"))
		var hn := str(r.get("hostName", "?"))
		if not q.is_empty() and not rn.to_lower().contains(q) and not hn.to_lower().contains(q):
			continue
		rooms_list.add_item("[%s] %s | %s | %s (%d+%d Bot)" % [
			str(r.get("country", "TR")),
			rn,
			hn,
			str(r.get("stadium", "classic")),
			int(r.get("players", 1)),
			int(r.get("bots", 0))
		])
		shown += 1
	if shown == 0:
		rooms_list.add_item("Henüz açık Firebase odası yok.")

func _on_firebase_chat(rows: Array) -> void:
	global_chat_log.clear()
	for m in rows:
		var badge := GameData.get_time_badge(int(m.get("playSeconds", 0)))
		global_chat_log.append_text("[b]%s [%s] %s:[/b] %s\n" % [
			badge["icon"],
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
	var col := "#facc15" if is_sys else "#e2e8f0"
	chat_log.append_text("[color=%s][b]%s:[/b] %s[/color]\n" % [col, safe_a, safe_t])

func _on_chat_send_pressed() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_room_chat_ms < 600:
		return
	var msg := chat_input.text.strip_edges()
	if msg.is_empty():
		return
	_last_room_chat_ms = now
	chat_input.clear()
	world.send_room_chat(msg)

func _open_profile_modal() -> void:
	_profile_modal["root"].visible = true
	_render_profile_stats({
		"username": GameData.settings.get("nickname", "Oyuncu"),
		"country": GameData.settings.get("country", "TR"),
		"goals": GameData.profile.get("goals", 0),
		"saves": GameData.profile.get("saves", 0),
		"assists": GameData.profile.get("assists", 0),
		"wins": GameData.profile.get("wins", 0),
		"matches": GameData.profile.get("matches", 0),
		"playSeconds": GameData.profile.get("play_seconds", 0)
	})
	var lb := await FirebaseService.fetch_leaderboard()
	var lines := []
	for i in range(lb.size()):
		var p: Dictionary = lb[i]
		var b := GameData.get_time_badge(int(p.get("playSeconds", 0)))
		lines.append("%d. %s [%s] [b]%s[/b] — ⚽ %d · 🧤 %d · 🏆 %d" % [
			i + 1, b["icon"], str(p.get("country", "TR")), str(p.get("username", "?")),
			int(p.get("goals", 0)), int(p.get("saves", 0)), int(p.get("wins", 0))
		])
	_profile_modal["lb_list"].text = "\n".join(lines) if not lines.is_empty() else "Veri yok."

func _on_profile_search_pressed() -> void:
	var q: String = _profile_modal["search_in"].text.strip_edges()
	if q.is_empty():
		return
	var p := await FirebaseService.fetch_profile(q)
	if p.is_empty():
		_profile_modal["stats_lbl"].text = "[color=#f87171]Oyuncu bulunamadı: %s[/color]" % q
		return
	_render_profile_stats(p)

func _render_profile_stats(p: Dictionary) -> void:
	var sec := int(p.get("playSeconds", 0))
	var b := GameData.get_time_badge(sec)
	@warning_ignore("integer_division")
	var mins := sec / 60
	_profile_modal["stats_lbl"].text = "[b]%s [%s] %s[/b] (%s)\n⚽ Gol: %d  |  🧤 Kurtarış: %d  |  🎯 Asist: %d\n🏆 Galibiyet: %d  |  🎮 Maç: %d  |  ⏱ Süre: %d dk" % [
		b["icon"], str(p.get("country", "TR")), str(p.get("username", "Oyuncu")), b["label"],
		int(p.get("goals", 0)), int(p.get("saves", 0)), int(p.get("assists", 0)),
		int(p.get("wins", 0)), int(p.get("matches", 0)), mins
	]

func _open_debug_modal() -> void:
	_debug_modal["root"].visible = true
	_debug_modal["log_txt"].text = "\n".join(GameData.debug_logs)

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
	if teams_modal.visible:
		_refresh_teams_modal()

func _on_btn_apply_settings_pressed() -> void:
	GameData.settings["fps_limit"] = int(set_fps.value)
	GameData.settings["room_max_fps"] = int(set_room_fps.value)
	GameData.settings["grass_detail"] = set_grass.get_item_text(set_grass.selected)
	GameData.settings["perf_boost"] = set_perfboost.button_pressed
	GameData.settings["master_sound"] = set_sound.button_pressed
	GameData.settings["lang"] = lang_select.get_item_text(lang_select.selected).to_lower()
	if _set_vol:
		GameData.settings["sound_volume"] = _set_vol.value
		GameData.settings["ball_style"] = _set_ball_style.get_item_text(_set_ball_style.selected)
		GameData.settings["ball_trail"] = _set_ball_trail.button_pressed
		GameData.settings["show_goal_nets"] = _set_nets.button_pressed
		GameData.settings["shadows"] = _set_shadows.button_pressed
		GameData.settings["particles"] = _set_particles.button_pressed
		GameData.settings["kick_flash"] = _set_kick_flash.button_pressed
		GameData.settings["show_avatars"] = _set_avatars.button_pressed
		GameData.settings["custom_team_colors"] = _set_custom_colors.button_pressed
		GameData.settings["show_fps_hud"] = _set_fps_hud.button_pressed
		GameData.settings["pause_on_blur"] = _set_pause_blur.button_pressed
		GameData.settings["physics_profile"] = _set_phys_profile.get_item_text(_set_phys_profile.selected)
		GameData.settings["physics_hz"] = int(_set_phys_hz.value)
		GameData.settings["custom_physics_enabled"] = _set_custom_phys.button_pressed
		GameData.settings["custom_ball_control"] = _set_ctrl_sl.value
		GameData.settings["custom_ball_damping"] = _set_damp_sl.value
		GameData.settings["custom_kick_power"] = _set_kick_sl.value
		GameData.settings["custom_player_speed"] = _set_spd_sl.value
		GameData.settings["custom_wall_bounce"] = _set_wall_sl.value
	GameData.save_settings()
	_sync_settings_to_ui()
	_apply_language_ui()
	settings_modal.visible = false
