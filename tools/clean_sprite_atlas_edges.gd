extends SceneTree
## Run with Godot headless. Rewrites only the 24 shipped living atlas PNGs and
## records before/after SHA-256 plus exact removed component/pixel counts.

const BATTLE_CATALOG := preload("res://scripts/battle/battle_catalog.gd")
const REPAIR := preload("res://tools/sprite_atlas_edge_repair.gd")
const MANIFEST := "res://docs/SPRITE_ATLAS_EDGE_REPAIR.json"

func _init() -> void:
	var previous := previous_reports()
	var reports: Array = []
	for definition in BATTLE_CATALOG.DATA.CREATURES:
		var creature_id := str(definition.get("id", ""))
		var report := REPAIR.repair_sheet(str(definition.get("sprite_sheet", "")))
		var prior: Dictionary = previous.get(str(report.get("path", "")), {})
		# A rerun over already repaired PNGs must retain the original evidence
		# rather than replacing it with a misleading zero-removal report.
		if int(report.get("removed_edge_pixels", 0)) == 0 and int(prior.get("removed_edge_pixels", 0)) > 0 and str(report.get("before_sha256", "")) == str(prior.get("after_sha256", "")):
			report["before_sha256"] = prior.get("before_sha256", "")
			report["removed_edge_pixels"] = prior.get("removed_edge_pixels", 0)
			report["removed_edge_components"] = prior.get("removed_edge_components", 0)
			report["frames"] = prior.get("frames", [])
		report["creature_id"] = creature_id
		reports.append(report)
		if report.has("error"):
			push_error("%s: %s" % [creature_id, str(report.get("error", "repair failed"))])
	var output := {"rule":"preserve largest alpha component; remove every other edge-touching component; preserve interior components", "cell_size":[384, 512], "sheets":reports}
	var file := FileAccess.open(MANIFEST, FileAccess.WRITE)
	if file == null:
		push_error("could not write %s" % MANIFEST)
		quit(1)
		return
	file.store_string(JSON.stringify(output, "\t") + "\n")
	file.close()
	print("SPRITE_ATLAS_EDGE_REPAIR: %d sheets" % reports.size())
	quit(0 if reports.all(func(report): return not (report as Dictionary).has("error")) else 1)

func previous_reports() -> Dictionary:
	var file := FileAccess.open(MANIFEST, FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	var reports: Dictionary = {}
	if parsed is Dictionary:
		for report in (parsed as Dictionary).get("sheets", []):
			reports[str((report as Dictionary).get("path", ""))] = report
	return reports
