# TrainerSelect.gd
# Player picks an AI trainer to battle.

extends Node2D

var selected_trainer: Dictionary = {}
var selected_prints: Array = []
var _print_toggles: Dictionary = {}
const TEAM_SIZE = 3

@onready var trainer_list: VBoxContainer = $UI/TrainerList
@onready var team_panel: Panel = $UI/TeamSelectPanel
@onready var print_list: VBoxContainer = $UI/TeamSelectPanel/PrintList
@onready var selected_team_label: Label = $UI/TeamSelectPanel/SelectedTeamLabel
@onready var fight_btn: Button = $UI/TeamSelectPanel/FightBtn
@onready var team_label: Label = $UI/TeamSelectPanel/TeamLabel

func _ready() -> void:
	team_panel.visible = false
	fight_btn.visible = false
	_build_trainer_list()
	AudioManager.play_for_scene("TrainerSelect")

func _required_team_size() -> int:
	var alive = 0
	for inst in SaveManager.get_prints():
		if inst["hp_current"] > 0:
			alive += 1
	return mini(TEAM_SIZE, alive)

func _build_trainer_list() -> void:
	for child in trainer_list.get_children():
		child.queue_free()

	for trainer in GameData.AI_TRAINERS:
		var card = Panel.new()
		card.custom_minimum_size = Vector2(0, 72)
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(vbox)

		var name_lbl = Label.new()
		name_lbl.text = "%s  (Difficulty %d)" % [trainer["name"], trainer["difficulty"]]
		name_lbl.add_theme_font_size_override("font_size", 18)
		vbox.add_child(name_lbl)

		var intro_lbl = Label.new()
		intro_lbl.text = trainer.get("intro_text", "")
		intro_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intro_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
		intro_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(intro_lbl)

		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_END
		var reward_lbl = Label.new()
		reward_lbl.text = "+%d coins  +%d XP" % [trainer["reward_coins"], trainer["reward_xp"]]
		reward_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(reward_lbl)

		var fight_btn_t = Button.new()
		fight_btn_t.text = "Challenge"
		fight_btn_t.pressed.connect(_on_trainer_selected.bind(trainer))
		hbox.add_child(fight_btn_t)
		vbox.add_child(hbox)

		trainer_list.add_child(card)

func _on_trainer_selected(trainer: Dictionary) -> void:
	selected_trainer = trainer
	selected_prints = []
	team_panel.visible = true
	var req = _required_team_size()
	team_label.text = "Select %d Print%s for battle" % [req, "s" if req != 1 else ""]
	_build_print_list()
	_refresh_team_label()

func _build_print_list() -> void:
	for child in print_list.get_children():
		child.queue_free()
	_print_toggles.clear()

	var prints = SaveManager.get_prints()
	var req = _required_team_size()
	if prints.is_empty() or req == 0:
		var lbl = Label.new()
		lbl.text = "You have no battle-ready prints!\nVisit the Filament Market to buy blueprints and print creatures."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		print_list.add_child(lbl)
		return

	for inst in prints:
		if inst["hp_current"] <= 0:
			continue
		var creature = GameData.CREATURES[inst["creature_id"]]
		var max_hp = SaveManager.get_print_max_hp(inst)
		var hbox = HBoxContainer.new()

		var icon = UIStyle.make_creature_sprite(creature, Vector2(40, 40))
		hbox.add_child(icon)

		var lbl = Label.new()
		lbl.text = "%s  [%s]  HP: %d/%d" % [
			creature["name"],
			creature["element"].capitalize(),
			inst["hp_current"],
			max_hp,
		]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		var toggle = CheckBox.new()
		toggle.text = "Select"
		toggle.toggled.connect(_on_print_toggled.bind(inst["instance_id"]))
		hbox.add_child(toggle)
		_print_toggles[inst["instance_id"]] = toggle

		print_list.add_child(hbox)

func _on_print_toggled(toggled_on: bool, instance_id: String) -> void:
	var req = _required_team_size()
	if toggled_on:
		if selected_prints.size() >= req:
			if instance_id in _print_toggles:
				_print_toggles[instance_id].set_pressed_no_signal(false)
			return
		if not instance_id in selected_prints:
			selected_prints.append(instance_id)
	else:
		selected_prints.erase(instance_id)
	_refresh_team_label()

func _refresh_team_label() -> void:
	var req = _required_team_size()
	selected_team_label.text = "Team: %d / %d selected" % [selected_prints.size(), req]
	fight_btn.visible = req > 0 and selected_prints.size() == req

func _on_fight_btn_pressed() -> void:
	var req = _required_team_size()
	if selected_prints.size() != req or req == 0:
		return

	var team = []
	for iid in selected_prints:
		var inst = SaveManager.get_print_by_instance_id(iid)
		if not inst.is_empty():
			team.append(inst)

	if team.is_empty():
		return

	SceneTransition.go_to("res://scenes/Battle.tscn", {
		"team": team,
		"trainer": selected_trainer,
	})

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")
