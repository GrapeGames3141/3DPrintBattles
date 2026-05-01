extends Control

signal exit_to_hub

const COLS := 4
const ROWS := 2
const CORE_HP_START := 20

class UnitState:
	var id: String
	var name: String
	var element: String
	var hp: int
	var atk: int
	var cost: int
	var owner: int # 0 player, 1 enemy
	var slot_index: int
	## Where this unit aims this turn (player only). UNSET = frontal column.
	var attack_target: int

	func _init(defn: Dictionary, p_owner: int, p_slot_index: int) -> void:
		id = str(defn.get("id", ""))
		name = str(defn.get("name", "Unit"))
		element = str(defn.get("element", "PLA"))
		hp = int(defn.get("hp", 1))
		atk = int(defn.get("atk", 1))
		cost = int(defn.get("cost", 1))
		owner = p_owner
		slot_index = p_slot_index
		attack_target = BattleResolver.TARGET_UNSET

var _rng := RandomNumberGenerator.new()

var _player_core_hp := CORE_HP_START
var _enemy_core_hp := CORE_HP_START

var _turn_owner := 0
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

var _player_grid_buttons: Array[Button] = []
var _enemy_grid_buttons: Array[Button] = []
var _targeting_from_slot := -1
var _btn_end: Button

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

	_btn_end = Button.new()
	_btn_end.text = "End Turn"
	_btn_end.pressed.connect(_on_end_turn_pressed)
	top.add_child(_btn_end)

	_lbl_toast = Label.new()
	_lbl_toast.modulate.a = 0.85
	_lbl_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_lbl_toast)

	_grid_root = HBoxContainer.new()
	_grid_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_root.add_theme_constant_override("separation", 16)
	root.add_child(_grid_root)

	_player_grid_buttons.clear()
	_enemy_grid_buttons.clear()
	_grid_root.add_child(_make_side("Enemy", false))
	_grid_root.add_child(_make_side("Player", true))
	_apply_touch_layout()

	root.add_child(_divider())

	var hand_wrap := VBoxContainer.new()
	hand_wrap.add_theme_constant_override("separation", 6)
	root.add_child(hand_wrap)

	var hand_title := Label.new()
	hand_title.text = "Summon from hand, then tap your unit → enemy cell (or Core) to aim attacks. End Turn resolves both sides."
	hand_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand_wrap.add_child(hand_title)

	var aim_row := HBoxContainer.new()
	aim_row.add_theme_constant_override("separation", 8)
	hand_wrap.add_child(aim_row)

	var btn_aim_core := Button.new()
	btn_aim_core.text = "Aim selected attacker → Enemy Core"
	btn_aim_core.pressed.connect(_on_aim_core_pressed)
	aim_row.add_child(btn_aim_core)

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

func _apply_touch_layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var short_side := min(s.x, s.y)
	if short_side < 720:
		var sz := Vector2(180, 104)
		for b in _player_grid_buttons:
			b.custom_minimum_size = sz
		for b in _enemy_grid_buttons:
			b.custom_minimum_size = sz

func _apply_hit(attacker: UnitState, defender: UnitState) -> void:
	if attacker == null or defender == null:
		return
	if defender.element == "TPU" and BattleResolver.tpu_dodges(_rng):
		return
	defender.hp -= BattleResolver.effective_damage(attacker.element, attacker.atk, defender.element)

func _on_aim_core_pressed() -> void:
	if _match_over or _turn_owner != 0:
		return
	if _targeting_from_slot < 0:
		_lbl_toast.text = "Select your attacking unit on the Player grid first."
		return
	var u: UnitState = _grid_player[_targeting_from_slot]
	if u == null:
		_targeting_from_slot = -1
		return
	u.attack_target = BattleResolver.TARGET_CORE
	_lbl_toast.text = "%s will strike the Enemy Core this turn." % u.name
	_targeting_from_slot = -1
	_refresh_grid_ui()

func _on_grid_cell_pressed(is_player_side: bool, index: int) -> void:
	if _match_over or _turn_owner != 0:
		return
	if is_player_side:
		var u: UnitState = _grid_player[index]
		if u == null:
			_targeting_from_slot = -1
			_lbl_toast.text = "Pick one of your units to set its attack target."
			return
		_targeting_from_slot = index
		_lbl_toast.text = "Attacker: %s — tap an enemy cell or use “Enemy Core”." % u.name
		return
	if _targeting_from_slot < 0:
		_lbl_toast.text = "Select your attacker on the Player grid first."
		return
	var attacker: UnitState = _grid_player[_targeting_from_slot]
	if attacker == null:
		_targeting_from_slot = -1
		return
	attacker.attack_target = index
	_lbl_toast.text = "%s → enemy column %d." % [attacker.name, index]
	_targeting_from_slot = -1
	_refresh_grid_ui()

func _coin_flip_and_start() -> void:
	_match_over = false
	_results_panel.visible = false
	_turn_owner = _rng.randi_range(0, 1)
	var starter_label := "Enemy"
	if _turn_owner == 0:
		starter_label = "Player"
	_lbl_toast.text = "Coin flip: %s starts." % starter_label
	_turn = 1
	_player_filament = 0
	_enemy_filament = 0
	_targeting_from_slot = -1
	_draw_new_hand()
	_start_turn()

func _start_turn() -> void:
	_player_filament = min(_player_filament + 1, _player_filament_max)
	_enemy_filament = min(_enemy_filament + 1, _enemy_filament_max)
	if _turn_owner == 0:
		_reset_player_attack_targets()
		_targeting_from_slot = -1
	_refresh_ui()
	if _turn_owner == 1:
		_enemy_play()

func _reset_player_attack_targets() -> void:
	for u in _grid_player:
		if u != null:
			u.attack_target = BattleResolver.TARGET_UNSET

func _draw_new_hand() -> void:
	_hand.clear()
	_hand_ids = Array(GameState.active_team, TYPE_STRING, "", null)
	for id in _hand_ids:
		var defn := UnitDatabase.get_unit(id)
		if not defn.is_empty():
			_hand.append(defn)
	if _hand.is_empty():
		_hand = UnitDatabase.random_units(5, _rng)
	_refresh_hand_ui()

func _refresh_hand_ui() -> void:
	for c in _player_hand_row.get_children():
		c.queue_free()
	for defn in _hand:
		var b := Button.new()
		var cost := int(defn.get("cost", 1))
		b.text = "%s (C%d)" % [str(defn.get("name", "Unit")), cost]
		b.pressed.connect(_try_summon_from_hand.bind(defn))
		_player_hand_row.add_child(b)

func _try_summon_from_hand(defn: Dictionary) -> void:
	if _match_over or _turn_owner != 0:
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
	var pending_damage_player_core := 0
	var pending_damage_enemy_core := 0

	for i in COLS * ROWS:
		var u: UnitState = _grid_enemy[i]
		if u == null:
			continue
		var target: UnitState = _grid_player[i]
		if target != null:
			_apply_hit(u, target)
		else:
			pending_damage_player_core += u.atk

	for i in COLS * ROWS:
		var u2: UnitState = _grid_player[i]
		if u2 == null:
			continue
		var tgt := u2.attack_target
		if tgt == BattleResolver.TARGET_UNSET:
			tgt = i
		if tgt == BattleResolver.TARGET_CORE:
			pending_damage_enemy_core += u2.atk
			continue
		if tgt >= 0 and tgt < _grid_enemy.size():
			var def: UnitState = _grid_enemy[tgt]
			if def != null:
				_apply_hit(u2, def)
			else:
				pending_damage_enemy_core += u2.atk

	_player_core_hp -= pending_damage_player_core
	_enemy_core_hp -= pending_damage_enemy_core

	_cleanup_dead(_grid_player)
	_cleanup_dead(_grid_enemy)
	_refresh_ui()

func _cleanup_dead(grid: Array) -> void:
	for idx in grid.size():
		var u: UnitState = grid[idx]
		if u != null and u.hp <= 0:
			grid[idx] = null

func _check_end() -> bool:
	if _player_core_hp <= 0 or _enemy_core_hp <= 0:
		_finish_match()
		return true
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
	var payout := 15
	if player_won:
		payout = 40
	GameState.coins += payout
	if player_won:
		GameState.progress["battles_won"] = int(GameState.progress.get("battles_won", 0)) + 1
	if GameState.active_slot >= 1:
		SaveSystem.write_slot(GameState.active_slot, GameState.to_save())
	var msg := "Defeat. +%d coins" % payout
	if player_won:
		msg = "Victory! +%d coins" % payout
	_lbl_toast.text = msg
	_results_label.text = "%s\n\n(Player Core %d vs Enemy Core %d)" % [msg, _player_core_hp, _enemy_core_hp]
	_results_panel.visible = true

func _is_exhausted_player() -> bool:
	return _no_units(_grid_player) and not _has_playable_hand(_hand, _player_filament, _grid_player)

func _is_exhausted_enemy() -> bool:
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
	var turn_label := "Enemy turn"
	if _turn_owner == 0:
		turn_label = "Your turn"
	_lbl_state.text = "Turn %d | Player HP %d | Enemy HP %d | Filament %d/%d | %s" % [
		_turn,
		_player_core_hp,
		_enemy_core_hp,
		_player_filament,
		_player_filament_max,
		turn_label
	]
	if _btn_end != null:
		_btn_end.disabled = _match_over or (_turn_owner != 0)
	_refresh_grid_ui()

func _make_side(title: String, is_player_team: bool) -> Control:
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
	if is_player_team:
		grid.name = "PlayerGrid"
	else:
		grid.name = "EnemyGrid"
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	side.add_child(grid)

	for i in COLS * ROWS:
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(160, 90)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "Empty"
		var idx := i
		var player_side := is_player_team
		btn.pressed.connect(func(): _on_grid_cell_pressed(player_side, idx))
		grid.add_child(btn)
		if is_player_team:
			_player_grid_buttons.append(btn)
		else:
			_enemy_grid_buttons.append(btn)

	return side

func _refresh_grid_ui() -> void:
	for i in COLS * ROWS:
		_set_cell_button(_enemy_grid_buttons[i], _grid_enemy[i], false, i)
		_set_cell_button(_player_grid_buttons[i], _grid_player[i], true, i)

func _set_cell_button(btn: Button, u: UnitState, is_player_unit: bool, slot: int) -> void:
	if u == null:
		btn.text = "Empty"
		return
	var aim := ""
	if is_player_unit:
		if u.attack_target == BattleResolver.TARGET_CORE:
			aim = " →Core"
		elif u.attack_target != BattleResolver.TARGET_UNSET:
			aim = " →%d" % u.attack_target
	btn.text = "%s\n%s HP:%d ATK:%d%s" % [u.name, u.element, u.hp, u.atk, aim]

func _divider() -> Control:
	var c := ColorRect.new()
	c.color = Color(1, 1, 1, 0.15)
	c.custom_minimum_size = Vector2(0, 2)
	return c
