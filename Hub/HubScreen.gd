extends Control

signal open_shop
signal open_battle
signal open_team
signal open_terrarium
signal open_archive
signal open_quests
signal open_overworld
signal open_trade
signal back_to_title

var _toast: Label
var _coins: Label
var _filament: Label
var _battles: Label
var _team: Label

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
	_team = Label.new()
	top.add_child(_coins)
	top.add_child(_filament)
	top.add_child(_battles)
	top.add_child(_team)
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

	var btn_terr := Button.new()
	btn_terr.text = "Terrarium"
	btn_terr.pressed.connect(func(): open_terrarium.emit())
	left.add_child(btn_terr)

	var btn_arch := Button.new()
	btn_arch.text = "Archive"
	btn_arch.pressed.connect(func(): open_archive.emit())
	left.add_child(btn_arch)

	var btn_quest := Button.new()
	btn_quest.text = "Learning Quests"
	btn_quest.pressed.connect(func(): open_quests.emit())
	left.add_child(btn_quest)

	left.add_child(_divider())

	var btn_world := Button.new()
	btn_world.text = "Overworld (Bosses)"
	btn_world.pressed.connect(func(): open_overworld.emit())
	left.add_child(btn_world)

	var btn_trade := Button.new()
	btn_trade.text = "Offline Trade"
	btn_trade.pressed.connect(func(): open_trade.emit())
	left.add_child(btn_trade)

	left.add_child(_divider())

	var btn_upgrade := Button.new()
	btn_upgrade.text = "Slicer Station: +1 Filament Cap (Cost %d)" % GameRules.SLICER_UPGRADE_COST_COINS
	btn_upgrade.pressed.connect(_on_upgrade_filament)
	left.add_child(btn_upgrade)

	var btn_armor := Button.new()
	btn_armor.text = "Slicer Station: +1 Core Armor slab (Cost %d)" % GameRules.SLICER_CORE_ARMOR_COST_COINS
	btn_armor.pressed.connect(_on_upgrade_core_armor)
	left.add_child(btn_armor)

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
	lore.text = "Welcome! Shop for blueprints, build a team, try Learning Quests, and battle from the terminal. Terrarium and Archive show your collection vs the full roster."
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
	var armor: int = int(GameState.printer_upgrades.get("core_armor", 0))
	var bonus_hp: int = GameRules.player_core_hp_bonus(armor)
	_filament.text = "Filament cap: %d · Core armor: %d/%d (+%d HP in duels)" % [
		int(GameState.printer_upgrades.get("filament_cap", 3)),
		armor,
		GameRules.CORE_ARMOR_SLABS_MAX,
		bonus_hp
	]
	_battles.text = "Battles won: %d" % int(GameState.progress.get("battles_won", 0))
	_team.text = "Team: %d/%d" % [GameState.active_team.size(), GameRules.TEAM_MAX_UNITS]

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
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())


func _on_upgrade_core_armor() -> void:
	var slabs := int(GameState.printer_upgrades.get("core_armor", 0))
	if slabs >= GameRules.CORE_ARMOR_SLABS_MAX:
		EventBus.request_toast.emit("Core armor already maxed (%d slabs)." % GameRules.CORE_ARMOR_SLABS_MAX)
		return
	if GameState.coins < GameRules.SLICER_CORE_ARMOR_COST_COINS:
		EventBus.request_toast.emit("Not enough coins.")
		return
	GameState.coins -= GameRules.SLICER_CORE_ARMOR_COST_COINS
	GameState.printer_upgrades["core_armor"] = slabs + 1
	_refresh_stats()
	EventBus.request_toast.emit("Reinforced core shell — +%d total HP in battles." % GameRules.player_core_hp_bonus(slabs + 1))
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())

func _on_save() -> void:
	if not GameState.session_active:
		EventBus.request_toast.emit("No active profile session.")
		return
	SaveSystem.write_save(GameState.to_save())
	EventBus.request_toast.emit("Progress saved.")

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

