extends Control

## COPPA-safe offline trade: no chat, no accounts — spare tier-1 blueprint voucher.

signal back

var _rng := RandomNumberGenerator.new()
var _toast: Label
var _coins: Label

func _ready() -> void:
	name = "TradeScreen"
	anchor_right = 1
	anchor_bottom = 1
	_rng.randomize()

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(func(): back.emit())
	top.add_child(btn_back)

	var hdr := Label.new()
	hdr.text = "Offline Trade"
	hdr.add_theme_font_size_override("font_size", 26)
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hdr)

	_coins = Label.new()
	top.add_child(_coins)

	var body := Label.new()
	body.text = "A traveling technician swaps spare draft prints for coins. No messages, no passwords — parent-friendly."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 560
	root.add_child(body)

	var offer := Label.new()
	offer.text = "Spare draft blueprint — random tier-1 unit you do not own yet."
	offer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(offer)

	var btn_trade := Button.new()
	btn_trade.text = "Buy spare draft blueprint (%d coins)" % GameRules.TRADE_DRAFT_BLUEPRINT_COINS
	btn_trade.pressed.connect(_on_buy_draft)
	root.add_child(btn_trade)

	_toast = Label.new()
	_toast.text = ""
	_toast.modulate.a = 0.88
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_toast)

	_refresh()


func _refresh() -> void:
	_coins.text = "Coins: %d" % GameState.coins


func _on_buy_draft() -> void:
	var pool: Array[String] = GameRules.trade_draft_blueprint_pool(UnitDatabase.units_array, GameState.owned_blueprints)
	if pool.is_empty():
		_toast.text = "No draft blueprints left to trade — you own every tier-1 print or the pool is empty."
		return
	if GameState.coins < GameRules.TRADE_DRAFT_BLUEPRINT_COINS:
		_toast.text = "Not enough coins."
		return
	var pick: String = pool[_rng.randi_range(0, pool.size() - 1)]
	GameState.coins -= GameRules.TRADE_DRAFT_BLUEPRINT_COINS
	GameState.owned_blueprints.append(pick)
	_toast.text = "Traded! Blueprint added: %s (%s)." % [pick, str(UnitDatabase.get_unit(pick).get("name", pick))]
	_refresh()
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())
