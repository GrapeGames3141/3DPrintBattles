# BattleManager.gd
# Autoload singleton — add to Autoload as "BattleManager"
# Manages all battle state, AI decisions, damage calculation, and turn flow.
# Emits signals that BattleScene.gd listens to for UI updates.
# No networking — pure local single-player logic.

extends Node

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS — BattleScene listens to these to update UI
# ─────────────────────────────────────────────────────────────────────────────
signal battle_started(player_team: Array, ai_team: Array)
signal turn_started(is_player_turn: bool, turn_number: int)
signal attack_landed(attacker_side: String, damage: int, is_super_effective: bool, is_not_effective: bool)
signal ability_used(user_side: String, ability_id: String, result: Dictionary)
signal card_played(card_id: String, result: Dictionary)
signal print_hp_changed(side: String, new_hp: int, max_hp: int)
signal forge_bar_changed(side: String, new_value: float)
signal print_defeated(side: String, creature_id: String)
signal next_print_summoned(side: String, print_data: Dictionary)
signal battle_ended(player_won: bool, rewards: Dictionary)
signal coin_flip_result(player_goes_first: bool)
signal status_effect_applied(side: String, effect: String, duration: int)

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE STATE
# ─────────────────────────────────────────────────────────────────────────────
enum BattlePhase { IDLE, COIN_FLIP, PLAYER_TURN, AI_TURN, RESOLVING, ENDED }

var phase: BattlePhase = BattlePhase.IDLE
var turn_number: int = 0
var player_goes_first: bool = true
var current_trainer: Dictionary = {}

# Teams: arrays of print instance dicts (live copies, not save data)
var player_team: Array = []
var ai_team: Array = []

# Active (front) prints
var player_active_idx: int = 0
var ai_active_idx: int = 0

# Forge bars (0.0 – 10.0)
var player_forge: float = 0.0
var ai_forge: float = 0.0

# Status effects: { "player": {effect_id: turns_remaining}, "ai": {...} }
var status_effects: Dictionary = {"player": {}, "ai": {}}

# Temporary battle flags
var player_charge_active: bool = false    # Cyclone Charge
var ai_charge_active: bool = false
var player_ability_cooldowns: Dictionary = {}  # ability_id: turns_remaining
var ai_ability_cooldowns: Dictionary = {}
var arcane_filament_used: bool = false    # Once per battle card
var _battle_team_instance_ids: Array = []  # Save instance IDs for stat tracking

# Card / ability combat flags
var player_attack_bonus: float = 0.0
var player_skip_attack: bool = false
var emergency_summon_active: bool = false

# ─────────────────────────────────────────────────────────────────────────────
# START BATTLE
# ─────────────────────────────────────────────────────────────────────────────
func start_battle(player_print_instances: Array, trainer: Dictionary) -> void:
	current_trainer = trainer
	phase = BattlePhase.IDLE
	turn_number = 0
	player_forge = 0.0
	ai_forge = 0.0
	status_effects = {"player": {}, "ai": {}}
	player_charge_active = false
	ai_charge_active = false
	player_ability_cooldowns = {}
	ai_ability_cooldowns = {}
	arcane_filament_used = false
	player_attack_bonus = 0.0
	player_skip_attack = false
	emergency_summon_active = false
	_battle_team_instance_ids = []

	# Deep copy player team from passed instances
	player_team = []
	for inst in player_print_instances:
		player_team.append(_make_battle_copy(inst))
		if inst.has("instance_id"):
			_battle_team_instance_ids.append(inst["instance_id"])
	player_active_idx = 0

	# Build AI team from trainer roster
	ai_team = []
	for creature_id in trainer["roster"]:
		var ai_inst = {
			"instance_id": "ai_%s" % creature_id,
			"creature_id": creature_id,
			"hp_current": GameData.CREATURES[creature_id]["hp_base"],
			"equipment": {"armor": "", "weapon": "", "accessory": ""},
			"times_battled": 0,
			"times_won": 0,
			# AI doesn't use save data equipment for simplicity
		}
		ai_team.append(ai_inst)
	ai_active_idx = 0

	emit_signal("battle_started", player_team, ai_team)
	_do_coin_flip()

# ─────────────────────────────────────────────────────────────────────────────
# COIN FLIP
# ─────────────────────────────────────────────────────────────────────────────
func _do_coin_flip() -> void:
	phase = BattlePhase.COIN_FLIP
	player_goes_first = randf() > 0.5
	emit_signal("coin_flip_result", player_goes_first)
	# BattleScene animates the flip, then calls begin_first_turn()

func begin_first_turn() -> void:
	turn_number = 1
	if player_goes_first:
		_start_player_turn()
	else:
		_start_ai_turn()

# ─────────────────────────────────────────────────────────────────────────────
# TURN FLOW
# ─────────────────────────────────────────────────────────────────────────────
func _start_player_turn() -> void:
	if _is_stunned("player"):
		phase = BattlePhase.PLAYER_TURN
		emit_signal("turn_started", true, turn_number)
		emit_signal("status_effect_applied", "player", "stunned", 1)
		call_deferred("_skip_player_turn_stunned")
		return
	phase = BattlePhase.PLAYER_TURN
	_fill_forge("player", 1.0)
	_apply_regen_effects("player")
	_tick_status_effects("player")
	_tick_ability_cooldowns(player_ability_cooldowns)
	emit_signal("turn_started", true, turn_number)

func _start_ai_turn() -> void:
	if _is_stunned("ai"):
		phase = BattlePhase.AI_TURN
		emit_signal("turn_started", false, turn_number)
		emit_signal("status_effect_applied", "ai", "stunned", 1)
		call_deferred("_skip_ai_turn_stunned")
		return
	phase = BattlePhase.AI_TURN
	_fill_forge("ai", 1.0)
	_apply_regen_effects("ai")
	_tick_status_effects("ai")
	_tick_ability_cooldowns(ai_ability_cooldowns)
	emit_signal("turn_started", false, turn_number)
	# AI acts automatically after a short delay (handled by BattleScene timer)

# Called by BattleScene after AI turn delay
func _skip_player_turn_stunned() -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	phase = BattlePhase.RESOLVING
	turn_number += 1
	_check_battle_end()
	if phase != BattlePhase.ENDED:
		_start_ai_turn()

func _skip_ai_turn_stunned() -> void:
	if phase != BattlePhase.AI_TURN:
		return
	phase = BattlePhase.RESOLVING
	turn_number += 1
	_check_battle_end()
	if phase != BattlePhase.ENDED:
		_start_player_turn()

func ai_take_turn() -> void:
	if phase != BattlePhase.AI_TURN:
		return
	phase = BattlePhase.RESOLVING

	var ai_print = get_ai_active_print()
	if ai_print.is_empty():
		_ai_try_summon()
		_end_ai_turn()
		return

	if ai_charge_active:
		_resolve_attack("ai", "player", 2.5)
		ai_charge_active = false
		_end_ai_turn()
		return

	if _ai_should_use_ability(ai_print):
		var charged = _ai_use_ability(ai_print)
		if not charged:
			_resolve_attack("ai", "player")
	else:
		_resolve_attack("ai", "player")

	_end_ai_turn()

func _end_ai_turn() -> void:
	turn_number += 1
	_check_battle_end()
	if phase != BattlePhase.ENDED:
		_start_player_turn()

# Called by player pressing "End Turn" or by the 15-second timer
func player_end_turn(skip_attack: bool = false) -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	phase = BattlePhase.RESOLVING

	var player_print = get_player_active_print()
	if not skip_attack and not player_skip_attack and not player_print.is_empty():
		if player_charge_active:
			_resolve_attack("player", "ai", 2.5)
			player_charge_active = false
		else:
			_resolve_attack("player", "ai")
	player_skip_attack = false

	turn_number += 1
	_check_battle_end()
	if phase != BattlePhase.ENDED:
		_start_ai_turn()

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER ACTIONS (called by BattleScene UI buttons)
# ─────────────────────────────────────────────────────────────────────────────
func player_use_ability() -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	var print_inst = get_player_active_print()
	if print_inst.is_empty():
		return
	var creature = GameData.CREATURES[print_inst["creature_id"]]
	var ability_id: String = creature["ability"]

	var cd = GameData.ABILITIES[ability_id]["cooldown"]
	cd = max(0, cd - _cooldown_reduction("player"))
	if player_ability_cooldowns.get(ability_id, 0) > 0:
		return

	var result = _apply_ability(ability_id, "player", "ai")
	player_ability_cooldowns[ability_id] = cd
	emit_signal("ability_used", "player", ability_id, result)

func player_play_card(card_id: String) -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	var card = GameData.FILAMENT_CARDS[card_id]
	var result = {}

	match card["effect_type"]:
		"forge_fill":
			_fill_forge("player", card["value"])
			result = {"forge_added": card["value"]}
		"forge_fill_attack":
			_fill_forge("player", card["forge_value"])
			player_attack_bonus += float(card["attack_bonus"])
			result = {"forge_added": card["forge_value"], "attack_bonus": card["attack_bonus"]}
		"heal":
			var healed = _heal_print("player", card["value"])
			result = {"healed": healed}
		"emergency_summon":
			emergency_summon_active = true
			result = {"emergency_summon": true}
		"forge_double":
			if not arcane_filament_used:
				var new_val = min(player_forge * 2.0, 10.0)
				player_forge = new_val
				arcane_filament_used = true
				emit_signal("forge_bar_changed", "player", player_forge)
				result = {"new_forge": player_forge}

	emit_signal("card_played", card_id, result)

func player_summon_print(bench_index: int) -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	if bench_index < 0 or bench_index >= player_team.size():
		return
	var print_inst = player_team[bench_index]
	if print_inst["hp_current"] <= 0:
		return
	var creature = GameData.CREATURES[print_inst["creature_id"]]
	var cost: float = float(creature["forge_cost"])
	if emergency_summon_active:
		cost *= 0.5

	if player_forge < cost:
		return

	player_forge -= cost
	player_active_idx = bench_index
	if emergency_summon_active:
		var max_hp = creature["hp_base"] + _get_armor_hp_bonus(print_inst)
		print_inst["hp_current"] = max(1, int(max_hp * 0.5))
		emergency_summon_active = false
		emit_signal("print_hp_changed", "player", print_inst["hp_current"], max_hp)

	player_forge = max(0.0, player_forge)
	emit_signal("forge_bar_changed", "player", player_forge)
	emit_signal("next_print_summoned", "player", print_inst)

# ─────────────────────────────────────────────────────────────────────────────
# ATTACK RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
func _resolve_attack(attacker_side: String, defender_side: String, multiplier: float = 1.0) -> void:
	var attacker = _get_active_print(attacker_side)
	var defender = _get_active_print(defender_side)
	if attacker.is_empty() or defender.is_empty():
		return

	var attacker_creature = GameData.CREATURES[attacker["creature_id"]]
	var defender_creature = GameData.CREATURES[defender["creature_id"]]

	var base_dmg: int = ceili(float(attacker_creature["bend_score"]) / 4.0)

	var weapon_bp = _equip_blueprint_id(attacker["equipment"].get("weapon", ""))
	var weapon_bonus = 0
	if weapon_bp != "" and weapon_bp in GameData.EQUIPMENT:
		weapon_bonus = GameData.EQUIPMENT[weapon_bp].get("attack_bonus", 0)

	var elem_mult = GameData.get_damage_multiplier(
		attacker_creature["element"],
		defender_creature["element"]
	)
	var is_super = elem_mult > 1.0
	var is_not   = elem_mult < 1.0

	var thorns_dmg = status_effects[defender_side].get("thorns", 0)

	var stat_mult = 1.0
	var boost = status_effects[attacker_side].get("stat_boost", null)
	if boost is Dictionary and int(boost.get("turns", 0)) > 0:
		stat_mult = 1.0 + float(boost.get("value", 0.0))

	var element_bonus = 0
	var acc_bp = _equip_blueprint_id(attacker["equipment"].get("accessory", ""))
	if acc_bp != "" and acc_bp in GameData.EQUIPMENT:
		var acc = GameData.EQUIPMENT[acc_bp]
		if acc.get("effect_type") == "element_damage_bonus" \
				and acc.get("element", "") == attacker_creature["element"]:
			element_bonus = int(acc.get("value", 0))

	var attack_bonus = int(player_attack_bonus) if attacker_side == "player" else 0
	if attacker_side == "player":
		player_attack_bonus = 0.0

	var total_dmg: int = int(ceil((base_dmg + weapon_bonus + element_bonus + attack_bonus) * elem_mult * multiplier * stat_mult))
	total_dmg = max(1, total_dmg)

	# Apply block status
	var block_val = status_effects[defender_side].get("block", 0)
	total_dmg = max(0, total_dmg - block_val)
	if block_val > 0:
		status_effects[defender_side].erase("block")

	defender["hp_current"] = max(0, defender["hp_current"] - total_dmg)
	emit_signal("attack_landed", attacker_side, total_dmg, is_super, is_not)
	emit_signal("print_hp_changed", defender_side,
		defender["hp_current"],
		defender_creature["hp_base"] + _get_armor_hp_bonus(defender))

	# Thorns retaliation
	if thorns_dmg > 0 and not attacker.is_empty():
		attacker["hp_current"] = max(0, attacker["hp_current"] - thorns_dmg)
		emit_signal("print_hp_changed", attacker_side,
			attacker["hp_current"],
			attacker_creature["hp_base"] + _get_armor_hp_bonus(attacker))

	# Weapon on-hit effects
	if weapon_bp != "" and weapon_bp in GameData.EQUIPMENT:
		var weapon = GameData.EQUIPMENT[weapon_bp]
		match weapon.get("effect_type", ""):
			"stun_chance":
				if randf() < float(weapon.get("value", 0.10)):
					status_effects[defender_side]["stunned"] = 1
					emit_signal("status_effect_applied", defender_side, "stunned", 1)
			"slow":
				status_effects[defender_side]["speed_debuff"] = int(weapon.get("value", 1))
			"burn":
				status_effects[defender_side]["burn"] = int(weapon.get("value", 1))

	# Check if defender fainted
	if defender["hp_current"] <= 0:
		emit_signal("print_defeated", defender_side, defender["creature_id"])
		_handle_print_fainted(defender_side)

# ─────────────────────────────────────────────────────────────────────────────
# ABILITY RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
func _apply_ability(ability_id: String, user_side: String, target_side: String) -> Dictionary:
	var ability = GameData.ABILITIES[ability_id]
	var result = {}

	match ability["effect_type"]:
		"damage_bonus":
			# Deals extra damage on top of normal attack
			_resolve_attack(user_side, target_side)
			var bonus = int(ability["value"])
			var defender = _get_active_print(target_side)
			if defender:
				defender["hp_current"] = max(0, defender["hp_current"] - bonus)
				var def_creature = GameData.CREATURES[defender["creature_id"]]
				emit_signal("print_hp_changed", target_side, defender["hp_current"],
					def_creature["hp_base"] + _get_armor_hp_bonus(defender))
			result = {"damage_bonus": bonus}

		"block":
			status_effects[user_side]["block"] = int(ability["value"])
			result = {"blocked": ability["value"]}

		"stun_chance":
			if randf() < float(ability["value"]):
				status_effects[target_side]["stunned"] = 1
				emit_signal("status_effect_applied", target_side, "stunned", 1)
				result = {"stunned": true}
			else:
				result = {"stunned": false}

		"heal":
			var healed = _heal_print(user_side, int(ability["value"]))
			result = {"healed": healed}

		"speed_debuff":
			status_effects[target_side]["speed_debuff"] = int(ability["value"])
			result = {"speed_debuffed": ability["value"]}

		"double_hit":
			_resolve_attack(user_side, target_side, float(ability["value"]))
			_resolve_attack(user_side, target_side, float(ability["value"]))
			result = {"double_hit": true}

		"damage_self":
			var bonus_dmg = int(ability["value"])
			var defender = _get_active_print(target_side)
			if defender:
				defender["hp_current"] = max(0, defender["hp_current"] - bonus_dmg)
				var def_creature = GameData.CREATURES[defender["creature_id"]]
				emit_signal("print_hp_changed", target_side, defender["hp_current"],
					def_creature["hp_base"] + _get_armor_hp_bonus(defender))
			var user = _get_active_print(user_side)
			if user:
				user["hp_current"] = max(0, user["hp_current"] - int(ability.get("self_damage", 0)))
				var usr_creature = GameData.CREATURES[user["creature_id"]]
				emit_signal("print_hp_changed", user_side, user["hp_current"],
					usr_creature["hp_base"] + _get_armor_hp_bonus(user))
			result = {"damage": bonus_dmg}

		"thorns":
			status_effects[user_side]["thorns"] = int(ability["value"])
			emit_signal("status_effect_applied", user_side, "thorns", 999)
			result = {"thorns": ability["value"]}

		"bench_damage":
			var dmg = int(ability["value"])
			var team = ai_team if target_side == "ai" else player_team
			var active_idx = ai_active_idx if target_side == "ai" else player_active_idx
			for i in range(team.size()):
				if i != active_idx and team[i]["hp_current"] > 0:
					team[i]["hp_current"] = max(0, team[i]["hp_current"] - dmg)
			result = {"bench_damage": dmg}

		"forge_drain":
			if target_side == "ai":
				ai_forge = max(0.0, ai_forge - float(ability["value"]))
				emit_signal("forge_bar_changed", "ai", ai_forge)
			else:
				player_forge = max(0.0, player_forge - float(ability["value"]))
				emit_signal("forge_bar_changed", "player", player_forge)
			result = {"drained": ability["value"]}

		"charge":
			if user_side == "player":
				player_charge_active = true
				player_skip_attack = true
			else:
				ai_charge_active = true
			result = {"charging": true}

		"stat_boost":
			status_effects[user_side]["stat_boost"] = {
				"value": float(ability["value"]),
				"turns": int(ability.get("duration", 2))
			}
			result = {"boost": ability["value"]}

	return result

# ─────────────────────────────────────────────────────────────────────────────
# AI LOGIC
# ─────────────────────────────────────────────────────────────────────────────
func _ai_try_summon() -> void:
	# Find next alive print in AI bench that we can afford
	for i in range(ai_team.size()):
		if i == ai_active_idx:
			continue
		var inst = ai_team[i]
		if inst["hp_current"] <= 0:
			continue
		var creature = GameData.CREATURES[inst["creature_id"]]
		if ai_forge >= float(creature["forge_cost"]):
			ai_forge -= float(creature["forge_cost"])
			ai_active_idx = i
			emit_signal("forge_bar_changed", "ai", ai_forge)
			emit_signal("next_print_summoned", "ai", inst)
			return

func _ai_should_use_ability(ai_print: Dictionary) -> bool:
	if ai_print.is_empty():
		return false
	var creature = GameData.CREATURES[ai_print["creature_id"]]
	var ability_id: String = creature["ability"]
	if ai_ability_cooldowns.get(ability_id, 0) > 0:
		return false
	# Use ability if HP is below 50% (heal) or always if damaging
	var ability = GameData.ABILITIES[ability_id]
	if ability["effect_type"] == "heal":
		var max_hp = float(creature["hp_base"])
		return float(ai_print["hp_current"]) / max_hp < 0.5
	return true  # Always use offensive abilities when available

func _ai_use_ability(ai_print: Dictionary) -> bool:
	var creature = GameData.CREATURES[ai_print["creature_id"]]
	var ability_id: String = creature["ability"]
	var ability = GameData.ABILITIES[ability_id]
	var result = _apply_ability(ability_id, "ai", "player")
	var cd = ability["cooldown"]
	ai_ability_cooldowns[ability_id] = cd
	emit_signal("ability_used", "ai", ability_id, result)
	return ability.get("effect_type") == "charge"

# ─────────────────────────────────────────────────────────────────────────────
# PRINT MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
func get_player_active_print() -> Dictionary:
	if player_active_idx < player_team.size():
		var p = player_team[player_active_idx]
		if p["hp_current"] > 0:
			return p
	return {}

func get_ai_active_print() -> Dictionary:
	if ai_active_idx < ai_team.size():
		var p = ai_team[ai_active_idx]
		if p["hp_current"] > 0:
			return p
	return {}

func _get_active_print(side: String) -> Dictionary:
	if side == "player":
		return get_player_active_print()
	return get_ai_active_print()

func _handle_print_fainted(side: String) -> void:
	# Try to auto-summon next available print
	var team = player_team if side == "player" else ai_team
	var active_idx = player_active_idx if side == "player" else ai_active_idx

	for i in range(team.size()):
		if i != active_idx and team[i]["hp_current"] > 0:
			if side == "player":
				player_active_idx = i
			else:
				ai_active_idx = i
			emit_signal("next_print_summoned", side, team[i])
			return
	# No prints left — battle ends
	_check_battle_end()

func _make_battle_copy(inst: Dictionary) -> Dictionary:
	var copy = inst.duplicate(true)
	copy["hp_current"] = SaveManager.get_print_max_hp(inst)
	return copy

func get_battle_max_hp(print_data: Dictionary) -> int:
	var creature = GameData.CREATURES[print_data["creature_id"]]
	return creature["hp_base"] + _get_armor_hp_bonus(print_data)

func _get_armor_hp_bonus(inst: Dictionary) -> int:
	var armor_bp = _equip_blueprint_id(inst["equipment"].get("armor", ""))
	if armor_bp != "" and armor_bp in GameData.EQUIPMENT:
		return GameData.EQUIPMENT[armor_bp].get("hp_bonus", 0)
	return 0

func _equip_blueprint_id(slot_value: String) -> String:
	return SaveManager.get_equipment_blueprint_id(slot_value)

func _cooldown_reduction(side: String) -> int:
	var inst = _get_active_print(side)
	if inst.is_empty():
		return 0
	var acc_bp = _equip_blueprint_id(inst["equipment"].get("accessory", ""))
	if acc_bp != "" and acc_bp in GameData.EQUIPMENT:
		var acc = GameData.EQUIPMENT[acc_bp]
		if acc.get("effect_type") == "cooldown_reduction":
			return int(acc.get("value", 0))
	return 0

func _is_stunned(side: String) -> bool:
	return status_effects[side].get("stunned", 0) > 0

func is_side_stunned(side: String) -> bool:
	return _is_stunned(side)

# ─────────────────────────────────────────────────────────────────────────────
# STATUS EFFECTS
# ─────────────────────────────────────────────────────────────────────────────
func _apply_regen_effects(side: String) -> void:
	var print_inst = _get_active_print(side)
	if print_inst.is_empty():
		return
	var acc_bp = _equip_blueprint_id(print_inst["equipment"].get("accessory", ""))
	if acc_bp != "" and acc_bp in GameData.EQUIPMENT:
		var acc = GameData.EQUIPMENT[acc_bp]
		if acc.get("effect_type") == "regen":
			_heal_print(side, int(acc["value"]))

func _tick_status_effects(side: String) -> void:
	var effects = status_effects[side]
	var to_remove = []
	for effect in effects:
		if effect == "stat_boost":
			var boost_data = effects[effect]
			if boost_data is Dictionary:
				boost_data["turns"] -= 1
				if boost_data["turns"] <= 0:
					to_remove.append(effect)
		elif effects[effect] is int:
			effects[effect] -= 1
			if effects[effect] <= 0:
				to_remove.append(effect)
	for e in to_remove:
		effects.erase(e)

func _tick_ability_cooldowns(cooldowns: Dictionary) -> void:
	for ability in cooldowns.keys():
		cooldowns[ability] -= 1
		if cooldowns[ability] <= 0:
			cooldowns.erase(ability)

# ─────────────────────────────────────────────────────────────────────────────
# HEAL
# ─────────────────────────────────────────────────────────────────────────────
func _heal_print(side: String, amount: int) -> int:
	var inst = _get_active_print(side)
	if inst.is_empty():
		return 0
	var creature = GameData.CREATURES[inst["creature_id"]]
	var max_hp: int = creature["hp_base"] + _get_armor_hp_bonus(inst)
	var old_hp: int = inst["hp_current"]
	inst["hp_current"] = min(max_hp, inst["hp_current"] + amount)
	var healed = inst["hp_current"] - old_hp
	emit_signal("print_hp_changed", side, inst["hp_current"], max_hp)
	return healed

# ─────────────────────────────────────────────────────────────────────────────
# FORGE BAR
# ─────────────────────────────────────────────────────────────────────────────
func _fill_forge(side: String, amount: float) -> void:
	var bonus = 0.0
	var inst = _get_active_print(side)
	if not inst.is_empty():
		var acc_bp = _equip_blueprint_id(inst["equipment"].get("accessory", ""))
		if acc_bp != "" and acc_bp in GameData.EQUIPMENT:
			var acc = GameData.EQUIPMENT[acc_bp]
			if acc.get("effect_type") == "forge_fill_passive":
				bonus = float(acc["value"])

	if side == "player":
		player_forge = min(10.0, player_forge + amount + bonus)
		emit_signal("forge_bar_changed", "player", player_forge)
	else:
		ai_forge = min(10.0, ai_forge + amount + bonus)
		emit_signal("forge_bar_changed", "ai", ai_forge)

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE END CHECK
# ─────────────────────────────────────────────────────────────────────────────
func _check_battle_end() -> void:
	var player_all_dead = player_team.all(func(p): return p["hp_current"] <= 0)
	var ai_all_dead = ai_team.all(func(p): return p["hp_current"] <= 0)

	if not (player_all_dead or ai_all_dead):
		return

	phase = BattlePhase.ENDED
	var player_won = ai_all_dead

	# Calculate rewards
	var rewards = {}
	if player_won:
		rewards["xp"] = current_trainer.get("reward_xp", 50)
		rewards["coins"] = current_trainer.get("reward_coins", 25)
		rewards["drop"] = _roll_battle_drop(current_trainer.get("difficulty", 1))
	else:
		rewards["xp"] = 15
		rewards["coins"] = 5
		rewards["drop"] = ""

	# Apply rewards to save
	SaveManager.add_xp(rewards["xp"])
	SaveManager.add_coins(rewards["coins"])
	if rewards["drop"] != "":
		SaveManager.add_blueprint(rewards["drop"])

	# Restore HP of player prints for next battle
	for inst in SaveManager.get_prints():
		SaveManager.restore_print_hp(inst["instance_id"])

	SaveManager.record_battle(
		current_trainer.get("id", "unknown"),
		player_won,
		rewards["xp"],
		rewards["coins"],
		rewards.get("drop", "")
	)

	for iid in _battle_team_instance_ids:
		SaveManager.record_print_battle(iid, player_won)

	if player_won:
		SteamManager.on_battle_won(
			SaveManager.data["player"]["total_wins"],
			current_trainer.get("id", "unknown")
		)
	if rewards.get("drop", "") != "":
		SteamManager.on_battle_drop(rewards["drop"])

	emit_signal("battle_ended", player_won, rewards)

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE DROP ROLL
# ─────────────────────────────────────────────────────────────────────────────
func _roll_battle_drop(difficulty: int) -> String:
	# Base 15% drop chance, scales with difficulty
	var drop_chance = 0.15 + (difficulty - 1) * 0.05  # Up to 35% at diff 5
	if randf() > drop_chance:
		return ""

	# Pick a random blueprint the player doesn't own yet
	var available = []
	for cid in GameData.CREATURES:
		if not GameData.CREATURES[cid]["is_starter"] and not SaveManager.has_blueprint(cid):
			available.append(cid)
	for eid in GameData.EQUIPMENT:
		if not SaveManager.has_blueprint(eid):
			available.append(eid)

	if available.is_empty():
		return ""

	available.shuffle()
	return available[0]
