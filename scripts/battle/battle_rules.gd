class_name BattleRules
extends RefCounted
## Deterministic integer-only rules. Client UI submits intents; server can use same contract.

const IMPLEMENTED_CARD_EFFECTS: Array[String] = ["filament", "heal", "shield", "attack_buff", "cooldown", "draw", "switch_discount", "debuff", "cleanse"]

static func apply_intent(state: BattleState, player: int, intent: Dictionary) -> Dictionary:
	if state.finished or player != state.active_player: return {"ok":false,"error":"Not your turn."}
	var type := str(intent.get("type", ""))
	match type:
		"attack": return _attack(state, player, false)
		"ability": return _attack(state, player, true)
		"defend": return _defend(state, player)
		"card": return _card(state, player, str(intent.get("card_id", "")))
		"switch": return _switch(state, player, int(intent.get("index", -1)), false)
		"end_turn": _end_turn(state); return {"ok":true}
		"concede": state.finished = true; state.winner = 1-player; state.log.append("Player %d conceded." % (player + 1)); return {"ok":true}
		_: return {"ok":false,"error":"Unknown intent."}

static func _attack(state: BattleState, player: int, ability: bool) -> Dictionary:
	var attacker := state.active_unit(player)
	var defender := state.active_unit(1-player)
	if state.turn == 1 and player == state.opening_player:
		return {"ok":false,"error":"The coin-flip winner cannot attack on the opening turn."}
	if ability and attacker.cooling:
		return {"ok":false,"error":"This print is cooling after a forced summon."}
	if ability:
		if int(attacker.ability_lock_turns) > 0: return {"ok":false,"error":"Filament lock prevents signature abilities."}
		if attacker.cooldown_remaining > 0: return {"ok":false,"error":"Ability is cooling down."}
		var ability_cost: int = int(attacker.ability_cost)
		if int(state.players[player].filament) < ability_cost: return {"ok":false,"error":"Need more filament."}
		state.players[player].filament = int(state.players[player].filament) - ability_cost
		attacker.cooldown_remaining = int(attacker.cooldown)
	var base: int = int(attacker.attack) + int(attacker.attack_buff) - int(attacker.attack_debuff) + (5 if ability else 0)
	var mult: int = Catalog.element_multiplier(str(attacker.element), str(defender.element))
	var scaled_damage: int = (maxi(1, base) * mult) / 100
	var incoming_shield: int = int(defender.shield)
	var post_armor_damage: int = maxi(1, scaled_damage - int(defender.armor))
	var damage: int = maxi(0, post_armor_damage - incoming_shield)
	defender.shield = maxi(0, incoming_shield - post_armor_damage)
	defender.hp = maxi(0, int(defender.hp) - damage)
	state.log.append("%s %s for %d damage." % [attacker.name, attacker.ability if ability else "attacks", damage])
	if defender.hp <= 0: _defeat(state, 1-player)
	if not state.finished: _end_turn(state)
	return {"ok":true,"damage":damage}

static func _defend(state: BattleState, player: int) -> Dictionary:
	var unit := state.active_unit(player)
	unit.shield = int(unit.shield) + 4
	state.log.append("%s reinforces its layers (+4 shield)." % ("You" if player == 0 else "Rival"))
	_end_turn(state)
	return {"ok":true,"shield":4}

static func _card(state: BattleState, player: int, card_id: String) -> Dictionary:
	var index: int = state.players[player].hand.find(card_id)
	if index < 0: return {"ok":false,"error":"Card is not in hand."}
	var card: Dictionary = {}
	for item in Catalog.SUPPORT_CARDS:
		if item.id == card_id: card = item; break
	var card_cost: int = int(card.cost)
	if card.is_empty() or int(state.players[player].filament) < card_cost: return {"ok":false,"error":"Cannot play this card."}
	state.players[player].filament = int(state.players[player].filament) - card_cost
	state.players[player].hand.remove_at(index)
	var unit := state.active_unit(player)
	match str(card.effect):
		"filament": state.players[player].filament = mini(int(state.players[player].spool_cap), int(state.players[player].filament) + int(card.amount))
		"heal": unit.hp = mini(int(unit.max_hp), int(unit.hp) + int(card.amount))
		"shield": unit.shield = int(unit.shield) + int(card.amount)
		"attack_buff": unit.attack_buff = int(unit.attack_buff) + int(card.amount)
		"cooldown": unit.cooldown_remaining = maxi(0, int(unit.cooldown_remaining) - int(card.amount))
		"draw":
			for n in int(card.amount):
				if not state.players[player].deck.is_empty() and state.players[player].hand.size() < 4: state.players[player].hand.append(state.players[player].deck.pop_front())
		"switch_discount": state.players[player].switch_discount = maxi(int(state.players[player].switch_discount), int(card.amount))
		"debuff":
			var target := state.active_unit(1-player)
			target.attack_debuff = int(target.attack_debuff) + int(card.amount)
			target.ability_lock_turns = maxi(int(target.ability_lock_turns), 1)
		"cleanse":
			unit.attack_debuff = 0
			unit.ability_lock_turns = 0
	state.log.append("%s played %s." % ["You" if player == 0 else "Rival", card.name])
	return {"ok":true}

static func _switch(state: BattleState, player: int, index: int, forced: bool) -> Dictionary:
	if index < 0 or index >= state.players[player].team.size() or state.players[player].team[index].hp <= 0: return {"ok":false,"error":"Choose a ready print."}
	if index == state.players[player].active: return {"ok":false,"error":"That print is already active."}
	var discount: int = int(state.players[player].get("switch_discount", 0))
	var cost: int = 0 if forced else maxi(0, int(state.players[player].team[index].cost) - discount)
	if int(state.players[player].filament) < cost: return {"ok":false,"error":"Not enough filament to switch."}
	state.players[player].filament = int(state.players[player].filament) - cost
	if not forced: state.players[player].switch_discount = 0
	state.players[player].active = index
	state.active_unit(player).cooling = forced
	state.log.append("%s printed %s." % ["You" if player == 0 else "Rival", state.active_unit(player).name])
	if not forced: _end_turn(state)
	return {"ok":true}

static func _defeat(state: BattleState, player: int) -> void:
	state.log.append("%s broke apart!" % state.active_unit(player).name)
	for i in state.players[player].team.size():
		if state.players[player].team[i].hp > 0:
			_switch(state, player, i, true)
			return
	state.finished = true
	state.winner = 1-player
	state.log.append("The Core Printer breaks. %s wins!" % ("You" if state.winner == 0 else "Rival"))

static func _end_turn(state: BattleState) -> void:
	var ending: int = state.active_player
	var unit := state.active_unit(ending)
	unit.cooling = false
	unit.cooldown_remaining = maxi(0, int(unit.cooldown_remaining) - 1)
	unit.ability_lock_turns = maxi(0, int(unit.ability_lock_turns) - 1)
	state.players[ending].switch_discount = 0
	state.active_player = 1 - ending
	state.turn += 1
	var next = state.players[state.active_player]
	var turn_bonus: int = state.turn / 2
	var turn_allowance: int = mini(int(next.spool_cap), 2 + mini(turn_bonus, int(next.spool_cap)))
	next.filament = turn_allowance
	if next.hand.size() < 4 and not next.deck.is_empty(): next.hand.append(next.deck.pop_front())
	state.log.append("Turn %d: %s's forge hums." % [state.turn, "Your" if state.active_player == 0 else "Rival's"])
