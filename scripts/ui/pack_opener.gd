class_name PackOpener
extends Control
## Opening one card pack by hand. Swipe across the top of the pouch to rip the
## foil strip off, the cards slide out as a stack, flick through them one at a
## time, then see everything laid out. Fills the stage; lives inside a modal.

## "Done" was pressed.
signal done
## "Open another" was pressed.
signal another

const CARD_PIVOT := Vector2(CardView.W, CardView.H) * 0.5
const PACK_PIVOT := Vector2(PackView.W, PackView.H) * 0.5
## Stage pixels the top card must be dragged before it is thrown aside.
const FLICK := 70.0
## A press that moves less than this is a tap.
const TAP := 14.0
## How far each card further down the stack shows below the one above it.
const STACK_STEP := 6.0

var kind := ""
## The pack's contents, as returned by Profile.open_pack.
var cards: Array = []
## Packs of this kind still unopened.
var more := 0
## sealed | pull | flip | summary. "pull" covers every moment that ignores input.
var stage := "sealed"
## During "flip": which card is on top of the stack.
var index := 0

var _w := 1280.0
var _h := 720.0
var _p := false
var _start_stage := "sealed"
var _nodes: Array = []
var _pack: PackView
var _guide: Control
var _guide_t := 0.0
var _idle: Tween
var _title: Label
var _hint: Label
var _tag: Label
var _skip: Button
var _rays: Control
var _rays_color := Color.WHITE
var _tweens: Array = []
## Per card: the tween moving it, and the "rare card" pop, so a new move can
## take over cleanly.
var _moving: Dictionary = {}
var _popping: Dictionary = {}
var _held := false
var _press := Vector2.ZERO
var _last := Vector2.ZERO
var _travel := 0.0
var _tear := 0.0
var _tear_dir := 0


static func make(pack_kind: String, pack_cards: Array, packs_left: int, stage_size: Vector2, portrait: bool,
		start_stage := "sealed", start_index := 0) -> PackOpener:
	var o := PackOpener.new()
	o.kind = pack_kind
	o.cards = pack_cards
	o.more = packs_left
	o._w = stage_size.x
	o._h = stage_size.y
	o._p = portrait
	o._start_stage = start_stage
	o.index = start_index
	o.size = stage_size
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	return o


func _ready() -> void:
	show_stage(_start_stage, index)


# ------------------------------------------------------------------ layout

func _pack_scale() -> float:
	return 1.5 if _p else 0.98


func _pack_center() -> Vector2:
	return Vector2(_w * 0.5, 640.0 if _p else 382.0)


func _stack_scale() -> float:
	return 1.5 if _p else 0.98


func _stack_center() -> Vector2:
	return Vector2(_w * 0.5, 540.0 if _p else 318.0)


## Where card `k` rests in the stack while card `index` is on top.
func _stack_spot(k: int) -> Vector2:
	var depth := k - index
	return _stack_center() + Vector2(0.0, STACK_STEP) * depth


func _tray_scale() -> float:
	return 0.4 if _p else 0.27


## The row of cards already looked at, under the stack.
func _tray_spot(k: int) -> Vector2:
	var w := CardView.W * _tray_scale()
	var gap := 14.0
	var x0 := (_w - (cards.size() * w + (cards.size() - 1) * gap)) * 0.5
	return Vector2(x0 + k * (w + gap) + w * 0.5, 1014.0 if _p else 644.0)


func _grid_scale() -> float:
	return 0.64 if _p else 0.7


## The final spread: one row in landscape, rows of three in portrait.
func _grid_spot(k: int) -> Vector2:
	var per_row := 3 if _p else 5
	var s := _grid_scale()
	var w := CardView.W * s
	var h := CardView.H * s
	var gap := 26.0 if _p else 30.0
	var row := k / per_row
	var in_row := mini(per_row, cards.size() - row * per_row)
	var x0 := (_w - (in_row * w + (in_row - 1) * gap)) * 0.5
	var y0 := 200.0 if _p else 150.0
	return Vector2(x0 + (k % per_row) * (w + gap) + w * 0.5, y0 + row * (h + 60.0) + h * 0.5)


func _put(card: CardView, center: Vector2, card_scale: float, lean: float = 0.0) -> void:
	card.pivot_offset = CARD_PIVOT
	card.position = center - CARD_PIVOT
	card.scale = Vector2(card_scale, card_scale)
	card.rotation = lean


func _rank(k: int) -> int:
	return GameData.RARITY_ORDER.find(GameData.card(cards[k]["id"])["rarity"])


func _rarity_color(k: int) -> Color:
	return GameData.rarity_color(GameData.card(cards[k]["id"])["rarity"])


func _tw() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


# ------------------------------------------------------------------ stages

## Throws everything away and builds the given stage from scratch. Also how a
## turned screen picks the opening back up where it was.
func show_stage(to_stage: String, at: int = 0) -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	_nodes.clear()
	_moving.clear()
	_popping.clear()
	_pack = null
	_tag = null
	_skip = null
	_held = false
	_build_backdrop()
	if to_stage == "sealed":
		_build_sealed()
	elif (to_stage == "flip" or to_stage == "pull") and at < cards.size():
		index = at
		_make_cards()
		for k in cards.size():
			if k < index:
				_put(_nodes[k], _tray_spot(k), _tray_scale())
			else:
				_put(_nodes[k], _stack_spot(k), _stack_scale())
		_begin_flip()
	else:
		_build_summary(false)


func _build_backdrop() -> void:
	var tint := Color(GameData.PACKS[kind]["foil"])
	var g := Gradient.new()
	g.set_color(0, Color(tint, 0.34))
	g.set_color(1, Color(tint, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var spot := TextureRect.new()
	spot.texture = tex
	spot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spot.stretch_mode = TextureRect.STRETCH_SCALE
	spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reach := Vector2(1100, 1100) if _p else Vector2(1000, 1000)
	spot.size = reach
	spot.position = _pack_center() - reach * 0.5
	add_child(spot)

	_rays = Control.new()
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rays.position = _stack_center()
	_rays.modulate.a = 0.0
	_rays.draw.connect(_draw_rays)
	add_child(_rays)
	var spin := _rays.create_tween().set_loops()
	spin.tween_property(_rays, "rotation", TAU, 16.0).from(0.0)

	_title = UI.label(GameData.PACKS[kind]["name"], 40 if _p else 34, UI.GOLD, true, 8)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, _title, Vector2(0, 84 if _p else 18), Vector2(_w, 52))
	_hint = UI.label("", 21 if _p else 19, UI.MUTED, false)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(self, _hint, Vector2(20, 142 if _p else 64), Vector2(_w - 40, 60 if _p else 28))


func _draw_rays() -> void:
	var reach := 620.0
	for i in 12:
		var a := TAU * i / 12.0
		var pts := PackedVector2Array([Vector2.ZERO, Vector2(cos(a), sin(a)) * reach, Vector2(cos(a + 0.26), sin(a + 0.26)) * reach])
		var cols := PackedColorArray([Color(_rays_color, 0.42), Color(_rays_color, 0.0), Color(_rays_color, 0.0)])
		_rays.draw_polygon(pts, cols)


func _add_skip() -> void:
	_skip = UI.button("Skip", "plain", Vector2(140, 48) if _p else Vector2(126, 44), 20)
	_skip.pressed.connect(show_stage.bind("summary"))
	UI.place(self, _skip, Vector2(_w * 0.5 - 70, 1176) if _p else Vector2(_w - 150, _h - 62))


# ------------------------------------------------------------------ sealed

func _build_sealed() -> void:
	stage = "sealed"
	index = 0
	_tear = 0.0
	_tear_dir = 0
	_hint.text = "Swipe across the top of the pack to rip it open"
	var s := _pack_scale()
	_pack = PackView.make(kind, s, 270.0)
	_pack.pivot_offset = PACK_PIVOT
	_pack.position = _pack_center() - PACK_PIVOT
	add_child(_pack)
	_pack.modulate.a = 0.0
	_pack.scale = Vector2(s, s) * 0.86
	var enter := _pack.create_tween().set_parallel(true)
	enter.tween_property(_pack, "modulate:a", 1.0, 0.18)
	enter.tween_property(_pack, "scale", Vector2(s, s), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# The pack sways and the light slides over the foil until it is touched.
	_idle = _pack.create_tween().set_loops()
	_idle.tween_method(_sway, 0.0, TAU, 3.6)

	# "Tear here": a dashed line with a fingertip running along it.
	_guide = Control.new()
	_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide.draw.connect(_draw_guide)
	_pack.add_child(_guide)
	var run := _guide.create_tween().set_loops()
	run.tween_method(func(v: float):
		_guide_t = v
		_guide.queue_redraw(), 0.0, 1.0, 1.25)
	run.tween_interval(0.45)
	_add_skip()


func _sway(phase: float) -> void:
	_pack.rotation = sin(phase) * 0.022
	_pack.set_tilt(sin(phase) * 0.45)


func _draw_guide() -> void:
	var y := PackView.TEAR_Y
	var x := 14.0
	while x < PackView.W - 14.0:
		_guide.draw_line(Vector2(x, y), Vector2(minf(x + 10.0, PackView.W - 14.0), y), Color(1, 1, 1, 0.8), 2.5, true)
		x += 18.0
	var fx := lerpf(30.0, PackView.W - 30.0, smoothstep(0.0, 1.0, _guide_t))
	var fade := sin(PI * _guide_t)
	_guide.draw_circle(Vector2(fx, y), 22.0, Color(1, 1, 1, 0.1 + 0.2 * fade))
	_guide.draw_circle(Vector2(fx, y), 11.0, Color(1, 1, 1, 0.2 + 0.7 * fade))
	for i in 3:
		var cx := fx + 34.0 + i * 15.0
		if cx < PackView.W - 16.0:
			_guide.draw_polyline(PackedVector2Array([Vector2(cx - 5, y - 8), Vector2(cx + 3, y), Vector2(cx - 5, y + 8)]),
					Color(1, 1, 1, 0.7 * fade), 3.0, true)


func _pack_rect() -> Rect2:
	var half := PACK_PIVOT * _pack_scale()
	return Rect2(_pack_center() - half, half * 2.0)


func _touch_pack() -> void:
	if _idle != null and _idle.is_valid():
		_idle.kill()
	if is_instance_valid(_guide):
		_guide.visible = false
	_pack.rotation = 0.0


func _apply_tear() -> void:
	_pack.set_tear(_tear, _tear_dir)
	_pack.set_strip(0.25 + 0.3 * _tear)


func _drag_tear(pos: Vector2, step: Vector2) -> void:
	if _tear_dir == 0:
		if absf(pos.x - _press.x) < 10.0:
			return
		_tear_dir = 1 if pos.x > _press.x else -1
		_touch_pack()
	var gain := step.x * _tear_dir
	if gain > 0.0:
		var before := _tear
		_tear = minf(1.0, _tear + gain / (PackView.W * _pack_scale()) * 1.25)
		if int(_tear * 7.0) > int(before * 7.0):
			Audio.sfx("foil", randf_range(0.9, 1.2))
	_apply_tear()
	_pack.set_tilt((pos.x - _pack_center().x) / (PackView.W * _pack_scale()) * 1.4)
	if _tear >= 1.0:
		_ripped()


## Finishes the rip without a finger: a tap on the pack, or a swipe let go
## most of the way across.
func _auto_rip() -> void:
	if stage != "sealed":
		return
	stage = "pull"
	_held = false
	_touch_pack()
	if _tear_dir == 0:
		_tear_dir = 1
	Audio.sfx("foil")
	var tw := _tw()
	tw.tween_method(func(v: float):
		_tear = v
		_apply_tear(), _tear, 1.0, 0.06 + 0.36 * (1.0 - _tear))
	tw.tween_callback(_ripped)


## The strip is off: fling it away and slide the cards out of the pouch.
func _ripped() -> void:
	stage = "pull"
	_held = false
	_touch_pack()
	if is_instance_valid(_skip):
		_skip.visible = false
	_hint.text = ""
	Audio.sfx("rip")
	_pack.set_tear(1.0, _tear_dir)
	var side := float(_tear_dir)
	var fling := _tw()
	fling.tween_method(func(v: float):
		_pack.set_strip(0.55 + 0.75 * v, Vector2(side * 80.0, -120.0) * v + Vector2(0.0, 110.0) * v * v, 1.0 - v * v), 0.0, 1.0, 0.5)

	var s := _pack_scale() * 0.97
	var inside := _pack_center() + Vector2(0.0, 8.0) * _pack_scale()
	index = 0
	_make_cards(_pack)
	for card in _nodes:
		_put(card, inside, s)
	# Up out of the pouch, but never off the top of the stage.
	var rise := minf(CardView.H * s * 0.6, inside.y - CARD_PIVOT.y * s - 12.0)
	var tw := _tw()
	tw.tween_interval(0.16)
	tw.tween_callback(Audio.sfx.bind("card", 0.8))
	for card: CardView in _nodes:
		tw.parallel().tween_property(card, "position:y", card.position.y - rise, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.12)
	# The empty pouch drops away while the cards settle into a stack.
	tw.tween_property(_pack, "position:y", _pack.position.y + PackView.H * _pack_scale() * 0.8, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_pack, "modulate:a", 0.0, 0.36)
	for k in _nodes.size():
		var card: CardView = _nodes[k]
		tw.parallel().tween_property(card, "position", _stack_spot(k) - CARD_PIVOT, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(card, "scale", Vector2.ONE * _stack_scale(), 0.36)
	tw.tween_callback(func():
		_pack.queue_free()
		_pack = null
		_begin_flip())


## Creates the card nodes, face up, card 0 drawn on top. They are slipped in
## underneath `cover` (the pouch) when one is given.
func _make_cards(cover: Node = null) -> void:
	_nodes.clear()
	_nodes.resize(cards.size())
	for k in range(cards.size() - 1, -1, -1):
		var card := CardView.make(cards[k]["id"], 1.0, Profile.build_of(cards[k]["id"]))
		add_child(card)
		if cover != null:
			move_child(card, cover.get_index())
		_nodes[k] = card


## A fresh tween for one card, replacing whatever was still moving it.
func _card_tween(card: CardView) -> Tween:
	_stop(_moving.get(card))
	var tw := card.create_tween().set_parallel(true)
	_moving[card] = tw
	return tw


func _stop(tween: Variant) -> void:
	if tween is Tween and (tween as Tween).is_valid():
		(tween as Tween).kill()


# -------------------------------------------------------------------- flip

func _begin_flip() -> void:
	stage = "flip"
	_tag = UI.label("", 30 if _p else 24, UI.GOLD, true, 6)
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Under the whole stack, and behind the cards so a dragged card covers it.
	var below := _stack_center().y + CARD_PIVOT.y * _stack_scale() + STACK_STEP * (cards.size() - 1)
	UI.place(self, _tag, Vector2(0, below + (10.0 if _p else 4.0)), Vector2(_w, 40))
	move_child(_tag, _rays.get_index() + 1)
	if _skip == null:
		_add_skip()
	_skip.visible = true
	_announce()


func _tag_text(k: int) -> Array:
	var info: Dictionary = cards[k]
	var rarity: String = GameData.card(info["id"])["rarity"]
	var rarity_name: String = GameData.RARITIES[rarity]["name"]
	if bool(info.get("lost", false)):
		return ["You already have the most copies", UI.MUTED]
	if bool(info["new"]):
		return ["NEW!  %s" % rarity_name, UI.GOLD if _rank(k) < 2 else _rarity_color(k)]
	return [rarity_name, _rarity_color(k)]


## Presents the card that has just come to the top of the stack.
func _announce() -> void:
	var rank := _rank(index)
	var card: CardView = _nodes[index]
	var tag := _tag_text(index)
	_tag.modulate.a = 1.0
	_tag.text = tag[0]
	_tag.add_theme_color_override("font_color", tag[1])
	_hint.text = "Card %d of %d" % [index + 1, cards.size()]
	if index == 0:
		_hint.text += "  -  swipe or tap it to see the next one"
	# Rarer cards wear their colour; a great one glows from under the top card.
	if rank >= 2:
		card.set_glow(_rarity_color(index))
	if index + 1 < cards.size() and _rank(index + 1) >= 3:
		(_nodes[index + 1] as CardView).set_glow(_rarity_color(index + 1))
	Audio.sfx("reveal_epic" if rank >= 4 else ("reveal" if rank >= 3 else "draw"), 1.0 + rank * 0.02)
	for k in range(index, cards.size()):
		var under: CardView = _nodes[k]
		var settle := _card_tween(under)
		settle.tween_property(under, "position", _stack_spot(k) - CARD_PIVOT, 0.18)
		if k == index:
			settle.tween_property(under, "rotation", 0.0, 0.18)
	_rays_color = _rarity_color(index)
	_rays.queue_redraw()
	_rays.create_tween().tween_property(_rays, "modulate:a", 1.0 if rank >= 3 else 0.0, 0.25)
	if rank >= 3:
		var base := Vector2.ONE * _stack_scale()
		var pop := card.create_tween()
		pop.tween_property(card, "scale", base * 1.07, 0.12)
		pop.tween_property(card, "scale", base, 0.18)
		_popping[card] = pop


func _top_rect() -> Rect2:
	var half := CARD_PIVOT * _stack_scale()
	return Rect2(_stack_center() - half, half * 2.0)


func _drag_card(pos: Vector2) -> void:
	var card: CardView = _nodes[index]
	var off := pos - _press
	card.position = _stack_center() + off - CARD_PIVOT
	card.rotation = clampf(off.x / 600.0, -0.35, 0.35)
	_tag.modulate.a = 0.0


## Throws the top card onto the row of cards already seen.
func _send_top(side: int) -> void:
	if stage != "flip":
		return
	var k := index
	var card: CardView = _nodes[k]
	Audio.sfx("swipe", randf_range(0.92, 1.1))
	_stop(_popping.get(card))
	# Out to the side it was flicked, then curving down into its place in the row.
	var from := card.position
	var to := _tray_spot(k) - CARD_PIVOT
	var fly := _card_tween(card)
	fly.tween_method(func(t: float):
		card.position = from.bezier_interpolate(from + Vector2(side * 260.0, -30.0), to + Vector2(side * 60.0, -160.0), to, t),
		0.0, 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.tween_property(card, "scale", Vector2.ONE * _tray_scale(), 0.34)
	fly.tween_property(card, "rotation", 0.0, 0.34)
	index += 1
	if index < cards.size():
		_announce()
		return
	stage = "pull"
	_rays.create_tween().tween_property(_rays, "modulate:a", 0.0, 0.2)
	var tw := _tw()
	tw.tween_interval(0.5)
	tw.tween_callback(_build_summary.bind(true))


# ----------------------------------------------------------------- summary

func _build_summary(animate: bool) -> void:
	stage = "summary"
	index = cards.size()
	_rays.modulate.a = 0.0
	if is_instance_valid(_tag):
		_tag.queue_free()
	_tag = null
	if is_instance_valid(_skip):
		_skip.queue_free()
	_skip = null
	if _nodes.is_empty():
		_make_cards()
		animate = false
	var fresh := 0
	var lost := 0
	for info in cards:
		fresh += 1 if bool(info["new"]) else 0
		lost += 1 if bool(info.get("lost", false)) else 0
	var parts: Array = []
	if fresh > 0:
		parts.append("%d new for your collection" % fresh)
	if lost > 0:
		parts.append("%d extra cop%s not kept" % [lost, "y" if lost == 1 else "ies"])
	_hint.text = ",  ".join(parts) if not parts.is_empty() else "More copies for your decks"

	var s := _grid_scale()
	var half_h := CardView.H * s * 0.5
	var lowest := 0.0
	for k in cards.size():
		var card: CardView = _nodes[k]
		var spot := _grid_spot(k)
		lowest = maxf(lowest, spot.y + half_h)
		if _rank(k) >= 2:
			card.set_glow(_rarity_color(k))
		if animate:
			var tw := _card_tween(card)
			tw.tween_property(card, "position", spot - CARD_PIVOT, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.04 * k)
			tw.tween_property(card, "scale", Vector2.ONE * s, 0.32).set_delay(0.04 * k)
			tw.tween_property(card, "rotation", 0.0, 0.2)
		else:
			_put(card, spot, s)
		var tag := _tag_text(k)
		var label := UI.label(tag[0], 16 if bool(cards[k].get("lost", false)) else 20, tag[1], true, 6)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(self, label, Vector2(spot.x - CardView.W * s * 0.5 - 20, spot.y + half_h + 12), Vector2(CardView.W * s + 40, 28))
		if animate:
			label.modulate.a = 0.0
			label.create_tween().tween_property(label, "modulate:a", 1.0, 0.2).set_delay(0.3)

	var by := lowest + (76.0 if _p else 86.0)
	var done_btn := UI.button("Done", "go", Vector2(200, 56), 23)
	done_btn.pressed.connect(func(): done.emit())
	if more > 0:
		var again := UI.button("Open another (%d left)" % more, "primary", Vector2(300, 56), 21)
		again.pressed.connect(func(): another.emit())
		UI.place(self, again, Vector2(_w * 0.5 - 260, by))
		UI.place(self, done_btn, Vector2(_w * 0.5 + 60, by))
	else:
		UI.place(self, done_btn, Vector2(_w * 0.5 - 100, by))


# ------------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.position
			_last = event.position
			_travel = 0.0
			if stage == "sealed":
				_held = _pack_rect().grow(50.0).has_point(event.position)
			elif stage == "flip":
				_held = _top_rect().grow(30.0).has_point(event.position)
		elif _held:
			_held = false
			_release(event.position)
	elif event is InputEventMouseMotion and _held:
		_travel += event.position.distance_to(_last)
		var step: Vector2 = event.position - _last
		_last = event.position
		if stage == "sealed":
			_drag_tear(event.position, step)
		elif stage == "flip":
			_drag_card(event.position)


func _release(pos: Vector2) -> void:
	if stage == "sealed":
		if _travel < TAP or _tear >= 0.7:
			_auto_rip()
	elif stage == "flip":
		var off := pos - _press
		if _travel < TAP:
			_send_top(1 if index % 2 == 0 else -1)
		elif off.length() > FLICK:
			_send_top(1 if off.x >= 0.0 else -1)
		else:
			var card: CardView = _nodes[index]
			var back := _card_tween(card)
			back.tween_property(card, "position", _stack_spot(index) - CARD_PIVOT, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			back.tween_property(card, "rotation", 0.0, 0.16)
			_tag.modulate.a = 1.0
