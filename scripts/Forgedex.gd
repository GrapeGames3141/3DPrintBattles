# Forgedex.gd
# Creature discovery log — owned prints shown in full, seen = silhouette, unknown = ???
# Scene file: res://scenes/Forgedex.tscn
#
# SCENE TREE:
# Forgedex (Node2D)
# ├── Background (TextureRect)
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer)
# │   │   ├── TitleLabel (Label)       "Forgedex"
# │   │   ├── CountLabel (Label)       "Discovered: 3 of ???"
# │   │   └── BackBtn (Button)
# │   ├── FilterBar (HBoxContainer)    — element filter buttons
# │   ├── EntryGrid (GridContainer)    — all creature cards
# │   └── DetailPanel (Panel)         — shown on entry click
# │       ├── DetailSprite (ColorRect)
# │       ├── DetailName (Label)
# │       ├── DetailElement (Label)
# │       ├── DetailRarity (Label)
# │       ├── DetailBend (Label)
# │       ├── DetailAbility (Label)
# │       └── DetailLore (Label)

extends Node2D

var _element_filter := "all"

@onready var count_label: Label        = $UI/TopBar/CountLabel
@onready var entry_grid: GridContainer = $UI/EntryGrid
@onready var detail_panel: Panel       = $UI/DetailPanel
@onready var detail_sprite: ColorRect  = $UI/DetailPanel/DetailSprite
@onready var detail_name: Label        = $UI/DetailPanel/DetailName
@onready var detail_element: Label     = $UI/DetailPanel/DetailElement
@onready var detail_rarity: Label      = $UI/DetailPanel/DetailRarity
@onready var detail_bend: Label        = $UI/DetailPanel/DetailBend
@onready var detail_ability: Label     = $UI/DetailPanel/DetailAbility
@onready var detail_lore: Label        = $UI/DetailPanel/DetailLore

func _ready() -> void:
	detail_panel.visible = false
	_build_grid()
	_update_count()

# ─────────────────────────────────────────────────────────────────────────────
# GRID
# ─────────────────────────────────────────────────────────────────────────────
func _build_grid() -> void:
	for child in entry_grid.get_children():
		child.queue_free()

	var idx := 1
	for cid in GameData.CREATURES:
		var creature := GameData.CREATURES[cid]
		if _element_filter != "all" and creature["element"] != _element_filter:
			idx += 1
			continue

		var status := SaveManager.get_forgedex_status(cid)
		var card := _make_entry_card(cid, creature, status, idx)
		entry_grid.add_child(card)
		idx += 1

func _make_entry_card(cid: String, creature: Dictionary, status: String, _idx: int) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(120, 160)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(vbox)

	# Sprite or silhouette
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(80, 80)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	match status:
		"owned":
			swatch.color = creature["placeholder_color"]
		"seen":
			swatch.color = Color(0.1, 0.1, 0.1)  # Dark silhouette
		_:
			swatch.color = Color(0.2, 0.2, 0.2)  # Unknown

	vbox.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	match status:
		"owned":
			name_lbl.text = creature["name"]
		"seen":
			name_lbl.text = "??? (Seen)"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_:
			name_lbl.text = "???"
			name_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

	vbox.add_child(name_lbl)

	if status == "owned":
		var rarity_lbl := Label.new()
		rarity_lbl.text = GameData.RARITY_NAMES.get(creature["rarity"], "")
		rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity_lbl.add_theme_color_override("font_color",
			GameData.RARITY_COLORS.get(creature["rarity"], Color.WHITE))
		vbox.add_child(rarity_lbl)

	# Clickable only if seen or owned
	if status != "unknown":
		card.gui_input.connect(_on_card_input.bind(cid, status))

	return card

func _on_card_input(event: InputEvent, cid: String, status: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		_show_detail(cid, status)

func _show_detail(cid: String, status: String) -> void:
	detail_panel.visible = true
	var creature := GameData.CREATURES[cid]

	if status == "owned":
		detail_sprite.color = creature["placeholder_color"]
		detail_name.text = creature["name"]
		detail_element.text = "Element: %s" % creature["element"].capitalize()
		detail_rarity.text = GameData.RARITY_NAMES.get(creature["rarity"], "")
		detail_rarity.add_theme_color_override("font_color",
			GameData.RARITY_COLORS.get(creature["rarity"], Color.WHITE))
		detail_bend.text = "Bend Score: %d  |  HP: %d" % [creature["bend_score"], creature["hp_base"]]
		var ability := GameData.ABILITIES[creature["ability"]]
		detail_ability.text = "Ability: %s — %s" % [ability["name"], ability["description"]]
		detail_lore.text = creature["lore"]
	else:
		# Seen — partial info
		detail_sprite.color = Color(0.1, 0.1, 0.1)
		detail_name.text = "???"
		detail_element.text = "Element: %s" % creature["element"].capitalize()
		detail_rarity.text = "???"
		detail_bend.text = "Spotted in battle — find its blueprint to learn more."
		detail_ability.text = ""
		detail_lore.text = ""

func _update_count() -> void:
	var discovered := 0
	for cid in GameData.CREATURES:
		var s := SaveManager.get_forgedex_status(cid)
		if s == "owned" or s == "seen":
			discovered += 1
	count_label.text = "Discovered: %d of ???" % discovered

# ─────────────────────────────────────────────────────────────────────────────
# FILTER BUTTONS
# ─────────────────────────────────────────────────────────────────────────────
func _on_filter_pressed(element: String) -> void:
	_element_filter = element
	detail_panel.visible = false
	_build_grid()

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")
