extends Control

signal exit_to_hub

const COLS := 4
const ROWS := 2
const CORE_HP_START := 20

class_name BattleScreen

class UnitState:
	var id: String
	var name: String
	var element: String
	var hp: int
	var atk: int
	var cost: int
	var owner: int # 0 player, 1 enemy
	var slot_index: int

	func _init(defn: Dictionary, p_owner: int, p_slot_index: int) -> void:
		id = str(defn.get("id", ""))
		name = str(defn.get("name", "Unit"))
		element = str(defn.get("element", "PLA"))
		hp = int(defn.get("hp", 1))
		atk = int(defn.get("atk", 1))
		cost = int(defn.get("cost", 1))
		owner = p_owner
		slot_index = p_slot_index

var _rng := RandomNumberGenerator.new()

var _player_core_hp := CORE_HP_START
var _enemy_core_hp := CORE_HP_START

var _turn_owner := 0 # 0 player starts after coin flip
var _turn := 1

var _player_filament_max := 3
var _player_filament := 0
var _enemy_filament_max := 3
var _enemy_filament := 0

var _grid_player: Array[UnitState] = []
var _grid_enemy: Array[UnitState] = []

var _hand: Array[Dictionary] = []
var _hand_ids: Array[String] = []

var _lbl_state: Label
var _lbl_toast: Label
var _player_hand_row: HBoxContainer
var _grid_root: HBoxContainer
var _results_panel: PanelContainer
var _results_label: Label
var _results_back: Button
var _match_over := false

func _ready() -> void:
	name = "BattleScreen"
	anchor_right = 1
	anchor_bottom = 1
	_rng.randomize()

	_player_filament_max = int(GameState.printer_upgrades.get("filament_cap", 3))
	_enemy_filament_max = 3

	_grid_player.resize(COLS * ROWS)
	_grid_enemy.resize(COLS * ROWS)

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)

	var btn_exit := Button.new()
	btn_exit.text = "Exit"
	btn_exit.pressed.connect(func(): exit_to_hub.emit())
	top.add_child(btn_exit)

	_lbl_state = Label.new()
	_lbl_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_lbl_state)

	var btn_end := Button.new()
	btn_end.text = "End Turn"
	btn_end.pressed.connect(_on_end_turn_pressed)
	top.add_child(btn_end)

	_lbl_toast = Label.new()
	_lbl_toast.modulate.a = 0.85
	_lbl_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_lbl_toast)

	_grid_root = HBoxContainer.new()
	_grid_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_root.add_theme_constant_override("separation", 16)
	root.add_child(_grid_root)

	_grid_root.add_child(_make_side("Enemy", 1))
	_grid_root.add_child(_make_side("Player", 0))

	root.add_child(_divider())

	var hand_wrap := VBoxContainer.new()
	hand_wrap.add_theme_constant_override("separation", 6)
	root.add_child(hand_wrap)

	var hand_title := Label.new()
	hand_title.text = "Hand (click a unit to summon into an empty Player slot)"
	hand_wrap.add_child(hand_title)

	_player_hand_row = HBoxContainer.new()
	_player_hand_row.add_theme_constant_override("separation", 8)
	hand_wrap.add_child(_player_hand_row)

	_results_panel = PanelContainer.new()
	_results_panel.visible = false
	_results_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_results_panel.add_theme_constant_override("content_margin_left", 14)
	_results_panel.add_theme_constant_override("content_margin_right", 14)
	_results_panel.add_theme_constant_override("content_margin_top", 14)
	_results_panel.add_theme_constant_override("content_margin_bottom", 14)
	root.add_child(_results_panel)

	var results_v := VBoxContainer.new()
	results_v.add_theme_constant_override("separation", 10)
	_results_panel.add_child(results_v)

	_results_label = Label.new()
	_results_label.text = ""
	_results_label.add_theme_font_size_override("font_size", 20)
	_results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_v.add_child(_results_label)

	_results_back = Button.new()
	_results_back.text = "Return to Hub"
	_results_back.pressed.connect(func(): exit_to_hub.emit())
	results_v.add_child(_results_back)

	_coin_flip_and_start()

func _coin_flip_and_start() -> void:
	_match_over = false
	_results_panel.visible = false
	_turn_owner = _rng.randi_range(0, 1)
	_lbl_toast.text = "Coin flip: %s starts." % (_turn_owner == 0 ? "Player" : "Enemy")
	_turn = 1
	_player_filament = 0
	_enemy_filament = 0
	_draw_new_hand()
	_start_turn()

func _start_turn() -> void:
	_player_filament = min(_player_filament + 1, _player_filament_max)
	_enemy_filament = min(_enemy_filament + 1, _enemy_filament_max)
	_refresh_ui()
	if _turn_owner == 1:
		_enemy_play()

func _draw_new_hand() -> void:
	_hand.clear()
	_hand_ids = Array(GameState.active_team, TYPE_STRING, "", null)
	for id in _hand_ids:
		var defn := UnitDatabase.get_unit(id)
		if not defn.is_empty():
			_hand.append(defn)
	if _hand.is_empty():
		# Safety: allow playtesting even if team is empty.
		_hand = UnitDatabase.random_units(5, _rng)
	_refresh_hand_ui()

func _refresh_hand_ui() -> void:
	for c in _player_hand_row.get_children():
		c.queue_free()
	for defn in _hand:
		var b := Button.new()
		var cost := int(defn.get("cost", 1))
		b.text = "%s (C%d)" % [str(defn.get("name", "Unit")), cost]
		b.pressed.connect(func(d := defn): _try_summon_from_hand(d))
		_player_hand_row.add_child(b)

func _try_summon_from_hand(defn: Dictionary) -> void:
	if _turn_owner != 0:
		_lbl_toast.text = "Wait your turn."
		return
	var cost := int(defn.get("cost", 1))
	if cost > _player_filament:
		_lbl_toast.text = "Not enough filament."
		return
	var empty := _first_empty_index(_grid_player)
	if empty < 0:
		_lbl_toast.text = "No empty slot."
		return
	_player_filament -= cost
	_grid_player[empty] = UnitState.new(defn, 0, empty)
	_lbl_toast.text = "Summoned %s." % str(defn.get("name", "Unit"))
	_refresh_ui()

func _enemy_play() -> void:
	# Simple MVP AI: summon cheapest possible into first empty, then end turn.
	var empty := _first_empty_index(_grid_enemy)
	if empty >= 0:
		var candidates := UnitDatabase.random_units(6, _rng)
		candidates.sort_custom(func(a, b): return int(a.get("cost", 1)) < int(b.get("cost", 1)))
		for d in candidates:
			var c := int(d.get("cost", 1))
			if c <= _enemy_filament:
				_enemy_filament -= c
				_grid_enemy[empty] = UnitState.new(d, 1, empty)
				_lbl_toast.text = "Enemy printed %s." % str(d.get("name", "Unit"))
				break
	_refresh_ui()
	_on_end_turn_pressed()

func _on_end_turn_pressed() -> void:
	if _match_over:
		return
	_resolve_combat()
	if _check_end():
		return
	_turn_owner = 1 - _turn_owner
	_turn += 1
	_start_turn()

func _resolve_combat() -> void:
	# MVP combat: each unit attacks the opposing slot; if none, hits core.
	var pending_damage_player_core := 0
	var pending_damage_enemy_core := 0

	# Enemy attacks player side
	for i in COLS * ROWS:
		var u: UnitState = _grid_enemy[i]
		if u == null:
			continue
		var target: UnitState = _grid_player[i]
		if target != null:
			target.hp -= _effective_damage(u, target)
		else:
			pending_damage_player_core += u.atk

	# Player attacks enemy side
	for i in COLS * ROWS:
		var u2: UnitState = _grid_player[i]
		if u2 == null:
			continue
		var target2: UnitState = _grid_enemy[i]
		if target2 != null:
			target2.hp -= _effective_damage(u2, target2)
		else:
			pending_damage_enemy_core += u2.atk

	_player_core_hp -= pending_damage_player_core
	_enemy_core_hp -= pending_damage_enemy_core

	_cleanup_dead(_grid_player)
	_cleanup_dead(_grid_enemy)
	_refresh_ui()

func _effective_damage(attacker: UnitState, defender: UnitState) -> int:
	var mult := 1.0
	if _is_advantage(attacker.element, defender.element):
		mult = 1.5
	elif _is_advantage(defender.element, attacker.element):
		mult = 0.75
	return max(1, int(round(attacker.atk * mult)))

func _is_advantage(a: String, b: String) -> bool:
	# Heat > PLA > Resin > Heat
	if a == "Heat" and b == "PLA":
		return true
	if a == "PLA" and b == "Resin":
		return true
	if a == "Resin" and b == "Heat":
		return true
	return false

func _cleanup_dead(grid: Array) -> void:
	for i in grid.size():
		var u: UnitState = grid[i]
		if u != null and u.hp <= 0:
			# MVP: "shatter" later; for now just remove.
			grid[i] = null

func _check_end() -> bool:
	if _player_core_hp <= 0 or _enemy_core_hp <= 0:
		_finish_match()
		return true
	# Exhaustion deadlock prevention:
	# Match ends if a player has no active units + no playable hand.
	if _is_exhausted_player():
		_finish_match()
		return true
	if _is_exhausted_enemy():
		_finish_match()
		return true
	return false

func _finish_match() -> void:
	_match_over = true
	var player_won := _enemy_core_hp <= 0 or (_player_core_hp > 0 and _no_units(_grid_enemy))
	var payout := player_won ? 40 : 15
	GameState.coins += payout
	if GameState.active_slot >= 1:
		SaveSystem.write_slot(GameState.active_slot, GameState.to_save())
	var msg := player_won ? "Victory! +%d coins" % payout : "Defeat. +%d coins" % payout
	_lbl_toast.text = msg
	_results_label.text = "%s\n\n(Player Core %d vs Enemy Core %d)" % [msg, _player_core_hp, _enemy_core_hp]
	_results_panel.visible = true

func _is_exhausted_player() -> bool:
	return _no_units(_grid_player) and not _has_playable_hand(_hand, _player_filament, _grid_player)

func _is_exhausted_enemy() -> bool:
	# Enemy "hand" is virtual; if they can't afford any random pick and have no units, treat as exhausted.
	if not _no_units(_grid_enemy):
		return false
	var cheapest := 9999
	for d in UnitDatabase.units_array:
		cheapest = min(cheapest, int(d.get("cost", 1)))
	return _enemy_filament < cheapest

func _has_playable_hand(hand: Array[Dictionary], filament: int, grid: Array) -> bool:
	if _first_empty_index(grid) < 0:
		return false
	for d in hand:
		if int(d.get("cost", 1)) <= filament:
			return true
	return false

func _no_units(grid: Array) -> bool:
	for u in grid:
		if u != null:
			return false
	return true

func _first_empty_index(grid: Array) -> int:
	for i in grid.size():
		if grid[i] == null:
			return i
	return -1

func _refresh_ui() -> void:
	_lbl_state.text = "Turn %d | Player HP %d | Enemy HP %d | Filament %d/%d" % [
		_turn,
		_player_core_hp,
		_enemy_core_hp,
		_player_filament,
		_player_filament_max
	]
	_refresh_grid_ui()

func _make_side(title: String, owner: int) -> Control:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 20)
	side.add_child(lbl)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.name = owner == 0 ? "PlayerGrid" : "EnemyGrid"
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	side.add_child(grid)

	for i in COLS * ROWS:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(160, 90)
		var l := Label.new()
		l.name = "CellLabel"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		grid.add_child(p)

	return side

func _refresh_grid_ui() -> void:
	var enemy_grid: GridContainer = _grid_root.get_node("VBoxContainer/EnemyGrid") if _grid_root.has_node("VBoxContainer/EnemyGrid") else null
	var player_grid: GridContainer = _grid_root.get_node("VBoxContainer2/PlayerGrid") if _grid_root.has_node("VBoxContainer2/PlayerGrid") else null

	# The exact VBoxContainer names can vary; find by name.
	enemy_grid = _find_grid("EnemyGrid")
	player_grid = _find_grid("PlayerGrid")
	if enemy_grid == null or player_grid == null:
		return

	for i in COLS * ROWS:
		_set_cell_label(enemy_grid.get_child(i), _grid_enemy[i])
		_set_cell_label(player_grid.get_child(i), _grid_player[i])

func _find_grid(n: String) -> GridContainer:
	for child in _grid_root.get_children():
		if child is VBoxContainer:
			var vb: VBoxContainer = child
			for c in vb.get_children():
				if c is GridContainer and c.name == n:
					return c
	return null

func _set_cell_label(panel: Control, u: UnitState) -> void:
	var l: Label = panel.get_node("CellLabel")
	if u == null:
		l.text = "Empty"
	else:
		l.text = "%s\n%s  HP:%d  ATK:%d" % [u.name, u.element, u.hp, u.atk]

func _divider() -> Control:
	var c := ColorRect.new()
	c.color = Color(1, 1, 1, 0.15)
	c.custom_minimum_size = Vector2(0, 2)
	return c

