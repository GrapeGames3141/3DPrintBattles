# SaveManager.gd
# Autoload singleton — add to Project > Project Settings > Autoload as "SaveManager"
# Handles all local save/load. No backend required.
# Save file location: user://save_data.json (Godot manages this per OS)
# On Steam: enable Steam Cloud Save in Godot's Steam export settings to sync automatically.

extends Node

const SAVE_PATH = "user://save_data.json"
const SAVE_VERSION = 1  # Increment when save format changes to handle migration

# ─────────────────────────────────────────────────────────────────────────────
# DEFAULT SAVE STRUCTURE
# This is what a brand-new save file looks like.
# ─────────────────────────────────────────────────────────────────────────────
var _defaults = {
	"version": SAVE_VERSION,
	"player": {
		"spool_level": 1,
		"xp": 0,
		"coins": 150,         # Starting coins — room for shop after 3 starter prints
		"starter_chosen": false,
		"starter_id": "",
		"total_battles": 0,
		"total_wins": 0,
		"last_login_date": "",
		"daily_login_claimed": false,
	},
	"blueprints_owned": [],    # Array of creature/equipment IDs (permanent)
	"prints_owned": [],        # Array of print instance dicts (see _make_print_instance)
	"equipment_owned": [],     # Array of equipment instance dicts
	"forgedex": {},            # { creature_id: "owned" | "seen" }
	"shop_state": {
		"slots": [],           # Array of 12 blueprint/equipment IDs currently in shop
		"refresh_timestamp": 0,# Unix time of last refresh
	},
	"academy_progress": {},    # { quest_type: { best_stars, plays_today, last_played } }
	"battle_history": [],      # Last 20 battles
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"music_enabled": true,
		"sfx_enabled": true,
		"ui_scale": 2.0,
		"fullscreen": false,
	},
	"spool_upgrades": [],      # IDs of purchased spool upgrades
}

# Live data — populated on load
var data = {}

# ─────────────────────────────────────────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	load_game()
	_handle_daily_login()

# ─────────────────────────────────────────────────────────────────────────────
# LOAD
# ─────────────────────────────────────────────────────────────────────────────
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _defaults.duplicate(true)
		print("[SaveManager] No save found — starting fresh.")
		save_game()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Could not open save file. Using defaults.")
		data = _defaults.duplicate(true)
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_string)
	if err != OK:
		push_error("[SaveManager] Save file corrupted. Using defaults.")
		data = _defaults.duplicate(true)
		save_game()
		return

	data = json.get_data()
	_merge_missing_defaults(["settings"])
	_migrate_save()
	print("[SaveManager] Save loaded. Player level: %d, Coins: %d" % [
		data["player"]["spool_level"],
		data["player"]["coins"]
	])

# ─────────────────────────────────────────────────────────────────────────────
# SAVE
# ─────────────────────────────────────────────────────────────────────────────
func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Could not write save file!")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# ─────────────────────────────────────────────────────────────────────────────
# MIGRATION — handle old save format versions
# ─────────────────────────────────────────────────────────────────────────────
func _migrate_save() -> void:
	var saved_version: int = data.get("version", 0)
	if saved_version == SAVE_VERSION:
		return
	# Future: add migration logic here when SAVE_VERSION increments
	data["version"] = SAVE_VERSION
	save_game()

func _merge_missing_defaults(keys: Array) -> void:
	for key in keys:
		if not key in _defaults:
			continue
		if not data.has(key) or typeof(data[key]) != typeof(_defaults[key]):
			data[key] = _defaults[key].duplicate(true)
			continue
		if typeof(_defaults[key]) == TYPE_DICTIONARY:
			for sub_key in _defaults[key]:
				if not sub_key in data[key]:
					data[key][sub_key] = _defaults[key][sub_key]

# ─────────────────────────────────────────────────────────────────────────────
# DAILY LOGIN
# ─────────────────────────────────────────────────────────────────────────────
func _handle_daily_login() -> void:
	var today = Time.get_date_string_from_system()
	if data["player"]["last_login_date"] != today:
		data["player"]["last_login_date"] = today
		data["player"]["daily_login_claimed"] = false
		# Reset academy daily play counts
		for quest_type in data["academy_progress"]:
			data["academy_progress"][quest_type]["plays_today"] = 0
		save_game()

func claim_daily_login() -> int:
	if data["player"]["daily_login_claimed"]:
		return 0
	var reward = 10
	add_coins(reward)
	data["player"]["daily_login_claimed"] = true
	save_game()
	return reward

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER STATS
# ─────────────────────────────────────────────────────────────────────────────
func get_coins() -> int:
	return data["player"]["coins"]

func add_coins(amount: int) -> void:
	data["player"]["coins"] = max(0, data["player"]["coins"] + amount)
	save_game()

func spend_coins(amount: int) -> bool:
	if data["player"]["coins"] < amount:
		return false
	data["player"]["coins"] -= amount
	save_game()
	return true

func get_xp() -> int:
	return data["player"]["xp"]

func add_xp(amount: int) -> void:
	data["player"]["xp"] += amount
	_check_level_up()
	save_game()

func get_level() -> int:
	return data["player"]["spool_level"]

# XP thresholds per level (level = index)
const XP_THRESHOLDS = [
	0, 100, 250, 500, 800, 1200, 1800, 2600, 3600, 5000,
	7000, 9500, 12500, 16000, 20000, 25000, 31000, 38000, 46000, 55000
]

func get_xp_for_next_level() -> int:
	var lvl = get_level()
	if lvl >= XP_THRESHOLDS.size():
		return 999999
	return XP_THRESHOLDS[lvl]

func get_xp_into_current_level() -> int:
	var lvl = get_level()
	var floor_xp = XP_THRESHOLDS[lvl - 1] if lvl > 0 and lvl - 1 < XP_THRESHOLDS.size() else 0
	return max(0, get_xp() - floor_xp)

func get_xp_span_for_current_level() -> int:
	var lvl = get_level()
	if lvl >= XP_THRESHOLDS.size():
		return 1
	var floor_xp = XP_THRESHOLDS[lvl - 1] if lvl > 0 else 0
	return max(1, get_xp_for_next_level() - floor_xp)

func _check_level_up() -> void:
	while get_level() < XP_THRESHOLDS.size() and get_xp() >= get_xp_for_next_level():
		data["player"]["spool_level"] += 1
		print("[SaveManager] LEVEL UP! Now level %d" % get_level())
		AudioManager.play_sfx("levelup")
		SteamManager.on_level_up(get_level())

# ─────────────────────────────────────────────────────────────────────────────
# STARTER SELECTION
# ─────────────────────────────────────────────────────────────────────────────
func has_chosen_starter() -> bool:
	return data["player"]["starter_chosen"]

func choose_starter(creature_id: String) -> void:
	data["player"]["starter_id"] = creature_id
	data["player"]["starter_chosen"] = true
	# Give the player the blueprint and one printed copy
	add_blueprint(creature_id)
	for i in range(3):
		data["prints_owned"].append(_make_print_instance(creature_id))
	# Mark in forgedex
	data["forgedex"][creature_id] = "owned"
	save_game()
	SteamManager.on_print_created()
	SteamManager.on_forgedex_update()

# ─────────────────────────────────────────────────────────────────────────────
# BLUEPRINTS (permanent ownership)
# ─────────────────────────────────────────────────────────────────────────────
func has_blueprint(id: String) -> bool:
	return id in data["blueprints_owned"]

func add_blueprint(id: String) -> void:
	if not has_blueprint(id):
		data["blueprints_owned"].append(id)
		# Update forgedex if it's a creature
		if id in GameData.CREATURES:
			if not data["forgedex"].has(id):
				data["forgedex"][id] = "owned"
			else:
				data["forgedex"][id] = "owned"
		save_game()
		SteamManager.on_blueprint_acquired(id)
		SteamManager.on_forgedex_update()

func buy_blueprint(id: String) -> bool:
	var cost: int = 0
	if id in GameData.CREATURES:
		cost = GameData.CREATURES[id]["blueprint_cost"]
	elif id in GameData.EQUIPMENT:
		cost = GameData.EQUIPMENT[id]["blueprint_cost"]
	else:
		push_error("[SaveManager] Unknown blueprint id: %s" % id)
		return false

	if not spend_coins(cost):
		return false
	add_blueprint(id)
	return true

# ─────────────────────────────────────────────────────────────────────────────
# PRINTS (creature instances)
# ─────────────────────────────────────────────────────────────────────────────
func _make_print_instance(creature_id: String) -> Dictionary:
	var creature = GameData.CREATURES[creature_id]
	return {
		"instance_id": _generate_id(),
		"creature_id": creature_id,
		"hp_current": creature["hp_base"],
		"equipment": {"armor": "", "weapon": "", "accessory": ""},
		"times_battled": 0,
		"times_won": 0,
	}

func get_prints() -> Array:
	return data["prints_owned"]

func print_creature(creature_id: String) -> bool:
	if not has_blueprint(creature_id):
		return false
	var cost: int = GameData.CREATURES[creature_id]["print_cost"]
	if not spend_coins(cost):
		return false
	var inst = _make_print_instance(creature_id)
	data["prints_owned"].append(inst)
	save_game()
	SteamManager.on_print_created()
	return true

func get_print_by_instance_id(instance_id: String) -> Dictionary:
	for p in data["prints_owned"]:
		if p["instance_id"] == instance_id:
			return p
	return {}

func restore_print_hp(instance_id: String) -> void:
	for p in data["prints_owned"]:
		if p["instance_id"] == instance_id:
			p["hp_current"] = get_print_max_hp(p)
			save_game()
			return

func get_equipment_blueprint_id(equipment_instance_id: String) -> String:
	if equipment_instance_id == "":
		return ""
	# Legacy saves may store blueprint keys directly in slots.
	if equipment_instance_id in GameData.EQUIPMENT:
		return equipment_instance_id
	var inst = _get_equipment_instance(equipment_instance_id)
	if inst.is_empty():
		return ""
	return inst["equipment_id"]

func get_equipment_name(equipment_instance_id: String) -> String:
	var blueprint_id = get_equipment_blueprint_id(equipment_instance_id)
	if blueprint_id == "" or not blueprint_id in GameData.EQUIPMENT:
		return ""
	return GameData.EQUIPMENT[blueprint_id]["name"]

func get_print_max_hp(print_inst: Dictionary) -> int:
	var creature = GameData.CREATURES[print_inst["creature_id"]]
	var max_hp: int = creature["hp_base"]
	var armor_bp = get_equipment_blueprint_id(print_inst["equipment"].get("armor", ""))
	if armor_bp != "" and armor_bp in GameData.EQUIPMENT:
		max_hp += GameData.EQUIPMENT[armor_bp].get("hp_bonus", 0)
	return max_hp

func unequip_slot(print_instance_id: String, slot: String) -> void:
	var print_inst = get_print_by_instance_id(print_instance_id)
	if print_inst.is_empty():
		return
	var slot_iid: String = print_inst["equipment"].get(slot, "")
	if slot_iid == "":
		return
	var eq_inst = _get_equipment_instance(slot_iid)
	if not eq_inst.is_empty():
		eq_inst["attached_to"] = ""
	print_inst["equipment"][slot] = ""
	save_game()
	SteamManager.on_equipment_equipped()

# ─────────────────────────────────────────────────────────────────────────────
# EQUIPMENT INSTANCES
# ─────────────────────────────────────────────────────────────────────────────
func _make_equipment_instance(equipment_id: String) -> Dictionary:
	return {
		"instance_id": _generate_id(),
		"equipment_id": equipment_id,
		"attached_to": "",  # print instance_id or empty
	}

func get_equipment_owned() -> Array:
	return data["equipment_owned"]

func print_equipment(equipment_id: String) -> bool:
	if not has_blueprint(equipment_id):
		return false
	var cost: int = GameData.EQUIPMENT[equipment_id]["print_cost"]
	if not spend_coins(cost):
		return false
	var inst = _make_equipment_instance(equipment_id)
	data["equipment_owned"].append(inst)
	save_game()
	return true

func equip_item(equipment_instance_id: String, print_instance_id: String) -> bool:
	var eq_inst = _get_equipment_instance(equipment_instance_id)
	if eq_inst.is_empty():
		return false
	var print_inst = get_print_by_instance_id(print_instance_id)
	if print_inst.is_empty():
		return false

	var eq_data = GameData.EQUIPMENT[eq_inst["equipment_id"]]
	var slot: String = eq_data["type"]  # "armor" | "weapon" | "accessory"

	# Unequip whatever is in that slot already
	if print_inst["equipment"][slot] != "":
		var old_eq = _get_equipment_instance_by_equip_id_on_print(slot, print_instance_id)
		if not old_eq.is_empty():
			old_eq["attached_to"] = ""

	print_inst["equipment"][slot] = equipment_instance_id
	eq_inst["attached_to"] = print_instance_id
	save_game()
	SteamManager.on_equipment_equipped()
	return true

func _get_equipment_instance(instance_id: String) -> Dictionary:
	for e in data["equipment_owned"]:
		if e["instance_id"] == instance_id:
			return e
	return {}

func _get_equipment_instance_by_equip_id_on_print(slot: String, print_instance_id: String) -> Dictionary:
	var print_inst = get_print_by_instance_id(print_instance_id)
	if print_inst.is_empty():
		return {}
	var eq_iid: String = print_inst["equipment"][slot]
	if eq_iid == "":
		return {}
	return _get_equipment_instance(eq_iid)

# ─────────────────────────────────────────────────────────────────────────────
# FORGEDEX
# ─────────────────────────────────────────────────────────────────────────────
func mark_seen(creature_id: String) -> void:
	if not data["forgedex"].has(creature_id):
		data["forgedex"][creature_id] = "seen"
		save_game()
		SteamManager.on_forgedex_update()

func get_forgedex_status(creature_id: String) -> String:
	return data["forgedex"].get(creature_id, "unknown")

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE HISTORY
# ─────────────────────────────────────────────────────────────────────────────
func record_print_battle(instance_id: String, won: bool) -> void:
	for p in data["prints_owned"]:
		if p["instance_id"] == instance_id:
			p["times_battled"] = p.get("times_battled", 0) + 1
			if won:
				p["times_won"] = p.get("times_won", 0) + 1
			save_game()
			return

func record_battle(trainer_id: String, won: bool, xp: int, coins: int, drop_id: String = "") -> void:
	data["player"]["total_battles"] += 1
	if won:
		data["player"]["total_wins"] += 1

	var entry = {
		"trainer_id": trainer_id,
		"result": "win" if won else "loss",
		"xp_earned": xp,
		"coins_earned": coins,
		"drop_id": drop_id,
		"timestamp": Time.get_unix_time_from_system(),
	}
	data["battle_history"].push_front(entry)
	if data["battle_history"].size() > 20:
		data["battle_history"].pop_back()
	save_game()

# ─────────────────────────────────────────────────────────────────────────────
# SHOP STATE
# ─────────────────────────────────────────────────────────────────────────────
func get_shop_slots() -> Array:
	_refresh_shop_if_needed()
	return data["shop_state"]["slots"]

func _refresh_shop_if_needed() -> void:
	var now = Time.get_unix_time_from_system()
	var last = data["shop_state"]["refresh_timestamp"]
	var seconds_in_day = 86400
	if now - last >= seconds_in_day or data["shop_state"]["slots"].is_empty():
		_generate_shop_rotation()

func _generate_shop_rotation() -> void:
	var player_level = get_level()
	var pool = []

	# Build pool of available blueprints by player level
	for cid in GameData.CREATURES:
		var c = GameData.CREATURES[cid]
		if c["is_starter"]:
			continue
		if c["rarity"] <= _max_rarity_for_level(player_level):
			pool.append({"id": cid, "kind": "creature"})

	for eid in GameData.EQUIPMENT:
		var e = GameData.EQUIPMENT[eid]
		if e["rarity"] <= _max_rarity_for_level(player_level):
			pool.append({"id": eid, "kind": "equipment"})

	pool.shuffle()
	var slots = []
	for i in range(min(12, pool.size())):
		slots.append(pool[i])

	data["shop_state"]["slots"] = slots
	data["shop_state"]["refresh_timestamp"] = Time.get_unix_time_from_system()
	save_game()

func _max_rarity_for_level(level: int) -> int:
	if level < 6:   return 1   # Common only
	if level < 11:  return 2   # Uncommon
	if level < 21:  return 3   # Rare
	if level < 36:  return 4   # Epic
	return 5                   # Legendary

# ─────────────────────────────────────────────────────────────────────────────
# ACADEMY PROGRESS
# ─────────────────────────────────────────────────────────────────────────────
func record_academy_quest(quest_type: String, stars: int, coins_earned: int) -> int:
	var today = Time.get_date_string_from_system()
	if not data["academy_progress"].has(quest_type):
		data["academy_progress"][quest_type] = {"best_stars": 0, "plays_today": 0, "last_played": ""}

	var p = data["academy_progress"][quest_type]
	if p["last_played"] != today:
		p["plays_today"] = 0
		p["last_played"] = today

	p["plays_today"] += 1
	if stars > p["best_stars"]:
		p["best_stars"] = stars

	# Diminishing returns starting on the 4th play of the same quest today
	var actual_coins = coins_earned
	if p["plays_today"] > 3:
		actual_coins = int(coins_earned * 0.25)

	add_coins(actual_coins)
	save_game()
	SteamManager.on_academy_quest_completed(quest_type, stars)
	return actual_coins

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _generate_id() -> String:
	return "%d_%d" % [Time.get_unix_time_from_system(), randi()]
