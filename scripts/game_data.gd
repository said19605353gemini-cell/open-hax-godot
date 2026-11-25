extends Node

const SETTINGS_PATH := "user://openhax_settings.cfg"
const PROFILE_PATH := "user://openhax_profile.json"

const BOT_DIFFICULTIES := ["very_easy", "easy", "medium", "hard", "pro"]
const GRASS_THEMES := ["hd_stadium", "arena_pro", "night_neon", "retro_arcade", "flat"]
const POWERUP_TYPES := ["hawk", "fire", "speed", "magnet", "giant"]

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
	"stadium": "classic",
	"resolution_scale": 1.0
}

var profile := {
	"goals": 0,
	"saves": 0,
	"assists": 0,
	"wins": 0,
	"matches": 0,
	"play_seconds": 0
}

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
		"classic": {"label": "OpenHax Klasik", "w": 860.0, "h": 460.0, "px": 70.0, "py": 45.0, "pw": 720.0, "ph": 370.0, "gh": 68.0, "gd": 36.0},
		"big": {"label": "Büyük Saha", "w": 1040.0, "h": 540.0, "px": 80.0, "py": 50.0, "pw": 880.0, "ph": 440.0, "gh": 82.0, "gd": 40.0},
		"huge": {"label": "Dev Stadyum 4v4", "w": 1160.0, "h": 600.0, "px": 85.0, "py": 52.0, "pw": 990.0, "ph": 496.0, "gh": 90.0, "gd": 44.0},
		"futsal": {"label": "Futsal", "w": 760.0, "h": 400.0, "px": 60.0, "py": 40.0, "pw": 640.0, "ph": 320.0, "gh": 58.0, "gd": 32.0},
		"tiny": {"label": "Mini 1v1", "w": 660.0, "h": 350.0, "px": 54.0, "py": 36.0, "pw": 552.0, "ph": 278.0, "gh": 52.0, "gd": 28.0},
		"long": {"label": "Uzun Koridor", "w": 1080.0, "h": 420.0, "px": 75.0, "py": 42.0, "pw": 930.0, "ph": 336.0, "gh": 66.0, "gd": 38.0},
		"arena_3v3": {"label": "3v3 Orta Arena", "w": 960.0, "h": 500.0, "px": 74.0, "py": 46.0, "pw": 812.0, "ph": 408.0, "gh": 76.0, "gd": 38.0},
		"mini_fast": {"label": "Hızlı 2v2", "w": 720.0, "h": 380.0, "px": 58.0, "py": 38.0, "pw": 604.0, "ph": 304.0, "gh": 56.0, "gd": 30.0},
		"wide_wing": {"label": "Geniş Kanat", "w": 980.0, "h": 580.0, "px": 76.0, "py": 48.0, "pw": 828.0, "ph": 484.0, "gh": 84.0, "gd": 38.0},
		"penalty_box": {"label": "Ceza Sahası", "w": 640.0, "h": 440.0, "px": 56.0, "py": 40.0, "pw": 528.0, "ph": 360.0, "gh": 78.0, "gd": 30.0},
		"hbs_classic": {"label": "HBS: Classic", "w": 840.0, "h": 440.0, "px": 68.0, "py": 42.0, "pw": 704.0, "ph": 356.0, "gh": 64.0, "gd": 34.0},
		"hbs_easy": {"label": "HBS: Easy", "w": 840.0, "h": 440.0, "px": 68.0, "py": 42.0, "pw": 704.0, "ph": 356.0, "gh": 84.0, "gd": 34.0},
		"hbs_small": {"label": "HBS: Small", "w": 700.0, "h": 380.0, "px": 58.0, "py": 38.0, "pw": 584.0, "ph": 304.0, "gh": 58.0, "gd": 30.0},
		"hbs_rounded": {"label": "HBS: Rounded", "w": 840.0, "h": 440.0, "px": 68.0, "py": 42.0, "pw": 704.0, "ph": 356.0, "gh": 64.0, "gd": 34.0},
		"hbs_big": {"label": "HBS: Big", "w": 1100.0, "h": 540.0, "px": 82.0, "py": 50.0, "pw": 936.0, "ph": 440.0, "gh": 80.0, "gd": 40.0},
		"hbs_big_easy": {"label": "HBS: Big Easy", "w": 1100.0, "h": 540.0, "px": 82.0, "py": 50.0, "pw": 936.0, "ph": 440.0, "gh": 96.0, "gd": 40.0},
		"hbs_huge": {"label": "HBS: Huge", "w": 1340.0, "h": 680.0, "px": 92.0, "py": 56.0, "pw": 1156.0, "ph": 568.0, "gh": 96.0, "gd": 46.0}
	}
	var st: Dictionary = presets.get(id, presets["classic"]).duplicate()
	st["id"] = id if presets.has(id) else "classic"
	var cy := float(st["py"]) + float(st["ph"]) * 0.5
	st["posts"] = [
		Vector2(float(st["px"]), cy - float(st["gh"])),
		Vector2(float(st["px"]), cy + float(st["gh"])),
		Vector2(float(st["px"]) + float(st["pw"]), cy - float(st["gh"])),
		Vector2(float(st["px"]) + float(st["pw"]), cy + float(st["gh"]))
	]
	return st

func get_physics_params(profile_name: String) -> Dictionary:
	var table := {
		"openhax": {"p_damp": 0.9735, "b_damp": 0.9915, "p_rest": 1.0, "pb_rest": 0.12, "bw_rest": 0.78, "accel": 0.125, "k_accel": 0.085, "k_imp": 5.4, "p_max": 3.33, "b_max": 11.2},
		"classic_hax": {"p_damp": 0.96, "b_damp": 0.99, "p_rest": 0.5, "pb_rest": 0.35, "bw_rest": 0.8, "accel": 0.175, "k_accel": 0.12, "k_imp": 5.8, "p_max": 4.1, "b_max": 11.2},
		"classic_hax_v2": {"p_damp": 0.964, "b_damp": 0.991, "p_rest": 0.55, "pb_rest": 0.38, "bw_rest": 0.82, "accel": 0.185, "k_accel": 0.13, "k_imp": 6.1, "p_max": 4.25, "b_max": 11.8},
		"pro_control": {"p_damp": 0.962, "b_damp": 0.986, "p_rest": 0.35, "pb_rest": 0.18, "bw_rest": 0.72, "accel": 0.195, "k_accel": 0.14, "k_imp": 5.65, "p_max": 3.9, "b_max": 11.2},
		"pro_control_v2": {"p_damp": 0.965, "b_damp": 0.988, "p_rest": 0.32, "pb_rest": 0.15, "bw_rest": 0.7, "accel": 0.21, "k_accel": 0.15, "k_imp": 5.9, "p_max": 4.1, "b_max": 11.8},
		"pro_control_v3": {"p_damp": 0.968, "b_damp": 0.989, "p_rest": 0.28, "pb_rest": 0.12, "bw_rest": 0.68, "accel": 0.225, "k_accel": 0.16, "k_imp": 6.2, "p_max": 4.25, "b_max": 12.2},
		"futsal": {"p_damp": 0.952, "b_damp": 0.983, "p_rest": 0.4, "pb_rest": 0.22, "bw_rest": 0.65, "accel": 0.205, "k_accel": 0.15, "k_imp": 5.9, "p_max": 4.0, "b_max": 11.6},
		"big_arena": {"p_damp": 0.968, "b_damp": 0.993, "p_rest": 0.6, "pb_rest": 0.35, "bw_rest": 0.82, "accel": 0.19, "k_accel": 0.135, "k_imp": 6.6, "p_max": 4.6, "b_max": 13.0},
		"turbo": {"p_damp": 0.965, "b_damp": 0.992, "p_rest": 0.7, "pb_rest": 0.45, "bw_rest": 0.85, "accel": 0.27, "k_accel": 0.2, "k_imp": 7.4, "p_max": 5.7, "b_max": 15.0},
		"turbo_v2": {"p_damp": 0.97, "b_damp": 0.993, "p_rest": 0.75, "pb_rest": 0.5, "bw_rest": 0.88, "accel": 0.31, "k_accel": 0.22, "k_imp": 8.0, "p_max": 6.2, "b_max": 16.5},
		"low_gravity": {"p_damp": 0.982, "b_damp": 0.996, "p_rest": 0.65, "pb_rest": 0.4, "bw_rest": 0.85, "accel": 0.145, "k_accel": 0.1, "k_imp": 6.2, "p_max": 4.4, "b_max": 13.0},
		"real_soccer": {"p_damp": 0.962, "b_damp": 0.986, "p_rest": 0.45, "pb_rest": 0.28, "bw_rest": 0.68, "accel": 0.145, "k_accel": 0.1, "k_imp": 6.1, "p_max": 3.65, "b_max": 11.8},
		"real_soccer_v2": {"p_damp": 0.965, "b_damp": 0.988, "p_rest": 0.42, "pb_rest": 0.24, "bw_rest": 0.65, "accel": 0.155, "k_accel": 0.11, "k_imp": 6.45, "p_max": 3.8, "b_max": 12.2},
		"ice_hockey": {"p_damp": 0.992, "b_damp": 0.997, "p_rest": 0.85, "pb_rest": 0.45, "bw_rest": 0.9, "accel": 0.11, "k_accel": 0.08, "k_imp": 7.0, "p_max": 4.9, "b_max": 13.8},
		"pinball": {"p_damp": 0.97, "b_damp": 0.996, "p_rest": 1.15, "pb_rest": 0.75, "bw_rest": 1.05, "accel": 0.19, "k_accel": 0.14, "k_imp": 6.6, "p_max": 4.3, "b_max": 13.5},
		"heavy_tank": {"p_damp": 0.945, "b_damp": 0.984, "p_rest": 1.05, "pb_rest": 0.22, "bw_rest": 0.72, "accel": 0.115, "k_accel": 0.075, "k_imp": 6.9, "p_max": 2.85, "b_max": 11.5}
	}
	return table.get(profile_name, table["openhax"])

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
