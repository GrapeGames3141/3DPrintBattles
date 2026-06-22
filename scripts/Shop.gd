# Shop.gd
# Filament Market — browse and buy blueprint instructions.
# Scene file: res://scenes/Shop.tscn
#
# SCENE TREE:
# Shop (Node2D)
# ├── Background (TextureRect)
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer)
# │   │   ├── TitleLabel (Label)       "Filament Market"
# │   │   ├── CoinLabel (Label)        "🪙 1,240"
# │   │   └── BackBtn (Button)         "← Workshop"
# │   ├── TabBar (HBoxContainer)
# │   │   ├── CreaturesTab (Button)    "Creatures"
# │   │   └── EquipmentTab (Button)    "Equipment"
# │   ├── ShopGrid (GridContainer)     — 12 slot cards
# │   ├── RefreshLabel (Label)         "Shop refreshes in: 23h 41m"
# │   └── ItemDetailPanel (Panel)      — shown on hover/select
# │       ├── DetailSprite (ColorRect)
# │       ├── DetailName (Label)
# │       ├── DetailRarity (Label)
# │       ├── DetailStats (Label)
# │       ├── DetailLore (Label)
# │       ├── BlueprintCostLabel (Label)
# │       ├── PrintCostLabel (Label)
# │       ├── BuyBlueprintBtn (Button) "Buy Blueprint"
# │       ├── PrintBtn (Button)        "Print It"  — only shown if blueprint owned
# │       └── OwnedLabel (Label)       "✓ Blueprint Owned"

extends Node2D

var _current_tab := "creatures"  # "creatures" | "equipment"
var _selected_slot: Dictionary = {}

@onready var coin_label: Label          = $UI/TopBar/CoinLabel
@onready var shop_grid: GridContainer   = $UI/ShopGrid
@onready var refresh_label: Label       = $UI/RefreshLabel
@onready var detail_panel: Panel        = $UI/ItemDetailPanel
@onready var detail_name: Label         = $UI/ItemDetailPanel/DetailName
@onready var detail_rarity: Label       = $UI/ItemDetailPanel/DetailRarity
@onready var detail_stats: Label        = $UI/ItemDetailPanel/DetailStats
@onready var detail_lore: Label         = $UI/ItemDetailPanel/DetailLore
@onready var blueprint_cost_lbl: Label  = $UI/ItemDetailPanel/BlueprintCostLabel
@onready var print_cost_lbl: Label      = $UI/ItemDetailPanel/PrintCostLabel
@onready var buy_blueprint_btn: Button  = $UI/ItemDetailPanel/BuyBlueprintBtn
@onready var print_btn: Button          = $UI/ItemDetailPanel/PrintBtn
@onready var owned_label: Label         = $UI/ItemDetailPanel/OwnedLabel
@onready var detail_sprite: ColorRect   = $UI/ItemDetailPanel/DetailSprite

func _ready() -> void:
	detail_panel.visible = false
	_refresh_coin_label()
	_build_shop_grid()
	_update_refresh_timer()

# ─────────────────────────────────────────────────────────────────────────────
# SHOP GRID
# ─────────────────────────────────────────────────────────────────────────────
func _build_shop_grid() -> void:
	for child in shop_grid.get_children():
		child.queue_free()

	var slots: Array = SaveManager.get_shop_slots()
	for slot in slots:
		var item_id: String = slot["id"]
		var kind: String = slot["kind"]

		if _current_tab == "creatures" and kind != "creature":
			continue
		if _current_tab == "equipment" and kind != "equipment":
			continue

		var card := _make_shop_card(item_id, kind)
		shop_grid.add_child(card)

func _make_shop_card(item_id: String, kind: String) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(180, 220)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(vbox)

	var data := {}
	var rarity := 1
	var bp_cost := 0
	var placeholder_color := Color.WHITE

	if kind == "creature" and item_id in GameData.CREATURES:
		data = GameData.CREATURES[item_id]
		rarity = data["rarity"]
		bp_cost = data["blueprint_cost"]
		placeholder_color = data["placeholder_color"]
	elif kind == "equipment" and item_id in GameData.EQUIPMENT:
		data = GameData.EQUIPMENT[item_id]
		rarity = data["rarity"]
		bp_cost = data["blueprint_cost"]
		placeholder_color = data["placeholder_color"]

	# Color swatch
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(120, 120)
	swatch.color = placeholder_color
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(swatch)

	var name_lbl := Label.new()
	name_lbl.text = data.get("name", item_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var rarity_lbl := Label.new()
	rarity_lbl.text = GameData.RARITY_NAMES.get(rarity, "Common")
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_color_override("font_color", GameData.RARITY_COLORS.get(rarity, Color.WHITE))
	vbox.add_child(rarity_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "Blueprint: %d 🪙" % bp_cost
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_lbl)

	# Owned badge
	if SaveManager.has_blueprint(item_id):
		var owned := Label.new()
		owned.text = "✓ Owned"
		owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned.add_theme_color_override("font_color", Color(0.22, 0.88, 0.22))
		vbox.add_child(owned)

	# Select button
	var select_btn := Button.new()
	select_btn.text = "View"
	select_btn.pressed.connect(_on_slot_selected.bind(item_id, kind))
	vbox.add_child(select_btn)

	return card

# ─────────────────────────────────────────────────────────────────────────────
# ITEM DETAIL PANEL
# ─────────────────────────────────────────────────────────────────────────────
func _on_slot_selected(item_id: String, kind: String) -> void:
	_selected_slot = {"id": item_id, "kind": kind}
	detail_panel.visible = true

	var data := {}
	if kind == "creature" and item_id in GameData.CREATURES:
		data = GameData.CREATURES[item_id]
		detail_stats.text = "Element: %s\nBend Score: %d\nHP: %d\nForge Cost: %d" % [
			data["element"].capitalize(),
			data["bend_score"],
			data["hp_base"],
			data["forge_cost"],
		]
		detail_lore.text = data.get("lore", "")
		detail_sprite.color = data["placeholder_color"]
	elif kind == "equipment" and item_id in GameData.EQUIPMENT:
		data = GameData.EQUIPMENT[item_id]
		detail_stats.text = data.get("description", "")
		detail_lore.text = "Type: %s" % data["type"].capitalize()
		detail_sprite.color = data["placeholder_color"]

	detail_name.text = data.get("name", item_id)
	var rarity: int = data.get("rarity", 1)
	detail_rarity.text = GameData.RARITY_NAMES.get(rarity, "Common")
	detail_rarity.add_theme_color_override("font_color",
		GameData.RARITY_COLORS.get(rarity, Color.WHITE))

	blueprint_cost_lbl.text = "Blueprint Cost: %d 🪙" % data.get("blueprint_cost", 0)
	print_cost_lbl.text = "Print Cost: %d 🪙" % data.get("print_cost", 0)

	var has_bp := SaveManager.has_blueprint(item_id)
	owned_label.visible = has_bp
	buy_blueprint_btn.visible = not has_bp
	print_btn.visible = has_bp

	buy_blueprint_btn.disabled = SaveManager.get_coins() < data.get("blueprint_cost", 0)

func _on_buy_blueprint_btn_pressed() -> void:
	var item_id: String = _selected_slot.get("id", "")
	if item_id == "":
		return
	var success := SaveManager.buy_blueprint(item_id)
	if success:
		_refresh_coin_label()
		_build_shop_grid()
		_on_slot_selected(item_id, _selected_slot.get("kind", "creature"))
	else:
		# Flash the coin label red briefly
		coin_label.add_theme_color_override("font_color", Color.RED)
		await get_tree().create_timer(0.5).timeout
		coin_label.remove_theme_color_override("font_color")

func _on_print_btn_pressed() -> void:
	var item_id: String = _selected_slot.get("id", "")
	var kind: String = _selected_slot.get("kind", "creature")
	if item_id == "":
		return

	var success := false
	if kind == "creature":
		success = SaveManager.print_creature(item_id)
	elif kind == "equipment":
		success = SaveManager.print_equipment(item_id)

	if success:
		_refresh_coin_label()
	else:
		coin_label.add_theme_color_override("font_color", Color.RED)
		await get_tree().create_timer(0.5).timeout
		coin_label.remove_theme_color_override("font_color")

# ─────────────────────────────────────────────────────────────────────────────
# TABS
# ─────────────────────────────────────────────────────────────────────────────
func _on_creatures_tab_pressed() -> void:
	_current_tab = "creatures"
	_build_shop_grid()

func _on_equipment_tab_pressed() -> void:
	_current_tab = "equipment"
	_build_shop_grid()

# ─────────────────────────────────────────────────────────────────────────────
# REFRESH TIMER DISPLAY
# ─────────────────────────────────────────────────────────────────────────────
func _update_refresh_timer() -> void:
	var last: float = SaveManager.data["shop_state"]["refresh_timestamp"]
	var next_refresh := last + 86400.0
	var now := Time.get_unix_time_from_system()
	var secs_remaining := max(0, int(next_refresh - now))
	var hours := secs_remaining / 3600
	var mins := (secs_remaining % 3600) / 60
	refresh_label.text = "Shop refreshes in: %dh %dm" % [hours, mins]

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_coin_label() -> void:
	coin_label.text = "🪙 %d" % SaveManager.get_coins()

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")

func _process(_delta: float) -> void:
	_update_refresh_timer()
