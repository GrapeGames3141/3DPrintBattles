extends SceneTree
## Derived portrait plates retain each reviewed landscape environment while
## preserving the central combat floor rather than stretching it.
const IDS := ["daily_arena", "first_layers", "element_bench", "reinforced_run", "masterwork_circuit", "primordial_proof"]
func _init() -> void:
	for id in IDS:
		var source := "res://assets/ui/battle_backgrounds/%s_landscape_v1.png" % id
		var image := Image.load_from_file(ProjectSettings.globalize_path(source))
		if image == null or image.is_empty(): push_error("Missing background: " + source); quit(1); return
		var crop_width := mini(image.get_width(), (image.get_height() * 9) / 16)
		var x := (image.get_width() - crop_width) / 2
		image = image.get_region(Rect2i(x, 0, crop_width, image.get_height()))
		image.resize(1080, 1920, Image.INTERPOLATE_LANCZOS)
		var output := ProjectSettings.globalize_path("res://assets/ui/battle_backgrounds/%s_portrait_v1.png" % id)
		if image.save_png(output) != OK: push_error("Could not write " + output); quit(1); return
		print("portrait background: " + id)
	quit()
