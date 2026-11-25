extends RefCounted
class_name BotAI

const DIFFICULTY_CFG := {
	"very_easy": {"look": 3, "speed": 0.56, "kick_bias": 20, "aim": 0.40, "mask": 3},
	"easy": {"look": 6, "speed": 0.72, "kick_bias": 12, "aim": 0.65, "mask": 1},
	"medium": {"look": 10, "speed": 0.89, "kick_bias": 5, "aim": 0.82, "mask": 0},
	"hard": {"look": 14, "speed": 1.0, "kick_bias": 1, "aim": 0.94, "mask": 0},
	"pro": {"look": 18, "speed": 1.0, "kick_bias": 0, "aim": 1.0, "mask": 0}
}

static func reflect_y(y: float, min_y: float, max_y: float) -> float:
	var span := max_y - min_y
	if span <= 0.0:
		return y
	var rel := y - min_y
	while rel < 0.0 or rel > span:
		if rel < 0.0:
			rel = -rel
		if rel > span:
			rel = 2.0 * span - rel
	return min_y + rel

static func get_formation_home(bot_idx: int, bot_count: int, is_blue: bool, st: Dictionary, ball_x: float) -> Dictionary:
	var px := float(st["px"])
	var py := float(st["py"])
	var pw := float(st["pw"])
	var ph := float(st["ph"])
	var progress := (px + pw - ball_x) / pw if is_blue else (ball_x - px) / pw
	var shift := (progress - 0.5) * 0.22

	if bot_count <= 1:
		return {"pos": Vector2(px + pw * (0.72 if is_blue else 0.28), py + ph * 0.5), "keeper": false}

	if bot_idx == 0:
		return {"pos": Vector2(px + pw - 30.0 if is_blue else px + 30.0, py + ph * 0.5), "keeper": true}

	var out_idx := bot_idx - 1
	var out_cnt := bot_count - 1
	var line_depths := [0.52] if out_cnt == 1 else ([0.28, 0.65] if out_cnt <= 3 else [0.22, 0.50, 0.76])

	var lines := []
	for _l in range(line_depths.size()):
		lines.append([])
	for i in range(out_cnt):
		var li := mini(lines.size() - 1, int(floor(float(i * lines.size()) / float(out_cnt))))
		lines[li].append(i)

	var my_line := 0
	var pos_in_line := 0
	var line_size := 1
	for l in range(lines.size()):
		var found: int = lines[l].find(out_idx)
		if found != -1:
			my_line = l
			pos_in_line = found
			line_size = lines[l].size()
			break

	var depth := clampf(float(line_depths[my_line]) + shift, 0.12, 0.88)
	var norm_y := 0.5 if line_size <= 1 else 0.16 + (float(pos_in_line) / float(line_size - 1)) * 0.68
	return {
		"pos": Vector2(px + pw * (1.0 - depth if is_blue else depth), py + ph * norm_y),
		"keeper": false
	}

static func compute_input(
	bot: Dictionary,
	bot_idx: int,
	bot_count: int,
	all_players: Array,
	ball: Dictionary,
	st: Dictionary,
	difficulty: String,
	tick: int
) -> Dictionary:
	var cfg: Dictionary = DIFFICULTY_CFG.get(difficulty, DIFFICULTY_CFG["medium"])
	var is_blue: bool = bot["team"] == "blue"

	var px := float(st["px"])
	var py := float(st["py"])
	var pw := float(st["pw"])
	var ph := float(st["ph"])
	var gh := float(st["gh"])
	var min_x := px + 10.0
	var max_x := px + pw - 10.0
	var min_y := py + 10.0
	var max_y := py + ph - 10.0
	var cy := py + ph * 0.5
	var own_gx := px + pw if is_blue else px
	var target_gx := px if is_blue else px + pw

	var bpos: Vector2 = ball["pos"]
	var bvel: Vector2 = ball["vel"]
	var ppos: Vector2 = bot["pos"]

	var raw_dist := bpos.distance_to(ppos)
	var dyn_look := mini(int(cfg["look"]), maxi(2, int(round(raw_dist / 18.0))))
	var pred_x := clampf(bpos.x + bvel.x * dyn_look, min_x, max_x)
	var pred_y := reflect_y(bpos.y + bvel.y * dyn_look, min_y, max_y)

	var teammates := []
	var opponents := []
	for p in all_players:
		if p["team"] == "spec":
			continue
		if p["team"] == bot["team"]:
			if p["id"] != bot["id"]:
				teammates.append(p)
		else:
			opponents.append(p)

	var home := get_formation_home(bot_idx, bot_count, is_blue, st, bpos.x)
	var home_pos: Vector2 = home["pos"]
	var is_keeper: bool = home["keeper"]

	var closest_dist := raw_dist
	for mate in teammates:
		var mpos: Vector2 = mate["pos"]
		if absf(mpos.x - own_gx) < 75.0 and absf(bpos.x - own_gx) > 150.0:
			continue
		var d := bpos.distance_to(mpos)
		if d < closest_dist:
			closest_dist = d
	var is_chaser := (not is_keeper) and raw_dist <= closest_dist + 14.0

	var corner_sign := -1.0 if pred_y >= cy else 1.0
	var aim_x := target_gx
	var aim_y := cy + corner_sign * (gh * 0.55 * float(cfg["aim"]))
	var passing := false

	var dist_to_goal := Vector2(target_gx, cy).distance_to(bpos)
	if teammates.size() > 0 and dist_to_goal > pw * 0.34:
		var best_mate = null
		var best_score := -999999.0
		for mate in teammates:
			var mpos: Vector2 = mate["pos"]
			var ahead := mpos.x < ppos.x - 35.0 if is_blue else mpos.x > ppos.x + 35.0
			var md := mpos.distance_to(ppos)
			if not ahead or md < 65.0 or md > pw * 0.58:
				continue
			var min_opp := 999.0
			for opp in opponents:
				min_opp = minf(min_opp, mpos.distance_to(opp["pos"]))
			var score := min_opp + (ppos.x - mpos.x if is_blue else mpos.x - ppos.x) * 0.45
			if min_opp > 42.0 and score > best_score:
				best_score = score
				best_mate = mate
		if best_mate != null:
			var mp: Vector2 = best_mate["pos"]
			var mv: Vector2 = best_mate["vel"]
			aim_x = mp.x + mv.x * 10.0
			aim_y = mp.y + mv.y * 10.0
			passing = true

	var ball_to_own := (bvel.x > 0.7) if is_blue else (bvel.x < -0.7)
	var emergency := (ball_to_own and absf(bpos.x - own_gx) < pw * 0.32) or absf(bpos.x - own_gx) < 115.0

	var desired := Vector2.ZERO
	if is_keeper:
		var in_box := absf(bpos.x - own_gx) < 125.0 and absf(bpos.y - cy) < gh + 70.0
		if in_box and ((ppos.x >= bpos.x - 6.0) if is_blue else (ppos.x <= bpos.x + 6.0)):
			desired = Vector2(pred_x + (18.0 if is_blue else -18.0), pred_y)
		else:
			desired = Vector2(home_pos.x, clampf(pred_y, cy - gh + 6.0, cy + gh - 6.0))
	elif not is_chaser:
		desired = Vector2(
			home_pos.x + (pred_x - home_pos.x) * 0.22,
			home_pos.y + (pred_y - home_pos.y) * 0.25
		)
	elif emergency and ((ppos.x < bpos.x + 8.0) if is_blue else (ppos.x > bpos.x - 8.0)):
		var side := -1.0 if ppos.y < pred_y else 1.0
		desired = Vector2(
			minf(max_x, pred_x + 36.0) if is_blue else maxf(min_x, pred_x - 36.0),
			clampf(pred_y + side * 42.0, min_y, max_y)
		)
	else:
		var to_pred := Vector2(pred_x - aim_x, pred_y - aim_y)
		var gdir := to_pred.normalized() if to_pred.length() > 0.01 else Vector2.RIGHT
		var app := 28.0 if raw_dist > 90.0 else 20.0
		desired = Vector2(pred_x, pred_y) + gdir * app
		var wrong_side := (ppos.x < pred_x + 2.0) if is_blue else (ppos.x > pred_x - 2.0)
		if wrong_side and absf(ppos.y - pred_y) < 36.0:
			var side := float(bot.get("avoid_side", 0.0))
			if side == 0.0 or absf(ppos.y - pred_y) > 6.0:
				side = -1.0 if ppos.y < pred_y else 1.0
				bot["avoid_side"] = side
			desired = Vector2(pred_x + (48.0 if is_blue else -48.0), pred_y + side * 50.0)
		else:
			bot["avoid_side"] = 0.0

	for mate in teammates:
		var diff := desired - (mate["pos"] as Vector2)
		var md := diff.length()
		if md > 0.1 and md < 54.0:
			desired += diff.normalized() * ((54.0 - md) * 0.7)

	if int(cfg["mask"]) > 0 and (tick & int(cfg["mask"])) != 0:
		desired.y += sin(float(tick) * 0.13) * 8.0

	desired.x = clampf(desired.x, min_x, max_x)
	desired.y = clampf(desired.y, min_y, max_y)

	var delta := desired - ppos
	var move := Vector2.ZERO
	if delta.length() > 3.5:
		var thr := maxf(2.5, delta.length() * 0.22)
		if delta.x < -thr:
			move.x = -1.0
		elif delta.x > thr:
			move.x = 1.0
		if delta.y < -thr:
			move.y = -1.0
		elif delta.y > thr:
			move.y = 1.0

	var kick := false
	var bdiff := bpos - ppos
	var bdist := bdiff.length()
	var sdir := bdiff.normalized() if bdist > 0.01 else Vector2.ZERO
	var tdir := (Vector2(aim_x, aim_y) - bpos).normalized()
	var align := sdir.dot(tdir)
	var aimed_fwd := (bdiff.x < -2.0) if is_blue else (bdiff.x > 2.0)
	var clear_act := align > (0.62 if passing else (0.55 if difficulty == "pro" else 0.35))
	if bdist <= float(bot["radius"]) + float(ball["radius"]) + 7.0 and aimed_fwd and (clear_act or (is_keeper and emergency)) and tick >= int(bot["next_kick_tick"]) + int(cfg["kick_bias"]):
		kick = true

	return {"move": move, "kick": kick, "speed_scale": float(cfg["speed"])}
