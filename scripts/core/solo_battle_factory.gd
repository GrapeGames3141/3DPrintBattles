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
	var owned_by_instance := {}
	var owned_order: Array = []
	for raw in profile.get("creatures", []):
		if not raw is Dictionary: continue
		var instance_id := str(raw.get("instance_id", ""))
		var creature_id := str(raw.get("creature_id", raw.get("id", "")))
		if instance_id.is_empty() or Catalog.creature(creature_id).is_empty(): continue
		owned_by_instance[instance_id] = {"creature_id":creature_id, "armor_id":str(raw.get("armor_id", ""))}
		owned_order.append(instance_id)
	owned_order.sort()
	if owned_order.is_empty():
		return {"team":[], "error":"No catalog-valid owned print is available. Print or recover a creature before starting a solo battle.", "temporary_repair":false}
	var intended: Array = []
	var seen := {}
	for raw_ref in profile.get("team", []):
		var instance_id := str(raw_ref.get("instance_id", raw_ref.get("id", ""))) if raw_ref is Dictionary else str(raw_ref)
		if owned_by_instance.has(instance_id) and not seen.has(instance_id) and intended.size() < 3:
			seen[instance_id] = true
			intended.append(owned_by_instance[instance_id])
	if not intended.is_empty():
		return {"team":intended, "temporary_repair":false, "repair_message":""}
	var repaired: Array = []
	for instance_id in owned_order:
		repaired.append(owned_by_instance[instance_id])
		if repaired.size() == 3: break
	return {"team":repaired, "temporary_repair":true, "repair_message":"Your saved team references were stale. This solo match temporarily uses your first ready owned print(s); update Team Builder after the match."}

static func player_deck(profile: Dictionary) -> Dictionary:
	var deck := ProgressionRules.active_deck(profile)
	if deck.size() == 15:
		var valid := true
		for card_id in deck:
			if Catalog.support_card(str(card_id)).is_empty(): valid = false; break
		if valid: return {"deck":deck, "fallback":false}
	return {"deck":BattleState.STARTER_LOADOUT.duplicate(), "fallback":true}
