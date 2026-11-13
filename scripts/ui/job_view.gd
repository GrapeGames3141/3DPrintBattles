class_name JobView
extends Control
## A long print sitting on a Printer's bed. It grows from the bed up as its
## Filament is laid down over several turns; both players can see it coming.
## The node's origin is the spot on the bed the print stands on.

var card_id := ""
var cost := 1
var paid := 0
## 0..1, how much of the print is drawn right now.
var shown := 0.0
var _figure: Control
var _unit: BoardUnit
var _card: CardView
var _clip: Control
var _chip: Panel
var _chip_label: Label
var _halo: Control
var _fig_scale := 0.56
var _glow := false

const CARD_SCALE := 0.4
const CARD_SIZE := Vector2(CardView.W, CardView.H) * CARD_SCALE


## `base` is the Printer's own scale, so the print fits its bed.
static func make(id: String, is_mirrored: bool, base: float) -> JobView:
	var v := JobView.new()
	v.card_id = id
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._fig_scale = 0.56 * base
	v._build(is_mirrored, base)
	return v


func _build(mirrored: bool, base: float) -> void:
	var def := GameData.card(card_id)
	_halo = Control.new()
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.visible = false
	_halo.draw.connect(func():
		_halo.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
		_halo.draw_circle(Vector2.ZERO, 78.0 * _fig_scale, Color(UI.GOOD, 0.9))
		_halo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	add_child(_halo)
	var pulse := _halo.create_tween().set_loops()
	pulse.tween_property(_halo, "modulate:a", 0.45, 0.5)
	pulse.tween_property(_halo, "modulate:a", 1.0, 0.5)

	_figure = Control.new()
	_figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_figure.scale = Vector2(_fig_scale, _fig_scale)
	add_child(_figure)
	if def["type"] == "creature":
		var unit := {"uid": -1, "id": card_id, "seat": 0, "atk": int(def["atk"]), "hp": int(def["hp"]), "max_hp": int(def["hp"]),
			"kw": [], "fresh": true, "attacks": 0, "jam": 0, "gear": []}
		_unit = BoardUnit.make(unit, mirrored)
		_unit.position = -BoardUnit.PLATE
		_unit.set_bare(true)
		_unit.begin_print()
		_figure.add_child(_unit)
	else:
		# Tools and armor print as the card itself: a faint outline of the whole
		# thing, filled in from the bottom.
		var ghost := CardView.make(card_id, CARD_SCALE)
		ghost.position = Vector2(-CARD_SIZE.x * 0.5, -CARD_SIZE.y)
		ghost.modulate = Color(0.55, 0.75, 1.0, 0.3)
		_figure.add_child(ghost)
		_clip = Control.new()
		_clip.clip_contents = true
		_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_figure.add_child(_clip)
		_card = CardView.make(card_id, CARD_SCALE)
		_clip.add_child(_card)

	var chip_size := Vector2(64, 22) * base
	_chip = UI.panel(self, Rect2(Vector2(-chip_size.x * 0.5, 3.0 * base), chip_size), UI.box(Color("0b1220"), UI.CYAN, 2, int(chip_size.y * 0.5)))
	_chip_label = UI.label("", int(13.0 * base), Color.WHITE)
	_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chip_label.size = chip_size
	_chip.add_child(_chip_label)
	set_shown(0.0)


## Draws the print built up to `v` of its height.
func set_shown(v: float) -> void:
	shown = clampf(v, 0.0, 1.0)
	if _unit != null:
		_unit.set_print_progress(shown)
	else:
		var h := CARD_SIZE.y * shown
		_clip.position = Vector2(-CARD_SIZE.x * 0.5, -h)
		_clip.size = Vector2(CARD_SIZE.x, h)
		_card.position = Vector2(0.0, h - CARD_SIZE.y)


## Updates the "3 / 7" label; a finished print reads READY.
func set_paid(new_paid: int, new_cost: int) -> void:
	paid = new_paid
	cost = maxi(new_cost, 1)
	var done := is_done()
	_chip_label.text = "READY" if done else "%d / %d" % [paid, cost]
	_chip_label.add_theme_color_override("font_color", Color("0b1220") if done else Color.WHITE)
	_chip.add_theme_stylebox_override("panel", UI.box(UI.GOOD if done else Color("0b1220"), UI.GOOD if done else UI.CYAN, 2, int(_chip.size.y * 0.5)))


func is_done() -> bool:
	return paid >= cost


## Colour floods into a finished creature (0 raw filament, 1 painted).
func set_color(v: float) -> void:
	if _unit != null:
		_unit.set_print_color(v)


## Shows the state straight away, with no animation.
func snap() -> void:
	set_shown(float(paid) / float(cost))
	set_color(1.0 if is_done() else 0.0)


## A green ring under a finished print the player can send into play.
func set_glow(on: bool) -> void:
	if _glow != on:
		_glow = on
		_halo.visible = on


## Where the top printed layer is, in the parent's coordinates.
func layer_point(v: float) -> Vector2:
	var top := 166.0 if _unit != null else CARD_SIZE.y
	return position + Vector2(0.0, -top * v + (12.0 if _unit != null else 0.0)) * _fig_scale


func center() -> Vector2:
	return position + Vector2(0.0, -70.0) * _fig_scale


func hit_rect() -> Rect2:
	return Rect2(position + Vector2(-66.0, -170.0) * _fig_scale, Vector2(132.0 * _fig_scale, 170.0 * _fig_scale + _chip.size.y + 6.0))
