extends Control

signal open_shop
signal open_battle
signal open_team
signal back_to_title

var _toast: Label
var _coins: Label
var _filament: Label
var _battles: Label

func _ready() -> void:
	name = "HubScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)

	var title := Label.new()
	title.text = "Core Printer Workshop (Hub)"
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	_coins = Label.new()
	_filament = Label.new()
	_battles = Label.new()
	top.add_child(_coins)
	top.add_child(_filament)
	top.add_child(_battles)
	_refresh_stats()

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	var btn_shop := Button.new()
	btn_shop.text = "Shop Terminal"
	btn_shop.pressed.connect(func(): open_shop.emit())
	left.add_child(btn_shop)

	var btn_team := Button.new()
	btn_team.text = "Team Manager"
	btn_team.pressed.connect(func(): open_team.emit())
	left.add_child(btn_team)

	var btn_battle := Button.new()
	btn_battle.text = "Battle Terminal"
	btn_battle.pressed.connect(func(): open_battle.emit())
	left.add_child(btn_battle)

	left.add_child(_divider())

	var btn_upgrade := Button.new()
	btn_upgrade.text = "Slicer Station: +1 Filament Cap (Cost %d)" % GameRules.SLICER_UPGRADE_COST_COINS
	btn_upgrade.pressed.connect(_on_upgrade_filament)
	left.add_child(btn_upgrade)

	left.add_child(_divider())

	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(_on_save)
	left.add_child(btn_save)

	var btn_title := Button.new()
	btn_title.text = "Back to Title"
	btn_title.pressed.connect(func(): back_to_title.emit())
	left.add_child(btn_title)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	right.add_child(info)

	var lore := Label.new()
	lore.text = "Welcome! Print units from filament and battle rival printers."
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(lore)

	_toast = Label.new()
	_toast.text = ""
	_toast.modulate.a = 0.85
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_toaster_panel(_toast))

	EventBus.request_toast.connect(func(m): _toast.text = m)

func _refresh_stats() -> void:
	_coins.text = "Coins: %d" % GameState.coins
	_filament.text = "Filament Cap: %d" % int(GameState.printer_upgrades.get("filament_cap", 3))
	_battles.text = "Battles won: %d" % int(GameState.progress.get("battles_won", 0))

func _on_upgrade_filament() -> void:
	var cap := int(GameState.printer_upgrades.get("filament_cap", 3))
	if cap >= GameRules.FILAMENT_CAP_MAX:
		EventBus.request_toast.emit("Filament cap already at max (%d)." % GameRules.FILAMENT_CAP_MAX)
		return
	if GameState.coins < GameRules.SLICER_UPGRADE_COST_COINS:
		EventBus.request_toast.emit("Not enough coins.")
		return
	GameState.coins -= GameRules.SLICER_UPGRADE_COST_COINS
	GameState.printer_upgrades["filament_cap"] = cap + 1
	_refresh_stats()
	EventBus.request_toast.emit("Upgraded filament cap to %d." % (cap + 1))

func _on_save() -> void:
	if GameState.active_slot < 1:
		EventBus.request_toast.emit("No active save slot.")
		return
	SaveSystem.write_slot(GameState.active_slot, GameState.to_save())
	EventBus.request_toast.emit("Saved to slot %d." % GameState.active_slot)

func _divider() -> Control:
	var c := ColorRect.new()
	c.color = Color(1, 1, 1, 0.15)
	c.custom_minimum_size = Vector2(0, 2)
	return c

func _toaster_panel(content: Control) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("content_margin_left", 10)
	p.add_theme_constant_override("content_margin_right", 10)
	p.add_theme_constant_override("content_margin_top", 10)
	p.add_theme_constant_override("content_margin_bottom", 10)
	p.add_child(content)
	return p

