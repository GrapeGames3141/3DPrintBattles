extends Node

var units_by_id: Dictionary = {}
var units_array: Array[Dictionary] = []


func load_units(path: String) -> void:
	units_by_id.clear()
	units_array.clear()
	if not FileAccess.file_exists(path):
		push_error("units.json missing at %s" % path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open %s" % path)
		return
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	if err != OK:
		push_error("Failed parsing units.json: %s" % json.get_error_message())
		return
	var raw: Variant = json.data
	if typeof(raw) != TYPE_ARRAY:
		push_error("units.json must be an array of unit objects")
		return
	var rows: Array = raw as Array
	for item_raw in rows:
		if typeof(item_raw) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_raw as Dictionary
		var id: String = str(item.get("id", ""))
		if id == "":
			continue
		units_by_id[id] = item
	_finalize_sorted_roster(GameRules.ACTIVE_ROSTER_CAP)
	refresh_asset_paths_from_disk()


func refresh_asset_paths_from_disk() -> void:
	var base: String = "res://Assets/Prints"
	var da: DirAccess = DirAccess.open(base)
	if da == null:
		return
	if da.list_dir_begin() != OK:
		return
	var fn: String = da.get_next()
	while fn != "":
		if da.current_is_dir() and fn != "." and fn != "..":
			var gltf_path: String = base + "/" + fn + "/model.gltf"
			if FileAccess.file_exists(gltf_path) and units_by_id.has(fn):
				var u: Dictionary = units_by_id[fn]
				u["model_path"] = gltf_path
		fn = da.get_next()
	da.list_dir_end()


func _synthetic_unit_dict(seq: int) -> Dictionary:
	var elems: Array[String] = ["Heat", "PLA", "Resin", "TPU", "Carbon"]
	var e: String = elems[(seq - 1) % elems.size()]
	var tier_level: int = 1 + ((seq - 1) % 8)
	var cost: int = 1 + ((seq - 1) % 8)
	var hp: int = 2 + ((seq * 3) % 12)
	var atk: int = 1 + ((seq * 2) % 9)
	return {
		"id": "%03d" % seq,
		"name": "Synth Unit %03d" % seq,
		"tier_name": "Synth",
		"tier_level": tier_level,
		"cost": cost,
		"element": e,
		"hp": hp,
		"atk": atk,
		"ability": "Synth roster pad (Phase 5)"
	}


func _finalize_sorted_roster(cap: int) -> void:
	for n in range(1, cap + 1):
		var sid: String = "%03d" % n
		if not units_by_id.has(sid):
			units_by_id[sid] = _synthetic_unit_dict(n)
	units_array.clear()
	for n in range(1, cap + 1):
		units_array.append(units_by_id["%03d" % n])


func get_unit(id: String) -> Dictionary:
	return units_by_id.get(id, {})


func active_roster_for_stage() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var n_cap: int = mini(GameRules.ACTIVE_ROSTER_CAP, units_array.size())
	for i in n_cap:
		result.append(units_array[i])
	return result


func random_units(count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	return random_units_from(active_roster_for_stage(), count, rng)


func random_units_from(pool: Array[Dictionary], count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if pool.is_empty() or count <= 0:
		return result
	var last: int = pool.size() - 1
	for i in count:
		result.append(pool[rng.randi_range(0, last)])
	return result
