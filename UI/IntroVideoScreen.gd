extends Control

## Plays `res://startVideo.mp4` (or `.webm` / `.ogv` fallback), then emits [signal finished_to_landing].
## Skip: click, tap, or ui_cancel. If no supported stream loads, continues immediately.

signal finished_to_landing

var _player: VideoStreamPlayer
var _finished_emitted: bool = false


func _ready() -> void:
	name = "IntroVideoScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_player = VideoStreamPlayer.new()
	_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_player.offset_left = 0
	_player.offset_top = 0
	_player.offset_right = 0
	_player.offset_bottom = 0
	# VideoStreamPlayer uses bool expand (not TextureRect-style expand_mode enums).
	_player.expand = true
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)

	var stream: VideoStream = _load_video_stream()
	if stream != null:
		_player.stream = stream
		_player.loop = false
		_player.play()
		if not _player.finished.is_connected(_on_video_finished):
			_player.finished.connect(_on_video_finished)
	else:
		push_warning("IntroVideoScreen: no playable video at res://startVideo.* — install WebM/Ogv or use a Godot build with MP4 support. Skipping intro.")
		call_deferred("_emit_finished")

	var hint := Label.new()
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint.add_theme_font_size_override("font_size", 16)
	hint.text = "Click or Esc to skip"
	hint.modulate.a = 0.75
	add_child(hint)


func _load_video_stream() -> VideoStream:
	for path in ["res://startVideo.mp4", "res://startVideo.webm", "res://startVideo.ogv"]:
		if not ResourceLoader.exists(path):
			continue
		var res: Resource = load(path)
		if res is VideoStream:
			return res as VideoStream
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		_skip()
		return
	if event is InputEventMouseButton and event.pressed:
		_skip()
		return
	if event is InputEventScreenTouch and event.pressed:
		_skip()


func _on_video_finished() -> void:
	_emit_finished()


func _skip() -> void:
	if _player != null and _player.is_playing():
		_player.stop()
	_emit_finished()


func _emit_finished() -> void:
	if _finished_emitted:
		return
	_finished_emitted = true
	finished_to_landing.emit()
