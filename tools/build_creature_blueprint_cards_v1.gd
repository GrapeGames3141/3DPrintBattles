extends SceneTree
## Deterministically promotes the approved intact-creature blueprint masters into
## compact runtime cards.  It deliberately preserves the entire authored card
## perimeter: this is a high-quality resize, never an illustration crop.

const SOURCE_DIR := "res://docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v1"
const OUTPUT_DIR := "res://assets/creatures/2d/blueprints"
const OUTPUT_SIZE := Vector2i(512, 512)
const OUTPUT_MANIFEST := OUTPUT_DIR + "/provenance-v1.json"

func _init() -> void:
	var source_manifest := _read_json(SOURCE_DIR + "/provenance-v3.json")
	var expected_hashes := _read_hashes(SOURCE_DIR + "/SHA256SUMS-v3.txt")
	if source_manifest.is_empty() or expected_hashes.is_empty():
		_fail("Missing approved v3 provenance or SHA manifest.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var outputs: Array = []
	var source_total := 0
	var output_total := 0
	for raw_master in source_manifest.get("masters", []):
		if not raw_master is Dictionary:
			_fail("Invalid master record.")
			return
		var master: Dictionary = raw_master
		var creature_id := str(master.get("id", ""))
		var file_name := str(master.get("file", ""))
		var source_path := SOURCE_DIR.path_join(file_name)
		if creature_id.is_empty() or file_name.is_empty() or not FileAccess.file_exists(source_path):
			_fail("Missing approved source for %s." % creature_id)
			return
		var source_bytes := FileAccess.get_file_as_bytes(source_path)
		var source_hash := _sha256(source_bytes)
		if source_hash != str(expected_hashes.get(file_name, "")):
			_fail("Source hash mismatch for %s." % file_name)
			return
		var image := Image.new()
		if image.load(source_path) != OK or image.get_size() != Vector2i(1254, 1254):
			_fail("Approved master dimensions/load failed for %s." % file_name)
			return
		image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var output_path := OUTPUT_DIR.path_join("%s_blueprint_card_v1.png" % creature_id)
		if image.save_png(output_path) != OK:
			_fail("Could not write %s." % output_path)
			return
		var output_bytes := FileAccess.get_file_as_bytes(output_path)
		var audit := Image.new()
		if audit.load(output_path) != OK or audit.get_size() != OUTPUT_SIZE:
			_fail("Output audit failed for %s." % creature_id)
			return
		var output_hash := _sha256(output_bytes)
		source_total += source_bytes.size()
		output_total += output_bytes.size()
		outputs.append({
			"id": creature_id,
			"source": source_path,
			"source_sha256": source_hash,
			"source_bytes": source_bytes.size(),
			"source_dimensions": [1254, 1254],
			"runtime": output_path,
			"runtime_sha256": output_hash,
			"runtime_bytes": output_bytes.size(),
			"runtime_dimensions": [OUTPUT_SIZE.x, OUTPUT_SIZE.y],
			"transform": "Image.INTERPOLATE_LANCZOS resize 1254x1254 -> 512x512; full card perimeter preserved; no crop"
		})
	var fallback_path := OUTPUT_DIR.path_join("unknown_blueprint_card_v1.png")
	var fallback := _generic_blueprint_fallback()
	if fallback.save_png(fallback_path) != OK:
		_fail("Could not write generic blueprint fallback.")
		return
	var fallback_bytes := FileAccess.get_file_as_bytes(fallback_path)
	var runtime_manifest := {
		"family": "PrintForge intact-creature blueprint cards v3 runtime derivatives",
		"generator": str(source_manifest.get("generator", "OpenAI ImageGen")),
		"source_provenance": SOURCE_DIR + "/provenance-v3.json",
		"approval_status": str(source_manifest.get("approval_status", "")),
		"approval_source": str(source_manifest.get("approval_source", "")),
		"runtime_contract": str(source_manifest.get("runtime_contract", "")),
		"processor": "res://tools/build_creature_blueprint_cards_v1.gd",
		"transform": "High-quality Lanczos resize only; preserve full authored 1254x1254 card edge/perimeter.",
		"source_total_bytes": source_total,
		"runtime_total_bytes": output_total,
		"runtime_materially_reduced": output_total < source_total,
		"fallback": {
			"runtime": fallback_path,
			"runtime_sha256": _sha256(fallback_bytes),
			"runtime_bytes": fallback_bytes.size(),
			"runtime_dimensions": [OUTPUT_SIZE.x, OUTPUT_SIZE.y],
			"identity": "generic intact blueprint card; no creature substitution"
		},
		"cards": outputs
	}
	var manifest_file := FileAccess.open(OUTPUT_MANIFEST, FileAccess.WRITE)
	if manifest_file == null:
		_fail("Could not write runtime provenance.")
		return
	manifest_file.store_string(JSON.stringify(runtime_manifest, "\t") + "\n")
	manifest_file.close()
	print("BLUEPRINT_RUNTIME_PASS cards=%d source_bytes=%d runtime_bytes=%d manifest=%s" % [outputs.size(), source_total, output_total, OUTPUT_MANIFEST])
	quit(0)

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

func _read_hashes(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var result := {}
	for line in file.get_as_text().split("\n", false):
		var parts := line.strip_edges().split("  ", false, 1)
		if parts.size() == 2: result[str(parts[1])] = str(parts[0]).to_upper()
	return result

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode().to_upper()

func _generic_blueprint_fallback() -> Image:
	var fallback := Image.create(OUTPUT_SIZE.x, OUTPUT_SIZE.y, false, Image.FORMAT_RGBA8)
	fallback.fill(Color("112c47"))
	for coordinate in range(24, OUTPUT_SIZE.x - 24, 32):
		for y in range(24, OUTPUT_SIZE.y - 24): fallback.set_pixel(coordinate, y, Color(0.25, 0.72, 0.78, 0.20))
		for x in range(24, OUTPUT_SIZE.x - 24): fallback.set_pixel(x, coordinate, Color(0.25, 0.72, 0.78, 0.20))
	for edge in 6:
		var color := Color("e5d4a8") if edge < 2 else Color("5e8fa2")
		for x in range(edge, OUTPUT_SIZE.x - edge):
			fallback.set_pixel(x, edge, color); fallback.set_pixel(x, OUTPUT_SIZE.y - 1 - edge, color)
		for y in range(edge, OUTPUT_SIZE.y - edge):
			fallback.set_pixel(edge, y, color); fallback.set_pixel(OUTPUT_SIZE.x - 1 - edge, y, color)
	return fallback

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
