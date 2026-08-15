# StarterSelection.gd
# First-run starter pick — styled cards with placeholder figurine art.

extends Node2D

const STARTER_IDS = ["cinderpaw", "aquafin", "voltwig"]

var selected_id = ""
var _card_panels: Dictionary = {}

@onready var confirm_btn: Button = $UI/Root/Layout/Footer/ConfirmBtn
@onready var selected_label: Label = $UI/Root/Layout/Footer/SelectedLabel
@onready var cards_row: HBoxContainer = $UI/Root/Layout/CardsRow


func _ready() -> void:
	confirm_btn.visible = false
	selected_label.visible = false
	_build_cards()
	AudioManager.play_for_scene("StarterSelection")


func _build_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()
	_card_panels.clear()

	for sid in STARTER_IDS:
		var creature = GameData.CREATURES[sid]
		var card = _make_card(sid, creature)
		cards_row.add_child(card)
		_card_panels[sid] = card


func _make_card(sid: String, creature: Dictionary) -> PanelContainer:
	var accent: Color = creature["placeholder_color"]
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 420)
	card.add_theme_stylebox_override("panel", UIStyle.card_stylebox(accent, false))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Sprite area
	var sprite_path = "res://assets/sprites/%s" % creature["sprite"]
	if ResourceLoader.exists(sprite_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.custom_minimum_size = Vector2(180, 180)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(tex_rect)
	else:
		var placeholder = UIStyle.make_sprite_placeholder(sid, creature)
		placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(placeholder)

	var name_lbl = Label.new()
	name_lbl.text = creature["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", accent.lightened(0.2))
	vbox.add_child(name_lbl)

	var elem_lbl = Label.new()
	elem_lbl.text = "%s  %s" % [UIStyle.element_icon(creature["element"]), creature["element"].capitalize()]
	elem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_lbl.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	vbox.add_child(elem_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "Bend %d  •  HP %d  •  Forge %d" % [
		creature["bend_score"], creature["hp_base"], creature["forge_cost"]
	]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_lbl.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	vbox.add_child(stats_lbl)

	var ability = GameData.ABILITIES[creature["ability"]]
	var ability_lbl = Label.new()
	ability_lbl.text = "%s — %s" % [ability["name"], ability["description"]]
	ability_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_lbl.custom_minimum_size = Vector2(240, 0)
	ability_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(ability_lbl)

	var btn = Button.new()
	btn.text = "Choose %s" % creature["name"]
	btn.custom_minimum_size = Vector2(220, 44)
	btn.pressed.connect(_on_card_selected.bind(sid))
	vbox.add_child(btn)

	return card


func _on_card_selected(sid: String) -> void:
	selected_id = sid
	var creature = GameData.CREATURES[sid]
	selected_label.text = "You chose: %s %s" % [UIStyle.starter_glyph(sid), creature["name"]]
	selected_label.visible = true
	confirm_btn.visible = true

	for id in _card_panels:
		var panel: PanelContainer = _card_panels[id]
		var accent: Color = GameData.CREATURES[id]["placeholder_color"]
		panel.add_theme_stylebox_override("panel", UIStyle.card_stylebox(accent, id == sid))


func _on_confirm_btn_pressed() -> void:
	if selected_id == "":
		return
	SaveManager.choose_starter(selected_id)
	AudioManager.play_sfx("summon")
	SceneTransition.go_to("res://scenes/Workshop.tscn")
