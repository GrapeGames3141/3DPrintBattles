# TrainerSelect.gd
# Player picks an AI trainer to battle.
# Scene file: res://scenes/TrainerSelect.tscn
#
# SCENE TREE:
# TrainerSelect (Node2D)
# ├── Background (TextureRect)
# ├── UI (CanvasLayer)
# │   ├── TitleLabel (Label)          "Proving Grounds"
# │   ├── BackBtn (Button)            "← Workshop"
# │   ├── TrainerList (VBoxContainer) — populated dynamically
# │   └── TeamSelectPanel (Panel)     — shown after trainer chosen, hidden by default
# │       ├── TeamLabel (Label)       "Select 3 Prints for battle"
# │       ├── PrintList (VBoxContainer)
# │       ├── SelectedTeamLabel (Label)
# │       └── FightBtn (Button)       "Enter the Forge!"

extends Node2D

var selected_trainer: Dictionary = {}
var selected_prints: Array = []   # Array of print instance_ids
const TEAM_SIZE := 3

@onready var trainer_list: VBoxContainer = $UI/TrainerList
@onready var team_panel: Panel = $UI/TeamSelectPanel
@onready var print_list: VBoxContainer = $UI/TeamSelectPanel/PrintList
@onready var selected_team_label: Label = $UI/TeamSelectPanel/SelectedTeamLabel
@onready var fight_btn: Button = $UI/TeamSelectPanel/FightBtn

func _ready() -> void:
	team_panel.visible = false
	fight_btn.visible = false
	_build_trainer_list()

# ─────────────────────────────────────────────────────────────────────────────
# TRAINER LIST
# ─────────────────────────────────────────────────────────────────────────────
func _build_trainer_list() -> void:
	for child in trainer_list.get_children():
		child.queue_free()

	for trainer in GameData.AI_TRAINERS:
		var hbox := HBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.text = "%s  (Difficulty %d)" % [trainer["name"], trainer["difficulty"]]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		var reward_lbl := Label.new()
		reward_lbl.text = "+%d coins  +%d XP" % [trainer["reward_coins"], trainer["reward_xp"]]
		hbox.add_child(reward_lbl)

		var fight_btn_t := Button.new()
		fight_btn_t.text = "Challenge"
		fight_btn_t.pressed.connect(_on_trainer_selected.bind(trainer))
		hbox.add_child(fight_btn_t)

		trainer_list.add_child(hbox)

# ─────────────────────────────────────────────────────────────────────────────
# TRAINER SELECTED → SHOW TEAM PICKER
# ─────────────────────────────────────────────────────────────────────────────
func _on_trainer_selected(trainer: Dictionary) -> void:
	selected_trainer = trainer
	selected_prints = []
	team_panel.visible = true
	_build_print_list()
	_refresh_team_label()

func _build_print_list() -> void:
	for child in print_list.get_children():
		child.queue_free()

	var prints := SaveManager.get_prints()
	if prints.is_empty():
		var lbl := Label.new()
		lbl.text = "You have no printed creatures! Go to the Filament Market first."
		print_list.add_child(lbl)
		return

	for inst in prints:
		if inst["hp_current"] <= 0:
			continue
		var creature := GameData.CREATURES[inst["creature_id"]]
		var hbox := HBoxContainer.new()

		# Placeholder color swatch
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(32, 32)
		swatch.color = creature["placeholder_color"]
		hbox.add_child(swatch)

		var lbl := Label.new()
		lbl.text = "%s  [%s]  HP: %d/%d" % [
			creature["name"],
			creature["element"].capitalize(),
			inst["hp_current"],
			creature["hp_base"],
		]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		var toggle := CheckBox.new()
		toggle.text = "Select"
		toggle.toggled.connect(_on_print_toggled.bind(inst["instance_id"]))
		hbox.add_child(toggle)

		print_list.add_child(hbox)

func _on_print_toggled(toggled_on: bool, instance_id: String) -> void:
	if toggled_on:
		if selected_prints.size() < TEAM_SIZE and not instance_id in selected_prints:
			selected_prints.append(instance_id)
		else:
			# Reject — team full or already selected
			# Find and uncheck this box
			pass
	else:
		selected_prints.erase(instance_id)
	_refresh_team_label()

func _refresh_team_label() -> void:
	selected_team_label.text = "Team: %d / %d selected" % [selected_prints.size(), TEAM_SIZE]
	fight_btn.visible = selected_prints.size() == TEAM_SIZE

# ─────────────────────────────────────────────────────────────────────────────
# ENTER BATTLE
# ─────────────────────────────────────────────────────────────────────────────
func _on_fight_btn_pressed() -> void:
	if selected_prints.size() != TEAM_SIZE:
		return

	# Gather full print instance dicts for the selected IDs
	var team := []
	for iid in selected_prints:
		var inst := SaveManager.get_print_by_instance_id(iid)
		if not inst.is_empty():
			team.append(inst)

	SceneTransition.go_to("res://scenes/Battle.tscn", {
		"team": team,
		"trainer": selected_trainer,
	})

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")
