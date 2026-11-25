extends Node

const SETTINGS_PATH := "user://openhax_settings.cfg"
const PROFILE_PATH := "user://openhax_profile.json"

const BOT_DIFFICULTIES := ["very_easy", "easy", "medium", "hard", "pro"]
const GRASS_THEMES := ["standard", "hd_stadium", "arena_pro", "night_neon", "retro_arcade", "flat"]
const POWERUP_TYPES := ["hawk", "fire", "speed", "magnet", "giant"]
const COUNTRIES := [
	"TR", "AZ", "DE", "GB", "US", "FR", "ES", "IT", "PT", "BR", "AR", "NL", "BE",
	"PL", "RU", "UA", "RO", "BG", "GR", "SE", "NO", "DK", "FI", "CH", "AT", "CZ",
	"HU", "RS", "HR", "BA", "AL", "MK", "GE", "KZ", "UZ", "KG", "TM", "JP", "KR",
	"CN", "IN", "ID", "SA", "AE", "EG", "MA", "DZ", "CA", "MX", "CL", "CO", "AU"
]

const LANGUAGES := {
	"tr": {
		"title": "OpenHax Godot 2D",
		"sub": "Sahaya çıkmadan önce oyuncu adını, avatarını ve ülkeni seç.",
		"nick": "Kullanıcı Adı",
		"avatar": "Avatar",
		"country": "Ülke",
		"enter_lobby": "Lobiye Gir",
		"guest": "Misafir Olarak Devam Et",
		"rooms_title": "Odalar & Bağlantı (LAN / Online)",
		"create_room": "Yeni Oda Oluştur",
		"create_btn": "Oda Oluştur ve Oyuna Gir",
		"join_btn": "IP ile Katıl",
		"pause": "Duraklat (P)",
		"resume": "Devam Et (P)",
		"reset": "Sıfırla (R)",
		"leave": "Odadan Çık",
		"teams": "Takımlar (ESC)",
		"settings": "Ayarlar",
		"paused_banner": "OYUN DURAKLATILDI (P)",
		"goal_red": "GOL! KIRMIZI TAKIM!",
		"goal_blue": "GOL! MAVİ TAKIM!",
		"send": "Gönder",
		"chat_ph": "Odaya mesaj yaz (Enter)..."
	},
	"en": {
		"title": "OpenHax Godot 2D",
		"sub": "Choose your player name, avatar and country before entering the pitch.",
		"nick": "Player Name",
		"avatar": "Avatar",
		"country": "Country",
		"enter_lobby": "Enter Lobby",
		"guest": "Continue as Guest",
		"rooms_title": "Rooms & Connect (LAN / Online)",
		"create_room": "Create New Room",
		"create_btn": "Create Room & Play",
		"join_btn": "Join by IP",
		"pause": "Pause (P)",
		"resume": "Resume (P)",
		"reset": "Reset (R)",
		"leave": "Leave Room",
		"teams": "Teams (ESC)",
		"settings": "Settings",
		"paused_banner": "GAME PAUSED (P)",
		"goal_red": "GOAL! RED TEAM!",
		"goal_blue": "GOAL! BLUE TEAM!",
		"send": "Send",
		"chat_ph": "Type a message (Enter)..."
	},
	"de": {
		"title": "OpenHax Godot 2D",
		"sub": "Wähle Namen, Avatar und Land, bevor du das Spielfeld betrittst.",
		"nick": "Spielername",
		"avatar": "Avatar",
		"country": "Land",
		"enter_lobby": "Lobby betreten",
		"guest": "Als Gast fortfahren",
		"rooms_title": "Räume & Verbindung",
		"create_room": "Neuen Raum erstellen",
		"create_btn": "Raum erstellen & spielen",
		"join_btn": "Per IP beitreten",
		"pause": "Pause (P)",
		"resume": "Fortsetzen (P)",
		"reset": "Reset (R)",
		"leave": "Verlassen",
		"teams": "Teams (ESC)",
		"settings": "Einstellungen",
		"paused_banner": "SPIEL PAUSIERT (P)",
		"goal_red": "TOR! TEAM ROT!",
		"goal_blue": "TOR! TEAM BLAU!",
		"send": "Senden",
		"chat_ph": "Nachricht eingeben..."
	},
	"fr": {
		"title": "OpenHax Godot 2D",
		"sub": "Choisis ton pseudo, ton avatar et ton pays avant d'entrer sur le terrain.",
		"nick": "Pseudo",
		"avatar": "Avatar",
		"country": "Pays",
		"enter_lobby": "Entrer dans le lobby",
		"guest": "Continuer en invité",
		"rooms_title": "Salles & Connexion",
		"create_room": "Créer une salle",
		"create_btn": "Créer et jouer",
		"join_btn": "Rejoindre par IP",
		"pause": "Pause (P)",
		"resume": "Reprendre (P)",
		"reset": "Réinitialiser (R)",
		"leave": "Quitter",
		"teams": "Équipes (ESC)",
		"settings": "Paramètres",
		"paused_banner": "JEU EN PAUSE (P)",
		"goal_red": "BUT ! ÉQUIPE ROUGE !",
		"goal_blue": "BUT ! ÉQUIPE BLEUE !",
		"send": "Envoyer",
		"chat_ph": "Écrire un message..."
	},
	"es": {
		"title": "OpenHax Godot 2D",
		"sub": "Elige tu nombre, avatar y país antes de salir al campo.",
		"nick": "Nombre",
		"avatar": "Avatar",
		"country": "País",
		"enter_lobby": "Entrar al Lobby",
		"guest": "Continuar como invitado",
		"rooms_title": "Salas y Conexión",
		"create_room": "Crear Sala",
		"create_btn": "Crear y Jugar",
		"join_btn": "Unirse por IP",
		"pause": "Pausa (P)",
		"resume": "Reanudar (P)",
		"reset": "Reiniciar (R)",
		"leave": "Salir",
		"teams": "Equipos (ESC)",
		"settings": "Ajustes",
		"paused_banner": "JUEGO EN PAUSA (P)",
		"goal_red": "¡GOL! ¡EQUIPO ROJO!",
		"goal_blue": "¡GOL! ¡EQUIPO AZUL!",
		"send": "Enviar",
		"chat_ph": "Escribe un mensaje..."
	},
	"az": {
		"title": "OpenHax Godot 2D",
		"sub": "Meydana çıxmazdan əvvəl adını, avatarını və ölkəni seç.",
		"nick": "Oyunçu Adı",
		"avatar": "Avatar",
		"country": "Ölkə",
		"enter_lobby": "Lobiyə Gir",
		"guest": "Qonaq kimi davam et",
		"rooms_title": "Otaqlar & Bağlantı",
		"create_room": "Yeni Otaq Yarat",
		"create_btn": "Otaq Yarat və Oyna",
		"join_btn": "IP ilə Qoşul",
		"pause": "Fasilə (P)",
		"resume": "Davam Et (P)",
		"reset": "Sıfırla (R)",
		"leave": "Otaqdan Çıx",
		"teams": "Komandalar (ESC)",
		"settings": "Parametrlər",
		"paused_banner": "OYUN DAYANDIRILDI (P)",
		"goal_red": "QOL! QIRMIZI KOMANDA!",
		"goal_blue": "QOL! MAVİ KOMANDA!",
		"send": "Göndər",
		"chat_ph": "Mesaj yaz..."
	},
	"ru": {
		"title": "OpenHax Godot 2D",
		"sub": "Выберите имя, аватар и страну перед выходом на поле.",
		"nick": "Имя игрока",
		"avatar": "Аватар",
		"country": "Страна",
		"enter_lobby": "Войти в лобби",
		"guest": "Продолжить как гость",
		"rooms_title": "Комнаты и подключение",
		"create_room": "Создать комнату",
		"create_btn": "Создать и играть",
		"join_btn": "Подключиться по IP",
		"pause": "Пауза (P)",
		"resume": "Продолжить (P)",
		"reset": "Сброс (R)",
		"leave": "Выйти",
		"teams": "Команды (ESC)",
		"settings": "Настройки",
		"paused_banner": "ИГРА НА ПАУЗЕ (P)",
		"goal_red": "ГОЛ! КРАСНЫЕ!",
		"goal_blue": "ГОЛ! СИНИЕ!",
		"send": "Отправить",
		"chat_ph": "Написать сообщение..."
	}
}

const BAD_WORDS := [
	"amk", "aq", "amcik", "amina", "orospu", "oruspu", "pic", "sik", "siktir", "yarrak", "gotveren", "ibne", "pezevenk",
	"fuck", "fucker", "fucking", "shit", "bitch", "asshole", "cunt", "whore", "nigger", "faggot",
	"arschloch", "scheisse", "hurensohn", "putain", "merde", "connard", "salope", "puta", "mierda", "caralho",
	"cazzo", "vaffanculo", "kanker", "kurwa", "blyat", "suka", "pizdec", "nahui"
]

var settings := {
	"nickname": "Oyuncu",
	"avatar": ":)",
	"country": "TR",
	"lang": "tr",
	"fps_limit": 60,
	"room_max_fps": 0,
	"grass_detail": "hd_stadium",
	"ball_style": "soccer",
	"ball_trail": true,
	"shadows": true,
	"particles": true,
	"perf_boost": false,
	"show_goal_nets": true,
	"master_sound": true,
	"sound_volume": 0.65,
	"bot_difficulty": "medium",
	"physics_profile": "openhax",
	"physics_hz": 60,
	"stadium": "classic",
	"resolution_scale": 1.0,
	"show_fps_hud": true,
	"show_avatars": true,
	"show_chat_indicators": true,
	"custom_team_colors": true,
	"kick_flash": true,
	"pause_on_blur": false,
	"chat_opacity": 0.85,
	"custom_physics_enabled": false,
	"custom_ball_control": 90.0,
	"custom_ball_damping": 0.9915,
	"custom_kick_power": 5.4,
	"custom_player_speed": 3.33,
	"custom_wall_bounce": 0.78,
	"is_member": false,
	"fav_stadium": "classic",
	"fav_mode": "openhax"
}

var powerups_enabled := {
	"hawk": true,
	"fire": true,
	"speed": true,
	"magnet": true,
	"giant": true
}

var debug_logs: Array[String] = []

var profile := {
	"goals": 0,
	"saves": 0,
	"assists": 0,
	"wins": 0,
	"matches": 0,
	"play_seconds": 0
}

func log_debug(level: String, msg: String) -> void:
	var ts := Time.get_time_string_from_system()
	debug_logs.append("[%s] [%s] %s" % [ts, level.to_upper(), msg])
	if debug_logs.size() > 250:
		debug_logs.pop_front()

func get_time_badge(play_sec: int) -> Dictionary:
	if play_sec >= 36000:
		return {"icon": "👑", "label": "Kral (10s+)"}
	if play_sec >= 18000:
		return {"icon": "💎", "label": "Elmas (5s+)"}
	if play_sec >= 3600:
		return {"icon": "🥇", "label": "Altın (1s+)"}
	if play_sec >= 1800:
		return {"icon": "🥈", "label": "Gümüş (30dk+)"}
	if play_sec >= 300:
		return {"icon": "🥉", "label": "Bronz (5dk+)"}
	return {"icon": "🌱", "label": "Çaylak"}

func apply_perf_preset(preset_id: String) -> void:
	match preset_id:
		"ultra_hd":
			settings["fps_limit"] = 0
			settings["grass_detail"] = "hd_stadium"
			settings["shadows"] = true
			settings["particles"] = true
			settings["ball_trail"] = true
			settings["perf_boost"] = false
			settings["resolution_scale"] = 1.5
		"balanced":
			settings["fps_limit"] = 120
			settings["grass_detail"] = "standard"
			settings["shadows"] = true
			settings["particles"] = true
			settings["ball_trail"] = true
			settings["perf_boost"] = false
			settings["resolution_scale"] = 1.0
		"pro_control":
			settings["fps_limit"] = 240
			settings["grass_detail"] = "arena_pro"
			settings["shadows"] = false
			settings["particles"] = true
			settings["ball_trail"] = true
			settings["perf_boost"] = true
			settings["physics_profile"] = "pro_control"
		"max_perf":
			settings["fps_limit"] = 0
			settings["grass_detail"] = "flat"
			settings["shadows"] = false
			settings["particles"] = false
			settings["ball_trail"] = false
			settings["perf_boost"] = true
			settings["resolution_scale"] = 0.75
		"power_saver":
			settings["fps_limit"] = 60
			settings["grass_detail"] = "flat"
			settings["shadows"] = false
			settings["particles"] = false
			settings["ball_trail"] = false
			settings["perf_boost"] = true
		_:
			settings["fps_limit"] = 60
			settings["grass_detail"] = "hd_stadium"
			settings["shadows"] = true
			settings["particles"] = true
			settings["ball_trail"] = true
			settings["perf_boost"] = false
			settings["resolution_scale"] = 1.0
	save_settings()

func _ready() -> void:
	load_settings()
	load_profile()
	apply_fps_limit()

func tr_key(key: String) -> String:
	var lang: String = settings.get("lang", "tr")
	if LANGUAGES.has(lang) and LANGUAGES[lang].has(key):
		return LANGUAGES[lang][key]
	if LANGUAGES["en"].has(key):
		return LANGUAGES["en"][key]
	return LANGUAGES["tr"].get(key, key)

func censor_text(text: String) -> String:
	if text.is_empty():
		return text
	var words := text.split(" ")
	for i in range(words.size()):
		var w := words[i].to_lower()
		w = w.replace("ı", "i").replace("ğ", "g").replace("ü", "u").replace("ş", "s").replace("ö", "o").replace("ç", "c")
		w = w.replace("0", "o").replace("1", "i").replace("3", "e").replace("4", "a").replace("5", "s").replace("@", "a")
		for bad in BAD_WORDS:
			if w == bad or (bad.length() >= 4 and w.contains(bad)):
				words[i] = "*".repeat(clampi(words[i].length(), 3, 8))
				break
	return " ".join(words)

func apply_fps_limit() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var u_fps := int(settings.get("fps_limit", 60))
	var r_fps := int(settings.get("room_max_fps", 0))
	var eff := 0
	if u_fps > 0 and r_fps > 0:
		eff = mini(u_fps, r_fps)
	else:
		eff = maxi(u_fps, r_fps)
	Engine.max_fps = eff

func get_effective_fps_label() -> String:
	var u_fps := int(settings.get("fps_limit", 60))
	var r_fps := int(settings.get("room_max_fps", 0))
	var eff := mini(u_fps, r_fps) if (u_fps > 0 and r_fps > 0) else maxi(u_fps, r_fps)
	return str(eff) + " FPS" if eff > 0 else "∞"

func get_stadium(id: String) -> Dictionary:
	var presets := {
		"classic": {"label": "OpenHax Klasik (860x460)", "w": 860.0, "h": 460.0, "px": 30.0, "py": 30.0, "pw": 800.0, "ph": 400.0, "gh": 70.0, "gd": 22.0, "cr": 75.0},
		"big": {"label": "Büyük Saha (1040x540)", "w": 1040.0, "h": 540.0, "px": 40.0, "py": 34.0, "pw": 960.0, "ph": 472.0, "gh": 84.0, "gd": 26.0, "cr": 86.0},
		"huge": {"label": "Dev Stadyum 4v4 (1160x600)", "w": 1160.0, "h": 600.0, "px": 44.0, "py": 36.0, "pw": 1072.0, "ph": 528.0, "gh": 94.0, "gd": 28.0, "cr": 96.0},
		"futsal": {"label": "Futsal (760x400)", "w": 760.0, "h": 400.0, "px": 30.0, "py": 28.0, "pw": 700.0, "ph": 344.0, "gh": 62.0, "gd": 22.0, "cr": 62.0},
		"tiny": {"label": "Mini 1v1 (660x350)", "w": 660.0, "h": 350.0, "px": 28.0, "py": 26.0, "pw": 604.0, "ph": 298.0, "gh": 54.0, "gd": 20.0, "cr": 52.0},
		"long": {"label": "Uzun Koridor (1080x420)", "w": 1080.0, "h": 420.0, "px": 36.0, "py": 28.0, "pw": 1008.0, "ph": 364.0, "gh": 68.0, "gd": 24.0, "cr": 70.0},
		"arena_3v3": {"label": "3v3 Orta Arena (960x500)", "w": 960.0, "h": 500.0, "px": 36.0, "py": 32.0, "pw": 888.0, "ph": 436.0, "gh": 78.0, "gd": 24.0, "cr": 80.0},
		"mini_fast": {"label": "Hızlı 2v2 (720x380)", "w": 720.0, "h": 380.0, "px": 28.0, "py": 26.0, "pw": 664.0, "ph": 328.0, "gh": 60.0, "gd": 20.0, "cr": 58.0},
		"wide_wing": {"label": "Geniş Kanat (980x580)", "w": 980.0, "h": 580.0, "px": 38.0, "py": 34.0, "pw": 904.0, "ph": 512.0, "gh": 88.0, "gd": 26.0, "cr": 84.0},
		"penalty_box": {"label": "Ceza Sahası / Şut (640x440)", "w": 640.0, "h": 440.0, "px": 28.0, "py": 28.0, "pw": 584.0, "ph": 384.0, "gh": 86.0, "gd": 22.0, "cr": 56.0},
		"hbs_classic": {"label": "HBS: Classic (740x400)", "w": 800.0, "h": 460.0, "px": 30.0, "py": 30.0, "pw": 740.0, "ph": 400.0, "gh": 64.0, "gd": 22.0, "cr": 70.0},
		"hbs_easy": {"label": "HBS: Easy (740x400)", "w": 800.0, "h": 460.0, "px": 30.0, "py": 30.0, "pw": 740.0, "ph": 400.0, "gh": 90.0, "gd": 22.0, "cr": 70.0},
		"hbs_small": {"label": "HBS: Small (640x400)", "w": 700.0, "h": 460.0, "px": 30.0, "py": 30.0, "pw": 640.0, "ph": 400.0, "gh": 55.0, "gd": 20.0, "cr": 62.0},
		"hbs_rounded": {"label": "HBS: Rounded (740x400)", "w": 800.0, "h": 460.0, "px": 30.0, "py": 30.0, "pw": 740.0, "ph": 400.0, "gh": 64.0, "gd": 22.0, "cr": 70.0},
		"hbs_big": {"label": "HBS: Big (1100x540)", "w": 1180.0, "h": 600.0, "px": 40.0, "py": 30.0, "pw": 1100.0, "ph": 540.0, "gh": 80.0, "gd": 26.0, "cr": 88.0},
		"hbs_big_easy": {"label": "HBS: Big Easy (1100x540)", "w": 1180.0, "h": 600.0, "px": 40.0, "py": 30.0, "pw": 1100.0, "ph": 540.0, "gh": 95.0, "gd": 26.0, "cr": 88.0},
		"hbs_huge": {"label": "HBS: Huge (1400x700)", "w": 1480.0, "h": 760.0, "px": 40.0, "py": 30.0, "pw": 1400.0, "ph": 700.0, "gh": 100.0, "gd": 28.0, "cr": 105.0}
	}
	var st: Dictionary = presets.get(id, presets["classic"]).duplicate()
	st["id"] = id if presets.has(id) else "classic"
	var x0 := float(st["px"])
	var y0 := float(st["py"])
	var x1 := x0 + float(st["pw"])
	var y1 := y0 + float(st["ph"])
	var cy := y0 + float(st["ph"]) * 0.5
	var gh := float(st["gh"])
	var gd := float(st["gd"])
	st["post_r"] = 7.5
	st["post_bcoef"] = 0.75
	st["posts"] = [
		Vector2(x0, cy - gh),
		Vector2(x0, cy + gh),
		Vector2(x1, cy - gh),
		Vector2(x1, cy + gh)
	]
	st["segments"] = [
		{"a": Vector2(x0, y0), "b": Vector2(x1, y0), "bcoef": 0.8, "mask": "ball"},
		{"a": Vector2(x0, y1), "b": Vector2(x1, y1), "bcoef": 0.8, "mask": "ball"},
		{"a": Vector2(x0, y0), "b": Vector2(x0, cy - gh), "bcoef": 0.8, "mask": "ball"},
		{"a": Vector2(x0, cy + gh), "b": Vector2(x0, y1), "bcoef": 0.8, "mask": "ball"},
		{"a": Vector2(x1, y0), "b": Vector2(x1, cy - gh), "bcoef": 0.8, "mask": "ball"},
		{"a": Vector2(x1, cy + gh), "b": Vector2(x1, y1), "bcoef": 0.8, "mask": "ball"},
		{"a": Vector2(x0 - gd, cy - gh), "b": Vector2(x0, cy - gh), "bcoef": 0.25, "mask": "both"},
		{"a": Vector2(x0 - gd, cy + gh), "b": Vector2(x0, cy + gh), "bcoef": 0.25, "mask": "both"},
		{"a": Vector2(x0 - gd, cy - gh), "b": Vector2(x0 - gd, cy + gh), "bcoef": 0.2, "mask": "both"},
		{"a": Vector2(x1, cy - gh), "b": Vector2(x1 + gd, cy - gh), "bcoef": 0.25, "mask": "both"},
		{"a": Vector2(x1, cy + gh), "b": Vector2(x1 + gd, cy + gh), "bcoef": 0.25, "mask": "both"},
		{"a": Vector2(x1 + gd, cy - gh), "b": Vector2(x1 + gd, cy + gh), "bcoef": 0.2, "mask": "both"}
	]
	return st

func get_physics_params(profile_name: String) -> Dictionary:
	var table := {
		"openhax": {"p_invmass": 1.0, "b_invmass": 1.25, "p_damp": 0.973535, "b_damp": 0.991523, "p_rest": 1.0, "pb_rest": 0.1, "pw_rest": 0.0, "bw_rest": 0.78, "accel": 0.125, "k_accel": 0.095, "k_imp": 5.4, "p_max": 3.3333, "b_max": 10.8},
		"classic_hax": {"p_invmass": 0.5, "b_invmass": 1.0, "p_damp": 0.96, "b_damp": 0.99, "p_rest": 0.5, "pb_rest": 0.35, "pw_rest": 0.0, "bw_rest": 0.8, "accel": 0.175, "k_accel": 0.12, "k_imp": 5.8, "p_max": 4.1, "b_max": 11.2},
		"classic_hax_v2": {"p_invmass": 0.5, "b_invmass": 1.0, "p_damp": 0.964, "b_damp": 0.991, "p_rest": 0.5, "pb_rest": 0.32, "pw_rest": 0.0, "bw_rest": 0.82, "accel": 0.185, "k_accel": 0.128, "k_imp": 6.05, "p_max": 4.25, "b_max": 11.6},
		"pro_control": {"p_invmass": 0.8, "b_invmass": 1.25, "p_damp": 0.96, "b_damp": 0.986, "p_rest": 0.6, "pb_rest": 0.04, "pw_rest": 0.0, "bw_rest": 0.72, "accel": 0.16, "k_accel": 0.12, "k_imp": 5.8, "p_max": 3.8, "b_max": 11.0},
		"pro_control_v2": {"p_invmass": 0.55, "b_invmass": 1.05, "p_damp": 0.962, "b_damp": 0.985, "p_rest": 0.55, "pb_rest": 0.14, "pw_rest": 0.0, "bw_rest": 0.72, "accel": 0.195, "k_accel": 0.135, "k_imp": 5.9, "p_max": 4.0, "b_max": 11.4},
		"pro_control_v3": {"p_invmass": 0.5, "b_invmass": 1.1, "p_damp": 0.966, "b_damp": 0.982, "p_rest": 0.5, "pb_rest": 0.08, "pw_rest": 0.0, "bw_rest": 0.68, "accel": 0.21, "k_accel": 0.15, "k_imp": 6.2, "p_max": 4.15, "b_max": 11.8},
		"futsal": {"p_invmass": 0.9, "b_invmass": 1.2, "p_damp": 0.955, "b_damp": 0.982, "p_rest": 0.75, "pb_rest": 0.08, "pw_rest": 0.0, "bw_rest": 0.76, "accel": 0.19, "k_accel": 0.14, "k_imp": 6.4, "p_max": 4.1, "b_max": 11.8},
		"big_arena": {"p_invmass": 0.7, "b_invmass": 1.25, "p_damp": 0.962, "b_damp": 0.993, "p_rest": 0.8, "pb_rest": 0.2, "pw_rest": 0.0, "bw_rest": 0.82, "accel": 0.21, "k_accel": 0.15, "k_imp": 7.2, "p_max": 4.6, "b_max": 13.0},
		"turbo": {"p_invmass": 1.0, "b_invmass": 1.25, "p_damp": 0.955, "b_damp": 0.991523, "p_rest": 0.9, "pb_rest": 0.2, "pw_rest": 0.0, "bw_rest": 0.82, "accel": 0.23, "k_accel": 0.17, "k_imp": 6.8, "p_max": 5.0, "b_max": 13.0},
		"turbo_v2": {"p_invmass": 0.45, "b_invmass": 1.25, "p_damp": 0.972, "b_damp": 0.994, "p_rest": 0.95, "pb_rest": 0.28, "pw_rest": 0.0, "bw_rest": 0.88, "accel": 0.26, "k_accel": 0.19, "k_imp": 7.4, "p_max": 5.5, "b_max": 14.2},
		"low_gravity": {"p_invmass": 1.0, "b_invmass": 1.25, "p_damp": 0.985, "b_damp": 0.996, "p_rest": 1.0, "pb_rest": 0.45, "pw_rest": 0.1, "bw_rest": 0.92, "accel": 0.11, "k_accel": 0.09, "k_imp": 6.2, "p_max": 4.4, "b_max": 12.5},
		"real_soccer": {"p_invmass": 0.7, "b_invmass": 0.85, "p_damp": 0.962, "b_damp": 0.986, "p_rest": 0.45, "pb_rest": 0.28, "pw_rest": 0.0, "bw_rest": 0.68, "accel": 0.145, "k_accel": 0.1, "k_imp": 6.1, "p_max": 3.65, "b_max": 11.8},
		"real_soccer_v2": {"p_invmass": 0.65, "b_invmass": 0.8, "p_damp": 0.965, "b_damp": 0.988, "p_rest": 0.42, "pb_rest": 0.24, "pw_rest": 0.0, "bw_rest": 0.65, "accel": 0.155, "k_accel": 0.11, "k_imp": 6.45, "p_max": 3.8, "b_max": 12.2},
		"ice_hockey": {"p_invmass": 0.65, "b_invmass": 1.3, "p_damp": 0.992, "b_damp": 0.997, "p_rest": 0.85, "pb_rest": 0.45, "pw_rest": 0.25, "bw_rest": 0.9, "accel": 0.11, "k_accel": 0.08, "k_imp": 7.0, "p_max": 4.9, "b_max": 13.8},
		"pinball": {"p_invmass": 0.8, "b_invmass": 1.5, "p_damp": 0.97, "b_damp": 0.996, "p_rest": 1.15, "pb_rest": 0.75, "pw_rest": 0.4, "bw_rest": 1.05, "accel": 0.19, "k_accel": 0.14, "k_imp": 6.6, "p_max": 4.3, "b_max": 13.5},
		"heavy_tank": {"p_invmass": 0.35, "b_invmass": 0.75, "p_damp": 0.945, "b_damp": 0.984, "p_rest": 1.05, "pb_rest": 0.22, "pw_rest": 0.0, "bw_rest": 0.72, "accel": 0.115, "k_accel": 0.075, "k_imp": 6.9, "p_max": 2.85, "b_max": 11.5}
	}
	var base: Dictionary = table.get(profile_name, table["openhax"]).duplicate()
	if bool(settings.get("custom_physics_enabled", false)):
		var ctrl := clampf(float(settings.get("custom_ball_control", 90.0)), 20.0, 100.0)
		base["pb_rest"] = lerpf(0.65, 0.02, (ctrl - 20.0) / 80.0)
		base["b_damp"] = clampf(float(settings.get("custom_ball_damping", base["b_damp"])), 0.975, 0.996)
		base["k_imp"] = clampf(float(settings.get("custom_kick_power", base["k_imp"])), 3.5, 8.5)
		base["p_max"] = clampf(float(settings.get("custom_player_speed", base["p_max"])), 2.8, 5.5)
		base["bw_rest"] = clampf(float(settings.get("custom_wall_bounce", base["bw_rest"])), 0.40, 0.95)
	return base

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings.keys():
			if cfg.has_section_key("general", k):
				settings[k] = cfg.get_value("general", k)
	else:
		var loc := OS.get_locale_language().to_lower()
		if LANGUAGES.has(loc):
			settings["lang"] = loc

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings.keys():
		cfg.set_value("general", k, settings[k])
	cfg.save(SETTINGS_PATH)
	apply_fps_limit()

func load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			for k in profile.keys():
				if parsed.has(k):
					profile[k] = int(parsed[k])

func save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profile))
