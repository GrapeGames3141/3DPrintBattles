class_name AudioDirector
extends Node
## Non-authoritative presentation routing. Captions are the accessible source of truth.

const CAPTIONS := {
	"workshop":"Workshop ambience: soft forge hum.",
	"battle":"Battle cue: print companions ready.",
	"forge":"Forge cue: layer printer active.",
	"press":"Button press.",
	"impact":"Impact: battle action resolved.",
	"card":"Support card: effect applied.",
}

var settings: Dictionary = AudioSettings.defaults()
var current_state := ""
var last_caption := ""
var muted_for_capture := false
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _remaining_frames := 0
var _phase := 0.0
var _frequency := 440.0
var _channel := "sfx"

static func channel_gain_bps(values: Dictionary, channel: String) -> int:
	var normalized := AudioSettings.ensure(values)
	var master := clampi(int(normalized.get("master_bps", 0)), 0, 10000)
	var channel_key := "music_bps" if channel == "music" else "sfx_bps"
	var channel_level := clampi(int(normalized.get(channel_key, 0)), 0, 10000)
	return clampi((master * channel_level) / 10000, 0, 10000)

static func sample_gain(values: Dictionary, channel: String) -> float:
	return 0.12 * float(channel_gain_bps(values, channel)) / 10000.0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.15
	_player.stream = stream
	add_child(_player)

func _process(_delta: float) -> void:
	if _playback == null or _remaining_frames <= 0: return
	var frames := mini(_remaining_frames, _playback.get_frames_available())
	for _index in frames:
		var sample := sin(_phase) * sample_gain(settings, _channel)
		_playback.push_frame(Vector2(sample, sample))
		_phase += TAU * _frequency / 22050.0
		_remaining_frames -= 1

func configure(values: Dictionary, capture_muted := false) -> void:
	settings = AudioSettings.ensure(values)
	muted_for_capture = capture_muted

func route(state: String) -> String:
	var next_state := state if state in ["workshop", "battle", "forge"] else "workshop"
	var changed := next_state != current_state
	current_state = next_state
	if changed or last_caption.is_empty():
		last_caption = str(CAPTIONS.get(current_state, ""))
	# A calm generated state-change cue is non-authoritative and never restarts
	# during ordinary UI rerenders.
	if changed and not muted_for_capture and int(settings.get("master_bps", 0)) > 0 and int(settings.get("music_bps", 0)) > 0 and is_inside_tree():
		_frequency = {"workshop":110.0, "battle":165.0, "forge":220.0}.get(current_state, 110.0)
		_channel = "music"
		_remaining_frames = 1800
		_phase = 0.0
		_player.play()
		_playback = _player.get_stream_playback()
	return last_caption

func cue(kind: String) -> String:
	last_caption = str(CAPTIONS.get(kind, ""))
	if audible(kind) and is_inside_tree():
		_frequency = {"press":520.0,"impact":180.0,"card":660.0}.get(kind, 300.0)
		_channel = "sfx"
		_remaining_frames = 1500 if kind == "impact" else 900
		_phase = 0.0
		_player.play()
		_playback = _player.get_stream_playback()
	return last_caption

func cue_card(card_name: String, effect_text: String) -> String:
	last_caption = "Support card: %s — %s." % [card_name, effect_text]
	if audible("card") and is_inside_tree():
		_frequency = 660.0; _channel = "sfx"; _remaining_frames = 900; _phase = 0.0; _player.play(); _playback = _player.get_stream_playback()
	return last_caption

func audible(kind: String) -> bool:
	return not muted_for_capture and int(settings.get("master_bps", 0)) > 0 and int(settings.get("sfx_bps", 0)) > 0 and not str(kind).is_empty()
