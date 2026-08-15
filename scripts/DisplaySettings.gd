# DisplaySettings.gd
# Autoload — UI scale + fullscreen. Works in windowed and fullscreen modes.

extends Node

const BASE_SIZE := Vector2i(1280, 720)
const DEFAULT_UI_SCALE := 2.0
const MIN_UI_SCALE := 1.0
const MAX_UI_SCALE := 2.5

var _current_ui_scale: float = DEFAULT_UI_SCALE
var _applying := false

func _ready() -> void:
	var tree := get_tree()
	if tree and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	call_deferred("_boot_apply")

func _boot_apply() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	apply_from_save()

func _on_scene_changed() -> void:
	call_deferred("_reapply")

func _reapply() -> void:
	if _applying:
		return
	_apply_display()

func apply_from_save() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	_current_ui_scale = clampf(
		settings.get("ui_scale", DEFAULT_UI_SCALE),
		MIN_UI_SCALE,
		MAX_UI_SCALE
	)
	_apply_display()

func apply_ui_scale(scale: float) -> void:
	_current_ui_scale = clampf(scale, MIN_UI_SCALE, MAX_UI_SCALE)
	if SaveManager.data.has("settings"):
		SaveManager.data["settings"]["ui_scale"] = _current_ui_scale
	_apply_display()

func apply_fullscreen(enabled: bool) -> void:
	if SaveManager.data.has("settings"):
		SaveManager.data["settings"]["fullscreen"] = enabled
		SaveManager.save_game()
	_apply_display()

func _apply_display() -> void:
	var win := get_window()
	if win == null:
		return

	_applying = true
	var fullscreen: bool = SaveManager.data.get("settings", {}).get("fullscreen", false)
	var scale: float = _current_ui_scale

	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_size = BASE_SIZE

	if fullscreen:
		if win.mode != Window.MODE_FULLSCREEN:
			win.mode = Window.MODE_FULLSCREEN
		# Fullscreen: scale via content_scale_factor (window resize is ignored).
		win.content_scale_factor = scale
	else:
		if win.mode != Window.MODE_WINDOWED:
			win.mode = Window.MODE_WINDOWED
		# Windowed: grow the window; keep factor at 1 to avoid clipping.
		win.content_scale_factor = 1.0
		var target := Vector2i(
			int(BASE_SIZE.x * scale),
			int(BASE_SIZE.y * scale)
		)
		DisplayServer.window_set_size(target, win.get_window_id())
		win.size = target
		_center_window(target)

	_applying = false

func _center_window(size: Vector2i) -> void:
	var win := get_window()
	if win == null:
		return
	var screen_size := DisplayServer.screen_get_size(win.current_screen)
	win.position = Vector2i(
		max(0, (screen_size.x - size.x) / 2),
		max(0, (screen_size.y - size.y) / 2)
	)

func is_fullscreen() -> bool:
	var win := get_window()
	if win == null:
		return false
	return win.mode == Window.MODE_FULLSCREEN \
		or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN

func get_ui_scale() -> float:
	return _current_ui_scale
