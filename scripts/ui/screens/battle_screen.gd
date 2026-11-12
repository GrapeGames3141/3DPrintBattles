extends GameScreen
## The battlefield. It shows whatever view of the battle its BattleSession
## gives it, turns clicks and drags into actions, and animates the events the
## rules engine reports back.

const MID_X := 646.0
const UNIT_PITCH := 138.0
const ROW_FOE := 112.0
const ROW_ME := 300.0
const BED_RECT_FOE := Rect2(226, 108, 840, 186)
const BED_RECT_ME := Rect2(226, 298, 840, 186)
const HAND_SCALE := 0.44
const HAND_Y := 532.0
const RAISED_SCALE := 0.72
const DECK_POS := Vector2(1180, 520)

var session: BattleSession
var st: Dictionary = {}
var me := 0

var _units: Dictionary = {}          # uid -> BoardUnit
var _rows: Array = [[], []]          # seat -> [uid] in board order
var _hand: Array = []                # [{uid, id, node}]
var _foe_backs: Array = []
var _printers: Array = [null, null]

var _board: Control
var _hand_layer: Control
var _fx: Control
var _arrow: Control
var _end_btn: Button
var _end_go: Button
var _power_btn: Button
var _power_cost: Badge
var _fil_me: Control
var _fil_foe: Control
var _fil: Array = [[0, 0], [0, 0]]
var _info_me: Label
var _info_foe: Label
var _preview: Control
var _menu: Control

var _queue: Array = []
var _busy := false
var _mode := "idle"                  # idle | drag | target
var _src: Dictionary = {}
var _valid: Array = []
var _sticky := false
var _press := Vector2.ZERO
var _mouse := Vector2.ZERO
var _hover_uid := -1
var _locked := false                 # result or curtain is showing
var _closed := false


func build() -> void:
	session = args["session"]
	st = session.view()
	me = session.my_seat
	if session.mode == "hotseat":
		me = int(st["active"])
	app.set_background("res://assets/ui/battle_backgrounds/%s_landscape_v1.png" % session.arena, 0.32)
	Audio.music("battle")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_board = Control.new()
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board)
	_build_beds()
	_build_hud()
	_hand_layer = Control.new()
	_hand_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_layer)
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.z_index = 50
	add_child(_fx)
	_arrow = Control.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.z_index = 45
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)

	session.updated.connect(_on_update)
	session.closed.connect(_on_closed)
	_rebuild()
	if session.mode == "hotseat":
		_curtain()
	else:
		var mine: bool = int(st["active"]) == me
		_banner("You go first" if mine else "%s goes first" % session.names[1 - me], UI.GOLD if mine else UI.BAD)
		_after_idle()


func _exit_tree() -> void:
	super()
	if session != null:
		if session.updated.is_connected(_on_update):
			session.updated.disconnect(_on_update)
		if session.closed.is_connected(_on_closed):
			session.closed.disconnect(_on_closed)
		session.leave()


# ------------------------------------------------------------------ layout

func _build_beds() -> void:
	for r in [BED_RECT_FOE, BED_RECT_ME]:
		var bed := UI.panel(_board, r, UI.box(Color(0.03, 0.05, 0.09, 0.62), Color(0.3, 0.62, 0.86, 0.55), 2, 16, 8))
		var grid := Control.new()
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.size = r.size
		bed.add_child(grid)
		grid.draw.connect(func():
			var c := Color(0.35, 0.7, 0.95, 0.10)
			var x := 20.0
			while x < r.size.x - 10:
				grid.draw_line(Vector2(x, 10), Vector2(x, r.size.y - 10), c, 1.0)
				x += 40.0
			var y := 13.0
			while y < r.size.y - 10:
				grid.draw_line(Vector2(10, y), Vector2(r.size.x - 10, y), c, 1.0)
				y += 40.0)


func _build_hud() -> void:
	var menu := UI.button("Menu", "plain", Vector2(96, 40), 17)
	menu.pressed.connect(_open_menu)
	UI.place(self, menu, Vector2(16, 14))

	# Right column: opponent summary, End Turn, your Filament.
	UI.panel(self, Rect2(1082, 96, 182, 108), UI.box(Color(0.03, 0.05, 0.1, 0.8), UI.BRASS_DARK, 2, 12))
	_info_foe = UI.label("", 15, UI.CREAM, false)
	UI.place(self, _info_foe, Vector2(1094, 102), Vector2(160, 44))
	_fil_foe = _make_pips(13.0)
	UI.place(self, _fil_foe, Vector2(1094, 150), Vector2(160, 46))

	_end_btn = UI.button("End Turn", "primary", Vector2(182, 62), 24)
	_end_btn.pressed.connect(_end_turn)
	UI.place(self, _end_btn, Vector2(1082, 264))
	_end_go = UI.button("End Turn", "go", Vector2(182, 62), 24)
	_end_go.pressed.connect(_end_turn)
	UI.place(self, _end_go, Vector2(1082, 264))

	UI.panel(self, Rect2(1082, 386, 182, 128), UI.box(Color(0.03, 0.05, 0.1, 0.8), UI.BRASS_DARK, 2, 12))
	_info_me = UI.label("", 15, UI.CREAM, false)
	UI.place(self, _info_me, Vector2(1094, 392), Vector2(160, 44))
	_fil_me = _make_pips(15.0)
	UI.place(self, _fil_me, Vector2(1094, 440), Vector2(160, 66))

	_power_btn = UI.button("", "primary", Vector2(190, 50), 16)
	_power_btn.pressed.connect(_on_power)
	_power_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.place(self, _power_btn, Vector2(30, 486))
	_power_cost = Badge.make("spool", CardView.COST_BLUE, 38)
	_power_cost.position = Vector2(150, 6)
	_power_cost.set_value(GameData.POWER_COST)
	_power_btn.add_child(_power_cost)


func _make_pips(r: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_meta("r", r)
	c.set_meta("fil", 0)
	c.set_meta("max", 0)
	c.draw.connect(func():
		var fil: int = c.get_meta("fil")
		var cap: int = c.get_meta("max")
		for i in GameData.MAX_FILAMENT:
			var pos := Vector2(r + (i % 5) * (r * 2.0 + 4.0), r + (i / 5) * (r * 2.0 + 4.0))
			if i < fil:
				UI.draw_icon(c, "spool", pos, r, UI.CYAN)
			elif i < cap:
				UI.draw_icon(c, "spool", pos, r, Color("27405e"))
			else:
				c.draw_arc(pos, r * 0.8, 0, TAU, 20, Color(1, 1, 1, 0.12), 1.5, true))
	return c


func _set_fil(seat: int, fil: int, cap: int) -> void:
	_fil[seat] = [fil, cap]
	var pips := _fil_me if seat == me else _fil_foe
	pips.set_meta("fil", fil)
	pips.set_meta("max", cap)
	pips.queue_redraw()
	_refresh_info()


func _refresh_info() -> void:
	var p: Dictionary = st["players"][me]
	var f: Dictionary = st["players"][1 - me]
	_info_me.text = "Filament %d / %d\nDeck %d" % [_fil[me][0], _fil[me][1], (p["deck"] as Array).size()]
	_info_foe.text = "Filament %d / %d\nHand %d   Deck %d" % [_fil[1 - me][0], _fil[1 - me][1], (f["hand"] as Array).size(), (f["deck"] as Array).size()]


## Throws away every battlefield node and builds it again from the state.
## Used at the start and whenever the seat at the bottom changes.
func _rebuild() -> void:
	for uid in _units:
		(_units[uid] as Node).queue_free()
	_units.clear()
	for h in _hand:
		(h["node"] as Node).queue_free()
	_hand.clear()
	for b in _foe_backs:
		(b as Node).queue_free()
	_foe_backs.clear()
	for seat in 2:
		if _printers[seat] != null:
			(_printers[seat] as Node).queue_free()
		var pv := PrinterView.make(st["players"][seat]["printer"], seat, session.names[seat])
		pv.position = Vector2(34, 300 if seat == me else 112)
		_board.add_child(pv)
		_printers[seat] = pv
	var power: Dictionary = GameData.printer(st["players"][me]["printer"])["power"]
	_power_btn.text = power["name"]
	_power_btn.tooltip_text = power["text"]
	_sync(false)


func _row_y(seat: int) -> float:
	return ROW_ME if seat == me else ROW_FOE


func _slot_pos(seat: int, index: int, count: int) -> Vector2:
	return Vector2(MID_X + (index - (count - 1) * 0.5) * UNIT_PITCH - 70.0, _row_y(seat) + 6.0)


func _layout_row(seat: int, animate := true) -> void:
	var row: Array = _rows[seat]
	for i in row.size():
		var node: BoardUnit = _units.get(row[i])
		if node == null:
			continue
		var pos := _slot_pos(seat, i, row.size())
		if animate:
			node.create_tween().tween_property(node, "position", pos, 0.16).set_ease(Tween.EASE_OUT)
		else:
			node.position = pos


## Where a hand card's centre sits, and how far it is tilted, in the fan.
func _hand_slot(index: int, count: int) -> Dictionary:
	var w := CardView.W * HAND_SCALE
	var pitch := minf(w + 6.0, 760.0 / maxf(count, 1.0))
	var off := index - (count - 1) * 0.5
	return {
		"center": Vector2(MID_X + off * pitch, HAND_Y + CardView.H * HAND_SCALE * 0.5 + off * off * 2.4),
		"rot": deg_to_rad(off * 2.2),
	}


func _layout_hand(animate := true) -> void:
	var half := Vector2(CardView.W, CardView.H) * 0.5
	for i in _hand.size():
		var h: Dictionary = _hand[i]
		var node: CardView = h["node"]
		if _mode == "drag" and _src.get("node") == node:
			continue
		var slot := _hand_slot(i, _hand.size())
		var center: Vector2 = slot["center"]
		var s := HAND_SCALE
		var rot: float = slot["rot"]
		var raised: bool = int(h["uid"]) == _hover_uid or (_mode == "target" and _src.get("node") == node)
		node.z_index = 20 if raised else i
		if raised:
			s = RAISED_SCALE
			rot = 0.0
			center = Vector2(clampf(center.x, 8.0 + half.x * s, 1272.0 - half.x * s), 716.0 - half.y * s)
		var pos := center - half
		if animate:
			var tw := node.create_tween().set_parallel(true)
			tw.tween_property(node, "position", pos, 0.12)
			tw.tween_property(node, "scale", Vector2(s, s), 0.12)
			tw.tween_property(node, "rotation", rot, 0.12)
		else:
			node.position = pos
			node.scale = Vector2(s, s)
			node.rotation = rot
	var n := _foe_backs.size()
	for i in n:
		var b: CardView = _foe_backs[i]
		var x := MID_X + (i - (n - 1) * 0.5) * 46.0 - CardView.W * 0.1
		var target := Vector2(x, -46.0)
		if animate:
			b.create_tween().tween_property(b, "position", target, 0.12)
		else:
			b.position = target


## Makes the screen match the state exactly (after animations have played).
func _sync(animate := true) -> void:
	for seat in 2:
		var p: Dictionary = st["players"][seat]
		var row: Array = []
		for u in p["board"]:
			var uid: int = int(u["uid"])
			row.append(uid)
			if not _units.has(uid):
				var node := BoardUnit.make(u, seat != me)
				_board.add_child(node)
				_units[uid] = node
				node.position = _slot_pos(seat, row.size() - 1, (p["board"] as Array).size())
			(_units[uid] as BoardUnit).refresh(u, false)
		_rows[seat] = row
		(_printers[seat] as PrinterView).set_state(p)
		_fil[seat] = [int(p["fil"]), int(p["max_fil"])]
	var alive: Dictionary = {}
	for seat in 2:
		for uid in _rows[seat]:
			alive[uid] = true
	for uid in _units.keys():
		if not alive.has(uid):
			(_units[uid] as Node).queue_free()
			_units.erase(uid)
	for seat in 2:
		_layout_row(seat, animate)

	# My hand: keep the nodes that are still there, add the new, drop the gone.
	var want: Array = st["players"][me]["hand"]
	var keep: Array = []
	for c in want:
		var found: Dictionary = {}
		for h in _hand:
			if int(h["uid"]) == int(c["uid"]):
				found = h
				break
		if found.is_empty():
			found = {"uid": int(c["uid"]), "id": c["id"], "node": _new_hand_card(c["id"])}
		keep.append(found)
	for h in _hand:
		if not keep.has(h):
			(h["node"] as Node).queue_free()
	_hand = keep
	var foe_n: int = (st["players"][1 - me]["hand"] as Array).size()
	while _foe_backs.size() > foe_n:
		(_foe_backs.pop_back() as Node).queue_free()
	while _foe_backs.size() < foe_n:
		_foe_backs.append(_new_back())
	_layout_hand(animate)
	_set_fil(0, _fil[0][0], _fil[0][1])
	_set_fil(1, _fil[1][0], _fil[1][1])
	_refresh_interactive()


func _new_hand_card(id: String) -> CardView:
	var c := CardView.make(id, HAND_SCALE)
	c.pivot_offset = Vector2(CardView.W, CardView.H) * 0.5
	c.position = DECK_POS - c.pivot_offset
	_hand_layer.add_child(c)
	return c


func _new_back() -> CardView:
	var b := CardView.make("?", 0.2)
	b.position = Vector2(MID_X, -90)
	_hand_layer.add_child(b)
	return b


func _my_turn() -> bool:
	return not _busy and not _locked and not st["over"] and int(st["active"]) == me and session.is_human(me)


## Updates everything that depends on what the player may do right now.
func _refresh_interactive() -> void:
	var mine := _my_turn()
	for h in _hand:
		var node: CardView = h["node"]
		var playable := mine and BattleEngine.play_error(st, me, int(h["uid"])) == ""
		node.set_glow(UI.GOOD if playable else null)
	for uid in _units:
		var node: BoardUnit = _units[uid]
		node.set_ready(mine and int(node.u["seat"]) == me and not BattleEngine.attack_targets(st, uid).is_empty())
	var idle := mine and BattleEngine.legal_actions(st, me).size() <= 1
	_end_btn.visible = not idle
	_end_go.visible = idle
	_end_btn.disabled = not mine
	_end_btn.text = "End Turn" if int(st["active"]) == me else "Enemy Turn"
	_power_btn.disabled = not (mine and BattleEngine.power_error(st, me) == "")
	_power_cost.modulate = Color(1, 1, 1, 0.45) if _power_btn.disabled else Color.WHITE
	_show_targets()


func _show_targets() -> void:
	var col := UI.BAD
	if _mode == "target" and not _src.is_empty():
		col = UI.BAD if _harmful() else UI.GOOD
	for uid in _units:
		(_units[uid] as BoardUnit).set_targeted(_mode == "target" and _valid.has("u%d" % uid), col)
	for seat in 2:
		(_printers[seat] as PrinterView).set_targeted(_mode == "target" and _valid.has("p%d" % seat), col)


func _harmful() -> bool:
	if _src.get("kind") == "unit":
		return true
	var kind := ""
	if _src.get("kind") == "card":
		kind = GameData.card(_src["id"]).get("target", "")
	else:
		kind = GameData.printer(st["players"][me]["printer"])["power"].get("target", "")
	return kind.begins_with("enemy")


# ------------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if _locked or is_instance_valid(_menu):
		return
	if event is InputEventMouseMotion:
		_mouse = (make_input_local(event) as InputEventMouse).position
		_update_hover()
		if _mode == "drag":
			var node: CardView = _src["node"]
			node.position = _mouse - Vector2(CardView.W, CardView.H) * 0.5
			node.rotation = 0.0
		_arrow.queue_redraw()
	elif event is InputEventMouseButton:
		_mouse = (make_input_local(event) as InputEventMouse).position
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press()
			else:
				_on_release()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _mode != "idle":
				_cancel()
			else:
				_open_menu()
		elif event.keycode == KEY_SPACE and _my_turn() and _mode == "idle":
			_end_turn()


func _hand_at(p: Vector2) -> Dictionary:
	# The raised card wins, then the right-most (top-most) card under the point.
	for pass_raised in [true, false]:
		for i in range(_hand.size() - 1, -1, -1):
			var h: Dictionary = _hand[i]
			var node: CardView = h["node"]
			if pass_raised != (int(h["uid"]) == _hover_uid):
				continue
			var half := Vector2(CardView.W, CardView.H) * node.scale * 0.5
			var c := node.position + Vector2(CardView.W, CardView.H) * 0.5
			if absf(p.x - c.x) <= half.x and absf(p.y - c.y) <= half.y:
				return h
	return {}


func _unit_at(p: Vector2) -> int:
	for uid in _units:
		var node: BoardUnit = _units[uid]
		if Rect2(node.position + Vector2(4, 0), Vector2(132, 168)).has_point(p):
			return uid
	return -1


func _ref_at(p: Vector2) -> String:
	var uid := _unit_at(p)
	if uid >= 0:
		return "u%d" % uid
	for seat in 2:
		var pv: PrinterView = _printers[seat]
		if Rect2(pv.position, PrinterView.SIZE).has_point(p):
			return "p%d" % seat
	return ""


func _update_hover() -> void:
	var uid := -1
	if _mode == "idle":
		var h := _hand_at(_mouse)
		if not h.is_empty():
			uid = int(h["uid"])
	if uid != _hover_uid:
		_hover_uid = uid
		_layout_hand()
	# Show the full card for a print on the bed while pointing at it.
	var over := _unit_at(_mouse) if _mode == "idle" and uid < 0 else -1
	var shown: int = _preview.get_meta("uid") if is_instance_valid(_preview) else -1
	if over != shown:
		if is_instance_valid(_preview):
			_preview.queue_free()
			_preview = null
		if over >= 0:
			var node: BoardUnit = _units[over]
			var card := CardView.make(node.u["id"], 0.62)
			card.set_meta("uid", over)
			card.z_index = 40
			var x := node.position.x + 150.0 if node.position.x < 760.0 else node.position.x - CardView.W * 0.62 - 10.0
			card.position = Vector2(x, clampf(node.position.y - 40.0, 8.0, 712.0 - CardView.H * 0.62))
			add_child(card)
			_preview = card


func _on_press() -> void:
	if _mode == "target" and _sticky:
		var ref := _ref_at(_mouse)
		if _valid.has(ref):
			_commit(ref)
			get_viewport().set_input_as_handled()
		else:
			_cancel()
		return
	if not _my_turn():
		return
	var h := _hand_at(_mouse)
	if not h.is_empty():
		get_viewport().set_input_as_handled()
		var err := BattleEngine.play_error(st, me, int(h["uid"]))
		if err != "":
			_deny(err)
			return
		_press = _mouse
		_src = {"kind": "card", "uid": int(h["uid"]), "id": h["id"], "node": h["node"]}
		if BattleEngine.needs_target(st, me, h["id"]):
			_begin_target(BattleEngine.play_targets(st, me, h["id"]))
		else:
			_mode = "drag"
			_hover_uid = -1
			var node: CardView = h["node"]
			node.z_index = 30
			node.scale = Vector2(0.56, 0.56)
		return
	var uid := _unit_at(_mouse)
	if uid >= 0 and int((_units[uid] as BoardUnit).u["seat"]) == me:
		get_viewport().set_input_as_handled()
		var targets := BattleEngine.attack_targets(st, uid)
		if targets.is_empty():
			var u := BattleEngine.find_unit(st, uid)
			if int(u["jam"]) > 0:
				_deny("That print is jammed this turn.")
			elif bool(u["fresh"]):
				_deny("Fresh prints need a turn before they can attack.")
			elif int(u["attacks"]) > 0:
				_deny("That print has already attacked.")
			else:
				_deny("That print cannot attack.")
			return
		_press = _mouse
		_src = {"kind": "unit", "uid": uid, "node": _units[uid]}
		_begin_target(targets)


func _on_release() -> void:
	if _mode == "drag":
		var uid: int = _src["uid"]
		_mode = "idle"
		if _mouse.y < 500.0:
			var slot := 0
			for other in _rows[me]:
				if (_units[other] as BoardUnit).center().x < _mouse.x:
					slot += 1
			_send({"t": "play", "hand": uid, "slot": slot})
		else:
			_src = {}
			_layout_hand()
	elif _mode == "target" and not _sticky:
		var ref := _ref_at(_mouse)
		if _valid.has(ref):
			_commit(ref)
		elif _mouse.distance_to(_press) < 16.0:
			_sticky = true    # a plain click: wait for a second click on the target
		else:
			_cancel()


func _begin_target(targets: Array) -> void:
	_mode = "target"
	_valid = targets
	_sticky = false
	_hover_uid = -1
	_layout_hand()
	_show_targets()
	_arrow.queue_redraw()


func _commit(ref: String) -> void:
	var src := _src
	_cancel(false)
	match src["kind"]:
		"card":
			_send({"t": "play", "hand": src["uid"], "target": ref})
		"unit":
			_send({"t": "attack", "unit": src["uid"], "target": ref})
		"power":
			_send({"t": "power", "target": ref})


func _cancel(relayout := true) -> void:
	_mode = "idle"
	_src = {}
	_valid = []
	_sticky = false
	_show_targets()
	_arrow.queue_redraw()
	if relayout:
		_layout_hand()


func _send(action: Dictionary) -> void:
	var err := session.submit(me, action)
	_src = {}
	if err != "":
		_deny(err)
		_layout_hand()


func _deny(text: String) -> void:
	Audio.sfx("error")
	UI.floater(_fx, text, Vector2(MID_X, 296), UI.AMBER, 24, 26.0, 1.3)


func _end_turn() -> void:
	if _my_turn():
		_cancel()
		_send({"t": "end"})


func _on_power() -> void:
	if not _my_turn():
		return
	var err := BattleEngine.power_error(st, me)
	if err != "":
		_deny(err)
		return
	var targets := BattleEngine.power_targets(st, me)
	if targets.is_empty():
		_send({"t": "power"})
		return
	_src = {"kind": "power", "node": _power_btn}
	_begin_target(targets)
	_sticky = true


func _draw_arrow() -> void:
	if _mode != "target" or _src.is_empty():
		return
	var from: Vector2
	var node: Control = _src["node"]
	match _src["kind"]:
		"unit":
			from = (node as BoardUnit).center()
		"card":
			from = node.position + Vector2(CardView.W, CardView.H) * 0.5 + Vector2(0, -CardView.H * 0.5 * node.scale.y + 30.0)
		_:
			from = node.position + node.size * 0.5
	var to := _mouse
	var col := UI.BAD if _harmful() else UI.GOOD
	var ctrl := (from + to) * 0.5 + Vector2(0, -minf(120.0, from.distance_to(to) * 0.35))
	var pts := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		pts.append(from.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t))
	_arrow.draw_polyline(pts, Color(0, 0, 0, 0.55), 13.0, true)
	_arrow.draw_polyline(pts, col, 8.0, true)
	var dir := (to - pts[22]).normalized()
	var side := dir.orthogonal() * 16.0
	_arrow.draw_colored_polygon(PackedVector2Array([to + dir * 18.0, to - dir * 12.0 + side, to - dir * 12.0 - side]), col)


# --------------------------------------------------------------- playback

func _on_update(events: Array, view: Dictionary) -> void:
	_queue.append([events, view])
	if not _busy:
		_drain()


func _drain() -> void:
	_busy = true
	_cancel(false)
	_refresh_interactive()
	while not _queue.is_empty():
		var item: Array = _queue.pop_front()
		var events: Array = item[0]
		for i in events.size():
			await _play_event(events[i], events[i + 1] if i + 1 < events.size() else {})
			if not is_inside_tree():
				return
		st = item[1]
		_sync()
	_busy = false
	_refresh_interactive()
	_after_idle()


## Decides what happens once the animations have caught up.
func _after_idle() -> void:
	if st["over"] or _locked or _closed:
		return
	if session.mode == "hotseat":
		if int(st["active"]) != me:
			_curtain()
	elif session.is_ai_turn():
		await get_tree().create_timer(0.55).timeout
		if is_inside_tree() and not _busy:
			session.ai_step()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _node_for(ref: String) -> Control:
	if ref.begins_with("p"):
		return _printers[int(ref.substr(1))]
	return _units.get(int(ref.substr(1)))


func _center_of(ref: String) -> Vector2:
	var n := _node_for(ref)
	if n == null:
		return Vector2(MID_X, 300)
	return (n as PrinterView).center() if n is PrinterView else (n as BoardUnit).center()


func _banner(text: String, color: Color) -> void:
	var l := UI.label(text, 56, color, true, 14)
	l.z_index = 55
	_fx.add_child(l)
	l.reset_size()
	l.position = Vector2(MID_X, 300) - l.size * 0.5
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.3, 0.3)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 1.0, 0.12)
	tw.tween_interval(0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.2)
	tw.tween_callback(l.queue_free)


func _play_event(e: Dictionary, next: Dictionary) -> void:
	match e["e"]:
		"turn":
			var seat: int = int(e["seat"])
			_set_fil(seat, int(e["fil"]), int(e["max_fil"]))
			if session.mode == "hotseat":
				_banner("%s's turn" % session.names[seat], UI.GOLD)
			elif seat == me:
				_banner("Your turn", UI.GOLD)
			else:
				_banner("Enemy turn", UI.BAD)
			await _wait(0.75)
		"draw":
			var seat: int = int(e["seat"])
			Audio.sfx("card", 1.15)
			if seat == me:
				_hand.append({"uid": int(e["card"]["uid"]), "id": e["card"]["id"], "node": _new_hand_card(e["card"]["id"])})
			else:
				_foe_backs.append(_new_back())
			_layout_hand()
			await _wait(0.2)
		"burn":
			UI.floater(_fx, "Hand full! %s was lost." % GameData.card(e["id"])["name"], Vector2(MID_X, 300), UI.AMBER, 26, 30.0, 1.4)
			await _wait(0.5)
		"fatigue":
			UI.floater(_fx, "Spool empty!", _center_of("p%d" % int(e["seat"])) + Vector2(60, -70), UI.AMBER, 26, 30.0, 1.2)
			await _wait(0.25)
		"play":
			await _ev_play(e)
		"summon":
			await _ev_summon(e)
		"attack":
			await _ev_attack(e)
		"damage":
			_ev_damage(e)
			await _wait(0.07 if next.get("e", "") == "damage" else 0.26)
		"heal":
			var n := _node_for(e["target"])
			UI.floater(_fx, "+%d" % int(e["n"]), _center_of(e["target"]), UI.GOOD, 34)
			if n is PrinterView:
				var p: Dictionary = st["players"][(n as PrinterView).seat]
				(n as PrinterView).set_health(int(e["hp"]), int(p["max_hp"]), int(p["armor"]))
				(n as PrinterView).pulse()
			elif n is BoardUnit:
				var data: Dictionary = (n as BoardUnit).u
				data["hp"] = int(e["hp"])
				(n as BoardUnit).refresh(data, false)
			await _wait(0.22)
		"buff", "gear":
			var node: BoardUnit = _units.get(int(e["uid"]))
			if node != null:
				node.refresh(e["unit"], false)
				node.pulse(UI.GOOD)
				Audio.sfx("tool", 1.2)
				if e["e"] == "gear":
					UI.floater(_fx, GameData.card(e["id"])["name"], node.center() + Vector2(0, -70), UI.GOLD, 22)
			await _wait(0.12 if next.get("e", "") == "buff" else 0.3)
		"jam", "unjam":
			var node: BoardUnit = _units.get(int(e["uid"]))
			if node != null:
				var data: Dictionary = node.u
				data["jam"] = 1 if e["e"] == "jam" else 0
				node.refresh(data, false)
				if e["e"] == "jam":
					UI.floater(_fx, "Jammed!", node.center() + Vector2(0, -50), UI.CYAN, 24)
					await _wait(0.1 if next.get("e", "") == "jam" else 0.25)
		"death":
			var uid: int = int(e["uid"])
			var node: BoardUnit = _units.get(uid)
			if node != null:
				Audio.sfx("hit", 0.7)
				_units.erase(uid)
				(_rows[int(e["seat"])] as Array).erase(uid)
				await node.shatter()
				node.queue_free()
				_layout_row(int(e["seat"]))
		"bounce":
			var uid: int = int(e["uid"])
			var node: BoardUnit = _units.get(uid)
			if node != null:
				_units.erase(uid)
				(_rows[int(e["seat"])] as Array).erase(uid)
				var tw := node.create_tween().set_parallel(true)
				tw.tween_property(node, "position:y", node.position.y + (160.0 if int(e["seat"]) == me else -160.0), 0.25)
				tw.tween_property(node, "modulate:a", 0.0, 0.25)
				await tw.finished
				node.queue_free()
				_layout_row(int(e["seat"]))
		"power":
			var seat: int = int(e["seat"])
			_set_fil(seat, int(e["fil"]), _fil[seat][1])
			var pv: PrinterView = _printers[seat]
			pv.pulse()
			Audio.sfx("tool")
			UI.floater(_fx, GameData.printer(pv.printer_id)["power"]["name"], pv.center() + Vector2(40, -90), UI.GOLD, 24)
			await _wait(0.35)
		"fil":
			_set_fil(int(e["seat"]), int(e["fil"]), int(e["max_fil"]))
		"armor":
			var pv: PrinterView = _printers[int(e["seat"])]
			var p: Dictionary = st["players"][int(e["seat"])]
			p["armor"] = int(e["armor"])
			pv.set_health(int(p["hp"]), int(p["max_hp"]), int(e["armor"]))
			pv.pulse()
			UI.floater(_fx, "Armor up", pv.center() + Vector2(0, -80), Color("dfe6f0"), 24)
			await _wait(0.25)
		"over":
			await _wait(0.5)
			_show_result(int(e["winner"]))


func _ev_play(e: Dictionary) -> void:
	var seat: int = int(e["seat"])
	_set_fil(seat, int(e["fil"]), _fil[seat][1])
	var id: String = e["card"]["id"]
	var def := GameData.card(id)
	Audio.sfx("card")
	if seat == me:
		for h in _hand:
			if int(h["uid"]) == int(e["card"]["uid"]):
				_hand.erase(h)
				var node: CardView = h["node"]
				var tw := node.create_tween().set_parallel(true)
				tw.tween_property(node, "modulate:a", 0.0, 0.18)
				tw.tween_property(node, "position:y", node.position.y - 60.0, 0.18)
				tw.chain().tween_callback(node.queue_free)
				break
		_layout_hand()
		if def["type"] != "creature":
			Audio.sfx("tool")
			await _wait(0.2)
		return
	# The opponent's card is shown face-up long enough to read.
	if not _foe_backs.is_empty():
		(_foe_backs.pop_back() as Node).queue_free()
	_layout_hand()
	var card := CardView.make(id, 0.3)
	card.z_index = 42
	card.position = Vector2(MID_X - 45, -30)
	_fx.add_child(card)
	var show_pos := Vector2(820, 96)
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "position", show_pos, 0.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2(0.7, 0.7), 0.2)
	await tw.finished
	if def["type"] != "creature":
		Audio.sfx("tool")
	await _wait(0.55 if def["type"] == "creature" else 0.95)
	var out := card.create_tween()
	out.tween_property(card, "modulate:a", 0.0, 0.2)
	out.tween_callback(card.queue_free)


func _ev_summon(e: Dictionary) -> void:
	var seat: int = int(e["seat"])
	var unit: Dictionary = e["unit"]
	var uid: int = int(unit["uid"])
	var node := BoardUnit.make(unit, seat != me)
	_board.add_child(node)
	_units[uid] = node
	var row: Array = _rows[seat]
	row.insert(clampi(int(e["slot"]), 0, row.size()), uid)
	node.position = _slot_pos(seat, row.find(uid), row.size())
	_layout_row(seat)
	Audio.sfx("print", 1.3)
	# A bead of hot filament runs from the Printer to the bed.
	var pv: PrinterView = _printers[seat]
	pv.pulse()
	var bead := Line2D.new()
	bead.width = 5.0
	bead.default_color = GameData.element_color(node.def.get("element", "Neutral"))
	bead.add_point(pv.center() + Vector2(0, -20))
	bead.add_point(node.position + BoardUnit.PLATE)
	_fx.add_child(bead)
	var fade := bead.create_tween()
	fade.tween_property(bead, "modulate:a", 0.0, 0.55)
	fade.tween_callback(bead.queue_free)
	await node.play_print()


func _ev_attack(e: Dictionary) -> void:
	var node: BoardUnit = _units.get(int(e["uid"]))
	if node == null:
		return
	var home := node.position
	var dest := _center_of(e["target"]) - Vector2(70, 80)
	var reach := home.lerp(dest, 0.72)
	node.z_index = 10
	if node._sprite.texture is AtlasTexture:
		node.set_frame(5)
	var tw := node.create_tween()
	tw.tween_property(node, "position", home + (home - reach).normalized() * 14.0, 0.08)
	tw.tween_property(node, "position", reach, 0.13).set_ease(Tween.EASE_IN)
	await tw.finished
	var back := node.create_tween()
	back.tween_interval(0.1)
	back.tween_property(node, "position", home, 0.2).set_ease(Tween.EASE_OUT)
	back.tween_callback(func():
		node.z_index = 0
		if node._sprite.texture is AtlasTexture:
			node.set_frame(0))


func _ev_damage(e: Dictionary) -> void:
	var ref: String = e["target"]
	var n := _node_for(ref)
	if n == null:
		return
	var at := _center_of(ref)
	if bool(e.get("brim", false)):
		var bu: BoardUnit = n
		var data: Dictionary = bu.u
		(data["kw"] as Array).erase("brim")
		bu.refresh(data, false)
		UI.floater(_fx, "Brim!", at, UI.GOLD, 28)
		Audio.sfx("tool", 1.5)
		return
	Audio.sfx("hit")
	UI.floater(_fx, "-%d" % int(e["n"]), at + Vector2(randf_range(-10, 10), -10), UI.BAD, 40)
	if n is PrinterView:
		var pv: PrinterView = n
		var p: Dictionary = st["players"][pv.seat]
		pv.set_health(int(e["hp"]), int(p["max_hp"]), int(e.get("armor", 0)))
		pv.flash()
	else:
		var bu: BoardUnit = n
		var data: Dictionary = bu.u
		data["hp"] = int(e["hp"])
		bu.refresh(data, false)
		bu.flash()


# --------------------------------------------------------------- overlays

## Pass-and-play: hide both hands until the next player is at the screen.
func _curtain() -> void:
	_locked = true
	var seat: int = int(st["active"])
	var m := modal()
	(m.get_parent() as ColorRect).color = Color(0.02, 0.03, 0.07, 1.0)
	var t := UI.label("%s's turn" % session.names[seat], 60, UI.GOLD, true, 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(m, t, Vector2(0, 230), Vector2(1280, 80))
	var s := UI.label("Pass the screen over, then press Ready.", 24, UI.CREAM, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(m, s, Vector2(0, 320), Vector2(1280, 34))
	var b := UI.button("Ready", "go", Vector2(260, 66), 28)
	b.pressed.connect(func():
		me = seat
		_rebuild()
		close_modal(m)
		_locked = false
		_refresh_interactive())
	UI.place(m, b, Vector2(510, 400))


func _open_menu() -> void:
	if is_instance_valid(_menu) or _locked:
		return
	_cancel()
	_menu = modal()
	var box := UI.panel(_menu, Rect2(440, 210, 400, 300))
	var t := UI.label("Paused", 32, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 22), Vector2(400, 40))
	var resume := UI.button("Keep playing", "go", Vector2(300, 56), 22)
	resume.pressed.connect(func(): close_modal(_menu))
	UI.place(box, resume, Vector2(50, 90))
	var concede := UI.button("Concede the battle", "danger", Vector2(300, 56), 22)
	concede.pressed.connect(func():
		close_modal(_menu)
		if st["over"]:
			app.go("play")
		else:
			session.submit(me, {"t": "concede"}))
	UI.place(box, concede, Vector2(50, 160))
	var hint := UI.label("Esc closes this menu. Space ends your turn.", 14, UI.MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, hint, Vector2(0, 240), Vector2(400, 22))


func _show_result(winner: int) -> void:
	if _locked:
		return
	_locked = true
	_cancel()
	var m := modal()
	var title := "Draw"
	var color := UI.CREAM
	var won := false
	if session.mode == "hotseat":
		if winner >= 0:
			title = "%s wins!" % session.names[winner]
			color = UI.GOLD
		Audio.sfx("win")
	else:
		won = winner == session.my_seat
		if winner >= 0:
			title = "Victory!" if won else "Defeat"
			color = UI.GOLD if won else UI.BAD
		Audio.sfx("win" if won else "lose")
	var reward := Profile.record_battle(session.mode, won, session.ai_level, session.rival_id)

	var box := UI.panel(m, Rect2(340, 110, 600, 500), UI.box(Color(UI.PANEL, 0.97), color, 3, 18, 12))
	var t := UI.label(title, 64, color, true, 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 26), Vector2(600, 80))
	var y := 130.0
	if session.mode == "rival":
		var r := GameData.rival(session.rival_id)
		var line := "You beat %s!" % r["name"] if won else "%s holds the bench this time." % r["name"]
		var l := UI.label(line, 22, UI.CREAM, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(box, l, Vector2(0, y), Vector2(600, 30))
		y += 44.0
	if int(reward["coins"]) > 0:
		var ic := IconView.make("coin", 40, UI.GOLD)
		UI.place(box, ic, Vector2(210, y))
		UI.place(box, UI.label("+%d Forge Coins" % int(reward["coins"]), 28, UI.GOLD), Vector2(262, y + 2), Vector2(320, 36))
		Audio.sfx("coin")
		y += 56.0
	if str(reward["pack"]) != "":
		var pack: Control = (load("res://scripts/ui/screens/shop_screen.gd") as GDScript).pack_art(reward["pack"], 0.5)
		pack.position = Vector2(170, y)
		box.add_child(pack)
		var pl := UI.label("First win reward:\n%s" % GameData.PACKS[reward["pack"]]["name"], 22, UI.CYAN)
		UI.place(box, pl, Vector2(296, y + 34), Vector2(290, 70))
	if session.mode == "hotseat":
		var l := UI.label("Friendly match: no coins this time.", 20, UI.MUTED, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(box, l, Vector2(0, 150), Vector2(600, 28))
	var cont := UI.button("Continue", "go", Vector2(240, 60), 26)
	cont.pressed.connect(func(): app.go("play"))
	UI.place(box, cont, Vector2(50 if str(reward["pack"]) != "" else 180, 414))
	if str(reward["pack"]) != "":
		var open := UI.button("Open the pack", "primary", Vector2(240, 60), 24)
		open.pressed.connect(func(): app.go("shop"))
		UI.place(box, open, Vector2(310, 414))


func _on_closed(reason: String) -> void:
	if _locked or st.get("over", false):
		return
	_closed = true
	_locked = true
	var m := modal()
	var box := UI.panel(m, Rect2(390, 230, 500, 240))
	var t := UI.label("Connection lost", 32, UI.AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 26), Vector2(500, 40))
	var l := UI.label(reason, 20, UI.CREAM, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, l, Vector2(0, 86), Vector2(500, 30))
	var b := UI.button("Back", "primary", Vector2(200, 54))
	b.pressed.connect(func(): app.go("play"))
	UI.place(box, b, Vector2(150, 150))
