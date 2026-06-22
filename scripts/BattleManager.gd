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

	# Deep copy player team from passed instances
	player_team = []
	for inst in player_print_instances:
		player_team.append(_make_battle_copy(inst))
	player_active_idx = 0

	# Build AI team from trainer roster
	ai_team = []
	for creature_id in trainer["roster"]:
		var ai_inst := {
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
	phase = BattlePhase.PLAYER_TURN
	_fill_forge("player", 1.0)
	_apply_regen_effects("player")
	_tick_status_effects("player")
	_tick_ability_cooldowns(player_ability_cooldowns)
	emit_signal("turn_started", true, turn_number)

func _start_ai_turn() -> void:
	phase = BattlePhase.AI_TURN
	_fill_forge("ai", 1.0)
	_apply_regen_effects("ai")
	_tick_status_effects("ai")
	_tick_ability_cooldowns(ai_ability_cooldowns)
	emit_signal("turn_started", false, turn_number)
	# AI acts automatically after a short delay (handled by BattleScene timer)

# Called by BattleScene after AI turn delay
func ai_take_turn() -> void:
	if phase != BattlePhase.AI_TURN:
		return
	phase = BattlePhase.RESOLVING

	# AI Decision tree:
	# 1. Try to summon if forge bar full enough and bench isn't empty and no active print
	# 2. Use ability if off cooldown and it's a good time
	# 3. Auto-attack

	var ai_print := get_ai_active_print()
	if ai_print == null:
		# Try to summon
		_ai_try_summon()
		_end_ai_turn()
		return

	# Check if ability is useful
	if _ai_should_use_ability(ai_print):
		_ai_use_ability(ai_print)
	else:
		# Auto attack
		_resolve_attack("ai", "player")

	_end_ai_turn()

func _end_ai_turn() -> void:
	turn_number += 1
	_check_battle_end()
	if phase != BattlePhase.ENDED:
		_start_player_turn()

# Called by player pressing "End Turn" or by the 15-second timer
func player_end_turn() -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	phase = BattlePhase.RESOLVING

	# Auto-attack if player has an active print
	var player_print := get_player_active_print()
	if player_print != null:
		if player_charge_active:
			# Cyclone Charge: double power attack
			_resolve_attack("player", "ai", 2.5)
			player_charge_active = false
		else:
			_resolve_attack("player", "ai")

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
	var print_inst := get_player_active_print()
	if print_inst == null:
		return
	var creature := GameData.CREATURES[print_inst["creature_id"]]
	var ability_id: String = creature["ability"]

	# Check cooldown
	if player_ability_cooldowns.get(ability_id, 0) > 0:
		return

	var result := _apply_ability(ability_id, "player", "ai")
	player_ability_cooldowns[ability_id] = GameData.ABILITIES[ability_id]["cooldown"]
	emit_signal("ability_used", "player", ability_id, result)

func player_play_card(card_id: String) -> void:
	if phase != BattlePhase.PLAYER_TURN:
		return
	var card := GameData.FILAMENT_CARDS[card_id]
	var result := {}

	match card["effect_type"]:
		"forge_fill":
			_fill_forge("player", card["value"])
			result = {"forge_added": card["value"]}
		"forge_fill_attack":
			_fill_forge("player", card["forge_value"])
			# Attack bonus applied next auto-attack via flag
			result = {"forge_added": card["forge_value"], "attack_bonus": card["attack_bonus"]}
		"heal":
			var healed := _heal_print("player", card["value"])
			result = {"healed": healed}
		"emergency_summon":
			# Halve forge cost for next summon
			result = {"emergency_summon": true}
		"forge_double":
			if not arcane_filament_used:
				var new_val := min(player_forge * 2.0, 10.0)
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
	var print_inst := player_team[bench_index]
	var creature := GameData.CREATURES[print_inst["creature_id"]]
	var cost: float = float(creature["forge_cost"])

	if player_forge < cost:
		return  # Not enough forge units

	player_forge -= cost
	player_active_idx = bench_index
	emit_signal("forge_bar_changed", "player", player_forge)
	emit_signal("next_print_summoned", "player", print_inst)

# ─────────────────────────────────────────────────────────────────────────────
# ATTACK RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
func _resolve_attack(attacker_side: String, defender_side: String, multiplier: float = 1.0) -> void:
	var attacker := _get_active_print(attacker_side)
	var defender := _get_active_print(defender_side)
	if attacker == null or defender == null:
		return

	var attacker_creature := GameData.CREATURES[attacker["creature_id"]]
	var defender_creature := GameData.CREATURES[defender["creature_id"]]

	# Base damage: bend_score / 4 rounded up
	var base_dmg: int = ceili(float(attacker_creature["bend_score"]) / 4.0)

	# Weapon bonus
	var weapon_bonus := 0
	var weapon_id: String = attacker["equipment"]["weapon"]
	if weapon_id != "" and weapon_id in GameData.EQUIPMENT:
		weapon_bonus = GameData.EQUIPMENT[weapon_id].get("attack_bonus", 0)

	# Elemental multiplier
	var elem_mult := GameData.get_damage_multiplier(
		attacker_creature["element"],
		defender_creature["element"]
	)
	var is_super := elem_mult > 1.0
	var is_not   := elem_mult < 1.0

	# Apply thorns status
	var thorns_dmg := status_effects[defender_side].get("thorns", 0)

	var total_dmg: int = int(ceil((base_dmg + weapon_bonus) * elem_mult * multiplier))
	total_dmg = max(1, total_dmg)

	# Apply block status
	var block_val := status_effects[defender_side].get("block", 0)
	total_dmg = max(0, total_dmg - block_val)
	if block_val > 0:
		status_effects[defender_side].erase("block")

	defender["hp_current"] = max(0, defender["hp_current"] - total_dmg)
	emit_signal("attack_landed", attacker_side, total_dmg, is_super, is_not)
	emit_signal("print_hp_changed", defender_side,
		defender["hp_current"],
		defender_creature["hp_base"] + _get_armor_hp_bonus(defender))

	# Thorns retaliation
	if thorns_dmg > 0 and attacker != null:
		attacker["hp_current"] = max(0, attacker["hp_current"] - thorns_dmg)
		emit_signal("print_hp_changed", attacker_side,
			attacker["hp_current"],
			attacker_creature["hp_base"] + _get_armor_hp_bonus(attacker))

	# Check if defender fainted
	if defender["hp_current"] <= 0:
		emit_signal("print_defeated", defender_side, defender["creature_id"])
		_handle_print_fainted(defender_side)

# ─────────────────────────────────────────────────────────────────────────────
# ABILITY RESOLUTION
# ─────────────────────────────────────────────────────────────────────────────
func _apply_ability(ability_id: String, user_side: String, target_side: String) -> Dictionary:
	var ability := GameData.ABILITIES[ability_id]
	var result := {}

	match ability["effect_type"]:
		"damage_bonus":
			# Deals extra damage on top of normal attack
			_resolve_attack(user_side, target_side)
			var bonus := int(ability["value"])
			var defender := _get_active_print(target_side)
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
			var healed := _heal_print(user_side, int(ability["value"]))
			result = {"healed": healed}

		"speed_debuff":
			status_effects[target_side]["speed_debuff"] = int(ability["value"])
			result = {"speed_debuffed": ability["value"]}

		"double_hit":
			_resolve_attack(user_side, target_side, float(ability["value"]))
			_resolve_attack(user_side, target_side, float(ability["value"]))
			result = {"double_hit": true}

		"damage_self":
			var bonus_dmg := int(ability["value"])
			var defender := _get_active_print(target_side)
			if defender:
				defender["hp_current"] = max(0, defender["hp_current"] - bonus_dmg)
				var def_creature = GameData.CREATURES[defender["creature_id"]]
				emit_signal("print_hp_changed", target_side, defender["hp_current"],
					def_creature["hp_base"] + _get_armor_hp_bonus(defender))
			var user := _get_active_print(user_side)
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
			var dmg := int(ability["value"])
			var team := ai_team if target_side == "ai" else player_team
			var active_idx := ai_active_idx if target_side == "ai" else player_active_idx
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
			# Skip attack this turn, set charge flag
			if user_side == "player":
				player_charge_active = true
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
		var inst := ai_team[i]
		if inst["hp_current"] <= 0:
			continue
		var creature := GameData.CREATURES[inst["creature_id"]]
		if ai_forge >= float(creature["forge_cost"]):
			ai_forge -= float(creature["forge_cost"])
			ai_active_idx = i
			emit_signal("forge_bar_changed", "ai", ai_forge)
			emit_signal("next_print_summoned", "ai", inst)
			return

func _ai_should_use_ability(ai_print: Dictionary) -> bool:
	if ai_print == null:
		return false
	var creature := GameData.CREATURES[ai_print["creature_id"]]
	var ability_id: String = creature["ability"]
	if ai_ability_cooldowns.get(ability_id, 0) > 0:
		return false
	# Use ability if HP is below 50% (heal) or always if damaging
	var ability := GameData.ABILITIES[ability_id]
	if ability["effect_type"] == "heal":
		var max_hp := float(creature["hp_base"])
		return float(ai_print["hp_current"]) / max_hp < 0.5
	return true  # Always use offensive abilities when available

func _ai_use_ability(ai_print: Dictionary) -> void:
	var creature := GameData.CREATURES[ai_print["creature_id"]]
	var ability_id: String = creature["ability"]
	var result := _apply_ability(ability_id, "ai", "player")
	ai_ability_cooldowns[ability_id] = GameData.ABILITIES[ability_id]["cooldown"]
	emit_signal("ability_used", "ai", ability_id, result)

# ─────────────────────────────────────────────────────────────────────────────
# PRINT MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
func get_player_active_print() -> Dictionary:
	if player_active_idx < player_team.size():
		var p := player_team[player_active_idx]
		if p["hp_current"] > 0:
			return p
	return {}

func get_ai_active_print() -> Dictionary:
	if ai_active_idx < ai_team.size():
		var p := ai_team[ai_active_idx]
		if p["hp_current"] > 0:
			return p
	return {}

func _get_active_print(side: String) -> Dictionary:
	if side == "player":
		return get_player_active_print()
	return get_ai_active_print()

func _handle_print_fainted(side: String) -> void:
	# Try to auto-summon next available print
	var team := player_team if side == "player" else ai_team
	var active_idx := player_active_idx if side == "player" else ai_active_idx

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
	var copy := inst.duplicate(true)
	# Apply equipment HP bonuses
	var armor_id: String = inst["equipment"]["armor"]
	if armor_id != "" and armor_id in GameData.EQUIPMENT:
		copy["hp_current"] = GameData.CREATURES[inst["creature_id"]]["hp_base"] + \
			GameData.EQUIPMENT[armor_id]["hp_bonus"]
	return copy

func _get_armor_hp_bonus(inst: Dictionary) -> int:
	var armor_id: String = inst["equipment"].get("armor", "")
	if armor_id != "" and armor_id in GameData.EQUIPMENT:
		return GameData.EQUIPMENT[armor_id].get("hp_bonus", 0)
	return 0

# ─────────────────────────────────────────────────────────────────────────────
# STATUS EFFECTS
# ─────────────────────────────────────────────────────────────────────────────
func _apply_regen_effects(side: String) -> void:
	# Tidal Core accessory regen
	var print_inst := _get_active_print(side)
	if print_inst == null or print_inst.is_empty():
		return
	var acc_id: String = print_inst["equipment"].get("accessory", "")
	if acc_id != "" and acc_id in GameData.EQUIPMENT:
		var acc := GameData.EQUIPMENT[acc_id]
		if acc.get("effect_type") == "regen":
			_heal_print(side, int(acc["value"]))

func _tick_status_effects(side: String) -> void:
	var effects := status_effects[side]
	var to_remove := []
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
	var inst := _get_active_print(side)
	if inst == null or inst.is_empty():
		return 0
	var creature := GameData.CREATURES[inst["creature_id"]]
	var max_hp: int = creature["hp_base"] + _get_armor_hp_bonus(inst)
	var old_hp: int = inst["hp_current"]
	inst["hp_current"] = min(max_hp, inst["hp_current"] + amount)
	var healed := inst["hp_current"] - old_hp
	emit_signal("print_hp_changed", side, inst["hp_current"], max_hp)
	return healed

# ─────────────────────────────────────────────────────────────────────────────
# FORGE BAR
# ─────────────────────────────────────────────────────────────────────────────
func _fill_forge(side: String, amount: float) -> void:
	# Check Filament Ring accessory
	var bonus := 0.0
	var inst := _get_active_print(side)
	if inst != null and not inst.is_empty():
		var acc_id: String = inst["equipment"].get("accessory", "")
		if acc_id != "" and acc_id in GameData.EQUIPMENT:
			var acc := GameData.EQUIPMENT[acc_id]
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
	var player_all_dead := player_team.all(func(p): return p["hp_current"] <= 0)
	var ai_all_dead := ai_team.all(func(p): return p["hp_current"] <= 0)

	if not (player_all_dead or ai_all_dead):
		return

	phase = BattlePhase.ENDED
	var player_won := ai_all_dead

	# Calculate rewards
	var rewards := {}
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

	emit_signal("battle_ended", player_won, rewards)

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE DROP ROLL
# ─────────────────────────────────────────────────────────────────────────────
func _roll_battle_drop(difficulty: int) -> String:
	# Base 15% drop chance, scales with difficulty
	var drop_chance := 0.15 + (difficulty - 1) * 0.05  # Up to 35% at diff 5
	if randf() > drop_chance:
		return ""

	# Pick a random blueprint the player doesn't own yet
	var available := []
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
