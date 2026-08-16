class_name SoloBattleFactory
extends RefCounted
## Shared, non-persisting construction seam for Daily Training and Workshop Trials.
## It repairs only the temporary launch lineup when stale team references exist.

static func create(profile: Dictionary, rival_team: Array, player_cap: int, rival_cap: int, seed: int) -> Dictionary:
	var team_result := player_loadout(profile)
	var player_team: Array = team_result.get("team", [])
	if player_team.is_empty():
		return {"ok":false, "battle":null, "error":str(team_result.get("error", "No catalog-valid owned creature is available.")), "temporary_repair":false}
	var legal_rival: Array = []
	for raw in rival_team:
		var creature_id := str(raw.get("creature_id", raw.get("id", ""))) if raw is Dictionary else str(raw)
		if not Catalog.creature(creature_id).is_empty(): legal_rival.append(raw)
	if legal_rival.is_empty():
		return {"ok":false, "battle":null, "error":"This rival setup has no catalog-valid creatures.", "temporary_repair":false}
	var deck_result := player_deck(profile)
	var battle := BattleState.create(player_team, legal_rival, clampi(player_cap, 3, 10), clampi(rival_cap, 3, 10), seed, deck_result.get("deck", []))
	var error := battle.validation_error(true)
	if not error.is_empty():
		return {"ok":false, "battle":null, "error":error, "temporary_repair":bool(team_result.get("temporary_repair", false))}
	return {"ok":true, "battle":battle, "error":"", "temporary_repair":bool(team_result.get("temporary_repair", false)), "repair_message":str(team_result.get("repair_message", "")), "deck_fallback":bool(deck_result.get("fallback", false))}

static func player_loadout(profile: Dictionary) -> Dictionary:
	# Team Builder is authoritative whenever it can produce a normalized lineup.
	# Do not reorder, fill, or otherwise reinterpret a valid saved team here.
	var authoritative: Array = ProfileRules.team_loadout(profile)
	if not authoritative.is_empty():
		return {"team":authoritative, "temporary_repair":false, "repair_message":""}
	# Some pre-integrity local saves contain a perfectly plausible raw species but
	# no printable instance ID.  A solo match may use that owned record for this
	# launch only; it never writes a repaired team, ID, inventory row, or armor.
	var owned_records := _owned_records(profile)
	if owned_records.is_empty():
		return {"team":[], "error":"No catalog-valid owned print is available. Print or recover a creature before starting a solo battle.", "temporary_repair":false}
	var repaired: Array = []
	var used := {}
	for raw_ref in profile.get("team", []):
		var wanted_instance := _instance_reference(raw_ref)
		var wanted_species := _species_reference(raw_ref)
		for candidate in owned_records:
			var key: String = str(candidate.get("key", ""))
			if used.has(key): continue
			if (not wanted_instance.is_empty() and wanted_instance == str(candidate.get("instance_id", ""))) or (not wanted_species.is_empty() and wanted_species == str(candidate.get("creature_id", ""))):
				used[key] = true
				repaired.append(_battle_entry(candidate))
				break
		if repaired.size() == 3: break
	for candidate in owned_records:
		if repaired.size() == 3: break
		var key: String = str(candidate.get("key", ""))
		if used.has(key): continue
		used[key] = true
		repaired.append(_battle_entry(candidate))
	return {"team":repaired, "temporary_repair":true, "repair_message":"Your saved team references were stale. This solo match temporarily uses your matching owned print(s); update Team Builder after the match."}

static func _owned_records(profile: Dictionary) -> Array:
	var owned_armor := _owned_armor_ids(profile)
	var records: Array = []
	var order := 0
	for raw in profile.get("creatures", []):
		if not raw is Dictionary: continue
		var creature_id := _species_reference(raw)
		if Catalog.creature(creature_id).is_empty(): continue
		var instance_id := _instance_reference(raw)
		var armor_id := str(raw.get("armor_id", ""))
		if ProgressionRules.armor_def(armor_id).is_empty() or not owned_armor.has(armor_id): armor_id = ""
		var stable_key := instance_id if not instance_id.is_empty() else "legacy-%06d" % order
		records.append({"key":stable_key, "instance_id":instance_id, "creature_id":creature_id, "armor_id":armor_id, "order":order})
		order += 1
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("key", "")) < str(b.get("key", "")))
	return records

static func _owned_armor_ids(profile: Dictionary) -> Dictionary:
	var result := {}
	for raw in profile.get("armor", []):
		if not raw is Dictionary: continue
		var armor_id := str(raw.get("armor_id", ""))
		if not ProgressionRules.armor_def(armor_id).is_empty(): result[armor_id] = true
	return result

static func _species_reference(raw) -> String:
	if raw is Dictionary:
		for key in ["creature_id", "species_id", "creature", "species", "id"]:
			var candidate := str(raw.get(key, ""))
			if not Catalog.creature(candidate).is_empty(): return candidate
		return ""
	var candidate := str(raw)
	return candidate if not Catalog.creature(candidate).is_empty() else ""

static func _instance_reference(raw) -> String:
	if not raw is Dictionary: return str(raw)
	for key in ["instance_id", "instance", "uid", "instance_key"]:
		var candidate := str(raw.get(key, ""))
		if not candidate.is_empty(): return candidate
	return ""

static func _battle_entry(candidate: Dictionary) -> Dictionary:
	return {"creature_id":str(candidate.get("creature_id", "")), "armor_id":str(candidate.get("armor_id", ""))}

static func player_deck(profile: Dictionary) -> Dictionary:
	var deck := ProgressionRules.active_deck(profile)
	if deck.size() == 15:
		var valid := true
		for card_id in deck:
			if Catalog.support_card(str(card_id)).is_empty(): valid = false; break
		if valid: return {"deck":deck, "fallback":false}
	return {"deck":BattleState.STARTER_LOADOUT.duplicate(), "fallback":true}
