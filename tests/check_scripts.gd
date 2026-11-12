extends SceneTree
## Compiles every script in the project and fails on the first that does not.
##   godot --headless --path . -s tests/check_scripts.gd


func _initialize() -> void:
	await process_frame
	var bad := 0
	var count := 0
	for dir in ["res://scripts", "res://tools"]:
		for path in _walk(dir):
			count += 1
			var script := load(path) as GDScript
			if script == null or not script.can_instantiate():
				bad += 1
				print("  FAIL: ", path)
	print("%d scripts checked, %d failed" % [count, bad])
	quit(1 if bad > 0 else 0)


func _walk(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_walk(dir + "/" + sub))
	return out
