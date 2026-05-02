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

var _arena_world: Node3D
var _arena_player_meshes: Array[MeshInstance3D] = []
var _arena_enemy_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	name = "BattleScreen"
	anchor_right = 1
	anchor_bottom = 1
	_rng.randomize()

	_player_filament_max = int(GameState.printer_upgrades.get("filament_cap", 3))
	_enemy_filament_max = GameRules.enemy_filament_max_for_battle_mode(GameState.battle_mode)
	_player_core_hp = CORE_HP_START + GameRules.player_core_hp_bonus(int(GameState.printer_upgrades.get("core_armor", 0)))

	_grid_player.resize(COLS * ROWS)
	_grid_enemy.resize(COLS * ROWS)

	_setup_battle_arena_3d()

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
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
	var mode_hint := ""
	match GameState.battle_mode:
		GameRules.BATTLE_MODE_MID:
			mode_hint = "[Midtown — rival +1 filament cap, sharper prints] "
		GameRules.BATTLE_MODE_BOSS:
			mode_hint = "[Boss spire — rival +2 filament, elite summons] "
	hand_title.text = "%sSummon from hand, then tap your unit → enemy cell (or Core) to aim attacks. End Turn resolves both sides." % mode_hint
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

	call_deferred("_begin_coin_flip_sequence")

func _begin_coin_flip_sequence() -> void:
	_match_over = false
	_results_panel.visible = false
	_turn_owner = _rng.randi_range(0, 1)

	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.color = Color(0.05, 0.07, 0.12, 0.75)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var hdr := Label.new()
	hdr.text = "Filament coin toss"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 22)
	vb.add_child(hdr)

	var coin := Label.new()
	coin.text = "◉"
	coin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin.add_theme_font_size_override("font_size", 64)
	coin.modulate = Color(1.0, 0.82, 0.28)
	vb.add_child(coin)

	var sub := Label.new()
	sub.text = "Heating nozzle… flipping…"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(sub)

	var tw := create_tween()
	tw.set_loops(8)
	tw.tween_property(coin, "scale", Vector2(1.14, 1.14), 0.08)
	tw.tween_property(coin, "scale", Vector2(1.0, 1.0), 0.08)

	await get_tree().create_timer(0.75).timeout
	tw.kill()
	if _turn_owner == 0:
		sub.text = "You print first."
	else:
		sub.text = "Enemy printer goes first."
	sub.add_theme_font_size_override("font_size", 18)

	await get_tree().create_timer(1.15).timeout
	layer.queue_free()
	_apply_match_start_after_coin()


func _apply_match_start_after_coin() -> void:
	_turn = 1
	_player_filament = 0
	_enemy_filament = 0
	_targeting_from_slot = -1
	var starter := "Enemy"
	if _turn_owner == 0:
		starter = "Player"
	_lbl_toast.text = "%s starts — summon & aim, then End Turn." % starter
	_draw_new_hand()
	_start_turn()

func _apply_touch_layout() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var short_side: float = minf(vp_size.x, vp_size.y)
	if short_side < 720.0:
		var sz: Vector2 = Vector2(180, 104)
		for b: Button in _player_grid_buttons:
			b.custom_minimum_size = sz
		for b: Button in _enemy_grid_buttons:
			b.custom_minimum_size = sz

func _apply_hit(attacker: UnitState, defender: UnitState) -> void:
	if attacker == null or defender == null:
		return
	if defender.element == "TPU" and BattleResolver.tpu_dodges(_rng):
		_lbl_toast.text = "%s dodged %s's attack!" % [defender.name, attacker.name]
		return
	var dmg: int = BattleResolver.effective_damage(attacker.element, attacker.atk, defender.element)
	defender.hp -= dmg

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

func _start_turn() -> void:
	_player_filament = mini(_player_filament + 1, _player_filament_max)
	_enemy_filament = mini(_enemy_filament + 1, _enemy_filament_max)
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
		var defn: Dictionary = UnitDatabase.get_unit(id)
		if not defn.is_empty():
			_hand.append(defn)
	if _hand.is_empty():
		_hand = UnitDatabase.random_units_from(UnitDatabase.active_roster_for_stage(), 5, _rng)
	_refresh_hand_ui()

func _refresh_hand_ui() -> void:
	for c in _player_hand_row.get_children():
		c.queue_free()
	for defn in _hand:
		var row: Dictionary = defn
		var b := Button.new()
		var cost: int = int(row.get("cost", 1))
		var elem: String = str(row.get("element", "?"))
		b.text = "%s (C%d) · %s" % [str(row.get("name", "Unit")), cost, elem]
		b.pressed.connect(_try_summon_from_hand.bind(row))
		_player_hand_row.add_child(b)

func _try_summon_from_hand(defn: Dictionary) -> void:
	if _match_over or _turn_owner != 0:
		_lbl_toast.text = "Wait your turn."
		return
	var cost: int = int(defn.get("cost", 1))
	if cost > _player_filament:
		_lbl_toast.text = "Not enough filament."
		return
	var empty: int = _first_empty_index(_grid_player)
	if empty < 0:
		_lbl_toast.text = "No empty slot."
		return
	_player_filament -= cost
	_grid_player[empty] = UnitState.new(defn, 0, empty)
	_lbl_toast.text = "Summoned %s." % str(defn.get("name", "Unit"))
	_refresh_ui()

func _enemy_roster_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = UnitDatabase.active_roster_for_stage()
	match GameState.battle_mode:
		GameRules.BATTLE_MODE_MID:
			var mid: Array[Dictionary] = []
			for u in pool:
				if int(u.get("tier_level", 1)) >= 2:
					mid.append(u)
			if not mid.is_empty():
				return mid
			return pool
		GameRules.BATTLE_MODE_BOSS:
			var hi: Array[Dictionary] = []
			for u in pool:
				if int(u.get("tier_level", 1)) >= 4:
					hi.append(u)
			if not hi.is_empty():
				return hi
			return pool
		_:
			return pool


func _enemy_best_summon_for_filament(filament: int) -> Dictionary:
	var pool: Array[Dictionary] = _enemy_roster_pool()
	var best: Dictionary = {}
	var best_score: int = -1
	for cand in pool:
		var c: int = int(cand.get("cost", 1))
		if c > filament:
			continue
		var atk: int = int(cand.get("atk", 1))
		var score: int = atk * 100 - c
		if score > best_score:
			best_score = score
			best = cand
	return best


func _enemy_play() -> void:
	var empty: int = _first_empty_index(_grid_enemy)
	if empty >= 0:
		var cand: Dictionary = _enemy_best_summon_for_filament(_enemy_filament)
		if not cand.is_empty():
			var c: int = int(cand.get("cost", 1))
			_enemy_filament -= c
			_grid_enemy[empty] = UnitState.new(cand, 1, empty)
			_lbl_toast.text = "Enemy printed %s." % str(cand.get("name", "Unit"))
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
		var tgt: int = u2.attack_target
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
	var payout: int = GameRules.BATTLE_LOSS_COINS
	if player_won:
		payout = GameRules.BATTLE_WIN_COINS
	GameState.coins += payout
	if player_won:
		GameState.progress["battles_won"] = int(GameState.progress.get("battles_won", 0)) + 1
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())
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
	var cheapest: int = 9999
	for d in _enemy_roster_pool():
		var ud: Dictionary = d
		cheapest = mini(cheapest, int(ud.get("cost", 1)))
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
	_lbl_state.text = "Turn %d | Player HP %d | Enemy HP %d | Your filament %d/%d | Enemy filament %d/%d | %s" % [
		_turn,
		_player_core_hp,
		_enemy_core_hp,
		_player_filament,
		_player_filament_max,
		_enemy_filament,
		_enemy_filament_max,
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
		btn.custom_minimum_size = Vector2(160, 90)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "Empty"
		_style_grid_hud_button(btn)
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
	_sync_arena_meshes()

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
	c.color = Color(1, 1, 1, 0.28)
	c.custom_minimum_size = Vector2(0, 2)
	return c


func _setup_battle_arena_3d() -> void:
	var vp_c := SubViewportContainer.new()
	vp_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_c.offset_right = 0
	vp_c.offset_bottom = 0
	vp_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp_c.stretch = true
	add_child(vp_c)

	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	vp.handle_input_locally = false
	vp.add_child(_create_arena_scene_root())
	vp_c.add_child(vp)


func _create_arena_scene_root() -> Node3D:
	_arena_world = Node3D.new()

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.52, 0.74, 0.96)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.97, 1.0)
	env.ambient_light_energy = 0.5
	we.environment = env
	_arena_world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 38, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.98, 0.92)
	_arena_world.add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 12.0, 16.5)
	cam.look_at(Vector3(0, 0.35, 0), Vector3.UP)
	cam.fov = 56.0
	cam.current = true
	_arena_world.add_child(cam)

	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 15)
	floor_mi.mesh = plane
	floor_mi.position = Vector3(0, -0.02, 0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.86, 0.93, 0.98)
	floor_mat.roughness = 0.78
	floor_mi.material_override = floor_mat
	_arena_world.add_child(floor_mi)

	_arena_player_meshes.resize(COLS * ROWS)
	_arena_enemy_meshes.resize(COLS * ROWS)
	for i in COLS * ROWS:
		var pm := _make_placeholder_unit_mesh(i, true)
		var em := _make_placeholder_unit_mesh(i, false)
		_arena_player_meshes[i] = pm
		_arena_enemy_meshes[i] = em
		_arena_world.add_child(pm)
		_arena_world.add_child(em)
	_sync_arena_meshes()
	return _arena_world


func _arena_slot_world_pos(is_player_side: bool, slot_index: int) -> Vector3:
	var row := slot_index / COLS
	var col := slot_index % COLS
	var spread_x := 2.75
	var spread_z := 2.05
	var x: float = (float(col) - 1.5) * spread_x
	var z_player_base := 5.3
	var z_enemy_base := -5.3
	var z_row := float(row) * spread_z
	if is_player_side:
		return Vector3(x, 0.62, z_player_base - z_row)
	return Vector3(x, 0.62, z_enemy_base + z_row)


func _make_placeholder_unit_mesh(slot_index: int, is_player_side: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var kind: int = slot_index % 3
	if kind == 0:
		var cap := CapsuleMesh.new()
		cap.radius = 0.46
		cap.height = 1.22
		mi.mesh = cap
	elif kind == 1:
		var box := BoxMesh.new()
		box.size = Vector3(0.88, 1.1, 0.88)
		mi.mesh = box
	else:
		var sph := SphereMesh.new()
		sph.radius = 0.52
		mi.mesh = sph
	mi.position = _arena_slot_world_pos(is_player_side, slot_index)
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.38
	mat.roughness = 0.42
	mat.albedo_color = Color(0.82, 0.85, 0.88)
	mi.material_override = mat
	mi.visible = false
	return mi


func _element_albedo(element: String) -> Color:
	match element:
		"Heat":
			return Color(1.0, 0.34, 0.26)
		"PLA":
			return Color(0.32, 0.88, 0.46)
		"Resin":
			return Color(0.32, 0.52, 1.0)
		"TPU":
			return Color(0.96, 0.82, 0.22)
		"Carbon":
			return Color(0.52, 0.56, 0.62)
		_:
			return Color(0.76, 0.78, 0.86)


func _sync_arena_meshes() -> void:
	if _arena_player_meshes.size() != COLS * ROWS:
		return
	for i in COLS * ROWS:
		_sync_one_unit_mesh(_arena_player_meshes[i], _grid_player[i])
		_sync_one_unit_mesh(_arena_enemy_meshes[i], _grid_enemy[i])


func _sync_one_unit_mesh(mi: MeshInstance3D, u: UnitState) -> void:
	if u == null:
		mi.visible = false
		return
	mi.visible = true
	var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = _element_albedo(u.element)


func _style_grid_hud_button(btn: Button) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(1, 1, 1, 0.12)
	base.border_width_left = 2
	base.border_width_top = 2
	base.border_width_right = 2
	base.border_width_bottom = 2
	base.border_color = Color(0.25, 0.55, 0.85, 0.35)
	base.corner_radius_top_left = 14
	base.corner_radius_top_right = 14
	base.corner_radius_bottom_left = 14
	base.corner_radius_bottom_right = 14
	var hover := base.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.26)
	hover.border_color = Color(0.95, 0.55, 0.35, 0.55)
	var pressed := base.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.75, 0.92, 1.0, 0.38)
	btn.add_theme_stylebox_override("normal", base)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", Color(0.1, 0.14, 0.22))
	btn.add_theme_color_override("font_hover_color", Color(0.06, 0.1, 0.18))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.08, 0.14))
