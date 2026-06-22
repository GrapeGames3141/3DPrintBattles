# SceneTransition.gd
# Autoload — handles all scene changes with a fade transition.
# Usage: SceneTransition.go_to("res://scenes/Battle.tscn")
# Usage: SceneTransition.go_to("res://scenes/Workshop.tscn", {"trainer_id": "trainer_gizmo"})

extends CanvasLayer

var _pending_scene = ""
var _pending_data = {}
var _overlay: ColorRect

func _ready() -> void:
	layer = 100  # Always on top
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

# Navigate to a new scene with optional data dictionary
func go_to(scene_path: String, data: Dictionary = {}) -> void:
	_pending_scene = scene_path
	_pending_data = data
	_fade_out()

func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 1), 0.35)
	tween.tween_callback(_change_scene)

func _change_scene() -> void:
	var tree = get_tree()

	if not ResourceLoader.exists(_pending_scene):
		push_error("[SceneTransition] Scene not found: %s" % _pending_scene)
		_fade_in()
		return

	var err = tree.change_scene_to_file(_pending_scene)
	if err != OK:
		push_error("[SceneTransition] Failed to change scene: %s (error %d)" % [_pending_scene, err])
		_fade_in()
		return

	# current_scene can be null for a frame after change_scene_to_file (esp. on boot)
	var root_scene = tree.current_scene
	if root_scene == null:
		await tree.scene_changed
		root_scene = tree.current_scene
	if root_scene == null:
		await tree.process_frame
		root_scene = tree.current_scene

	if root_scene != null and root_scene.has_method("receive_data"):
		root_scene.receive_data(_pending_data)
	elif root_scene == null:
		push_error("[SceneTransition] current_scene is null after loading: %s" % _pending_scene)

	_fade_in()

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 0), 0.35)
