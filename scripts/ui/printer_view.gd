class_name PrinterView
extends Control
## A player's Printer on the battlefield, with its Health and Armor.

const SIZE := Vector2(176, 178)
const BED := Vector2(86, 100)        # where a print stands while being built

var seat := 0
var printer_id := ""
var targeted := false
var target_color := UI.BAD
var base_scale := 1.0
var flipped := false
var _art: TextureRect
var _hp: Badge
var _armor: Badge
var _name: Label


## `flipped` mirrors the machine so the two Printers face each other.
static func make(printer: String, owner_seat: int, title: String, is_flipped: bool = false) -> PrinterView:
	var v := PrinterView.new()
	v.flipped = is_flipped
	v.size = SIZE
	v.pivot_offset = SIZE * 0.5
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.seat = owner_seat
	v.printer_id = printer
	var col := GameData.element_color(GameData.printer(printer)["element"])
	v._art = UI.image("res://assets/printers/%s.png" % printer, Rect2(8, 0, 160, 146))
	v._art.flip_h = is_flipped
	v.add_child(v._art)
	v._name = UI.label(title, 16, col, true, 5)
	v._name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v._name.position = Vector2(-20, 150)
	v._name.size = Vector2(216, 22)
	v._name.clip_text = true
	v.add_child(v._name)
	v._hp = Badge.make("hex", CardView.HP_RED, 60)
	v._hp.position = Vector2(-2, 96) if is_flipped else Vector2(118, 96)
	v.add_child(v._hp)
	v._armor = Badge.make("shield", Color("b8c4d6"), 48)
	v._armor.position = Vector2(126, 100) if is_flipped else Vector2(2, 100)
	v.add_child(v._armor)
	return v


## Puts the printer's top-left corner at `top_left`, drawn at `s` times size.
func place(top_left: Vector2, s: float) -> void:
	base_scale = s
	scale = Vector2(s, s)
	position = top_left - pivot_offset * (1.0 - s)


func _at(local: Vector2) -> Vector2:
	return position + pivot_offset + (local - pivot_offset) * base_scale


func center() -> Vector2:
	return _at(Vector2(88, 76))


func bed_point() -> Vector2:
	return _at(Vector2(SIZE.x - BED.x, BED.y) if flipped else BED)


func hit_rect() -> Rect2:
	return Rect2(_at(Vector2.ZERO), SIZE * base_scale)


func set_state(p: Dictionary) -> void:
	set_health(int(p["hp"]), int(p["max_hp"]), int(p["armor"]))


func set_health(hp: int, max_hp: int, armor: int) -> void:
	_hp.set_value(maxi(hp, 0), Color("ffb0b0") if hp < max_hp else Color.WHITE)
	_armor.visible = armor > 0
	_armor.set_value(armor, Color("101826"))


func set_targeted(on: bool, color := UI.BAD) -> void:
	if targeted == on and target_color == color:
		return
	targeted = on
	target_color = color
	queue_redraw()


func _draw() -> void:
	if targeted:
		draw_style_box(UI.box(Color(target_color, 0.16), target_color, 4, 18), Rect2(-4, -6, SIZE.x + 8, 160))


func flash() -> void:
	var tw := create_tween()
	tw.tween_property(_art, "modulate", Color(2.2, 1.2, 1.2), 0.05)
	tw.tween_property(_art, "modulate", Color.WHITE, 0.25)
	var home := Vector2(8, 0)
	var sh := create_tween()
	for i in 4:
		sh.tween_property(_art, "position", home + Vector2(randf_range(-8, 8), randf_range(-5, 5)), 0.035)
	sh.tween_property(_art, "position", home, 0.04)


func pulse() -> void:
	var b := Vector2(base_scale, base_scale)
	var tw := create_tween()
	tw.tween_property(self, "scale", b * 1.1, 0.1)
	tw.tween_property(self, "scale", b, 0.18)


## A gentle hum while a print is on the bed.
func set_working(on: bool) -> void:
	_art.modulate = Color(1.15, 1.1, 1.0) if on else Color.WHITE
