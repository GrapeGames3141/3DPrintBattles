# SteamManager.gd
# Autoload — add as "SteamManager" in Project Settings > Autoload
# Handles Steam achievements and initialization via GodotSteam plugin.
# Safe to include before GodotSteam is installed — all calls are
# guarded with Engine.has_singleton("Steam") checks, so the game
# runs normally without Steam during development.
#
# SETUP REQUIRED (Phase 4):
# 1. Download GodotSteam from https://godotsteam.com
# 2. Replace your Godot editor with the GodotSteam version
# 3. Create steam_appid.txt in project root with your App ID
# 4. Add Steam autoload in project.godot

extends Node

# ─────────────────────────────────────────────────────────────────────────────
# ACHIEVEMENT IDs
# These must match EXACTLY what you create in Steamworks dashboard
# Steamworks > Your App > Achievements > Create New Achievement
# ─────────────────────────────────────────────────────────────────────────────
const ACHIEVEMENTS = {
	# Battle achievements
	"FIRST_WIN":          "Win your first battle",
	"BATTLES_10":         "Win 10 battles",
	"BATTLES_50":         "Win 50 battles",
	"BATTLES_100":        "Win 100 battles",
	"BEAT_FORGE_MASTER":  "Defeat the Forge Master",

	# Collection achievements
	"FIRST_BLUEPRINT":    "Purchase your first blueprint",
	"FIRST_RARE":         "Obtain a Rare blueprint",
	"FIRST_EPIC":         "Obtain an Epic blueprint",
	"FIRST_LEGENDARY":    "Obtain a Legendary blueprint",
	"FIRST_PRINT":        "Print your first creature",
	"COLLECTION_5":       "Own 5 different printed creatures",
	"COLLECTION_10":      "Own 10 different printed creatures",
	"COLLECTION_15":      "Own all 15 launch creatures",
	"FIRST_EQUIPMENT":    "Equip your first piece of gear",
	"FULL_LOADOUT":       "Equip a print with armor, weapon, AND accessory",

	# Academy achievements
	"FIRST_QUEST":        "Complete your first Academy quest",
	"THREE_STARS":        "Earn 3 stars on any Academy quest",
	"ACADEMY_ALL":        "Complete all Academy quest types",

	# Progression achievements
	"LEVEL_5":            "Reach Spool Level 5",
	"LEVEL_10":           "Reach Spool Level 10",
	"LEVEL_20":           "Reach Spool Level 20",
	"FIRST_DROP":         "Receive a battle drop blueprint",
	"FORGEDEX_HALF":      "Discover 8 creatures in the Forgedex",
	"FORGEDEX_FULL":      "Discover all 15 launch creatures",
}

var _steam_initialized = false

# ─────────────────────────────────────────────────────────────────────────────
# INIT
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		print("[SteamManager] Steam not available — running without Steam features.")
		return

	var steam = Engine.get_singleton("Steam")
	var init_result = steam.steamInit()

	if init_result["status"] != 1:
		push_warning("[SteamManager] Steam init failed: %s" % str(init_result))
		return

	_steam_initialized = true
	print("[SteamManager] Steam initialized. App ID: %d" % steam.getAppID())

func _process(_delta: float) -> void:
	if _steam_initialized and Engine.has_singleton("Steam"):
		Engine.get_singleton("Steam").run_callbacks()

# ─────────────────────────────────────────────────────────────────────────────
# UNLOCK ACHIEVEMENT
# Call this from anywhere: SteamManager.unlock("FIRST_WIN")
# ─────────────────────────────────────────────────────────────────────────────
func unlock(achievement_id: String) -> void:
	if not achievement_id in ACHIEVEMENTS:
		push_warning("[SteamManager] Unknown achievement: %s" % achievement_id)
		return

	if not _steam_initialized:
		print("[SteamManager] Achievement would unlock (no Steam): %s" % achievement_id)
		return

	var steam = Engine.get_singleton("Steam")
	steam.setAchievement(achievement_id)
	steam.storeStats()
	print("[SteamManager] Achievement unlocked: %s" % achievement_id)

# ─────────────────────────────────────────────────────────────────────────────
# ACHIEVEMENT TRIGGERS
# Call these from the appropriate game systems.
# BattleManager, SaveManager, and Academy call these after events.
# ─────────────────────────────────────────────────────────────────────────────
func on_battle_won(total_wins: int, trainer_id: String) -> void:
	if total_wins == 1:    unlock("FIRST_WIN")
	if total_wins >= 10:   unlock("BATTLES_10")
	if total_wins >= 50:   unlock("BATTLES_50")
	if total_wins >= 100:  unlock("BATTLES_100")
	if trainer_id == "trainer_forge_master":
		unlock("BEAT_FORGE_MASTER")

func on_blueprint_acquired(blueprint_id: String) -> void:
	var total = SaveManager.data["blueprints_owned"].size()
	if total == 1:
		unlock("FIRST_BLUEPRINT")

	# Check rarity
	var rarity = 0
	if blueprint_id in GameData.CREATURES:
		rarity = GameData.CREATURES[blueprint_id]["rarity"]
	elif blueprint_id in GameData.EQUIPMENT:
		rarity = GameData.EQUIPMENT[blueprint_id]["rarity"]

	match rarity:
		3: unlock("FIRST_RARE")
		4: unlock("FIRST_EPIC")
		5: unlock("FIRST_LEGENDARY")

func on_print_created() -> void:
	unlock("FIRST_PRINT")
	var count = SaveManager.get_prints().size()
	if count >= 5:   unlock("COLLECTION_5")
	if count >= 10:  unlock("COLLECTION_10")
	if count >= 15:  unlock("COLLECTION_15")

func on_equipment_equipped() -> void:
	unlock("FIRST_EQUIPMENT")
	# Check for full loadout
	for inst in SaveManager.get_prints():
		var eq = inst["equipment"]
		if eq["armor"] != "" and eq["weapon"] != "" and eq["accessory"] != "":
			unlock("FULL_LOADOUT")
			break

func on_academy_quest_completed(quest_type: String, stars: int) -> void:
	unlock("FIRST_QUEST")
	if stars == 3:
		unlock("THREE_STARS")
	# Check if all quest types attempted
	var progress = SaveManager.data["academy_progress"]
	if progress.size() >= 4:
		unlock("ACADEMY_ALL")

func on_level_up(new_level: int) -> void:
	if new_level >= 5:   unlock("LEVEL_5")
	if new_level >= 10:  unlock("LEVEL_10")
	if new_level >= 20:  unlock("LEVEL_20")

func on_battle_drop(drop_id: String) -> void:
	if drop_id != "":
		unlock("FIRST_DROP")

func on_forgedex_update() -> void:
	var discovered = 0
	for cid in GameData.CREATURES:
		var s = SaveManager.get_forgedex_status(cid)
		if s == "owned" or s == "seen":
			discovered += 1
	if discovered >= 8:   unlock("FORGEDEX_HALF")
	if discovered >= 15:  unlock("FORGEDEX_FULL")
