extends Node

## True after Continue / New Game until returning to title (session has a loaded profile).
var session_active: bool = false

var coins: int = 0
var owned_blueprints: Array[String] = []
var active_team: Array[String] = []
var printer_upgrades: Dictionary = {"filament_cap": 3}
var progress: Dictionary = {
	"starter_chosen": false,
	"battles_won": 0,
	"quest_math_bonus_claimed": false,
	"quests_claimed": {"add": false, "sub": false, "geo": false}
}
var settings: Dictionary = {"music": true, "sfx": true}
## Unix time of last shop reroll; offers stored in [member shop_offer_ids].
var shop_last_refresh_unix: int = 0
var shop_offer_ids: Array[String] = []

func load_from_save(save: Dictionary) -> void:
	coins = int(save.get("coins", 0))
	owned_blueprints = Array(save.get("owned_blueprints", []), TYPE_STRING, "", null)
	active_team = Array(save.get("active_team", []), TYPE_STRING, "", null)
	printer_upgrades = save.get("printer_upgrades", {"filament_cap": 3}) as Dictionary
	progress = save.get("progress", {}) as Dictionary
	if not progress.has("battles_won"):
		progress["battles_won"] = 0
	if not progress.has("quest_math_bonus_claimed"):
		progress["quest_math_bonus_claimed"] = false
	if not progress.has("quests_claimed"):
		var qc: Dictionary = {"add": false, "sub": false, "geo": false}
		if bool(progress.get("quest_math_bonus_claimed", false)):
			qc["add"] = true
		progress["quests_claimed"] = qc
	else:
		var qcx: Dictionary = progress["quests_claimed"] as Dictionary
		for k in ["add", "sub", "geo"]:
			if not qcx.has(k):
				qcx[k] = false
	settings = save.get("settings", {"music": true, "sfx": true}) as Dictionary
	shop_last_refresh_unix = int(save.get("shop_last_refresh_unix", 0))
	shop_offer_ids = Array(save.get("shop_offer_ids", []), TYPE_STRING, "", null)

func to_save() -> Dictionary:
	return {
		"coins": coins,
		"owned_blueprints": owned_blueprints,
		"active_team": active_team,
		"printer_upgrades": printer_upgrades,
		"progress": progress,
		"settings": settings,
		"shop_last_refresh_unix": shop_last_refresh_unix,
		"shop_offer_ids": shop_offer_ids
	}
