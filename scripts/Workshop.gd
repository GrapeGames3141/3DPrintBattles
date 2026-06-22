# Workshop.gd
# Main hub scene — player's home base.
# This scene is shown after starter selection and after every battle.
# Scene file: res://scenes/Workshop.tscn
#
# SCENE TREE (build this in Godot editor):
# Workshop (Node2D)
# ├── Background (TextureRect) — workshop background art
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer)
# │   │   ├── SpoolIcon (TextureRect)
# │   │   ├── LevelLabel (Label)          "Lv. 5"
# │   │   ├── XPBar (ProgressBar)
# │   │   ├── CoinIcon (TextureRect)
# │   │   └── CoinLabel (Label)           "1,240"
# │   ├── LocationButtons (VBoxContainer)
# │   │   ├── BattleBtn (Button)          "Proving Grounds ⚔"
# │   │   ├── ShopBtn (Button)            "Filament Market 🛒"
# │   │   ├── AcademyBtn (Button)         "The Academy 🎓"
# │   │   ├── ForgedexBtn (Button)        "Forgedex 📖"
# │   │   └── PrintYardBtn (Button)       "Print Yard 🐾"
# │   └── DailyLoginPopup (Panel)         — hidden by default
# └── PrintYardViewport (SubViewportContainer) — creature playground

extends Node2D

@onready var level_label: Label = $UI/Root/TopBarPanel/TopBar/LevelLabel
@onready var xp_bar: ProgressBar = $UI/Root/TopBarPanel/TopBar/XPBar
@onready var coin_label: Label = $UI/Root/TopBarPanel/TopBar/CoinLabel
@onready var daily_popup: Panel = $UI/Root/DailyLoginPopup

func _ready() -> void:
	_refresh_hud()
	_check_daily_login()
	_check_starter()

# ─────────────────────────────────────────────────────────────────────────────
# SCENE DATA (passed from SceneTransition)
# ─────────────────────────────────────────────────────────────────────────────
func receive_data(_data: Dictionary) -> void:
	_refresh_hud()

# ─────────────────────────────────────────────────────────────────────────────
# HUD
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_hud() -> void:
	level_label.text = "Lv. %d" % SaveManager.get_level()
	xp_bar.value = SaveManager.get_xp()
	xp_bar.max_value = SaveManager.get_xp_for_next_level()
	coin_label.text = "%d" % SaveManager.get_coins()

# ─────────────────────────────────────────────────────────────────────────────
# STARTER CHECK
# ─────────────────────────────────────────────────────────────────────────────
func _check_starter() -> void:
	if not SaveManager.has_chosen_starter():
		SceneTransition.go_to("res://scenes/StarterSelection.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# DAILY LOGIN
# ─────────────────────────────────────────────────────────────────────────────
func _check_daily_login() -> void:
	var reward = SaveManager.claim_daily_login()
	if reward > 0:
		daily_popup.visible = true
		var popup_label: Label = daily_popup.get_node("Label")
		if popup_label:
			popup_label.text = "Daily Login Bonus!\n+%d Forge Coins" % reward
		_refresh_hud()

func _on_daily_popup_close_pressed() -> void:
	daily_popup.visible = false

# ─────────────────────────────────────────────────────────────────────────────
# NAVIGATION BUTTONS
# ─────────────────────────────────────────────────────────────────────────────
func _on_battle_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/TrainerSelect.tscn")

func _on_shop_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Shop.tscn")

func _on_academy_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Academy.tscn")

func _on_forgedex_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Forgedex.tscn")

func _on_print_yard_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/PrintYard.tscn")
