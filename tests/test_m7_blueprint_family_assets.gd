extends Node

const MANIFEST_PATH := "res://assets/creatures/2d/blueprints/v2/manifest-v2.json"
const LEGACY_DIR := "res://assets/creatures/2d/blueprints/"
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	require(parsed is Dictionary, "M7 runtime manifest parses as a dictionary.")
	if parsed is Dictionary:
		var manifest: Dictionary = parsed
		require(str(manifest.get("schema", "")) == "printforge.runtime-blueprints.v2" and int(manifest.get("version", 0)) == 2, "M7 runtime manifest has exact schema/version.")
		var entries: Array = manifest.get("entries", [])
		var order: Array = manifest.get("catalog_order", [])
		var ids := {}
		require(entries.size() == 24 and order.size() == 24, "M7 runtime manifest contains exactly 24 entries/order IDs.")
		for index in range(entries.size()):
			var entry: Dictionary = entries[index]
			var id := str(entry.get("id", ""))
			ids[id] = true
			var path := str(entry.get("runtime_path", ""))
			var bytes := FileAccess.get_file_as_bytes(path)
			var hash: String = _sha256_bytes(bytes)
			var image := Image.new(); var image_ok := image.load(path) == OK
			require(id == str(order[index]) and path == "res://assets/creatures/2d/blueprints/v2/%s_blueprint_ink_v2.png" % id and bytes.size() == int(entry.get("runtime_bytes", -1)) and hash == str(entry.get("runtime_sha256", "")) and image_ok and image.get_width() == 1254 and image.get_height() == 1254, "M7 runtime entry binding is exact for %s." % id)
			if image_ok: require(_corner_alpha_max(image) <= 1, "M7 runtime alpha corners pass for %s." % id)
		require(ids.size() == 24, "M7 runtime manifest IDs are unique.")
	for path in [LEGACY_DIR + "cinderpaw_blueprint_card_v1.png", LEGACY_DIR + "unknown_blueprint_card_v1.png", LEGACY_DIR + "provenance-v1.json"]:
		require(not FileAccess.file_exists(path), "Retired M7 top-level legacy package input is absent: %s" % path)
	if failures.is_empty(): print("PASS: M7 blueprint family runtime assets are exact and legacy package inputs are retired")
	get_tree().quit(0 if failures.is_empty() else 1)

func _sha256_bytes(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK: return ""
	if context.update(bytes) != OK: return ""
	return context.finish().hex_encode().to_upper()

func _corner_alpha_max(image: Image) -> int:
	var maximum := 0
	for point in [Vector2i(0, 0), Vector2i(1253, 0), Vector2i(0, 1253), Vector2i(1253, 1253)]:
		maximum = max(maximum, int(round(image.get_pixelv(point).a * 255.0)))
	return maximum
