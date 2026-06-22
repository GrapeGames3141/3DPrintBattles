# StarterSelection.gd
# Shown once on first run. Player picks one of the 3 starter Prints.
# Scene file: res://scenes/StarterSelection.tscn
#
# SCENE TREE:
# StarterSelection (Node2D)
# ├── Background (TextureRect)
# ├── UI (CanvasLayer)
# │   ├── TitleLabel (Label)           "Choose Your First Print"
# │   ├── SubtitleLabel (Label)        "Your starter stays with you forever."
# │   ├── StarterCards (HBoxContainer)
# │   │   ├── CinderpawCard (Panel)
# │   │   ├── AquafinCard (Panel)
# │   │   └── VoltCard (Panel)
# │   ├── ConfirmBtn (Button)          "Begin Forging!" — hidden until a card is picked
# │   └── SelectedLabel (Label)        "You chose: Cinderpaw" — hidden until picked
#
# Each StarterCard Panel contains:
#   ├── CreatureSprite (TextureRect or ColorRect placeholder)
#   ├── NameLabel (Label)
#   ├── ElementLabel (Label)
#   ├── BendLabel (Label)             "Bend Score: 12"
#   ├── AbilityLabel (Label)
#   └── LoreLabel (Label)

extends Node2D

const STARTER_IDS = ["cinderpaw", "aquafin", "voltwig"]

var selected_id = ""

@onready var confirm_btn: Button = $UI/ConfirmBtn
@onready var selected_label: Label = $UI/SelectedLabel

func _ready() -> void:
	confirm_btn.visible = false
	selected_label.visible = false
	_build_cards()

# ─────────────────────────────────────────────────────────────────────────────
# BUILD CARDS DYNAMICALLY
# Each card is created from a template Panel. In the Godot editor you can
# replace this with a preloaded PackedScene (StarterCard.tscn) for polish.
# ─────────────────────────────────────────────────────────────────────────────
func _build_cards() -> void:
	var container: HBoxContainer = $UI/StarterCards
	# Clear any placeholder children
	for child in container.get_children():
		child.queue_free()

	for sid in STARTER_IDS:
		var creature = GameData.CREATURES[sid]
		var card = _make_card(sid, creature)
		container.add_child(card)

func _make_card(sid: String, creature: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(260, 380)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# Sprite or placeholder
	var sprite_rect = ColorRect.new()
	sprite_rect.custom_minimum_size = Vector2(200, 200)
	sprite_rect.color = creature["placeholder_color"]
	sprite_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Try to load real sprite
	var sprite_path = "res://assets/sprites/%s" % creature["sprite"]
	if ResourceLoader.exists(sprite_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.custom_minimum_size = Vector2(200, 200)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(tex_rect)
	else:
		vbox.add_child(sprite_rect)

	# Labels
	var name_lbl = Label.new()
	name_lbl.text = creature["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_lbl)

	var elem_lbl = Label.new()
	elem_lbl.text = "Element: %s" % creature["element"].capitalize()
	elem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(elem_lbl)

	var bend_lbl = Label.new()
	bend_lbl.text = "Bend Score: %d  |  HP: %d" % [creature["bend_score"], creature["hp_base"]]
	bend_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(bend_lbl)

	var ability = GameData.ABILITIES[creature["ability"]]
	var ability_lbl = Label.new()
	ability_lbl.text = "Ability: %s\n%s" % [ability["name"], ability["description"]]
	ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ability_lbl)

	var lore_lbl = Label.new()
	lore_lbl.text = creature["lore"]
	lore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(lore_lbl)

	# Make card clickable
	var btn = Button.new()
	btn.text = "Choose %s" % creature["name"]
	btn.pressed.connect(_on_card_selected.bind(sid))
	vbox.add_child(btn)

	return card

# ─────────────────────────────────────────────────────────────────────────────
# SELECTION
# ─────────────────────────────────────────────────────────────────────────────
func _on_card_selected(sid: String) -> void:
	selected_id = sid
	var creature = GameData.CREATURES[sid]
	selected_label.text = "You chose: %s" % creature["name"]
	selected_label.visible = true
	confirm_btn.visible = true

func _on_confirm_btn_pressed() -> void:
	if selected_id == "":
		return
	SaveManager.choose_starter(selected_id)
	SceneTransition.go_to("res://scenes/Workshop.tscn")
