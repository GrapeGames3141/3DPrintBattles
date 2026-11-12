class_name GameScreen
extends Control
## Base class for every screen. Screens lay themselves out on a 1280x720 stage.

var app: Node
var args: Dictionary = {}
var _coin_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Override: create the screen's nodes.
func build() -> void:
	pass


## Title bar with a Back button on the left and the coin purse on the right.
func top_bar(title: String, back_to: String = "menu") -> void:
	var bar := UI.panel(self, Rect2(-20, -20, 1320, 92), UI.box(Color(0.03, 0.05, 0.1, 0.82), UI.BRASS_DARK, 2, 0))
	bar.z_index = 5
	if back_to != "":
		var back := UI.button("<  Back", "plain", Vector2(130, 46))
		back.pressed.connect(func(): app.go(back_to))
		UI.place(self, back, Vector2(20, 13))
		back.z_index = 6
	var t := UI.label(title, 34, UI.CREAM, true, 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.z_index = 6
	UI.place(self, t, Vector2(240, 12), Vector2(800, 48))
	add_coins(Vector2(1090, 14))


func add_coins(pos: Vector2) -> void:
	var pill := UI.panel(self, Rect2(pos, Vector2(170, 44)), UI.box(Color("0b1220"), UI.BRASS, 2, 22))
	pill.z_index = 6
	var icon := IconView.make("coin", 32, UI.GOLD)
	icon.position = Vector2(8, 6)
	pill.add_child(icon)
	_coin_label = UI.label("", 24, UI.GOLD)
	_coin_label.position = Vector2(48, 6)
	_coin_label.size = Vector2(112, 32)
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


## A modal dimmer that swallows clicks; returns the layer to put content on.
func modal() -> Control:
	var m := ColorRect.new()
	m.color = Color(0.01, 0.02, 0.05, 0.9)
	m.position = Vector2(-400, -400)
	m.size = Vector2(2080, 1520)
	m.mouse_filter = Control.MOUSE_FILTER_STOP
	m.z_index = 40
	add_child(m)
	var inner := Control.new()
	inner.position = Vector2(400, 400)
	inner.size = Vector2(1280, 720)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(inner)
	return inner


func close_modal(inner: Control) -> void:
	if is_instance_valid(inner):
		inner.get_parent().queue_free()
