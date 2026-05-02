extends Object
class_name PrintMeshResolver

## If `res://Assets/Prints/<unit_id>/model.gltf` exists, a 3D scene can load it; else use primitives.

static func try_model_path(unit_id: String) -> String:
	var p: String = "res://Assets/Prints/%s/model.gltf" % unit_id
	if FileAccess.file_exists(p):
		return p
	return ""
