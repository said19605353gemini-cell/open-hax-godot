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
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5

	var grass: String = GameData.settings.get("grass_detail", "hd_stadium")
	var perf_boost := bool(GameData.settings.get("perf_boost", false))
	var show_nets := bool(GameData.settings.get("show_goal_nets", true))
	var shadows := bool(GameData.settings.get("shadows", true)) and not perf_boost

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
	if grass != "flat":
		var stripe_w := 46.0
		var x := px
		var toggle := false
		while x < px + pw:
			if toggle:
				var sw := minf(stripe_w, px + pw - x)
				draw_rect(Rect2(x, py, sw, ph), c2)
			toggle = not toggle
			x += stripe_w

	# Goal interiors
	draw_rect(Rect2(px - gd, cy - gh, gd, gh * 2.0), Color(0, 0, 0, 0.20))
	draw_rect(Rect2(px + pw, cy - gh, gd, gh * 2.0), Color(0, 0, 0, 0.20))

	if show_nets and not perf_boost:
		var y := cy - gh + 8.0
		while y < cy + gh:
			draw_line(Vector2(px - gd, y), Vector2(px, y), Color(1, 1, 1, 0.22), 1.0)
			draw_line(Vector2(px + pw, y), Vector2(px + pw + gd, y), Color(1, 1, 1, 0.22), 1.0)
			y += 10.0

	# Pitch lines
	var line_col := Color(0.65, 0.95, 0.82, 0.72) if (grass == "night_neon" or grass == "arena_pro") else Color(1, 1, 1, 0.82)
	draw_rect(Rect2(px, py, pw, ph), line_col, false, 2.0)
	draw_line(Vector2(cx, py), Vector2(cx, py + ph), line_col, 2.0)
	draw_arc(Vector2(cx, cy), 68.0, 0.0, TAU, 48, line_col, 2.0)
	draw_circle(Vector2(cx, cy), 4.0, line_col)

	# Penalty boxes
	if not perf_boost:
		var bw := pw * 0.14
		var bh := gh * 2.15
		draw_rect(Rect2(px, cy - bh * 0.5, bw, bh), line_col, false, 2.0)
		draw_rect(Rect2(px + pw - bw, cy - bh * 0.5, bw, bh), line_col, false, 2.0)

	# Goal frames
	draw_rect(Rect2(px - gd, cy - gh, gd, gh * 2.0), Color.BLACK, false, 3.0)
	draw_rect(Rect2(px + pw, cy - gh, gd, gh * 2.0), Color.BLACK, false, 3.0)

	# Goalposts
	var posts: Array = stadium.get("posts", [])
	for post in posts:
		var pvec: Vector2 = post
		var pcol := Color("#ffcccc") if pvec.x <= cx else Color("#ccccff")
		draw_circle(pvec, 8.0, pcol)
		draw_arc(pvec, 8.0, 0.0, TAU, 20, Color.BLACK, 2.0)

	# Field powerup
	if field_powerup != null:
		var fpos: Vector2 = field_powerup["pos"]
		var ptype: String = field_powerup["type"]
		var pu_col := Color("#f59e0b")
		if ptype == "hawk":
			pu_col = Color("#38bdf8")
		elif ptype == "speed":
			pu_col = Color("#eab308")
		elif ptype == "magnet":
			pu_col = Color("#a855f7")
		elif ptype == "giant":
			pu_col = Color("#22c55e")
		draw_circle(fpos, 14.0, Color(pu_col.r, pu_col.g, pu_col.b, 0.25))
		draw_circle(fpos, 10.0, pu_col)
		draw_arc(fpos, 10.0, 0.0, TAU, 24, Color.WHITE, 2.0)

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
	var font := ThemeDB.fallback_font
	for p in players:
		if p["team"] == "spec":
			continue
		var ppos: Vector2 = p["pos"]
		var pr: float = float(p["radius"])
		if shadows:
			draw_circle(ppos + Vector2(2, 3), pr, Color(0, 0, 0, 0.28))

		if bool(p.get("kick_armed", false)):
			draw_arc(ppos, pr + 4.0, 0.0, TAU, 24, Color.WHITE, 2.0)

		var fill := Color("#ea4141") if p["team"] == "red" else Color("#2d7eff")
		draw_circle(ppos, pr, fill)
		var ring_col := Color("#fde047") if p["id"] == my_player_id else Color.BLACK
		draw_arc(ppos, pr, 0.0, TAU, 28, ring_col, 2.5 if p["id"] == my_player_id else 2.0)

		if font:
			var av: String = str(p.get("avatar", ":)"))
			draw_string(font, ppos + Vector2(-8, 5), av, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
			var tag: String = ("[BOT] " if bool(p.get("is_bot", false)) else "") + str(p.get("name", ""))
			draw_string(font, ppos + Vector2(-40, pr + 14), tag, HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color(1, 1, 1, 0.9))

	# Ball
	if not ball.is_empty():
		var bpos: Vector2 = ball["pos"]
		var br: float = float(ball.get("radius", 10.0))
		if shadows:
			draw_circle(bpos + Vector2(2, 3), br, Color(0, 0, 0, 0.30))
		var bfill := Color("#fb923c") if ball_fire_type == "fire" else (Color("#38bdf8") if ball_fire_type == "hawk" else Color.WHITE)
		draw_circle(bpos, br, bfill)
		if GameData.settings.get("ball_style", "soccer") == "soccer":
			draw_circle(bpos, br * 0.35, Color("#1e293b"))
		draw_arc(bpos, br, 0.0, TAU, 24, Color.BLACK, 2.0)
