class_name SupportCardRules
extends RefCounted
## Single pure definition seam for card legality, effects, text, AI and rendering.
## Targets are deliberately explicit so a multi-effect card cannot silently use
## the primary card target for every operation.

const EFFECTS: Array[String] = ["filament", "heal", "shield", "attack_buff", "cooldown", "draw", "switch_discount", "debuff", "cleanse"]

static func normalized_effects(definition: Dictionary) -> Array:
	var result: Array = []
	var authored = definition.get("effects", [])
	if authored is Array:
		for raw in authored:
			if raw is Dictionary and str(raw.get("effect", "")) in EFFECTS:
				result.append({"effect":str(raw.get("effect", "")), "target":str(raw.get("target", definition.get("target", "self"))), "amount":maxi(0, int(raw.get("amount", 0)))})
	if result.is_empty() and str(definition.get("effect", "")) in EFFECTS:
		result.append({"effect":str(definition.effect), "target":str(definition.get("target", _legacy_target(str(definition.effect)))), "amount":maxi(0, int(definition.get("amount", 0)))})
	return result

static func _legacy_target(effect: String) -> String:
	if effect in ["filament", "draw"]: return "forge"
	if effect == "switch_discount": return "team"
	if effect == "debuff": return "foe"
	return "self"

static func target_text(definition: Dictionary) -> String:
	var labels: Array[String] = []
	for effect in normalized_effects(definition):
		var target := target_label(str(effect.target))
		if not target in labels: labels.append(target)
	return ", ".join(labels)

static func target_label(target: String) -> String:
	match target:
		"forge": return "Your Forge"
		"team": return "Your team"
		"foe": return "Foe active print"
		_: return "Your active print"

static func effect_phrase(effect: Dictionary) -> String:
	var amount: int = int(effect.get("amount", 0))
	match str(effect.get("effect", "")):
		"filament": return "Gain %d Filament" % amount
		"heal": return "Restore %d HP" % amount
		"shield": return "Gain %d shield" % amount
		"attack_buff": return "Gain +%d Attack" % amount
		"cooldown": return "Reduce signature cooldown by %d" % amount
		"draw": return "Draw %d support card%s" % [amount, "s" if amount != 1 else ""]
		"switch_discount": return "Next switch costs %d less" % amount
		"debuff": return "Foe loses %d Attack and signature locks 1 turn" % amount
		"cleanse": return "Cleanse debuffs"
	return "Catalog effect unavailable"

static func rules_text(definition: Dictionary) -> String:
	var phrases: Array[String] = []
	for effect in normalized_effects(definition): phrases.append(effect_phrase(effect))
	return "; ".join(phrases)

static func legality_reason(state: BattleState, player: int, definition: Dictionary) -> String:
	if definition.is_empty(): return "Unknown support card."
	if player < 0 or player >= state.players.size(): return "Invalid player."
	if not str(definition.get("id", "")) in state.players[player].get("hand", []): return "Card is not in hand."
	var cost := int(definition.get("cost", 0))
	if int(state.players[player].get("filament", 0)) < cost: return "Needs %d more Filament." % (cost - int(state.players[player].get("filament", 0)))
	return ""

static func apply_effect(state: BattleState, player: int, effect: Dictionary) -> void:
	var target_name := str(effect.get("target", "self"))
	var target_player := 1 - player if target_name == "foe" else player
	var target := state.active_unit(target_player)
	var amount: int = maxi(0, int(effect.get("amount", 0)))
	match str(effect.get("effect", "")):
		"filament": state.players[player].filament = mini(int(state.players[player].spool_cap), int(state.players[player].filament) + amount)
		"heal": target.hp = mini(int(target.max_hp), int(target.hp) + amount)
		"shield": target.shield = int(target.shield) + amount
		"attack_buff": target.attack_buff = int(target.attack_buff) + amount
		"cooldown": target.cooldown_remaining = maxi(0, int(target.cooldown_remaining) - amount)
		"draw":
			for unused in amount:
				if state.players[player].hand.size() >= 4 or state.players[player].deck.is_empty(): break
				state.players[player].hand.append(state.players[player].deck.pop_front())
		"switch_discount":
			state.players[player].switch_discount = maxi(int(state.players[player].switch_discount), amount)
			state.players[player].switch_discount_turns = maxi(int(state.players[player].get("switch_discount_turns", 0)), 1)
		"debuff":
			target.attack_debuff = int(target.attack_debuff) + amount
			target.ability_lock_turns = maxi(int(target.ability_lock_turns), 1)
		"cleanse":
			target.attack_debuff = 0
			target.ability_lock_turns = 0

static func ai_utility(state: BattleState, player: int, definition: Dictionary) -> int:
	var score := 0
	var unit := state.active_unit(player)
	var foe := state.active_unit(1-player)
	for effect in normalized_effects(definition):
		var amount := int(effect.amount)
		match str(effect.effect):
			"filament": score += mini(amount, int(state.players[player].spool_cap) - int(state.players[player].filament)) * 3
			"heal": score += mini(amount, int(unit.max_hp) - int(unit.hp)) * 2
			"shield": score += amount * 2
			"attack_buff": score += amount * 3
			"cooldown": score += mini(amount, int(unit.cooldown_remaining)) * 3
			"draw": score += mini(amount, 4 - state.players[player].hand.size()) * 3
			"switch_discount": score += amount if state.players[player].team.size() > 1 else 0
			"debuff": score += amount * 3 if int(foe.hp) > 0 else 0
			"cleanse": score += 5 if int(unit.attack_debuff) > 0 or int(unit.ability_lock_turns) > 0 else 0
	return score - int(definition.get("cost", 0))
