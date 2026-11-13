extends GameScreen
## The battlefield. It shows whatever view of the battle its BattleSession
## gives it, turns taps and drags into actions, and animates the events the
## rules engine reports back. It lays itself out for landscape or portrait.

const TIPS := {
	"goal": ["info", "Welcome to the bench! Break the enemy Printer before it breaks yours. The red number is its Health."],
	"filament": ["info", "Your Printer can print %d Filament each turn. The blue number on a card is what it costs. The Spool bar is all the Filament you have for the whole battle." % GameData.PRINT_SPEED],
	"guard": ["info", "A print holding a shield has Guard. You must attack Guard prints before anything else on that side."],
	"print": ["do", "Drag a glowing card onto your side of the bench (the blue lane), or tap the card and then tap the lane. Your Printer builds it layer by layer."],
	"fresh": ["info", "Fresh prints need a turn to cool down. They can attack on your next turn."],
	"attack": ["do", "A green ring means ready. Drag your print onto an enemy print or the enemy Printer. Each deals its Attack (orange) to the other's Health (red)."],
	"tool": ["do", "Tools are one-shot effects. Drag a tool from your hand onto its target."],
	"upgrade": ["do", "Upgrades are printed armor. Drag one onto one of your prints to make it stronger for the rest of the battle."],
	"long": ["do", "A blue glow means a long print: it costs more than you can print this turn. Drag it to your Printer and it will finish over the next turns."],
	"deploy": ["do", "Your long print is finished! Tap it on your Printer to send it into battle."],
	"power": ["do", "Your Printer has a Power that costs Filament and can be used once per turn. Tap it, then tap a target."],
	"end": ["do", "Nothing else to do this turn. Press End Turn."],
}
const LOW_SPOOL := 8

const TIP_ORDER := ["goal", "filament", "guard", "deploy", "print", "fresh", "attack", "tool", "upgrade", "long", "power", "end"]

var session: BattleSession
var st: Dictionary = {}
var me := 0

# ---- layout (set by _layout for the current stage shape)
var mid_x := 650.0
var backs_x := 640.0
var bed_foe := Rect2()
var bed_me := Rect2()
var unit_scale := 1.0
var hand_y := 526.0
var hand_scale := 0.44
var raised_scale := 0.72
var hand_span := 760.0
var deck_pos := Vector2.ZERO
var banner_pos := Vector2.ZERO
var show_pos := Vector2.ZERO
var board_bottom := 506.0
var tip_rect := Rect2()

var _units: Dictionary = {}          # uid -> BoardUnit
var _rows: Array = [[], []]          # seat -> [uid] in board order
var _printing: Dictionary = {}       # uid -> true while it is still on the Printer
var _hand: Array = []                # [{uid, id, node}]
var _foe_backs: Array = []
var _printers: Array = [null, null]
var _jobs: Array = [null, null]      # seat -> JobView, the long print on that Printer

var _board: Control
var _hand_layer: Control
var _fx: Control
var _arrow: Control
var _end_btn: Button
var _end_go: Button
var _power_btn: Button
var _power_cost: Badge
var _gauge: FilamentGauge
var _foe_gauge: FilamentGauge
var _deck_label: Label
var _foe_label: Label
var _preview: Control
var _menu: Control

var _queue: Array = []
var _busy := false
var _mode := "idle"                  # idle | pending | drag | target | armed
var _src: Dictionary = {}
var _valid: Array = []
var _sticky := false
var _press := Vector2.ZERO
var _mouse := Vector2.ZERO
var _hover_uid := -1
var _locked := false                 # an overlay (result, curtain, lost link) is up
var _closed := false
var _overlay := ""                   # "" | "result" | "curtain" | "closed"
var _result_winner := -9
var _reward: Dictionary = {}
var _closed_reason := ""
var _relayout_pending := false
var _spool_warned := false

# ---- tutorial coach
var _coach := false
var _tips_done: Dictionary = {}
var _tip := ""
var _tip_node: Control
var _tip_blocking := false
var _end_tips := 0


func build() -> void:
	session = args["session"]
	st = session.view()
	me = session.my_seat
	_coach = session.mode == "tutorial"
	if session.mode == "hotseat":
		me = int(st["active"])
	Audio.music(_battle_track())
	Audio.set_intensity(0.0)
	session.updated.connect(_on_update)
	session.closed.connect(_on_closed)
	_build_all()
	if session.mode == "hotseat":
		_curtain()
	else:
		var mine: bool = int(st["active"]) == me
		if not _coach:
			_banner("You go first" if mine else "%s goes first" % session.names[1 - me], UI.GOLD if mine else UI.BAD)
		_after_idle()


## The stage turned: rebuild every node from the state, once animations stop.
func relayout() -> void:
	if _busy:
		_relayout_pending = true
		return
	_relayout_pending = false
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	_units.clear()
	_printing.clear()
	_hand.clear()
	_foe_backs.clear()
	_printers = [null, null]
	_jobs = [null, null]
	_preview = null
	_menu = null
	_tip_node = null
	_tip = ""
	_tip_blocking = false
	_mode = "idle"
	_src = {}
	_valid = []
	_hover_uid = -1
	_build_all()
	_locked = false
	match _overlay:
		"result":
			_show_result_panel()
		"curtain":
			_curtain()
		"closed":
			_show_closed_panel()
		_:
			_coach_update()


func _exit_tree() -> void:
	super()
	if session != null:
		if session.updated.is_connected(_on_update):
			session.updated.disconnect(_on_update)
		if session.closed.is_connected(_on_closed):
			session.closed.disconnect(_on_closed)
		session.leave()


# ------------------------------------------------------------------ layout

func _layout() -> void:
	var spec := Arena.spec(P)
	bed_foe = spec["zone_foe"]
	bed_me = spec["zone_me"]
	if P:
		mid_x = 360.0
		backs_x = 390.0
		unit_scale = 0.86
		hand_y = 884.0
		hand_scale = 0.6
		raised_scale = 0.96
		hand_span = 600.0
		deck_pos = Vector2(690, 900)
		banner_pos = Vector2(360, 430)
		show_pos = Vector2(255, 250)
		board_bottom = 640.0
		tip_rect = Rect2(8, 1148, 704, 126)
	else:
		mid_x = 700.0
		backs_x = 640.0
		unit_scale = 1.0
		hand_y = 528.0
		hand_scale = 0.44
		raised_scale = 0.72
		hand_span = 640.0
		deck_pos = Vector2(1166, 500)
		banner_pos = Vector2(660, 296)
		show_pos = Vector2(540, 70)
		board_bottom = 502.0
		tip_rect = Rect2(372, 0, 628, 84)


func _build_all() -> void:
	_layout()
	app.set_background("", 1.0)
	# The workbench. The picture is bigger than the stage so that wide or tall
	# screens show more bench around the edges instead of bars.
	var spec := Arena.spec(P)
	var margin: Vector2 = spec["margin"]
	var bench := UI.image(Arena.image(session.arena, P), Rect2(-margin, Vector2(W, H) + margin * 2.0), true)
	bench.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(bench)
	_board = Control.new()
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board)
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
	_rebuild()


func _build_hud() -> void:
	var menu := UI.button("Menu", "plain", Vector2(96, 40), 17)
	menu.pressed.connect(_open_menu)
	UI.place(self, menu, Vector2(12, 10) if P else Vector2(16, 14))

	var foe_rect := Rect2(12, 60, 250, 84) if P else Rect2(124, 12, 236, 84)
	_foe_gauge = FilamentGauge.make(foe_rect.size, "ENEMY THIS TURN", true)
	UI.place(self, _foe_gauge, foe_rect.position)
	_foe_label = UI.label("", 15, UI.CREAM, false, 5)
	UI.place(self, _foe_label, foe_rect.position + Vector2(8, foe_rect.size.y + 3), Vector2(foe_rect.size.x, 22))

	var end_rect := Rect2(466, 644, 246, 64) if P else Rect2(1064, 598, 204, 80)
	_end_btn = UI.button("End Turn", "primary", end_rect.size, 26)
	_end_btn.pressed.connect(_end_turn)
	UI.place(self, _end_btn, end_rect.position)
	_end_go = UI.button("End Turn", "go", end_rect.size, 26)
	_end_go.pressed.connect(_end_turn)
	UI.place(self, _end_go, end_rect.position)

	var gauge_rect := Rect2(222, 716, 490, 118) if P else Rect2(1064, 408, 204, 156)
	_gauge = FilamentGauge.make(gauge_rect.size, "FILAMENT THIS TURN" if P else "THIS TURN")
	UI.place(self, _gauge, gauge_rect.position)
	_deck_label = UI.label("", 15, UI.CREAM, false, 5)
	UI.place(self, _deck_label, Vector2(228, 838) if P else Vector2(1070, 568), Vector2(200, 22))

	var power_rect := Rect2(222, 648, 232, 56) if P else Rect2(24, 664, 250, 50)
	_power_btn = UI.button("", "primary", power_rect.size, 17)
	_power_btn.pressed.connect(_on_power)
	_power_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI.place(self, _power_btn, power_rect.position)
	_power_cost = Badge.make("spool", CardView.COST_BLUE, 38)
	_power_cost.position = Vector2(power_rect.size.x - 46, (power_rect.size.y - 38) * 0.5)
	_power_cost.set_value(int(st["players"][me]["power_cost"]))
	_power_btn.add_child(_power_cost)


## Battle music: the heavier theme for the late rivals and Master-level sparring.
func _battle_track() -> String:
	if session.mode == "rival":
		for i in GameData.RIVALS.size():
			if GameData.RIVALS[i]["id"] == session.rival_id:
				return "battle2" if i >= 7 else "battle1"
	elif session.mode == "quick" and session.ai_level >= 2:
		return "battle2"
	return "battle1"


## The music follows the battle: calm while the bench is empty, driving once
## prints are out, tense when a Printer is nearly down.
func _update_music() -> void:
	if st.is_empty() or st["over"]:
		return
	var weakest := 99
	var prints := 0
	for seat in 2:
		weakest = mini(weakest, int(st["players"][seat]["hp"]) + int(st["players"][seat]["armor"]))
		prints += (st["players"][seat]["board"] as Array).size()
	var mood := 0.0
	if int(st["turn"]) >= 3 or prints >= 2:
		mood = 1.0
	if weakest <= 8:
		mood = 2.0
	Audio.set_intensity(mood)


## Shows a seat's Filament: what the nozzle can still print this turn, and
## what is left on the Spool.
func _set_res(seat: int, flow: int, spool: int) -> void:
	var p: Dictionary = st["players"][seat]
	# One warning as the Spool runs low, and again if it is topped up and runs low again.
	if seat == me:
		var low: bool = spool <= LOW_SPOOL
		if low and not _spool_warned and session.is_human(me):
			Audio.sfx("spool_low")
		_spool_warned = low
	(_gauge if seat == me else _foe_gauge).set_value(flow, int(p["speed"]), spool, int(p["spool_max"]))


func _refresh_info() -> void:
	var p: Dictionary = st["players"][me]
	var f: Dictionary = st["players"][1 - me]
	_deck_label.text = "Deck: %d cards" % (p["deck"] as Array).size()
	_foe_label.text = "Hand %d    Deck %d" % [(f["hand"] as Array).size(), (f["deck"] as Array).size()]


## Throws away every battlefield piece and builds it again from the state.
## Used at the start and whenever the seat at the bottom changes.
func _rebuild() -> void:
	for uid in _units:
		(_units[uid] as Node).queue_free()
	_units.clear()
	_printing.clear()
	for h in _hand:
		(h["node"] as Node).queue_free()
	_hand.clear()
	for b in _foe_backs:
		(b as Node).queue_free()
	_foe_backs.clear()
	for seat in 2:
		_clear_job(seat)
		if _printers[seat] != null:
			(_printers[seat] as Node).queue_free()
		# Yours stands near you in the bottom-left corner; the enemy's faces it
		# from the far corner.
		var mine: bool = seat == me
		var spec := Arena.spec(P)
		var pv := PrinterView.make(st["players"][seat]["printer"], seat, session.names[seat], not mine)
		_board.add_child(pv)
		pv.place(spec["printer_me"] if mine else spec["printer_foe"], float(spec["printer_me_scale"] if mine else spec["printer_foe_scale"]))
		_printers[seat] = pv
	var power: Dictionary = GameData.printer(st["players"][me]["printer"])["power"]
	_power_btn.text = power["name"]
	_power_btn.tooltip_text = power["text"]
	_power_cost.set_value(int(st["players"][me]["power_cost"]))
	_sync(false)


## A seat's Blueprint for a card (empty for the plain card).
func _build_of(seat: int, id: String) -> Dictionary:
	return (st["players"][seat].get("builds", {}) as Dictionary).get(id, {})


func _bed(seat: int) -> Rect2:
	return bed_me if seat == me else bed_foe


func _clear_job(seat: int) -> void:
	if is_instance_valid(_jobs[seat]):
		(_jobs[seat] as Node).queue_free()
	_jobs[seat] = null


## The long print on a seat's Printer, created on its bed if it is not there.
func _job_view(seat: int, id: String) -> JobView:
	var jv: JobView = _jobs[seat] if is_instance_valid(_jobs[seat]) else null
	if jv != null and jv.card_id == id:
		return jv
	_clear_job(seat)
	var pv: PrinterView = _printers[seat]
	jv = JobView.make(id, seat != me, pv.base_scale, _build_of(seat, id))
	jv.position = pv.bed_point()
	jv.z_index = 12
	_board.add_child(jv)
	_jobs[seat] = jv
	return jv


## Top-left position for the unit in slot `index` of `count`.
func _slot_pos(seat: int, index: int, count: int) -> Vector2:
	var bed := _bed(seat)
	var uw := 140.0 * unit_scale
	var pitch := 138.0 * unit_scale
	if count > 1:
		pitch = minf(pitch, (bed.size.x - 60.0 - uw) / (count - 1))
	var cx := bed.get_center().x + (index - (count - 1) * 0.5) * pitch
	return Vector2(cx, bed.end.y - bed.size.y * 0.3) - BoardUnit.PLATE


func _layout_row(seat: int, animate := true) -> void:
	var row: Array = _rows[seat]
	for i in row.size():
		var node: BoardUnit = _units.get(row[i])
		if node == null or _printing.has(row[i]):
			continue
		var pos := _slot_pos(seat, i, row.size())
		node.z_index = 0
		if animate:
			node.create_tween().tween_property(node, "position", pos, 0.16).set_ease(Tween.EASE_OUT)
		else:
			node.position = pos


## Where a hand card's centre sits, and how far it is tilted, in the fan.
func _hand_slot(index: int, count: int) -> Dictionary:
	var w := CardView.W * hand_scale
	var pitch := minf(w + 6.0, hand_span / maxf(count, 1.0))
	var off := index - (count - 1) * 0.5
	return {
		"center": Vector2(mid_x + off * pitch, hand_y + CardView.H * hand_scale * 0.5 + off * off * 1.8),
		"rot": deg_to_rad(off * 2.0),
	}


func _raised_uid() -> int:
	if _mode in ["armed", "pending", "target"] and _src.get("kind") == "card":
		return int(_src["uid"])
	return _hover_uid


func _layout_hand(animate := true) -> void:
	var half := Vector2(CardView.W, CardView.H) * 0.5
	var up := _raised_uid()
	for i in _hand.size():
		var h: Dictionary = _hand[i]
		var node: CardView = h["node"]
		if _mode == "drag" and _src.get("node") == node:
			continue
		var slot := _hand_slot(i, _hand.size())
		var center: Vector2 = slot["center"]
		var s := hand_scale
		var rot: float = slot["rot"]
		var raised: bool = int(h["uid"]) == up
		node.z_index = 20 if raised else i
		if raised:
			s = raised_scale
			rot = 0.0
			center = Vector2(clampf(center.x, 8.0 + half.x * s, W - 8.0 - half.x * s), H - 4.0 - half.y * s)
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
		var x := backs_x + (i - (n - 1) * 0.5) * 46.0 - CardView.W * 0.1
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
				node.scale = Vector2(unit_scale, unit_scale)
				_board.add_child(node)
				_units[uid] = node
				node.position = _slot_pos(seat, row.size() - 1, (p["board"] as Array).size())
			(_units[uid] as BoardUnit).refresh(u, false)
		_rows[seat] = row
		(_printers[seat] as PrinterView).set_state(p)
		_set_res(seat, int(p["flow"]), int(p["spool"]))
		var job: Dictionary = p["job"]
		if job.is_empty():
			_clear_job(seat)
		else:
			var jv := _job_view(seat, job["id"])
			jv.set_paid(int(job["paid"]), int(job["cost"]))
			jv.snap()
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
	_refresh_info()
	_refresh_interactive()
	_update_music()


func _new_hand_card(id: String) -> CardView:
	var c := CardView.make(id, hand_scale, _build_of(me, id))
	c.pivot_offset = Vector2(CardView.W, CardView.H) * 0.5
	c.position = deck_pos - c.pivot_offset
	_hand_layer.add_child(c)
	return c


func _new_back() -> CardView:
	var b := CardView.make("?", 0.2)
	b.position = Vector2(backs_x, -90)
	_hand_layer.add_child(b)
	return b


func _my_turn() -> bool:
	return not _busy and not _locked and not _tip_blocking and not st["over"] and int(st["active"]) == me and session.is_human(me)


## Updates everything that depends on what the player may do right now.
func _refresh_interactive() -> void:
	var mine := _my_turn()
	for h in _hand:
		var node: CardView = h["node"]
		var playable := mine and BattleEngine.play_error(st, me, int(h["uid"])) == ""
		if _mode == "armed" and _src.get("node") == node:
			node.set_glow(UI.GOLD)
		elif playable:
			# Green lands this turn; blue is a long print that goes on the Printer.
			node.set_glow(UI.CYAN if BattleEngine.is_long(st, me, int(h["uid"])) else UI.GOOD)
		else:
			node.set_glow(null)
	for seat in 2:
		if is_instance_valid(_jobs[seat]):
			(_jobs[seat] as JobView).set_glow(seat == me and mine and BattleEngine.deploy_error(st, me) == "")
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
	# While you are choosing what to attack, everything a Guard print is
	# shielding goes grey, so it is plain what has to be hit first.
	var attacking: bool = _mode == "target" and _src.get("kind") == "unit"
	var walled: bool = attacking and BattleEngine.has_guard(st, 1 - me)
	for uid in _units:
		var unit: BoardUnit = _units[uid]
		var ref := "u%d" % uid
		unit.set_targeted(_mode == "target" and _valid.has(ref), col)
		unit.set_selected(attacking and int(_src["uid"]) == uid)
		unit.set_blocked(walled and int(unit.u["seat"]) != me and not _valid.has(ref))
	for seat in 2:
		var pv: PrinterView = _printers[seat]
		pv.set_targeted(_mode == "target" and _valid.has("p%d" % seat), col)
		pv.modulate = Color(0.5, 0.52, 0.58) if walled and seat != me else Color.WHITE


## Tapping something a Guard print is shielding: say so, and point at the Guard.
func _guard_hint(ref: String) -> void:
	if _src.get("kind") != "unit" or ref == "":
		return
	var foe := 1 - me
	if not BattleEngine.has_guard(st, foe):
		return
	if ref != "p%d" % foe and int(BattleEngine.unit_of(st, ref).get("seat", -1)) != foe:
		return
	_deny("Attack the Guard print first.")
	_point_at_guards()


func _point_at_guards() -> void:
	for u in st["players"][1 - me]["board"]:
		if (u["kw"] as Array).has("guard") and _units.has(int(u["uid"])):
			var node: BoardUnit = _units[int(u["uid"])]
			node.pulse(Color("dfe6f0"))
			UI.floater(_fx, "Guard", node.center() + Vector2(0, -74.0 * unit_scale), Color("dfe6f0"), 24, 14.0, 1.1)


func _harmful() -> bool:
	if _src.get("kind") == "unit":
		return true
	var kind := ""
	if _src.get("kind") in ["card", "job"]:
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
		if _mode == "pending" and _mouse.distance_to(_press) > 18.0:
			_start_drag()
		if _mode == "drag":
			var node: CardView = _src["node"]
			node.position = _mouse - Vector2(CardView.W, CardView.H) * 0.5
			node.rotation = 0.0
		_update_hover()
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
	var up := _raised_uid()
	for pass_raised in [true, false]:
		for i in range(_hand.size() - 1, -1, -1):
			var h: Dictionary = _hand[i]
			var node: CardView = h["node"]
			if pass_raised != (int(h["uid"]) == up):
				continue
			var half := Vector2(CardView.W, CardView.H) * node.scale * 0.5
			var c := node.position + Vector2(CardView.W, CardView.H) * 0.5
			if absf(p.x - c.x) <= half.x and absf(p.y - c.y) <= half.y:
				return h
	return {}


func _unit_at(p: Vector2) -> int:
	for uid in _units:
		if not _printing.has(uid) and (_units[uid] as BoardUnit).hit_rect().has_point(p):
			return uid
	return -1


func _ref_at(p: Vector2) -> String:
	var uid := _unit_at(p)
	if uid >= 0:
		return "u%d" % uid
	for seat in 2:
		if (_printers[seat] as PrinterView).hit_rect().has_point(p):
			return "p%d" % seat
	return ""


func _over_board(p: Vector2) -> bool:
	return p.y < board_bottom and p.y > 56.0


## Where a card may be dropped to play it: the bench, or your own Printer.
func _drop_ok(p: Vector2) -> bool:
	return _over_board(p) or (_printers[me] as PrinterView).hit_rect().has_point(p)


## The seat whose long print is under the point, or -1.
func _job_at(p: Vector2) -> int:
	for seat in 2:
		if is_instance_valid(_jobs[seat]) and (_jobs[seat] as JobView).hit_rect().has_point(p):
			return seat
	return -1


func _turns_left(job: Dictionary, seat: int) -> int:
	var left: int = int(job["cost"]) - int(job["paid"])
	return ceili(float(left) / maxf(float(st["players"][seat]["speed"]), 1.0))


func _update_hover() -> void:
	if _mode != "idle":
		return
	var uid := -1
	var h := _hand_at(_mouse)
	if not h.is_empty():
		uid = int(h["uid"])
	if uid != _hover_uid:
		_hover_uid = uid
		_layout_hand()
	var key := -1
	if uid < 0:
		key = _unit_at(_mouse)
		if key < 0 and _job_at(_mouse) >= 0:
			key = -2 - _job_at(_mouse)
	_set_preview(key)


## Shows the full card for a print on the bench (its uid), or for the long
## print on a Printer (-2 for seat 0, -3 for seat 1). -1 hides it.
func _set_preview(uid: int) -> void:
	var shown: int = _preview.get_meta("uid") if is_instance_valid(_preview) else -1
	if uid == shown:
		return
	if is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null
	var s := 0.7 if P else 0.62
	var size_px := Vector2(CardView.W, CardView.H) * s
	if uid <= -2:
		var seat := -2 - uid
		if not is_instance_valid(_jobs[seat]):
			return
		var jv: JobView = _jobs[seat]
		var job_card := CardView.make(jv.card_id, s, _build_of(seat, jv.card_id))
		job_card.set_meta("uid", uid)
		job_card.z_index = 40
		var box := jv.hit_rect()
		var jx := box.end.x + 10.0 if box.get_center().x < W * 0.5 else box.position.x - size_px.x - 10.0
		job_card.position = Vector2(clampf(jx, 8.0, W - 8.0 - size_px.x), clampf(box.get_center().y - size_px.y * 0.5, 8.0, H - 8.0 - size_px.y))
		add_child(job_card)
		_preview = job_card
		return
	if uid < 0 or not _units.has(uid):
		return
	var node: BoardUnit = _units[uid]
	var card := CardView.make(node.u["id"], s, _build_of(int(node.u["seat"]), node.u["id"]))
	card.set_meta("uid", uid)
	card.z_index = 40
	var at := Vector2.ZERO
	if P:
		var above: bool = int(node.u["seat"]) == me
		at = Vector2(clampf(node.center().x - size_px.x * 0.5, 8.0, W - 8.0 - size_px.x),
			bed_foe.position.y - 40.0 if above else bed_me.position.y + 20.0)
	else:
		var x := node.position.x + 150.0 if node.position.x < 760.0 else node.position.x - size_px.x - 10.0
		at = Vector2(x, clampf(node.position.y - 40.0, 8.0, H - 8.0 - size_px.y))
	card.position = at
	add_child(card)
	_preview = card


func _on_press() -> void:
	_set_preview(-1)
	if _mode == "target" and _sticky:
		var ref := _ref_at(_mouse)
		if _valid.has(ref):
			_commit(ref)
			get_viewport().set_input_as_handled()
		else:
			_guard_hint(ref)
			_cancel()
		return
	var h := _hand_at(_mouse)
	if _mode == "armed":
		var armed := _src
		if not h.is_empty() and int(h["uid"]) == int(armed["uid"]):
			_cancel()                      # tapping the raised card again puts it back
			get_viewport().set_input_as_handled()
			return
		if h.is_empty() and _drop_ok(_mouse):
			_cancel(false)
			_send({"t": "play", "hand": armed["uid"], "slot": _slot_for(_mouse.x)})
			get_viewport().set_input_as_handled()
			return
		_cancel()
	if not h.is_empty():
		get_viewport().set_input_as_handled()
		_press = _mouse
		_hover_uid = int(h["uid"])
		if not _my_turn():
			_layout_hand()                 # just a closer look
			return
		var err := BattleEngine.play_error(st, me, int(h["uid"]))
		if err != "":
			_layout_hand()
			_deny(err)
			return
		_src = {"kind": "card", "uid": int(h["uid"]), "id": h["id"], "node": h["node"]}
		_mode = "pending"
		_layout_hand()
		return
	if _hover_uid >= 0:
		_hover_uid = -1
		_layout_hand()
	var job_seat := _job_at(_mouse)
	if job_seat >= 0:
		get_viewport().set_input_as_handled()
		_press_job(job_seat)
		return
	var uid := _unit_at(_mouse)
	if uid >= 0:
		get_viewport().set_input_as_handled()
		var unit: BoardUnit = _units[uid]
		var targets: Array = BattleEngine.attack_targets(st, uid) if _my_turn() and int(unit.u["seat"]) == me else []
		if targets.is_empty():
			_set_preview(uid)
			if _my_turn() and int(unit.u["seat"]) == me:
				var u := BattleEngine.find_unit(st, uid)
				if int(u["jam"]) > 0:
					_deny("That print is jammed this turn.")
				elif bool(u["fresh"]):
					_deny("Fresh prints need a turn before they can attack.")
				elif int(u["attacks"]) > 0:
					_deny("That print has already attacked.")
			return
		_press = _mouse
		_src = {"kind": "unit", "uid": uid, "node": unit}
		_begin_target(targets)
		return
	for seat in 2:
		var pv: PrinterView = _printers[seat]
		if pv.hit_rect().has_point(_mouse):
			var def: Dictionary = GameData.printer(pv.printer_id)
			UI.floater(_fx, "%s: %s" % [def["power"]["name"], def["power"]["text"]], Vector2(clampf(pv.center().x + 150.0, 220.0, W - 220.0), pv.center().y - 20.0), UI.CREAM, 20, 16.0, 2.2)


## A tap on a long print: send a finished one of yours into play, otherwise
## show what it is and how far along.
func _press_job(seat: int) -> void:
	var jv: JobView = _jobs[seat]
	var job: Dictionary = st["players"][seat]["job"]
	_set_preview(-2 - seat)
	if job.is_empty():
		return
	var title: String = GameData.card(job["id"])["name"]
	if not BattleEngine.job_ready(job):
		var turns := _turns_left(job, seat)
		UI.floater(_fx, "%s: %d of %d printed. Ready %s." % [title, int(job["paid"]), int(job["cost"]),
			"next turn" if turns <= 1 else "in %d turns" % turns], Vector2(clampf(jv.center().x, 230.0, W - 230.0), jv.hit_rect().position.y - 16.0), UI.CYAN, 20, 16.0, 2.0)
		return
	if seat != me or not _my_turn():
		UI.floater(_fx, "%s is finished." % title, Vector2(clampf(jv.center().x, 230.0, W - 230.0), jv.hit_rect().position.y - 16.0), UI.GOOD, 20, 16.0, 1.6)
		return
	var err := BattleEngine.deploy_error(st, me)
	if err != "":
		_deny(err)
		return
	var targets := BattleEngine.play_targets(st, me, job["id"])
	if targets.is_empty():
		_set_preview(-1)
		_send({"t": "deploy"})
		return
	_press = _mouse
	_src = {"kind": "job", "id": job["id"], "node": jv}
	_begin_target(targets)


## Is the card being handled one that would start a long print?
func _src_long() -> bool:
	return _src.get("kind") == "card" and BattleEngine.is_long(st, me, int(_src["uid"]))


## A press on a hand card has moved far enough to count as a drag.
func _start_drag() -> void:
	if not _src_long() and BattleEngine.needs_target(st, me, _src["id"]):
		_begin_target(BattleEngine.play_targets(st, me, _src["id"]))
	else:
		_mode = "drag"
		_hover_uid = -1
		var node: CardView = _src["node"]
		node.z_index = 30
		node.scale = Vector2.ONE * maxf(hand_scale, 0.5)
		_layout_hand()


func _slot_for(x: float) -> int:
	var slot := 0
	for other in _rows[me]:
		if _units.has(other) and (_units[other] as BoardUnit).center().x < x:
			slot += 1
	return slot


func _on_release() -> void:
	match _mode:
		"pending":
			# A tap, not a drag: the card stays raised and waits for a second tap.
			if not _src_long() and BattleEngine.needs_target(st, me, _src["id"]):
				_begin_target(BattleEngine.play_targets(st, me, _src["id"]))
				_sticky = true
			else:
				_mode = "armed"
				_refresh_interactive()
				_layout_hand()
				if _src_long():
					UI.floater(_fx, "Long print: now tap your Printer", bed_me.get_center(), UI.CYAN, 24, 20.0, 1.6)
				else:
					UI.floater(_fx, "Now tap your side of the bench", bed_me.get_center(), UI.GOLD, 24, 20.0, 1.4)
		"drag":
			var uid: int = _src["uid"]
			_mode = "idle"
			if _drop_ok(_mouse):
				_send({"t": "play", "hand": uid, "slot": _slot_for(_mouse.x)})
			else:
				_src = {}
				_layout_hand()
		"target":
			if _sticky:
				return
			var ref := _ref_at(_mouse)
			if _valid.has(ref):
				_commit(ref)
			elif _mouse.distance_to(_press) < 18.0:
				_sticky = true    # a plain tap: wait for a second tap on the target
				_arrow.queue_redraw()
				if _src.get("kind") == "unit" and BattleEngine.has_guard(st, 1 - me):
					_point_at_guards()
			else:
				_guard_hint(ref)
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
		"job":
			_send({"t": "deploy", "target": ref})
		"power":
			_send({"t": "power", "target": ref})


func _cancel(relayout_hand := true) -> void:
	_mode = "idle"
	_src = {}
	_valid = []
	_sticky = false
	_hover_uid = -1
	if is_instance_valid(_arrow):
		_show_targets()
		_arrow.queue_redraw()
		if relayout_hand:
			_layout_hand()
			_refresh_interactive()


func _send(action: Dictionary) -> void:
	var err := session.submit(me, action)
	_src = {}
	if err != "":
		_deny(err)
		_layout_hand()


func _deny(text: String) -> void:
	Audio.sfx("error")
	if text.contains("Spool") or text.contains("printing for this turn"):
		_gauge.deny()
	UI.floater(_fx, text, banner_pos, UI.AMBER, 22 if P else 24, 26.0, 1.3)


func _end_turn() -> void:
	if _my_turn():
		_cancel()
		_send({"t": "end"})


func _on_power() -> void:
	if not _my_turn():
		return
	_cancel()
	var err := BattleEngine.power_error(st, me)
	if err != "":
		_deny(err)
		return
	var targets := BattleEngine.power_targets(st, me)
	if targets.is_empty():
		_send({"t": "power"})
		return
	_src = {"kind": "power", "node": _power_btn}
	_press = _mouse
	_begin_target(targets)
	_sticky = true


func _draw_arrow() -> void:
	if _mode != "target" or _src.is_empty():
		return
	# After a tap (no drag) the pointer is still where it was tapped, so an
	# arrow would point at nothing. It appears once the pointer moves away.
	if _sticky and _mouse.distance_to(_press) < 28.0:
		return
	var from: Vector2
	var node: Control = _src["node"]
	match _src["kind"]:
		"unit":
			from = (node as BoardUnit).center()
		"job":
			from = (node as JobView).center()
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
	_set_preview(-1)
	_hide_tip_if_action()
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
	if _relayout_pending:
		relayout()
	_refresh_interactive()
	_after_idle()


## Decides what happens once the animations have caught up.
func _after_idle() -> void:
	if st["over"] or _locked or _closed:
		return
	_coach_update()
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
		return banner_pos
	return (n as PrinterView).center() if n is PrinterView else (n as BoardUnit).center()


func _banner(text: String, color: Color) -> void:
	var l := UI.label(text, 44 if P else 56, color, true, 14)
	l.z_index = 55
	_fx.add_child(l)
	l.reset_size()
	l.position = banner_pos - l.size * 0.5
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
			_set_res(seat, int(e["flow"]), int(e["spool"]))
			Audio.sfx("turn_foe" if seat != me and session.mode != "hotseat" else "turn_mine")
			if _tip == "end":
				_end_tips += 1
			if session.mode == "hotseat":
				_banner("%s's turn" % session.names[seat], UI.GOLD)
			elif seat == me:
				_banner("Your turn", UI.GOLD)
			else:
				_banner("Enemy turn", UI.BAD)
			await _wait(0.75)
		"draw":
			var seat: int = int(e["seat"])
			Audio.sfx("draw")
			if seat == me:
				_hand.append({"uid": int(e["card"]["uid"]), "id": e["card"]["id"], "node": _new_hand_card(e["card"]["id"])})
			else:
				_foe_backs.append(_new_back())
			_layout_hand()
			await _wait(0.2)
		"burn":
			Audio.sfx("burn")
			UI.floater(_fx, "Hand full! %s was lost." % GameData.card(e["id"])["name"], banner_pos, UI.AMBER, 24, 30.0, 1.4)
			await _wait(0.5)
		"fatigue":
			Audio.sfx("fatigue")
			UI.floater(_fx, "Out of cards!", _center_of("p%d" % int(e["seat"])) + Vector2(60, -70), UI.AMBER, 26, 30.0, 1.2)
			await _wait(0.25)
		"play":
			await _ev_play(e)
		"summon":
			await _ev_summon(e, next)
		"attack":
			if int(e["seat"]) == me:
				_tips_done["attack"] = true
			await _ev_attack(e)
		"damage":
			_ev_damage(e)
			await _wait(0.07 if next.get("e", "") == "damage" else 0.26)
		"heal":
			Audio.sfx("heal")
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
				Audio.sfx("attach" if e["e"] == "gear" else "buff")
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
					Audio.sfx("jam")
					UI.floater(_fx, "Jammed!", node.center() + Vector2(0, -50), UI.CYAN, 24)
					await _wait(0.1 if next.get("e", "") == "jam" else 0.25)
		"death":
			var uid: int = int(e["uid"])
			var node: BoardUnit = _units.get(uid)
			if node != null:
				Audio.sfx("shatter")
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
			if seat == me:
				_tips_done["power"] = true
			_set_res(seat, int(e["flow"]), int(e["spool"]))
			var pv: PrinterView = _printers[seat]
			pv.pulse()
			Audio.sfx("power")
			UI.floater(_fx, GameData.printer(pv.printer_id)["power"]["name"], pv.center() + Vector2(40, -90), UI.GOLD, 24)
			await _wait(0.35)
		"fil":
			_set_res(int(e["seat"]), int(e["flow"]), int(e["spool"]))
			if int(e.get("gain", 0)) > 0:
				Audio.sfx("spool_add")
				UI.floater(_fx, "+%d Filament" % int(e["gain"]), (_printers[int(e["seat"])] as PrinterView).center() + Vector2(0, -90), UI.CYAN, 22)
		"scrap":
			# The pieces of a shattered print go back on its owner's Spool.
			var seat: int = int(e["seat"])
			_set_res(seat, (_gauge if seat == me else _foe_gauge).flow, int(e["spool"]))
			Audio.sfx("scrap", 1.0 + randf_range(0.0, 0.2), 0.8)
		"job":
			await _ev_job(e)
		"deploy":
			await _ev_deploy(e)
		"armor":
			var pv: PrinterView = _printers[int(e["seat"])]
			var p: Dictionary = st["players"][int(e["seat"])]
			p["armor"] = int(e["armor"])
			pv.set_health(int(p["hp"]), int(p["max_hp"]), int(e["armor"]))
			pv.pulse()
			Audio.sfx("armor")
			UI.floater(_fx, "Armor up", pv.center() + Vector2(0, -80), Color("dfe6f0"), 24)
			await _wait(0.25)
		"over":
			await _wait(0.5)
			_show_result(int(e["winner"]))


func _ev_play(e: Dictionary) -> void:
	var seat: int = int(e["seat"])
	_set_res(seat, int(e["flow"]), int(e["spool"]))
	var id: String = e["card"]["id"]
	var def := GameData.card(id)
	Audio.sfx("drop")
	if seat == me:
		if def["type"] == "tool":
			_tips_done["tool"] = true
		elif def["type"] == "upgrade":
			_tips_done["upgrade"] = true
		_drop_hand_card(int(e["card"]["uid"]))
		if def["type"] != "creature":
			Audio.sfx("attach" if def["type"] == "upgrade" else "tool")
			await _wait(0.2)
		return
	# The opponent's card is shown face-up long enough to read.
	if not _foe_backs.is_empty():
		(_foe_backs.pop_back() as Node).queue_free()
	_layout_hand()
	await _show_foe_card(id, Vector2(backs_x - 45, -30), 0.55 if def["type"] == "creature" else 0.95, def["type"] != "creature", seat)


## A card of mine leaves the hand: it lifts and fades.
func _drop_hand_card(uid: int) -> void:
	for h in _hand:
		if int(h["uid"]) == uid:
			_hand.erase(h)
			var node: CardView = h["node"]
			var tw := node.create_tween().set_parallel(true)
			tw.tween_property(node, "modulate:a", 0.0, 0.18)
			tw.tween_property(node, "position:y", node.position.y - 60.0, 0.18)
			tw.chain().tween_callback(node.queue_free)
			break
	_layout_hand()


## Holds one of the opponent's cards up, face-up, long enough to read.
func _show_foe_card(id: String, from: Vector2, hold: float, chime: bool, seat: int = -1) -> void:
	var card := CardView.make(id, 0.3, _build_of(1 - me if seat < 0 else seat, id))
	card.z_index = 42
	card.position = from
	_fx.add_child(card)
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "position", show_pos, 0.2).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2(0.7, 0.7), 0.2)
	await tw.finished
	if chime:
		Audio.sfx("attach" if GameData.card(id)["type"] == "upgrade" else "tool")
	await _wait(hold)
	var out := card.create_tween()
	out.tween_property(card, "modulate:a", 0.0, 0.2)
	out.tween_callback(card.queue_free)


## A long print starts, or the Printer lays down this turn's share of one.
func _ev_job(e: Dictionary) -> void:
	var seat: int = int(e["seat"])
	var id: String = e["card"]["id"]
	var paid: int = int(e["paid"])
	var cost: int = int(e["cost"])
	_set_res(seat, int(e["flow"]), int(e["spool"]))
	if bool(e["start"]):
		Audio.sfx("job_start")
		if seat == me:
			_tips_done["long"] = true
			_drop_hand_card(int(e["card"]["uid"]))
		else:
			if not _foe_backs.is_empty():
				(_foe_backs.pop_back() as Node).queue_free()
			_layout_hand()
			await _show_foe_card(id, Vector2(backs_x - 45, -30), 0.7, false, seat)
			if not is_inside_tree():
				return
	var jv := _job_view(seat, id)
	var pv: PrinterView = _printers[seat]
	var to := float(paid) / float(maxi(cost, 1))
	if to > jv.shown + 0.001:
		pv.set_working(true)
		var head := _make_toolhead(GameData.element_color(GameData.printer(pv.printer_id)["element"]))
		head.scale = Vector2(pv.base_scale, pv.base_scale) * 0.8
		Audio.sfx("print", 1.2)
		var sway := 30.0 * 0.56 * pv.base_scale
		var from := jv.shown
		var build := create_tween()
		build.tween_method(func(v: float):
			jv.set_shown(v)
			head.set_meta("dx", sin(v * TAU * 7.0) * sway / head.scale.x)
			head.position = jv.layer_point(v)
			head.queue_redraw(), from, to, 0.45 + 0.6 * (to - from))
		await build.finished
		if not is_inside_tree():
			return
		head.queue_free()
		pv.set_working(false)
	jv.set_paid(paid, cost)
	var above := Vector2(clampf(jv.center().x, 200.0, W - 200.0), jv.hit_rect().position.y - 14.0)
	if jv.is_done():
		var paint := create_tween()
		paint.tween_method(jv.set_color, 0.0, 1.0, 0.2)
		Audio.sfx("print_done")
		UI.floater(_fx, "Print finished!", above, UI.GOOD, 24, 20.0, 1.3)
		await _wait(0.4)
	elif bool(e["start"]):
		var turns := _turns_left({"cost": cost, "paid": paid}, seat)
		UI.floater(_fx, "Long print: ready %s" % ("next turn" if turns <= 1 else "in %d turns" % turns), above, UI.CYAN, 22, 20.0, 1.5)
		await _wait(0.35)
	else:
		await _wait(0.15)


## A finished long print leaves the Printer. Creatures hop to the bench in the
## summon that follows; tools and armor are used up here.
func _ev_deploy(e: Dictionary) -> void:
	var seat: int = int(e["seat"])
	var id: String = e["card"]["id"]
	var def := GameData.card(id)
	if seat == me:
		_tips_done["deploy"] = true
	if def["type"] == "creature":
		return
	var jv: JobView = _jobs[seat] if is_instance_valid(_jobs[seat]) else null
	var from := jv.center() - Vector2(45, 63) if jv != null else Vector2(backs_x - 45, -30)
	_clear_job(seat)
	if seat == me:
		if def["type"] == "tool":
			_tips_done["tool"] = true
		else:
			_tips_done["upgrade"] = true
		Audio.sfx("attach" if def["type"] == "upgrade" else "tool")
		await _wait(0.2)
	else:
		await _show_foe_card(id, from, 0.95, true, seat)


## The print head that rides up the figure while it is being built.
func _make_toolhead(accent: Color) -> Control:
	var head := Control.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.z_index = 14
	head.set_meta("dx", 0.0)
	head.draw.connect(func():
		var dx: float = head.get_meta("dx")
		# X-axis rail, then the carriage, heat block and nozzle on it.
		head.draw_rect(Rect2(-64, -34, 128, 7), Color("8794a8"))
		head.draw_rect(Rect2(-64, -29, 128, 2), Color("3a4454"))
		head.draw_style_box(UI.box(accent.darkened(0.2), Color("0e131b"), 2, 4), Rect2(dx - 16, -44, 32, 24))
		head.draw_rect(Rect2(dx - 9, -20, 18, 9), Color("2a313d"))
		head.draw_colored_polygon(PackedVector2Array([Vector2(dx - 7, -11), Vector2(dx + 7, -11), Vector2(dx, 0)]), Color("e9a91c"))
		head.draw_circle(Vector2(dx, 1), 5.0, Color(1.0, 0.75, 0.3, 0.55))
		head.draw_circle(Vector2(dx, 1), 2.4, Color(1.0, 0.95, 0.7)))
	_fx.add_child(head)
	return head


## A print is built on its owner's Printer, layer by layer, in raw filament.
## When the last layer is down the colour floods in and it hops onto the bed.
func _ev_summon(e: Dictionary, next: Dictionary) -> void:
	var seat: int = int(e["seat"])
	var unit: Dictionary = e["unit"]
	var uid: int = int(unit["uid"])
	if seat == me and bool(e.get("hand", false)):
		_tips_done["print"] = true
	var node := BoardUnit.make(unit, seat != me)
	_board.add_child(node)
	_units[uid] = node
	_printing[uid] = true
	var row: Array = _rows[seat]
	row.insert(clampi(int(e["slot"]), 0, row.size()), uid)
	_layout_row(seat)

	var pv: PrinterView = _printers[seat]
	var small := 0.56 * pv.base_scale
	var start := pv.bed_point() - BoardUnit.PLATE
	node.set_bare(true)
	node.z_index = 12
	node.scale = Vector2(small, small)
	node.position = start
	if bool(e.get("built", false)):
		# It was built over the last few turns and is standing there finished.
		_clear_job(seat)
		Audio.sfx("deploy")
	else:
		# A long print already on the bed steps back while this one is built.
		var waiting: JobView = _jobs[seat] if is_instance_valid(_jobs[seat]) else null
		if waiting != null:
			waiting.modulate.a = 0.0
			waiting.create_tween().tween_property(waiting, "modulate:a", 1.0, 0.25).set_delay(1.3)
		node.begin_print()
		pv.set_working(true)
		var head := _make_toolhead(GameData.element_color(GameData.printer(pv.printer_id)["element"]))
		head.scale = Vector2(pv.base_scale, pv.base_scale) * 0.8
		Audio.sfx("print", 1.2)
		var quick: bool = next.get("e", "") == "summon"
		var sway := 30.0 * small
		var build := create_tween()
		build.tween_method(func(v: float):
			node.set_print_progress(v)
			head.set_meta("dx", sin(v * TAU * 7.0) * sway / head.scale.x)
			head.position = node.layer_point(v)
			head.queue_redraw(), 0.0, 1.0, 0.6 if quick else 1.15)
		await build.finished
		if not is_inside_tree():
			return
		head.queue_free()
		pv.set_working(false)
		var paint := create_tween()
		paint.tween_method(node.set_print_color, 0.0, 1.0, 0.2)
		await paint.finished
		node.end_print()

	# Off the Printer and onto the bed in one hop.
	var dest := _slot_pos(seat, row.find(uid), row.size())
	var hop := create_tween()
	hop.tween_method(func(t: float):
		node.position = start.lerp(dest, t) + Vector2(0, -120.0 * sin(t * PI))
		node.scale = Vector2.ONE * lerpf(small, unit_scale, t), 0.0, 1.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await hop.finished
	if not is_inside_tree():
		return
	_printing.erase(uid)
	node.position = dest
	node.scale = Vector2(unit_scale, unit_scale)
	node.z_index = 0
	node.set_bare(false)
	Audio.sfx("drop", 0.8)
	var land := node.create_tween()
	land.tween_property(node, "scale", Vector2(unit_scale * 1.12, unit_scale * 0.88), 0.07)
	land.tween_property(node, "scale", Vector2(unit_scale, unit_scale), 0.12)
	await _wait(0.1)


func _ev_attack(e: Dictionary) -> void:
	var node: BoardUnit = _units.get(int(e["uid"]))
	if node == null:
		return
	Audio.sfx("swing")
	var element: String = str(node.def.get("element", "Neutral")).to_lower()
	if element != "neutral":
		Audio.sfx("atk_" + element, 1.0, 0.85)
	var home := node.position
	var dest := home + (_center_of(e["target"]) - node.center())
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
		Audio.sfx("armor", 1.6)
		return
	if n is PrinterView:
		Audio.sfx("hit_printer")
	else:
		Audio.sfx("hit_heavy" if int(e["n"]) >= 4 else "hit")
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


# ------------------------------------------------------------------- coach

func _tip_ready(id: String) -> bool:
	if _tips_done.get(id, false):
		return false
	var mine: bool = int(st["active"]) == me and not st["over"]
	match id:
		"goal", "filament":
			return true
		"guard":
			return mine and BattleEngine.has_guard(st, 1 - me) and _tips_done.get("print", false)
		"print":
			return mine and _has_playable("creature")
		"long":
			if not mine or not _tips_done.get("print", false):
				return false
			for c in st["players"][me]["hand"]:
				if BattleEngine.play_error(st, me, int(c["uid"])) == "" and BattleEngine.is_long(st, me, int(c["uid"])):
					return true
			return false
		"deploy":
			return mine and BattleEngine.deploy_error(st, me) == ""
		"fresh":
			if not _tips_done.get("print", false):
				return false
			for u in st["players"][me]["board"]:
				if bool(u["fresh"]):
					return true
			return false
		"attack":
			if not mine:
				return false
			for u in st["players"][me]["board"]:
				if not BattleEngine.attack_targets(st, int(u["uid"])).is_empty():
					return true
			return false
		"tool":
			return mine and _has_playable("tool")
		"upgrade":
			return mine and _has_playable("upgrade")
		"power":
			return mine and _tips_done.get("attack", false) and BattleEngine.power_error(st, me) == ""
		"end":
			return mine and _end_tips < 3 and BattleEngine.legal_actions(st, me).size() <= 1
	return false


func _has_playable(type: String) -> bool:
	for c in st["players"][me]["hand"]:
		if GameData.card(c["id"]).get("type", "") == type and BattleEngine.play_error(st, me, int(c["uid"])) == "" \
				and not BattleEngine.is_long(st, me, int(c["uid"])):
			return true
	return false


## The part of the screen a tip is talking about.
func _tip_focus(id: String) -> Rect2:
	match id:
		"goal":
			return (_printers[1 - me] as PrinterView).hit_rect()
		"filament":
			return Rect2(_gauge.position, _gauge.size)
		"guard":
			return bed_foe
		"fresh", "attack":
			return bed_me
		"power":
			return Rect2(_power_btn.position, _power_btn.size)
		"deploy":
			return (_printers[me] as PrinterView).hit_rect()
		"end":
			return Rect2(_end_btn.position, _end_btn.size)
	var top := hand_y - 8.0
	return Rect2(mid_x - hand_span * 0.5 - 20.0, top, hand_span + 40.0, minf(H - top - 2.0, CardView.H * hand_scale + 20.0))


func _coach_update() -> void:
	if not _coach or _locked or _busy or st["over"]:
		return
	var want := ""
	for id in TIP_ORDER:
		if _tip_ready(id):
			want = id
			break
	if want != _tip:
		_show_tip(want)


func _hide_tip_if_action() -> void:
	if _tip != "" and not _tip_blocking:
		_show_tip("")


func _show_tip(id: String) -> void:
	if is_instance_valid(_tip_node):
		_tip_node.queue_free()
	_tip_node = null
	_tip = id
	_tip_blocking = false
	if id == "":
		return
	var info: bool = TIPS[id][0] == "info"
	_tip_blocking = info
	_tip_node = Control.new()
	_tip_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_node.z_index = 48
	add_child(_tip_node)
	var focus := _tip_focus(id).grow(6.0)
	var ring := UI.panel(_tip_node, focus, UI.box(Color(UI.GOLD, 0.07), UI.GOLD, 4, 16))
	var pulse := ring.create_tween().set_loops()
	pulse.tween_property(ring, "modulate:a", 0.35, 0.6)
	pulse.tween_property(ring, "modulate:a", 1.0, 0.6)
	var box := UI.panel(_tip_node, tip_rect, UI.box(Color(0.04, 0.07, 0.14, 0.97), UI.GOLD, 3, 14, 10))
	var btn_w := 120.0 if info else 0.0
	var text := UI.label(TIPS[id][1], 19 if P else 17, UI.CREAM, false)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.position = Vector2(16, 6)
	text.size = Vector2(tip_rect.size.x - 32 - btn_w, tip_rect.size.y - 12)
	box.add_child(text)
	if info:
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		var ok := UI.button("Got it", "go", Vector2(108, 50), 20)
		ok.position = Vector2(tip_rect.size.x - 122, (tip_rect.size.y - 50) * 0.5)
		ok.pressed.connect(func():
			_tips_done[id] = true
			_show_tip("")
			_refresh_interactive()
			_coach_update())
		box.add_child(ok)
	_refresh_interactive()


# --------------------------------------------------------------- overlays

## Pass-and-play: hide both hands until the next player is at the screen.
func _curtain() -> void:
	_locked = true
	_overlay = "curtain"
	var seat: int = int(st["active"])
	var m := modal(1.0)
	var t := UI.label("%s's turn" % session.names[seat], 48 if P else 60, UI.GOLD, true, 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(m, t, Vector2(0, H * 0.5 - 130), Vector2(W, 80))
	var s := UI.label("Pass the screen over, then press Ready.", 22, UI.CREAM, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(m, s, Vector2(0, H * 0.5 - 40), Vector2(W, 34))
	var b := UI.button("Ready", "go", Vector2(260, 66), 28)
	b.pressed.connect(func():
		me = seat
		_overlay = ""
		_rebuild()
		close_modal(m)
		_locked = false
		_refresh_interactive())
	UI.place(m, b, Vector2(W * 0.5 - 130, H * 0.5 + 40))


func _open_menu() -> void:
	if is_instance_valid(_menu) or _locked:
		return
	_cancel()
	_menu = modal()
	var box := dialog(_menu, Vector2(400, 300))
	var t := UI.label("Paused", 32, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 22), Vector2(400, 40))
	var resume := UI.button("Keep playing", "go", Vector2(300, 56), 22)
	resume.pressed.connect(func(): close_modal(_menu))
	UI.place(box, resume, Vector2(50, 90))
	var leaving: bool = session.mode == "tutorial"
	var concede := UI.button("Leave the tutorial" if leaving else "Concede the battle", "danger", Vector2(300, 56), 22)
	concede.pressed.connect(func():
		close_modal(_menu)
		if st["over"] or leaving:
			app.go("menu" if leaving else "play")
		else:
			session.submit(me, {"t": "concede"}))
	UI.place(box, concede, Vector2(50, 160))
	var hint := UI.label("Esc closes this menu. Space ends your turn.", 14, UI.MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, hint, Vector2(0, 240), Vector2(400, 22))


func _show_result(winner: int) -> void:
	if _locked:
		return
	_cancel()
	_show_tip("")
	_result_winner = winner
	var won: bool = session.mode != "hotseat" and winner == session.my_seat
	_reward = Profile.record_battle(session.mode, won, session.ai_level, session.rival_id, str(st["players"][session.my_seat]["printer"]))
	Audio.set_intensity(0.0)
	Audio.stinger("win" if won or session.mode == "hotseat" else "lose", 0.2)
	if int(_reward["coins"]) > 0:
		Audio.sfx("coin")
	_show_result_panel()


func _show_result_panel() -> void:
	_locked = true
	_overlay = "result"
	var winner := _result_winner
	var m := modal()
	var title := "Draw"
	var color := UI.CREAM
	var won: bool = session.mode != "hotseat" and winner == session.my_seat
	if session.mode == "hotseat":
		if winner >= 0:
			title = "%s wins!" % session.names[winner]
			color = UI.GOLD
	elif session.mode == "tutorial":
		title = "Well played!" if won else "So close"
		color = UI.GOLD if won else UI.AMBER
	elif winner >= 0:
		title = "Victory!" if won else "Defeat"
		color = UI.GOLD if won else UI.BAD
	var has_pack: bool = str(_reward["pack"]) != ""

	var box := dialog(m, Vector2(600, 546), UI.box(Color(UI.PANEL, 0.97), color, 3, 18, 12))
	var bw := box.size.x
	var t := UI.label(title, 52 if P else 64, color, true, 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 26), Vector2(bw, 80))
	var y := 130.0
	var line := ""
	if session.mode == "rival":
		var r := GameData.rival(session.rival_id)
		line = "You beat %s!" % r["name"] if won else "%s holds the bench this time." % r["name"]
	elif session.mode == "tutorial":
		line = "Tutorial complete. You are ready for real rivals." if won else "Give the tutorial another go whenever you like."
	elif session.mode == "hotseat":
		line = "Friendly match: no coins this time."
	if line != "":
		var l := UI.label(line, 21, UI.CREAM, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(box, l, Vector2(20, y), Vector2(bw - 40, 56))
		y += 62.0
	if int(_reward["coins"]) > 0:
		var ic := IconView.make("coin", 40, UI.GOLD)
		UI.place(box, ic, Vector2(bw * 0.5 - 150, y))
		UI.place(box, UI.label("+%d Forge Coins" % int(_reward["coins"]), 28, UI.GOLD), Vector2(bw * 0.5 - 98, y + 2), Vector2(320, 36))
		y += 50.0
	if int(_reward.get("xp", 0)) > 0:
		var xp_line := "+%d Maker XP" % int(_reward["xp"])
		var up: bool = int(_reward["rank_to"]) > int(_reward["rank_from"])
		if up:
			xp_line += "   Rank %d!" % int(_reward["rank_to"])
		var xl := UI.label(xp_line, 22, UI.GOOD if up else UI.CYAN)
		xl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(box, xl, Vector2(0, y), Vector2(bw, 30))
		y += 38.0
	if has_pack:
		var pack := PackView.make(_reward["pack"], 0.29)
		pack.position = Vector2(bw * 0.5 - 180, y - 2)
		box.add_child(pack)
		var pl := UI.label("First win reward:\n%s" % GameData.PACKS[_reward["pack"]]["name"], 21, UI.CYAN)
		UI.place(box, pl, Vector2(bw * 0.5 - 60, y + 34), Vector2(260, 70))
	var home := "menu" if session.mode == "tutorial" else "play"
	var cont := UI.button("Continue", "go", Vector2(240, 60), 26)
	cont.pressed.connect(func(): app.go(home))
	UI.place(box, cont, Vector2(bw * 0.5 - 250 if has_pack or (session.mode == "tutorial" and not won) else bw * 0.5 - 120, 460))
	if has_pack:
		var open := UI.button("Open the pack", "primary", Vector2(240, 60), 24)
		open.pressed.connect(func(): app.go("shop"))
		UI.place(box, open, Vector2(bw * 0.5 + 10, 460))
	elif session.mode == "tutorial" and not won:
		var again := UI.button("Try again", "primary", Vector2(240, 60), 24)
		again.pressed.connect(func(): app.go("battle", {"session": BattleSession.tutorial()}))
		UI.place(box, again, Vector2(bw * 0.5 + 10, 460))


func _on_closed(reason: String) -> void:
	if _locked or st.get("over", false):
		return
	_closed = true
	_closed_reason = reason
	_show_closed_panel()


func _show_closed_panel() -> void:
	_locked = true
	_overlay = "closed"
	var m := modal()
	var box := dialog(m, Vector2(500, 240))
	var t := UI.label("Connection lost", 32, UI.AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 26), Vector2(500, 40))
	var l := UI.label(_closed_reason, 20, UI.CREAM, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, l, Vector2(0, 86), Vector2(500, 30))
	var b := UI.button("Back", "primary", Vector2(200, 54))
	b.pressed.connect(func(): app.go("play"))
	UI.place(box, b, Vector2(150, 150))
