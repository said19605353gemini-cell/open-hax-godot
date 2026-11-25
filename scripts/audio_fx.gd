extends Node
class_name AudioFX

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _pb: AudioStreamGeneratorPlayback

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_idx := 0
var _streams: Dictionary = {}
var _last_kick_ms := 0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050.0
	_gen.buffer_length = 0.25
	_player.stream = _gen
	add_child(_player)
	_player.play()
	_pb = _player.get_stream_playback() as AudioStreamGeneratorPlayback

	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)

	_load_stream("kick", "res://assets/sounds/kick.mp3")
	_load_stream("goal1", "res://assets/sounds/goal-1.mp3")
	_load_stream("goal2", "res://assets/sounds/goal-2.mp3")
	_load_stream("start", "res://assets/sounds/game-start.mp3")
	_load_stream("end", "res://assets/sounds/game-end.mp3")
	_load_stream("oh", "res://assets/sounds/people-oh.mp3")

func _load_stream(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_streams[key] = load(path)

func _play_stream(key: String, vol_mul: float = 1.0) -> bool:
	if not bool(GameData.settings.get("master_sound", true)):
		return true
	var vol := clampf(float(GameData.settings.get("sound_volume", 0.65)) * vol_mul, 0.0, 1.0)
	if vol <= 0.01:
		return true
	if not _streams.has(key) or _streams[key] == null:
		return false
	var p := _sfx_players[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
	p.stream = _streams[key]
	p.volume_db = linear_to_db(vol)
	p.play()
	return true

func play_tone(freq_start: float, freq_end: float, duration: float, amp: float = 0.25) -> void:
	if not bool(GameData.settings.get("master_sound", true)):
		return
	if _pb == null:
		return
	var vol := clampf(float(GameData.settings.get("sound_volume", 0.65)), 0.0, 1.0)
	if vol <= 0.01:
		return
	var rate := _gen.mix_rate
	var total := mini(int(duration * rate), _pb.get_frames_available())
	var phase := 0.0
	for i in range(total):
		var t := float(i) / maxf(1.0, float(total))
		var freq := lerpf(freq_start, freq_end, t)
		var env := (1.0 - t) * amp * vol
		var s := sin(phase * TAU) * env
		_pb.push_frame(Vector2(s, s))
		phase += freq / rate

func play_kick() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_kick_ms < 75:
		return
	_last_kick_ms = now
	if not _play_stream("kick", 0.9):
		play_tone(180.0, 65.0, 0.08, 0.35)

func play_post() -> void:
	play_tone(520.0, 380.0, 0.14, 0.30)

func play_goal() -> void:
	var key := "goal1" if randf() < 0.5 else "goal2"
	if not _play_stream(key, 0.95):
		play_tone(440.0, 660.0, 0.22, 0.32)

func play_whistle() -> void:
	if not _play_stream("start", 0.85):
		play_tone(1450.0, 1380.0, 0.16, 0.18)

func play_game_start() -> void:
	if not _play_stream("start", 0.85):
		play_whistle()

func play_game_end() -> void:
	if not _play_stream("end", 0.9):
		play_tone(660.0, 440.0, 0.35, 0.28)

func play_save_oh() -> void:
	if not _play_stream("oh", 0.85):
		play_tone(320.0, 480.0, 0.22, 0.25)
