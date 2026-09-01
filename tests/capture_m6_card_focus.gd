extends Control
## Deterministic component-level visual proof for the shared native card focus.
## It exercises the production UnifiedCardView rather than a painted fixture.

const CARD := preload("res://scripts/ui/unified_card_view.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

func _ready() -> void:
	var viewport := _arg_viewport()
	if viewport.x > 0 and viewport.y > 0: DisplayServer.window_set_size(viewport)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new(); background.color = Color("0b1520"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(background)
	var card := CARD.new(); card.name = "M6FocusProofCard"; card.configure(RULES.card("cinderpaw"), 1, -1, "Selected blueprint", true, true); card.size = CARD.FULL_SIZE; card.position = (get_viewport_rect().size - card.size) * .5; add_child(card)
	if _is_text150():
		var title := card.find_child("UnifiedCardTitle", true, false) as Label
		if title != null: title.add_theme_font_size_override("font_size", 17)
	await get_tree().process_frame
	card.grab_focus()
	await get_tree().process_frame
	var ring := card.find_child("UnifiedCardFocusRing", true, false) as Panel
	if ring == null or not ring.visible:
		push_error("M6 focus proof requires the live art-aperture focus ring.")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var expected := _arg_viewport()
	if expected.x > 0 and image.get_size() != expected:
		push_error("M6 focus proof dimension mismatch: %s != %s" % [image.get_size(), expected])
		get_tree().quit(1)
		return
	var output := _arg_output()
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	if image.save_png(output) != OK:
		push_error("M6 focus proof could not save %s" % output)
		get_tree().quit(1)
		return
	print("CAPTURED: %s" % output)
	get_tree().quit()

func _arg_viewport() -> Vector2i:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-viewport="):
			var parts := arg.trim_prefix("--capture-viewport=").split("x")
			if parts.size() == 2: return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO

func _arg_output() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-output="): return arg.trim_prefix("--capture-output=")
	return "E:/CodexCache/printforge-validation/m6-focus.png"

func _is_text150() -> bool:
	return "--capture-text150" in OS.get_cmdline_user_args()
