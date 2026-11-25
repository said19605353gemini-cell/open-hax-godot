extends Node
class_name AudioFX

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _pb: AudioStreamGeneratorPlayback

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050.0
	_gen.buffer_length = 0.25
	_player.stream = _gen
	add_child(_player)
	_player.play()
	_pb = _player.get_stream_playback() as AudioStreamGeneratorPlayback

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
	play_tone(180.0, 65.0, 0.08, 0.35)

func play_post() -> void:
	play_tone(520.0, 380.0, 0.14, 0.30)

func play_goal() -> void:
	play_tone(440.0, 660.0, 0.22, 0.32)

func play_whistle() -> void:
	play_tone(1450.0, 1380.0, 0.16, 0.18)
