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
		units_array.append(item)

func get_unit(id: String) -> Dictionary:
	return units_by_id.get(id, {})


func active_roster_for_stage() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var cap: int = mini(GameRules.MVP_ACTIVE_UNIT_COUNT, units_array.size())
	for i in cap:
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

