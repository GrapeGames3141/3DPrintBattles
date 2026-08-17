class_name SoloBattleFactory
extends RefCounted
## Shared, non-persisting construction seam for Daily Training and Workshop Trials.
## It repairs only the temporary launch lineup when stale team references exist.

static func create(profile: Dictionary, rival_team: Array, player_cap: int, rival_cap: int, seed: int) -> Dictionary:
	return create_from_setup(profile, {"team":rival_team,"spool":rival_cap}, player_cap, seed)

## Rich contract/Trial launch seam.  The legacy create() wrapper deliberately
## remains so existing local-versus callers cannot accidentally drop decks.
static func create_from_setup(profile: Dictionary, opponent_setup: Dictionary, player_cap: int, seed: int) -> Dictionary:
	var team_result := player_loadout(profile)
	var player_team: Array = team_result.get("team", [])
	if player_team.is_empty():
		return {"ok":false, "battle":null, "error":str(team_result.get("error", "No catalog-valid owned creature is available.")), "temporary_repair":false}
	var legal_rival: Array = []
	var rival_team: Array = opponent_setup.get("team", [])
	for raw in rival_team:
		var creature_id := str(raw.get("creature_id", raw.get("id", ""))) if raw is Dictionary else str(raw)
		if not Catalog.creature(creature_id).is_empty(): legal_rival.append(raw)
	if legal_rival.is_empty():
		return {"ok":false, "battle":null, "error":"This rival setup has no catalog-valid creatures.", "temporary_repair":false}
	var deck_result := player_deck(profile)
	var capped_player: int = clampi(player_cap, 3, 10)
	var capped_rival: int = clampi(int(opponent_setup.get("rival_spool", opponent_setup.get("spool", 3))), 3, 10)
	var opponent_deck: Array = opponent_setup.get("deck", [])
	var battle := BattleState.create(player_team, legal_rival, capped_player, capped_rival, seed, deck_result.get("deck", []), opponent_deck)
	# Contract policy may visibly grant the rival a prepared spool. This is a
	# frozen setup value (shown in the Proving Door), never a hidden stat change.
	battle.players[1]["filament"] = clampi(int(opponent_setup.get("rival_starting_filament", 3)), 3, capped_rival)
	battle.players[1]["tactics"] = str(opponent_setup.get("tactics", ""))
	var error := battle.validation_error(true)
	# This is deliberately a second construction attempt, not a bypass: it only
	# strips optional equipment dictionaries when canonical creature IDs could not be
	# constructed by a legacy/runtime boundary. It never writes the profile.
	var equipment_free_retry := false
	var retry_built_ids: Array[String] = []
	if not error.is_empty():
		var canonical_ids := _team_ids(player_team)
		if not canonical_ids.is_empty():
			var retry := BattleState.create(canonical_ids, legal_rival, capped_player, capped_rival, seed, deck_result.get("deck", []), opponent_deck)
			retry_built_ids = _built_ids(retry, 0)
			var retry_error := retry.validation_error(true)
			if retry_error.is_empty():
				battle = retry
				error = ""
				equipment_free_retry = true
			else:
				error = _launch_error(canonical_ids, _built_ids(battle, 0), retry_built_ids, retry_error)
	if not error.is_empty():
		return {"ok":false, "battle":null, "error":error, "temporary_repair":bool(team_result.get("temporary_repair", false)), "canonical_ids":_team_ids(player_team), "built_ids":_built_ids(battle, 0), "retry_built_ids":retry_built_ids}
	var repair_message := str(team_result.get("repair_message", ""))
	if equipment_free_retry:
		repair_message = (repair_message + " " if not repair_message.is_empty() else "") + "This match used catalog creature IDs without optional equipment after a setup retry; your saved team was not changed."
	return {"ok":true, "battle":battle, "error":"", "temporary_repair":bool(team_result.get("temporary_repair", false)), "repair_message":repair_message, "deck_fallback":bool(deck_result.get("fallback", false)), "equipment_free_retry":equipment_free_retry, "canonical_ids":_team_ids(player_team), "built_ids":_built_ids(battle, 0)}

## Presentation and launch call this same pure result so the displayed names are
## exactly the entries that BattleState will receive.
static func preview(profile: Dictionary) -> Dictionary:
	return player_loadout(profile)

static func player_loadout(profile: Dictionary) -> Dictionary:
	# Team Builder is authoritative whenever it can produce a normalized lineup.
	# Do not reorder, fill, or otherwise reinterpret a valid saved team here.
	var authoritative: Array = _canonicalize_entries(ProfileRules.team_loadout(profile))
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
	var records: Array = []
	var order := 0
	for raw in profile.get("creatures", []):
		if not raw is Dictionary: continue
		var creature_id := _species_reference(raw)
		if Catalog.creature(creature_id).is_empty(): continue
		var instance_id := _instance_reference(raw)
		var loadout := EquipmentRules.suit_loadout(profile, instance_id)
		var stable_key := instance_id if not instance_id.is_empty() else "legacy-%06d" % order
		records.append({"key":stable_key, "instance_id":instance_id, "creature_id":creature_id, "suit_id":str(loadout.get("tier_id", "")), "core_id":str(loadout.get("core_id", "")), "order":order})
		order += 1
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("key", "")) < str(b.get("key", "")))
	return records

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
	return {"creature_id":str(candidate.get("creature_id", "")), "suit_id":str(candidate.get("suit_id", "")), "core_id":str(candidate.get("core_id", ""))}

static func _canonicalize_entries(entries: Array) -> Array:
	var result: Array = []
	for entry in entries:
		var creature_id := _species_reference(entry)
		if Catalog.creature(creature_id).is_empty(): continue
		var suit_id := ""
		var core_id := ""
		if entry is Dictionary:
			suit_id = str(entry.get("suit_id", ""))
			core_id = str(entry.get("core_id", ""))
		result.append({"creature_id":creature_id, "suit_id":suit_id, "core_id":core_id})
	return result

static func _team_ids(team: Array) -> Array[String]:
	var ids: Array[String] = []
	for entry in team:
		var creature_id := _species_reference(entry)
		if not creature_id.is_empty(): ids.append(creature_id)
	return ids

static func _built_ids(state: BattleState, player: int) -> Array[String]:
	var ids: Array[String] = []
	if state == null or player < 0 or player >= state.players.size(): return ids
	var data = state.players[player]
	if not data is Dictionary: return ids
	var team = data.get("team", [])
	if not team is Array: return ids
	for entry in team:
		if entry is Dictionary: ids.append(str(entry.get("id", "")))
	return ids

static func _launch_error(canonical_ids: Array[String], built_ids: Array[String], retry_built_ids: Array[String], underlying: String) -> String:
	return "Battle setup could not build your player team. Canonical IDs: %s. First build: %s. Catalog-ID retry: %s. %s Open Team Builder and save the current lineup." % [", ".join(canonical_ids), ", ".join(built_ids), ", ".join(retry_built_ids), underlying]

static func player_deck(profile: Dictionary) -> Dictionary:
	var deck := ProgressionRules.active_deck(profile)
	if deck.size() == 15:
		var valid := true
		for card_id in deck:
			if Catalog.support_card(str(card_id)).is_empty(): valid = false; break
		if valid: return {"deck":deck, "fallback":false}
	return {"deck":BattleState.STARTER_LOADOUT.duplicate(), "fallback":true}
