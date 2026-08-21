class_name UnifiedBattleRules
extends RefCounted
## Pure deterministic v3.1 battle authority. This file has no UI dependencies.

const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RECOVERY := {"common":2500, "uncommon":3000, "rare":3500, "epic":4000, "legendary":5000, "mythic":5000, "prismatic":5000, "primordial":5000}
const ELEMENTS := {"Fire":{"Nature":150,"Ice":150,"Water":60,"Stone":60},"Water":{"Fire":150,"Lightning":150,"Nature":60,"Ice":60},"Lightning":{"Water":150,"Wind":150,"Stone":60,"Nature":60},"Nature":{"Water":150,"Stone":150,"Fire":60,"Lightning":60},"Ice":{"Nature":150,"Wind":150,"Fire":60,"Lightning":60},"Stone":{"Fire":150,"Lightning":150,"Water":60,"Nature":60},"Wind":{"Lightning":150,"Nature":150,"Stone":60,"Ice":60}}

static func apply_intent(state: UnifiedBattleState, seat: int, intent: Dictionary) -> Dictionary:
	if state.finished: return _no("The printer has already fallen.")
	if seat != state.active_seat: return _no("It is the other printer's turn.")
	var result: Dictionary = {}
	match str(intent.get("type", "")):
		"concede":
			state.finished = true
			state.winner = 1 - seat
			result = {"ok":true}
		"play_card": result = _play(state, seat, str(intent.get("card_id", "")), int(intent.get("target", -2)))
		"upgrade_reprint": result = _upgrade_reprint(state, seat, int(intent.get("graveyard_index", -1)))
		"cancel_queue": result = _cancel(state, seat, int(intent.get("queue_index", -1)))
		"place_completed": result = _place(state, seat, int(intent.get("slot", -1)), str(intent.get("mode", "attack")))
		"attach_completed": result = _attach(state, seat, int(intent.get("slot", -1)))
		"switch_mode": result = _switch_mode(state, seat, int(intent.get("slot", -1)), str(intent.get("mode", "")))
		"activate_ability": result = _activate(state, seat, int(intent.get("slot", -1)), int(intent.get("target", -2)))
		"attack": result = _attack(state, seat, int(intent.get("slot", -1)), int(intent.get("target", -2)))
		"discard_overflow": result = _discard(state, seat, intent.get("card_ids", []))
		"advance_phase": result = _advance(state, seat)
		_: return _no("Unknown v3 battle intent.")
	if bool(result.get("ok", false)): state.revision += 1
	return result

static func _play(state: UnifiedBattleState, seat: int, card_id: String, target: int) -> Dictionary:
	if state.phase != "main": return _no("Cards can only be played during Main.")
	var p := state.player(seat)
	var card := RULES.card(card_id)
	if card.is_empty() or not p.hand.has(card_id): return _no("Card is not in hand.")
	var kind := str(card.get("type", ""))
	var cost := int(card.get("filament_cost", 0))
	if kind != "trap" and kind != "upgrade" and int(p.filament) < cost: return _no("Need more filament.")
	if kind in ["creature", "equipment"] and p.queue.size() >= _queue_capacity(p): return _no("Print queue is full.")
	if kind == "equipment" and (target < 0 or target > 2): return _no("Choose an equipment target.")
	if kind == "upgrade":
		if int(p.upgrade_plays) >= 1 or p.installed_upgrades.size() >= 5: return _no("Only one upgrade per turn and five per match.")
		var unique_key := str(card.get("unique_key", ""))
		if not unique_key.is_empty() and p.installed_upgrades.has(card_id): return _no("That hardware upgrade is already installed.")
	p.hand.erase(card_id)
	p.played.append(card_id)
	if kind != "trap" and kind != "upgrade": p.filament -= cost
	match kind:
		"creature", "equipment": p.queue.append({"card_id":card_id,"remaining":int(card.get("print_turns", 1)),"target":target,"cost":cost})
		"filament":
			_gain(p, int(card.get("filament_gain", 0)))
			p.graveyard.append(card_id)
			_trigger_trap(state, 1 - seat, "filament", {"amount":int(card.get("filament_gain", 0)),"owner":seat})
			_filament_effect(state, seat, card)
		"spell": p.graveyard.append(card_id); _spell(state, seat, card, target)
		"trap":
			if not p.trap.is_empty(): p.graveyard.append(str(p.trap.get("card_id", "")))
			p.trap = {"card_id":card_id}
		"upgrade":
			p.installed_upgrades.append(card_id)
			p.upgrade_plays += 1
			if card_id == "reinforced_chassis": p.printer.max_hp += 500; p.printer.hp += 500
			if card_id == "emergency_reprint_upgrade": p.emergency_reprints += 1
	return {"ok":true,"card_id":card_id}

static func _filament_effect(state: UnifiedBattleState, seat: int, card: Dictionary) -> void:
	if str(card.get("id", "")) == "heated_spool" and not state.player(seat).queue.is_empty(): state.player(seat).queue[0].remaining = maxi(0, int(state.player(seat).queue[0].remaining) - 1)
	if str(card.get("id", "")) == "recycled_scrap":
		var scraps: Array = state.player(seat).scrap
		_gain(state.player(seat), scraps.size() * 60)
		scraps.clear()

static func _spell(state: UnifiedBattleState, seat: int, card: Dictionary, target: int) -> void:
	var p := state.player(seat)
	var foe := state.player(1 - seat)
	match str(card.get("id", "")):
		"layer_melt":
			if target >= 0 and target < 3 and foe.slots[target] != null: _damage_unit(state, 1 - seat, target, 150, false)
		"print_jam": foe["queue_paused"] = 1
		"spool_drain":
			var stolen := mini(100, int(foe.filament)); foe.filament -= stolen; _gain(p, stolen)
		"forge_surge":
			if target >= 0 and target < 3 and p.slots[target] != null: p.slots[target]["surge_bps"] = 15000
		"emergency_reprint_spell": _reprint(p, target)
		"blueprint_thief":
			if not foe.queue.is_empty() and p.queue.size() < _queue_capacity(p):
				var copy_id := str(foe.queue[0].get("card_id", "")); var copy := RULES.card(copy_id)
				if not copy.is_empty(): p.queue.append({"card_id":copy_id,"remaining":int(copy.get("print_turns", 1)),"target":-1,"cost":int(copy.get("filament_cost", 0)) / 2})

static func _reprint(p: Dictionary, graveyard_index: int) -> bool:
	if graveyard_index < 0 or graveyard_index >= p.graveyard.size() or p.queue.size() >= _queue_capacity(p): return false
	var card_id := str(p.graveyard[graveyard_index]); var definition := RULES.card(card_id)
	if str(definition.get("type", "")) != "creature": return false
	var cost := int(definition.get("filament_cost", 0)) / 2
	if int(p.filament) < cost: return false
	p.filament -= cost
	p.queue.append({"card_id":card_id,"remaining":int(definition.get("print_turns", 1)),"target":-1,"cost":cost,"reprint":true})
	return true

static func _upgrade_reprint(state: UnifiedBattleState, seat: int, graveyard_index: int) -> Dictionary:
	if state.phase != "main": return _no("Emergency Reprint is used in Main.")
	var p := state.player(seat)
	if int(p.get("emergency_reprints", 0)) <= 0: return _no("No installed Emergency Reprint charge remains.")
	if not _reprint(p, graveyard_index): return _no("Choose a graveyard creature you can reprint.")
	p.emergency_reprints -= 1
	return {"ok":true,"graveyard_index":graveyard_index,"remaining_charges":int(p.emergency_reprints)}

static func _cancel(state: UnifiedBattleState, seat: int, index: int) -> Dictionary:
	if state.phase != "main": return _no("Cancel prints in Main.")
	var p := state.player(seat)
	if index < 0 or index >= p.queue.size(): return _no("Choose a queued print.")
	var item: Dictionary = p.queue[index]; p.queue.remove_at(index)
	var refund := int(item.get("cost", 0)) / 2; _gain(p, refund); p.graveyard.append(str(item.get("card_id", "")))
	return {"ok":true,"refund":refund}

static func _place(state: UnifiedBattleState, seat: int, slot: int, mode: String) -> Dictionary:
	if str(state.pending.get("kind", "")) != "place" or int(state.pending.get("seat", -1)) != seat: return _no("Nothing is waiting for a field slot.")
	var p := state.player(seat)
	if slot < 0 or slot > 2 or p.slots[slot] != null or not mode in ["attack", "defense"]: return _no("Choose an open slot and combat mode.")
	p.slots[slot] = state.pending.get("unit", {}).duplicate(true); p.slots[slot].mode = mode; p.slots[slot].ready = true
	if bool(state.pending.get("from_staging", false)) and not p.staging.is_empty(): p.staging.pop_front()
	state.pending = {}
	_present_waiting(state, seat)
	_print_continue(state, seat)
	return {"ok":true}

static func _attach(state: UnifiedBattleState, seat: int, slot: int) -> Dictionary:
	if str(state.pending.get("kind", "")) != "attach" or int(state.pending.get("seat", -1)) != seat: return _no("Nothing is waiting to attach.")
	var p := state.player(seat); var card := RULES.card(str(state.pending.get("card_id", "")))
	if not _can_attach(p, slot, card): return _no("Choose a compatible creature.")
	_attach_card(p.slots[slot], card)
	var holding_index := int(state.pending.get("holding_index", -1))
	if holding_index >= 0 and holding_index < p.holding.size(): p.holding.remove_at(holding_index)
	state.pending = {}
	_present_waiting(state, seat)
	_print_continue(state, seat)
	return {"ok":true}

static func _switch_mode(state: UnifiedBattleState, seat: int, slot: int, mode: String) -> Dictionary:
	if state.phase != "main": return _no("Switch modes in Main.")
	var p := state.player(seat)
	if slot < 0 or slot > 2 or p.slots[slot] == null or not mode in ["attack", "defense"]: return _no("Choose a legal mode.")
	var unit: Dictionary = p.slots[slot]
	if bool(unit.get("mode_changed", false)) or (bool(unit.get("preprinted", false)) and state.turn == 1): return _no("That creature cannot switch mode now.")
	if int(unit.statuses.get("frost_lock", 0)) > 0: return _no("Frost prevents a mode change.")
	unit.mode = mode; unit.mode_changed = true
	return {"ok":true}

static func _activate(state: UnifiedBattleState, seat: int, slot: int, target: int) -> Dictionary:
	if state.phase != "main": return _no("Activate abilities in Main.")
	var p := state.player(seat)
	if slot < 0 or slot > 2 or p.slots[slot] == null: return _no("Choose a creature.")
	var unit: Dictionary = p.slots[slot]; var definition := RULES.card(str(unit.get("card_id", "")))
	if str(definition.get("ability_trigger", "attack")) != "main" or int(unit.get("ability_cooldown", 0)) > 0 or int(unit.statuses.get("ability_lock", 0)) > 0 or (bool(unit.get("preprinted", false)) and state.turn == 1): return _no("That ability is not ready.")
	if str(definition.get("ability_effect", "")) == "heal": unit.hp = mini(int(unit.base_hp), int(unit.hp) + int(definition.get("ability_amount", 0)))
	elif str(definition.get("ability_effect", "")) == "damage" and target >= 0 and target < 3 and state.player(1 - seat).slots[target] != null: _damage_unit(state, 1 - seat, target, int(definition.get("ability_amount", 0)), false)
	else: return _no("That ability has no valid target.")
	unit.ability_cooldown = int(definition.get("ability_cooldown", 1))
	return {"ok":true}

static func _attack(state: UnifiedBattleState, seat: int, slot: int, target: int) -> Dictionary:
	if state.phase != "attack": return _no("Attack in Attack.")
	var p := state.player(seat); var foe := state.player(1 - seat)
	if slot < 0 or slot > 2 or p.slots[slot] == null: return _no("Choose an attacker.")
	var attacker: Dictionary = p.slots[slot]
	if attacker.mode != "attack" or not bool(attacker.ready) or bool(attacker.attacked) or int(attacker.statuses.get("attack_lock", 0)) > 0: return _no("That creature cannot attack.")
	if state.turn == 1 and seat == state.starting_seat: return _no("The first player cannot attack on turn one.")
	if target == -1:
		for defender in foe.slots:
			if defender != null: return _no("Clear every defender before the printer.")
		var printer_damage := _damage(attacker, {})
		foe.printer.hp = maxi(0, int(foe.printer.hp) - printer_damage); attacker.attacked = true; _check_win(state)
		return {"ok":true,"damage":printer_damage}
	if target < 0 or target > 2 or foe.slots[target] == null: return _no("Choose a defending creature or printer.")
	var defender: Dictionary = foe.slots[target]
	var damage := _damage(attacker, defender) * _trigger_trap(state, 1 - seat, "attack", {"attacker":slot,"target":target}) / 10000
	var drill := str((attacker.equipment.get("weapon", {}) as Dictionary).get("effect", "")) == "arcane_drill"
	_damage_unit(state, 1 - seat, target, damage, drill); attacker.attacked = true; _apply_weapon_on_hit(attacker, defender); _resolve_attack_ability(state, seat, slot, target)
	return {"ok":true,"damage":damage}

static func _damage(attacker: Dictionary, defender: Dictionary) -> int:
	var weapon: Dictionary = attacker.get("equipment", {}).get("weapon", {}) if attacker.get("equipment", {}) is Dictionary else {}
	var base := (int(attacker.get("bend", 0)) + int(attacker.get("ability_bend_bonus", 0)) + 3) / 4 + int(weapon.get("attack_bonus", 0))
	var multiplier := 100
	if not defender.is_empty():
		multiplier = _element_multiplier(str(attacker.get("element", "Arcane")), str(defender.get("element", "Arcane")))
		var armor: Dictionary = defender.get("equipment", {}).get("armor", {}) if defender.get("equipment", {}) is Dictionary else {}
		if multiplier == 150 and int(armor.get("super_effective_bps", 15000)) == 12000: multiplier = 120
	return maxi(1, base * multiplier * int(attacker.get("surge_bps", 10000)) / 1000000)

static func _damage_unit(state: UnifiedBattleState, owner: int, slot: int, damage: int, bypass_armor: bool) -> void:
	var unit: Dictionary = state.player(owner).slots[slot]
	if not bypass_armor and int(unit.armor_hp) > 0:
		var absorbed := mini(damage, int(unit.armor_hp)); unit.armor_hp -= absorbed; damage -= absorbed
	if damage > 0: unit.hp = maxi(0, int(unit.hp) - damage)
	if int(unit.hp) <= 0: _destroy(state, owner, slot)

static func _destroy(state: UnifiedBattleState, owner: int, slot: int) -> void:
	var p := state.player(owner); var unit: Dictionary = p.slots[slot]
	if unit == null: return
	var total_cost := int(RULES.card(str(unit.get("card_id", ""))).get("filament_cost", 0)) + int(unit.get("equipment_cost", 0))
	p.scrap.append({"cost":total_cost,"rarity":str(unit.get("rarity", "common"))}); p.graveyard.append(str(unit.get("card_id", "")))
	for equipment in unit.equipment.values():
		if equipment is Dictionary and not equipment.is_empty(): p.graveyard.append(str(equipment.get("card_id", "")))
	p.slots[slot] = null; _trigger_trap(state, 1 - owner, "destroy", {"owner":owner,"cost":total_cost})
	# The owner makes the mode decision as soon as it is legal; if the owner is
	# currently defending, staging remains public until that owner's next Draw.
	if owner == state.active_seat: _present_waiting(state, owner)

static func _advance(state: UnifiedBattleState, seat: int) -> Dictionary:
	if not state.pending.is_empty(): return _no("Finish the completed print first.")
	match state.phase:
		"draw": _draw_start(state, seat); state.phase = "main"
		"main": state.phase = "print"
		"print": _print(state, seat); if state.pending.is_empty(): state.phase = "attack"
		"attack": state.phase = "collect"
		"collect":
			if state.player(seat).hand.size() > 8: return _no("Discard to eight cards before ending Collect.")
			_collect(state, seat); state.active_seat = 1 - seat
			if state.active_seat == state.starting_seat: state.turn += 1
			state.phase = "draw"; state.player(state.active_seat).upgrade_plays = 0
	return {"ok":true,"phase":state.phase}

static func _draw_start(state: UnifiedBattleState, seat: int) -> void:
	var p := state.player(seat); p.draw_count += 1
	var count := 1
	if state.turn == 1: count = 0 if seat == state.starting_seat else 2
	for _index in count:
		if not p.deck.is_empty(): p.hand.append(p.deck.pop_front())
	for slot in 3:
		var unit = p.slots[slot]
		if unit == null: continue
		unit.attacked = false; unit.mode_changed = false; unit.ready = not (bool(unit.preprinted) and state.turn == 1)
		if bool(unit.preprinted) and state.turn > 1: unit.preprinted = false
		var accessory: Dictionary = unit.equipment.get("accessory", {})
		unit.ability_cooldown = maxi(0, int(unit.ability_cooldown) - (2 if str(accessory.get("effect", "")) == "arcane_sigil" else 1))
		if str(accessory.get("effect", "")) == "tidal_core": unit.hp = mini(int(unit.base_hp), int(unit.hp) + 10)
		if int(unit.statuses.get("burn", 0)) > 0: _damage_unit(state, seat, slot, 10, false)
		for status in unit.statuses.keys(): unit.statuses[status] = maxi(0, int(unit.statuses[status]) - 1)
	_present_waiting(state, seat)

static func _print(state: UnifiedBattleState, seat: int) -> void:
	var p := state.player(seat)
	if int(p.get("queue_paused", 0)) > 0: p.queue_paused -= 1; return
	var speed: int = 1 + p.installed_upgrades.count("speed_spool") + p.installed_upgrades.count("turbo_spool") * 2
	while speed > 0 and not p.queue.is_empty() and state.pending.is_empty():
		var item: Dictionary = p.queue[0]; var remaining: int = int(item.get("remaining", 1)) - speed
		if remaining > 0: item.remaining = remaining; break
		speed = -remaining; p.queue.pop_front()
		var card := RULES.card(str(item.get("card_id", "")))
		if str(card.get("type", "")) == "creature":
			# Print Interrupt consumes the completed card before it can stage or
			# request a slot. All other traps return a neutral multiplier.
			if _trigger_trap(state, 1 - seat, "print_complete", {"card_id":str(card.get("id", "")),"owner":seat}) == 0:
				p.graveyard.append(str(card.get("id", "")))
				continue
			var open_slot := _open_slot(p)
			if open_slot >= 0: state.pending = {"kind":"place","seat":seat,"unit":STATE._unit(card)}
			else: p.staging.append(STATE._unit(card))
		else:
			var target := int(item.get("target", -1))
			if _can_attach(p, target, card): _attach_card(p.slots[target], card)
			else: p.holding.append({"card_id":str(card.get("id", "")),"target":target})

static func _print_continue(state: UnifiedBattleState, seat: int) -> void:
	if state.pending.is_empty(): _print(state, seat)
static func _can_attach(p: Dictionary, slot: int, card: Dictionary) -> bool:
	var equip_slot := str(card.get("equipment_slot", ""))
	return slot >= 0 and slot < 3 and p.slots[slot] != null and not equip_slot.is_empty() and (p.slots[slot].equipment.get(equip_slot, {}) as Dictionary).is_empty()
static func _present_waiting(state: UnifiedBattleState, seat: int) -> void:
	if not state.pending.is_empty(): return
	var p := state.player(seat)
	if not p.staging.is_empty() and _open_slot(p) >= 0:
		state.pending = {"kind":"place","seat":seat,"unit":(p.staging[0] as Dictionary).duplicate(true),"from_staging":true}
		return
	for index in p.holding.size():
		var held: Dictionary = p.holding[index]
		var card := RULES.card(str(held.get("card_id", "")))
		for slot in 3:
			if _can_attach(p, slot, card):
				state.pending = {"kind":"attach","seat":seat,"card_id":str(card.get("id", "")),"holding_index":index}
				return
static func _attach_card(unit: Dictionary, card: Dictionary) -> void:
	var slot := str(card.get("equipment_slot", "")); unit.equipment[slot] = {"card_id":str(card.get("id", "")),"effect":str(card.get("effect", "")),"attack_bonus":int(card.get("attack_bonus", 0)),"super_effective_bps":int(card.get("super_effective_bps", 15000)),"used":false}; unit.equipment_cost += int(card.get("filament_cost", 0)); unit.armor_hp += int(card.get("armor_hp", 0))
static func _apply_weapon_on_hit(attacker: Dictionary, defender: Dictionary) -> void:
	var weapon: Dictionary = attacker.equipment.get("weapon", {})
	match str(weapon.get("effect", "")):
		"ember_fang": defender.statuses["burn"] = 3 # Draw resolves, then decrements: exactly two owner Draws.
		"frost_shard": defender.statuses["frost_lock"] = 2
		"thunder_coil": if not bool(weapon.get("used", false)): defender.statuses["attack_lock"] = 2; weapon.used = true

static func _resolve_attack_ability(state: UnifiedBattleState, seat: int, slot: int, target: int) -> void:
	var attacker: Variant = state.player(seat).slots[slot]
	if attacker == null: return
	var definition := RULES.card(str(attacker.get("card_id", "")))
	if str(definition.get("ability_trigger", "")) != "attack" or int(attacker.get("ability_cooldown", 0)) > 0 or int(attacker.statuses.get("ability_lock", 0)) > 0: return
	if target >= 0 and target < 3 and state.player(1 - seat).slots[target] != null and int(definition.get("ability_damage_bonus", 0)) > 0:
		_damage_unit(state, 1 - seat, target, int(definition.get("ability_damage_bonus", 0)), false)
	var effects: Array = definition.get("ability_effects", []) if definition.get("ability_effects", []) is Array else []
	if effects.is_empty() and not str(definition.get("ability_effect", "")).is_empty(): effects = [{"effect":str(definition.get("ability_effect", "")),"target":"foe" if str(definition.get("ability_effect", "")) == "damage" else "self","amount":int(definition.get("ability_amount", 0))}]
	for raw_effect in effects:
		if not raw_effect is Dictionary: continue
		var effect := str(raw_effect.get("effect", "")); var amount := int(raw_effect.get("amount", 0)); var target_unit: Variant = attacker
		if str(raw_effect.get("target", "self")) == "foe" and target >= 0 and target < 3: target_unit = state.player(1 - seat).slots[target]
		if target_unit == null: continue
		if effect == "heal": target_unit.hp = mini(int(target_unit.base_hp), int(target_unit.hp) + amount)
		elif effect in ["shield", "armor"]: target_unit.armor_hp += amount
		elif effect == "filament": _gain(state.player(seat), amount)
		elif effect == "damage" and target >= 0 and target < 3: _damage_unit(state, 1 - seat, target, amount, false)
		elif effect == "attack_buff": attacker["ability_bend_bonus"] = int(attacker.get("ability_bend_bonus", 0)) + amount
		elif effect == "ability_lock": target_unit.statuses["ability_lock"] = maxi(int(target_unit.statuses.get("ability_lock", 0)), amount + 1)
		elif effect == "cleanse": target_unit.statuses.clear()
	attacker.ability_cooldown = int(definition.get("ability_cooldown", 0))
static func _collect(state: UnifiedBattleState, seat: int) -> void:
	_consume_scrap(state, seat, true)
	for unit in state.player(seat).slots:
		if unit != null and str((unit.equipment.get("accessory", {}) as Dictionary).get("effect", "")) == "filament_ring": _gain(state.player(seat), 20)
static func _consume_scrap(state: UnifiedBattleState, seat: int, include_foe: bool) -> void:
	var p := state.player(seat); var sources: Array = [p.scrap]
	if include_foe and p.installed_upgrades.has("battlefield_collector"): sources.append(state.player(1 - seat).scrap)
	for source in sources:
		for token in source:
			var rate := mini(8000, int(RECOVERY.get(str(token.get("rarity", "common")), 2500)) + p.installed_upgrades.count("spooler") * 1000); var amount := int(token.get("cost", 0)) * rate / 10000
			if p.installed_upgrades.has("smelter"): amount = mini(int(token.get("cost", 0)), amount * 110 / 100)
			_gain(p, amount)
		source.clear()
static func _trigger_trap(state: UnifiedBattleState, defender_seat: int, event_name: String, context: Dictionary) -> int:
	var p := state.player(defender_seat)
	if p.trap.is_empty(): return 10000
	var trap_id := str(p.trap.get("card_id", "")); var trap := RULES.card(trap_id)
	if str(trap.get("trigger", "")) != event_name: return 10000
	p.trap = {}; p.graveyard.append(trap_id)
	match trap_id:
		"print_interrupt": return 0
		"filament_siphon":
			var owner := int(context.get("owner", -1))
			if owner >= 0: var amount := mini(int(state.player(owner).filament), int(context.get("amount", 0)) / 2); state.player(owner).filament -= amount; _gain(p, amount)
		"counter_strike": return 5000
		"scrap_grab":
			_gain(p, int(context.get("cost", 0)))
			var destroyed_owner := int(context.get("owner", -1))
			if destroyed_owner >= 0 and not state.player(destroyed_owner).scrap.is_empty(): state.player(destroyed_owner).scrap.pop_back()
	return 10000
static func _discard(state: UnifiedBattleState, seat: int, ids: Variant) -> Dictionary:
	if state.phase != "collect" or not ids is Array: return _no("Discard choices are only valid in Collect.")
	var p := state.player(seat); var wanted: Array = ids
	if p.hand.size() - wanted.size() > 8: return _no("Choose enough cards to reach eight.")
	for id in wanted:
		if not p.hand.has(str(id)): return _no("Discard card is not in hand.")
	for id in wanted: p.hand.erase(str(id)); p.graveyard.append(str(id))
	return {"ok":true}
static func _queue_capacity(p: Dictionary) -> int: return 3 + p.installed_upgrades.count("dual_queue") * 2
static func _open_slot(p: Dictionary) -> int:
	for slot in 3:
		if p.slots[slot] == null: return slot
	return -1
static func _gain(p: Dictionary, amount: int) -> void: p.filament = mini(int(p.filament_max), int(p.filament) + maxi(0, amount))
static func _element_multiplier(attacker: String, defender: String) -> int: return 100 if attacker == "Arcane" else int(ELEMENTS.get(attacker, {}).get(defender, 100))
static func _check_win(state: UnifiedBattleState) -> void:
	for seat in 2:
		if int(state.player(seat).printer.hp) <= 0: state.finished = true; state.winner = 1 - seat
static func _no(error: String) -> Dictionary: return {"ok":false,"error":error}
