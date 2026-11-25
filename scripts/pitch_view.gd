extends Node2D
class_name PitchView

var stadium: Dictionary = {}
var players: Array = []
var ball: Dictionary = {}
var trail: Array = []
var particles: Array = []
var field_powerup = null
var ball_fire_type := ""
var my_player_id := "host"
var my_ping_ms := 0

var _grass_tex: Texture2D = null
var _pulse := 0.0

const PU_COLORS := {
	"hawk": Color("#facc15"),
	"fire": Color("#f97316"),
	"speed": Color("#38bdf8"),
	"magnet": Color("#c084fc"),
	"giant": Color("#4ade80")
}

const PU_ICONS := {
	"hawk": "🦅",
	"fire": "🔥",
	"speed": "⚡",
	"magnet": "🧲",
	"giant": "🛡️"
}

func _ready() -> void:
	if ResourceLoader.exists("res://assets/img/grass.png"):
		_grass_tex = load("res://assets/img/grass.png")

func _process(delta: float) -> void:
	_pulse += delta * 5.0

func _draw() -> void:
	if stadium.is_empty():
		return
	var w := float(stadium["w"])
	var h := float(stadium["h"])
	var px := float(stadium["px"])
	var py := float(stadium["py"])
	var pw := float(stadium["pw"])
	var ph := float(stadium["ph"])
	var gh := float(stadium["gh"])
	var gd := float(stadium["gd"])
	var cr := float(stadium.get("cr", 75.0))
	var post_r := float(stadium.get("post_r", 7.5))
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5

	var grass: String = GameData.settings.get("grass_detail", "hd_stadium")
	var perf_boost := bool(GameData.settings.get("perf_boost", false))
	var show_nets := bool(GameData.settings.get("show_goal_nets", true))
	var shadows := bool(GameData.settings.get("shadows", true)) and not perf_boost
	var show_avatars := bool(GameData.settings.get("show_avatars", true))
	var use_custom_colors := bool(GameData.settings.get("custom_team_colors", true))
	var kick_flash_en := bool(GameData.settings.get("kick_flash", true))

	# Outer surround
	draw_rect(Rect2(0, 0, w, h), Color("#465d37"))

	# Pitch surface
	var c1 := Color("#718c5a")
	var c2 := Color("#688251")
	if grass == "night_neon":
		c1 = Color("#1b3b2b")
		c2 = Color("#204533")
	elif grass == "arena_pro":
		c1 = Color("#2d6a4f")
		c2 = Color("#255c44")
	elif grass == "retro_arcade":
		c1 = Color("#578a34")
		c2 = Color("#4d7d2c")

	draw_rect(Rect2(px, py, pw, ph), c1)

	if grass == "standard" and _grass_tex != null and not perf_boost:
		draw_texture_rect(_grass_tex, Rect2(px, py, pw, ph), true)
	elif grass != "flat":
		# 45-degree diagonal stripes clipped to pitch
		var stripe_w := 44.0
		var x := -ph
		var toggle := false
		while x < pw + ph:
			if toggle:
				var p1 := Vector2(clampf(px + x, px, px + pw), py)
				var p2 := Vector2(clampf(px + x + stripe_w, px, px + pw), py)
				var p3 := Vector2(clampf(px + x + stripe_w - ph * 0.45, px, px + pw), py + ph)
				var p4 := Vector2(clampf(px + x - ph * 0.45, px, px + pw), py + ph)
				draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), c2)
			toggle = not toggle
			x += stripe_w

	# Goal interiors
	draw_rect(Rect2(px - gd, cy - gh, gd, gh * 2.0), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(px + pw, cy - gh, gd, gh * 2.0), Color(0, 0, 0, 0.22))

	if show_nets and not perf_boost:
		var y := cy - gh + 8.0
		while y < cy + gh:
			draw_line(Vector2(px - gd, y), Vector2(px, y), Color(1, 1, 1, 0.20), 1.0)
			draw_line(Vector2(px + pw, y), Vector2(px + pw + gd, y), Color(1, 1, 1, 0.20), 1.0)
			y += 10.0

	# Pitch lines + corner arcs
	var line_col := Color(0.65, 0.95, 0.82, 0.72) if (grass == "night_neon" or grass == "arena_pro") else Color(1, 1, 1, 0.82)
	draw_rect(Rect2(px, py, pw, ph), line_col, false, 2.0)
	draw_line(Vector2(cx, py), Vector2(cx, py + ph), line_col, 2.0)
	draw_arc(Vector2(cx, cy), cr, 0.0, TAU, 48, line_col, 2.0)
	draw_circle(Vector2(cx, cy), 4.0, line_col)

	# Corner arcs (r=14)
	draw_arc(Vector2(px, py), 14.0, 0.0, PI * 0.5, 12, line_col, 2.0)
	draw_arc(Vector2(px + pw, py), 14.0, PI * 0.5, PI, 12, line_col, 2.0)
	draw_arc(Vector2(px + pw, py + ph), 14.0, PI, PI * 1.5, 12, line_col, 2.0)
	draw_arc(Vector2(px, py + ph), 14.0, PI * 1.5, TAU, 12, line_col, 2.0)

	# Penalty boxes
	if not perf_boost:
		var bw := pw * 0.14
		var bh := gh * 2.15
		draw_rect(Rect2(px, cy - bh * 0.5, bw, bh), line_col, false, 2.0)
		draw_rect(Rect2(px + pw - bw, cy - bh * 0.5, bw, bh), line_col, false, 2.0)

	# Dashed goal mouth trigger lines
	draw_dashed_line(Vector2(px, cy - gh), Vector2(px, cy + gh), Color(1, 1, 1, 0.35), 2.0, 6.0)
	draw_dashed_line(Vector2(px + pw, cy - gh), Vector2(px + pw, cy + gh), Color(1, 1, 1, 0.35), 2.0, 6.0)

	# Curved goal frames
	var r_net := minf(12.0, gd * 0.65)
	draw_polyline(PackedVector2Array([
		Vector2(px, cy - gh), Vector2(px - gd + r_net, cy - gh),
		Vector2(px - gd, cy - gh + r_net), Vector2(px - gd, cy + gh - r_net),
		Vector2(px - gd + r_net, cy + gh), Vector2(px, cy + gh)
	]), Color.BLACK, 3.0)
	draw_polyline(PackedVector2Array([
		Vector2(px + pw, cy - gh), Vector2(px + pw + gd - r_net, cy - gh),
		Vector2(px + pw + gd, cy - gh + r_net), Vector2(px + pw + gd, cy + gh - r_net),
		Vector2(px + pw + gd - r_net, cy + gh), Vector2(px + pw, cy + gh)
	]), Color.BLACK, 3.0)

	# Goalposts
	var posts: Array = stadium.get("posts", [])
	for post in posts:
		var pvec: Vector2 = post
		var pcol := Color("#ff6666") if pvec.x <= cx else Color("#6699ff")
		draw_circle(pvec, post_r, pcol)
		draw_arc(pvec, post_r, 0.0, TAU, 20, Color.BLACK, 2.0)

	var font := ThemeDB.fallback_font

	# Field powerup with pulsing aura & icon
	if field_powerup != null:
		var fpos: Vector2 = field_powerup["pos"]
		var ptype: String = field_powerup["type"]
		var pu_col: Color = PU_COLORS.get(ptype, Color("#f59e0b"))
		var aura_r := 16.0 + sin(_pulse) * 3.0
		draw_circle(fpos, aura_r, Color(pu_col.r, pu_col.g, pu_col.b, 0.28))
		draw_circle(fpos, 11.0, pu_col)
		draw_arc(fpos, 11.0, 0.0, TAU, 24, Color.WHITE, 2.0)
		if font:
			draw_string(font, fpos + Vector2(-7, 5), str(PU_ICONS.get(ptype, "*")), HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color.WHITE)

	# Ball trail
	if bool(GameData.settings.get("ball_trail", true)) and trail.size() > 1:
		for i in range(trail.size()):
			var a := float(i + 1) / float(trail.size()) * 0.35
			var r := float(ball.get("radius", 10.0)) * (0.4 + 0.5 * (float(i) / float(trail.size())))
			var tcol := Color(0.98, 0.45, 0.09, a) if ball_fire_type == "fire" else (Color(0.22, 0.74, 0.97, a) if ball_fire_type == "hawk" else Color(1, 1, 1, a))
			draw_circle(trail[i], r, tcol)

	# Particles
	for pt in particles:
		draw_circle(pt["pos"], pt["r"], pt["col"])

	# Players
	for p in players:
		if p["team"] == "spec":
			continue
		var ppos: Vector2 = p["pos"]
		var pr: float = float(p["radius"])
		var is_me: bool = (str(p.get("id", "")) == my_player_id)
		if shadows:
			draw_circle(ppos + Vector2(2, 3), pr, Color(0, 0, 0, 0.28))

		# Local player outer guide ring
		if is_me:
			draw_arc(ppos, pr + 9.0, 0.0, TAU, 28, Color(1, 1, 1, 0.25), 1.5)

		# Powerup aura ring
		var p_pu := str(p.get("powerup", ""))
		if not p_pu.is_empty():
			var auc: Color = PU_COLORS.get(p_pu, Color.WHITE)
			draw_arc(ppos, pr + 5.0, 0.0, TAU, 28, auc, 2.5)

		# Kick armed / flash ring
		if bool(p.get("kick_armed", false)) or (kick_flash_en and int(p.get("kick_flash_ticks", 0)) > 0):
			draw_arc(ppos, pr + 4.0, 0.0, TAU, 24, Color.WHITE, 2.2)

		var fill := Color("#ea4141") if p["team"] == "red" else Color("#2d7eff")
		var cc := str(p.get("custom_color", ""))
		if use_custom_colors and cc.is_valid_html_color():
			fill = Color.html(cc)
		draw_circle(ppos, pr, fill)
		var ring_col := Color("#fde047") if is_me else Color.BLACK
		draw_arc(ppos, pr, 0.0, TAU, 28, ring_col, 2.5 if is_me else 2.0)

		if font:
			if show_avatars:
				var av: String = str(p.get("avatar", ":)"))
				draw_string(font, ppos + Vector2(-8, 5), av, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
			var tag: String = ("[BOT] " if bool(p.get("is_bot", false)) else "") + str(p.get("name", ""))
			draw_string(font, ppos + Vector2(-44, pr + 14), tag, HORIZONTAL_ALIGNMENT_CENTER, 88, 11, Color(1, 1, 1, 0.92))

	# Ball
	if not ball.is_empty():
		var bpos: Vector2 = ball["pos"]
		var br: float = float(ball.get("radius", 10.0))
		if shadows:
			draw_circle(bpos + Vector2(2, 3), br, Color(0, 0, 0, 0.30))
		var bfill := Color("#fb923c") if ball_fire_type == "fire" else (Color("#38bdf8") if ball_fire_type == "hawk" else Color.WHITE)
		draw_circle(bpos, br, bfill)
		if GameData.settings.get("ball_style", "soccer") == "soccer":
			draw_circle(bpos - Vector2(2, 2), br * 0.45, Color(1, 1, 1, 0.85))
			draw_circle(bpos + Vector2(2, 2), br * 0.30, Color("#1e293b"))
		draw_arc(bpos, br, 0.0, TAU, 24, Color.BLACK, 2.0)

	# FPS / Ping HUD
	if bool(GameData.settings.get("show_fps_hud", true)) and font:
		var hud_txt := "FPS: %d | Cap: %s" % [Engine.get_frames_per_second(), GameData.get_effective_fps_label()]
		if my_ping_ms > 0:
			hud_txt += " | Ping: %dms" % my_ping_ms
		draw_string(font, Vector2(12, 20), hud_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.85))
