extends Control

signal back

var _offers: Array[String] = []
var _rng := RandomNumberGenerator.new()

var _coins: Label
var _toast: Label
var _list: VBoxContainer

func _ready() -> void:
	name = "ShopScreen"
	anchor_right = 1
	anchor_bottom = 1

	_rng.randomize()
	_generate_offers()

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)

	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(func(): back.emit())
	top.add_child(btn_back)

	var title := Label.new()
	title.text = "Blueprint Shop (MVP)"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	_coins = Label.new()
	top.add_child(_coins)

	_toast = Label.new()
	_toast.text = "Offers refresh every launch (MVP)."
	_toast.modulate.a = 0.85
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_toaster_panel(_toast))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	_refresh()

func _generate_offers() -> void:
	_offers.clear()
	if UnitDatabase.units_array.is_empty():
		return
	while _offers.size() < 5:
		var pick: Dictionary = UnitDatabase.units_array[_rng.randi_range(0, UnitDatabase.units_array.size() - 1)]
		var id := String(pick.get("id", ""))
		if id != "" and not _offers.has(id):
			_offers.append(id)

func _refresh() -> void:
	_coins.text = "Coins: %d" % GameState.coins

	for c in _list.get_children():
		c.queue_free()

	for id in _offers:
		_list.add_child(_make_offer_row(id))

func _make_offer_row(unit_id: String) -> Control:
	var defn := UnitDatabase.get_unit(unit_id)
	var name := String(defn.get("name", "Unknown"))
	var tier_level := int(defn.get("tier_level", 1))
	var cost := int(defn.get("cost", 1))
	var price := 8 + tier_level * 4 + cost
	var owned := GameState.owned_blueprints.has(unit_id)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = "%s  (Blueprint)  Tier %d  Price %d" % [name, tier_level, price]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var btn := Button.new()
	btn.text = "Owned" if owned else "Buy"
	btn.disabled = owned
	btn.pressed.connect(func():
		_buy(unit_id, price)
	)
	row.add_child(btn)

	return _panel(row)

func _buy(unit_id: String, price: int) -> void:
	if GameState.owned_blueprints.has(unit_id):
		_toast.text = "Already owned."
		return
	if GameState.coins < price:
		_toast.text = "Not enough coins."
		return
	GameState.coins -= price
	GameState.owned_blueprints.append(unit_id)
	_toast.text = "Purchased blueprint."
	if GameState.active_slot >= 1:
		SaveSystem.write_slot(GameState.active_slot, GameState.to_save())
	_refresh()

func _panel(content: Control) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("content_margin_left", 10)
	p.add_theme_constant_override("content_margin_right", 10)
	p.add_theme_constant_override("content_margin_top", 10)
	p.add_theme_constant_override("content_margin_bottom", 10)
	p.add_child(content)
	return p

func _toaster_panel(content: Control) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("content_margin_left", 10)
	p.add_theme_constant_override("content_margin_right", 10)
	p.add_theme_constant_override("content_margin_top", 10)
	p.add_theme_constant_override("content_margin_bottom", 10)
	p.add_child(content)
	return p

