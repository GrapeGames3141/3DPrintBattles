class_name PrinterView
extends Control
## A player's Printer on the battlefield, with its Health and Armor.

const SIZE := Vector2(176, 178)

var seat := 0
var printer_id := ""
var targeted := false
var target_color := UI.BAD
var _art: TextureRect
var _hp: Badge
var _armor: Badge
var _name: Label


static func make(printer: String, owner_seat: int, title: String) -> PrinterView:
	var v := PrinterView.new()
	v.size = SIZE
	v.pivot_offset = SIZE * 0.5
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.seat = owner_seat
	v.printer_id = printer
	var col := GameData.element_color(GameData.printer(printer)["element"])
	v._art = UI.image("res://assets/printers/%s.png" % printer, Rect2(8, 0, 160, 146))
	v.add_child(v._art)
	v._name = UI.label(title, 16, col, true, 5)
	v._name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v._name.position = Vector2(-20, 150)
	v._name.size = Vector2(216, 22)
	v._name.clip_text = true
	v.add_child(v._name)
	v._hp = Badge.make("hex", CardView.HP_RED, 60)
	v._hp.position = Vector2(118, 96)
	v.add_child(v._hp)
	v._armor = Badge.make("shield", Color("b8c4d6"), 48)
	v._armor.position = Vector2(2, 100)
	v.add_child(v._armor)
	return v


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


func center() -> Vector2:
	return position + Vector2(88, 76)


func _draw() -> void:
	if targeted:
		draw_style_box(UI.box(Color(target_color, 0.16), target_color, 4, 18), Rect2(-4, -6, SIZE.x + 8, 160))


func flash() -> void:
	var tw := create_tween()
	tw.tween_property(_art, "modulate", Color(2.2, 1.2, 1.2), 0.05)
	tw.tween_property(_art, "modulate", Color.WHITE, 0.25)
	var home := _art.position
	var sh := create_tween()
	for i in 4:
		sh.tween_property(_art, "position", home + Vector2(randf_range(-8, 8), randf_range(-5, 5)), 0.035)
	sh.tween_property(_art, "position", home, 0.04)


func pulse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18)
