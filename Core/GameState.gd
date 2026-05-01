extends Node

var active_slot: int = -1

var coins: int = 0
var owned_blueprints: Array[String] = []
var active_team: Array[String] = []
var printer_upgrades := {
	"filament_cap": 3
}
var progress := {
	"starter_chosen": false,
	"battles_won": 0
}
var settings := {
	"music": true,
	"sfx": true
}

func load_from_save(save: Dictionary) -> void:
	coins = int(save.get("coins", 0))
	owned_blueprints = Array(save.get("owned_blueprints", []), TYPE_STRING, "", null)
	active_team = Array(save.get("active_team", []), TYPE_STRING, "", null)
	printer_upgrades = save.get("printer_upgrades", {"filament_cap": 3})
	progress = save.get("progress", {"starter_chosen": false, "battles_won": 0})
	if not progress.has("battles_won"):
		progress["battles_won"] = 0
	settings = save.get("settings", {"music": true, "sfx": true})

func to_save() -> Dictionary:
	return {
		"coins": coins,
		"owned_blueprints": owned_blueprints,
		"active_team": active_team,
		"printer_upgrades": printer_upgrades,
		"progress": progress,
		"settings": settings
	}

