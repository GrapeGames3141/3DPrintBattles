class_name GameScreen
extends Control
## Base class for every screen. Screens lay themselves out on the app's stage:
## W x H is 1280x720 in landscape and 720x1280 in portrait (P is true).

var app: Node
var args: Dictionary = {}
var _coin_label: Label

var W: float:
	get:
		return app.stage_size.x
var H: float:
	get:
		return app.stage_size.y
var P: bool:
	get:
		return app.portrait


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Override: create the screen's nodes.
func build() -> void:
	pass


## Called when the stage changes shape. The default throws the nodes away and
## builds again; screens keep what matters in plain variables.
func relayout() -> void:
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	build()


## Title bar with a Back button on the left and the coin purse on the right.
func top_bar(title: String, back_to: String = "menu") -> void:
	var bar := UI.panel(self, Rect2(-20, -20, W + 40, 92), UI.box(Color(0.03, 0.05, 0.1, 0.82), UI.BRASS_DARK, 2, 0))
	bar.z_index = 5
	if back_to != "":
		var back := UI.button("<  Back", "plain", Vector2(110 if P else 130, 46), 17 if P else 20)
		back.pressed.connect(func(): app.go(back_to))
		UI.place(self, back, Vector2(14 if P else 20, 13))
		back.z_index = 6
	var t := UI.label(title, 25 if P else 34, UI.CREAM, true, 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.z_index = 6
	if P:
		UI.place(self, t, Vector2(128, 12), Vector2(W - 128 - 158, 48))
	else:
		UI.place(self, t, Vector2(240, 12), Vector2(800, 48))
	add_coins(Vector2(W - (150 if P else 190), 14), 138 if P else 170)


func add_coins(pos: Vector2, width: float = 170.0) -> void:
	var pill := UI.panel(self, Rect2(pos, Vector2(width, 44)), UI.box(Color("0b1220"), UI.BRASS, 2, 22))
	pill.z_index = 6
	var icon := IconView.make("coin", 32, UI.GOLD)
	icon.position = Vector2(8, 6)
	pill.add_child(icon)
	_coin_label = UI.label("", 24, UI.GOLD)
	_coin_label.position = Vector2(48, 6)
	_coin_label.size = Vector2(width - 58, 32)
	pill.add_child(_coin_label)
	_refresh_coins()
	if not Profile.changed.is_connected(_refresh_coins):
		Profile.changed.connect(_refresh_coins)


func _refresh_coins() -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = str(Profile.coins())


func _exit_tree() -> void:
	if Profile.changed.is_connected(_refresh_coins):
		Profile.changed.disconnect(_refresh_coins)


## A scrolling area from `top` to the bottom of the stage. Returns the content
## node (W wide, `content_h` tall) to place things on. Rebuilding the screen
## with the same `key` (after buying something, say) keeps the list where it was.
func scroll_body(top: float, content_h: float, key := "") -> Control:
	var keep := 0
	if is_instance_valid(_body_scroll) and key == _body_scroll_key:
		keep = _body_scroll.scroll_vertical
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# A finger has to move a little before a tap turns into a scroll.
	scroll.scroll_deadzone = 14
	scroll.position = Vector2(0, top)
	scroll.size = Vector2(W, H - top)
	add_child(scroll)
	var inner := Control.new()
	inner.custom_minimum_size = Vector2(W - 12, content_h)
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(inner)
	_body_scroll = scroll
	_body_scroll_key = key
	if keep > 0:
		_restore_scroll(scroll, keep)
	_let_drags_through.call_deferred(inner)
	return inner


var _body_scroll: ScrollContainer
var _body_scroll_key := ""


func _restore_scroll(scroll: ScrollContainer, y: int) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = y


## Buttons in a scrolling list pass a drag on to the list, so a finger that
## lands on a button can still scroll.
func _let_drags_through(n: Node) -> void:
	if not is_instance_valid(n):
		return
	for c in n.get_children():
		if c is BaseButton:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_let_drags_through(c)


## A modal dimmer that swallows clicks; returns a stage-sized layer for content.
func modal(alpha: float = 0.9) -> Control:
	var m := ColorRect.new()
	m.color = Color(0.01, 0.02, 0.05, alpha)
	m.position = Vector2(-700, -700)
	m.size = Vector2(W + 1400, H + 1400)
	m.mouse_filter = Control.MOUSE_FILTER_STOP
	# Above the battle's coaching tip (48), so a tip's highlight ring never
	# shows through a menu or the Handbook.
	m.z_index = 49
	add_child(m)
	var inner := Control.new()
	inner.position = Vector2(700, 700)
	inner.size = Vector2(W, H)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(inner)
	return inner


## A panel centred on the stage, never wider than the stage.
func dialog(layer: Control, box_size: Vector2, style: StyleBox = null) -> Panel:
	var s := Vector2(minf(box_size.x, W - 24), minf(box_size.y, H - 24))
	return UI.panel(layer, Rect2((Vector2(W, H) - s) * 0.5, s), style)


## `inner` is untyped on purpose: a screen often keeps the layer it opened, and
## after Cancel that object is already freed (a typed Control argument would
## make the call itself fail, so the next dialog never opened).
func close_modal(inner) -> void:
	if inner != null and is_instance_valid(inner):
		inner.get_parent().queue_free()
