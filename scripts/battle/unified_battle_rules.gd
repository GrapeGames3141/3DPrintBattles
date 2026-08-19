class_name UnifiedBattleRules
extends RefCounted
const RULES := preload("res://scripts/core/unified_rules.gd")

static func apply_intent(state: UnifiedBattleState, seat: int, intent: Dictionary) -> Dictionary:
	if state.finished or seat != state.active_seat: return _no("Not your turn.")
	var type := str(intent.get("type", ""))
	match type:
		# -2 means the client did not make a target choice.  Printer is the
		# explicit target -1, so neither attacks nor targeted spells can quietly
		# fall through to it when a UI has not made a selection yet.
		"play_card": return _play(state, seat, str(intent.get("card_id", "")), int(intent.get("slot", -1)), int(intent.get("target", -2)))
		"attack": return _attack(state, seat, int(intent.get("slot", -1)), int(intent.get("target", -2)))
		"use_signature": return _signature(state, seat, int(intent.get("slot", -1)))
		"collect": return _collect(state, seat, int(intent.get("pile", -1)))
		"smelt": return _smelt(state, seat)
		"advance_phase": return _advance(state, seat)
		"concede": state.finished = true; state.winner = 1 - seat; return {"ok":true}
		_: return _no("Unknown battle intent.")

static func _play(state: UnifiedBattleState, seat: int, card_id: String, slot: int, target: int) -> Dictionary:
	if state.phase != "play": return _no("Cards can only be played in Play.")
	var p := state.player(seat); var card := RULES.card(card_id)
	if card.is_empty() or not card_id in p.hand: return _no("Card is not in hand.")
	var builds: Array = p.card_builds.get(card_id, []) if p.get("card_builds", {}) is Dictionary else []
	var tempo_discount := (1 if "tempo_a" in builds else 0) + (1 if "tempo_b" in builds else 0)
	var filament_cost := maxi(0, int(card.get("cost", 0)) - tempo_discount)
	if int(p.filament) < filament_cost: return _no("Need more filament.")
	if str(card.type) == "creature":
		if not p.print_job.is_empty(): return _no("Printer already has a job.")
		if slot < 0 or slot > 2 or p.slots[slot] != null: return _no("Choose an open print slot.")
		p.filament -= filament_cost; p.hand.erase(card_id); p.discard.append(card_id); p.played.append(card_id)
		var ticks := maxi(1, int(card.get("print_ticks", 1)) - (1 if "rapid_start" in p.nodes else 0) - (1 if "calibrated_rails" in p.nodes else 0) - tempo_discount); p.print_job = {"card_id":card_id,"slot":slot,"ticks":ticks,"arriving":false}; state.log.append("%s is printing (%d ticks)." % [str(card.name), ticks]); return {"ok":true,"card_id":card_id}
	# Validate all target data before committing the hand/filament transaction.
	if str(card.type) == "equipment" and (target < 0 or target > 2 or p.slots[target] == null): return _no("Equipment needs a friendly print.")
	if str(card.type) == "spell" and target != -1: return _no("Choose the printer target.")
	p.filament -= filament_cost; p.hand.erase(card_id); p.discard.append(card_id); p.played.append(card_id)
	match str(card.type):
		"refill": p.filament = mini(int(p.spool_cap), int(p.filament) + int(card.amount) + (1 if "power_a" in builds else 0) + (1 if "power_b" in builds else 0) + (1 if "utility_a" in builds else 0) + (1 if "utility_b" in builds else 0)); state.log.append("Refill consumed.")
		"equipment":
			var power := (1 if "power_a" in builds else 0) + (1 if "power_b" in builds else 0); var utility := (1 if "utility_a" in builds else 0) + (1 if "utility_b" in builds else 0)
			p.slots[target].attack += (2 + power) if str(card.effect) == "attack" else utility; p.slots[target].guard += (2 + power) if str(card.effect) == "guard" else utility
		"spell": _spell(state, seat, card, target, builds)
	return {"ok":true,"card_id":card_id}

static func _spell(state: UnifiedBattleState, seat: int, card: Dictionary, target: int, builds: Array) -> void:
	# Target has been validated by _play.  Its direction is card-defined: jam
	# and leak target the rival printer, while ward and vent target your own.
	if target != -1: return
	var foe := state.player(1 - seat)
	var potency := (1 if "power_a" in builds else 0) + (1 if "power_b" in builds else 0) + (1 if "utility_a" in builds else 0) + (1 if "utility_b" in builds else 0)
	match str(card.get("effect", "")):
		"slow_printer": foe.printer.slow = maxi(int(foe.printer.slow), 1 + potency)
		"steal_filament": var stolen := mini(2 + potency, int(foe.filament)); foe.filament -= stolen; var p := state.player(seat); p.filament = mini(int(p.spool_cap), int(p.filament) + stolen)
		"printer_guard": state.player(seat).printer.durability = mini(100, int(state.player(seat).printer.durability) + 10 + potency * 2)
		"cleanse_printer": state.player(seat).printer.slow = 0
		_: state.player(seat).printer.durability = mini(100, int(state.player(seat).printer.durability) + 3 + potency)

static func _attack(state: UnifiedBattleState, seat: int, slot: int, target: int) -> Dictionary:
	if state.phase != "attack": return _no("Attack in Attack phase.")
	var p := state.player(seat); var foe := state.player(1-seat)
	if slot < 0 or slot > 2 or p.slots[slot] == null: return _no("Choose a completed print.")
	var attacker: Dictionary = p.slots[slot]
	if bool(attacker.get("ready", false)) == false: return _no("That print has acted or is cooling.")
	var damage := maxi(1, int(attacker.attack))
	if target >= 0 and target <= 2 and foe.slots[target] != null:
		foe.slots[target].hp -= damage; if int(foe.slots[target].hp) <= 0: _break_print(foe, target, seat)
	elif target == -1:
		for unit in foe.slots:
			if unit != null: return _no("Enemy prints guard the printer.")
		foe.printer.durability -= damage
	else:
		return _no("Choose a legal enemy target.")
	attacker.ready = false; _check_printer(state); return {"ok":true,"damage":damage}

static func _signature(state: UnifiedBattleState, seat: int, slot: int) -> Dictionary:
	if state.phase != "attack": return _no("Signature in Attack phase.")
	var p := state.player(seat); if slot < 0 or slot > 2 or p.slots[slot] == null or not bool(p.slots[slot].ready): return _no("Choose a ready print.")
	for unit in state.player(1-seat).slots: if unit != null: return _no("Enemy prints guard the printer.")
	var cost := 1; if int(p.filament) < cost: return _no("Need filament.")
	p.filament -= cost; p.slots[slot].ready = false; state.player(1-seat).printer.durability -= maxi(1, int(p.slots[slot].attack) / 2); _check_printer(state); return {"ok":true}

static func _break_print(owner: Dictionary, slot: int, claimant: int) -> void:
	var unit: Dictionary = owner.slots[slot]
	owner.debris.append({"amount":int(unit.cost),"claimed_by":claimant})
	owner.slots[slot] = null

static func _collect(state: UnifiedBattleState, seat: int, pile: int) -> Dictionary:
	if state.phase != "collect": return _no("Collect in Collect phase.")
	var p := state.player(seat); var foe := state.player(1-seat); var sources := [p.debris, foe.debris]
	for debris in sources:
		if pile >= 0 and pile < debris.size() and int(debris[pile].get("claimed_by", -1)) == seat and int(p.collector) < int(p.collector_cap):
			var take := mini(int(debris[pile].amount), int(p.collector_cap) - int(p.collector)); p.collector += take; debris[pile].amount -= take; if int(debris[pile].amount) <= 0: debris.remove_at(pile); return {"ok":true,"amount":take}
	return _no("No debris fits the collector.")

static func _smelt(state: UnifiedBattleState, seat: int) -> Dictionary:
	var p := state.player(seat); if "clip_smelter" not in p.nodes: return _no("Clip-on smelter required.")
	p.melted += int(p.collector); p.collector = 0
	if "spooler" in p.nodes:
		var ratio := 1 if "closed_loop" in p.nodes else 2; var made := int(p.melted) / ratio; p.melted -= made * ratio; p.filament = mini(int(p.spool_cap), int(p.filament) + made)
	return {"ok":true}

static func _advance(state: UnifiedBattleState, seat: int) -> Dictionary:
	if state.phase == "play": state.phase = "attack"; return {"ok":true}
	if state.phase == "attack": state.phase = "collect"; return {"ok":true}
	_collect_income_and_print(state, seat); state.active_seat = 1-seat; state.turn += 1; state.phase = "play"; _start_turn(state, state.active_seat); return {"ok":true}

static func _collect_income_and_print(state: UnifiedBattleState, seat: int) -> void:
	var p := state.player(seat); p.filament = mini(int(p.spool_cap), int(p.filament) + 1 + (1 if "high_flow" in p.nodes else 0))
	if not p.print_job.is_empty():
		if int(p.printer.slow) > 0: p.printer.slow -= 1
		else: p.print_job.ticks -= 1
		if int(p.print_job.ticks) <= 0:
			var card := RULES.card(str(p.print_job.card_id)); var builds: Array = p.card_builds.get(str(card.id), []) if p.get("card_builds", {}) is Dictionary else []; p.slots[int(p.print_job.slot)] = {"card_id":str(card.id),"name":str(card.name),"hp":int(card.hp) + (5 if "utility_a" in builds else 0) + (5 if "utility_b" in builds else 0),"attack":int(card.attack) + (2 if "power_a" in builds else 0) + (3 if "power_b" in builds else 0),"cost":int(card.cost),"guard":1 if "utility_b" in builds else 0,"ready":false,"arriving":true}; p.print_job = {}; state.log.append("Print walks onto the field.")

static func _start_turn(state: UnifiedBattleState, seat: int) -> void:
	var p := state.player(seat)
	if state.turn > 2:
		if p.deck.is_empty(): p.fatigue += 5; p.printer.durability -= p.fatigue
		elif p.hand.size() < 7: p.hand.append(p.deck.pop_front())
	for unit in p.slots:
		if unit != null: unit.ready = not bool(unit.get("arriving", false)); unit.arriving = false
	_check_printer(state)
static func _check_printer(state: UnifiedBattleState) -> void:
	for seat in [0,1]:
		if int(state.player(seat).printer.durability) <= 0: state.finished = true; state.winner = 1-seat
static func _no(error: String) -> Dictionary: return {"ok":false,"error":error}
