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
	_sync_shop_offers_from_clock()

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
	_toast.text = "Six rotating blueprints per day (lower tiers appear more often). Real-time clock — same deals until the next refresh."
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

func _sync_shop_offers_from_clock() -> void:
	var now := int(Time.get_unix_time_from_system())
	if GameRules.shop_refresh_due(GameState.shop_last_refresh_unix, now):
		GameState.shop_last_refresh_unix = now
		_generate_offers()
		_persist_offers_to_game_state()
		if GameState.session_active:
			SaveSystem.write_save(GameState.to_save())
	else:
		if not GameState.shop_offer_ids.is_empty():
			_offers = GameState.shop_offer_ids.duplicate()
		else:
			_generate_offers()
			_persist_offers_to_game_state()
			if GameState.session_active:
				SaveSystem.write_save(GameState.to_save())


func _persist_offers_to_game_state() -> void:
	GameState.shop_offer_ids.clear()
	for id in _offers:
		GameState.shop_offer_ids.append(id)


func _generate_offers() -> void:
	_offers = GameRules.pick_shop_offer_unit_ids(_rng, UnitDatabase.active_roster_for_stage(), GameRules.SHOP_OFFER_COUNT)

func _refresh() -> void:
	_coins.text = "Coins: %d" % GameState.coins

	for c in _list.get_children():
		c.queue_free()

	for id in _offers:
		_list.add_child(_make_offer_row(id))

func _make_offer_row(unit_id: String) -> Control:
	var defn: Dictionary = UnitDatabase.get_unit(unit_id)
	var unit_name: String = str(defn.get("name", "Unknown"))
	var tier_level: int = int(defn.get("tier_level", 1))
	var cost: int = int(defn.get("cost", 1))
	var elem: String = str(defn.get("element", "?"))
	var price: int = GameRules.blueprint_shop_price(tier_level, cost)
	var owned: bool = GameState.owned_blueprints.has(unit_id)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = "%s · %s · Tier %d · Summon C%d · %d coins" % [unit_name, elem, tier_level, cost, price]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var btn := Button.new()
	if owned:
		btn.text = "Owned"
	else:
		btn.text = "Buy"
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
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())
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

