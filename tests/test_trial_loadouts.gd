extends Node

var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _ready() -> void:
	var count := 0
	for tier in Catalog.WORKSHOP_TRIAL_TIERS:
		for raw in tier.get("encounters", []):
			count += 1
			var encounter := CampaignRules.authored_encounter(Catalog.workshop_trial_encounter(str(raw.get("id", ""))))
			var number := int(encounter.get("tier", 0)); var boss := bool(encounter.get("boss", false))
			require((encounter.get("deck", []) as Array).size() == 15, "every Trial uses a legal authored opponent deck")
			for entry in encounter.get("team", []):
				var suit := str(entry.get("suit_id", "")); var core := str(entry.get("core_id", ""))
				if number == 1: require(suit.is_empty() and core.is_empty(), "Tier 1 has no equipment")
				elif number == 2: require(suit == "standard" and core.is_empty(), "Tier 2 has Standard suits only")
				elif number == 3: require(suit == "reinforced" and (boss or core.is_empty()), "Tier 3 boss-only Cores")
				elif number == 4: require(suit == "masterwork" and not core.is_empty(), "Tier 4 has Masterwork suits and Cores")
				elif number == 5: require(suit == "legendary" and not core.is_empty(), "Tier 5 has Legendary suits and Cores")
	require(count == 20, "all 20 Trial IDs and order remain authored")
	if failures.is_empty(): print("PASS: authored Trial equipment/deck matrix preserves 20 encounters")
	call_deferred("finish")
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
