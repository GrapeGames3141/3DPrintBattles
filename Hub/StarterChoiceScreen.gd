extends Control

signal starter_chosen(unit_id)
signal back

const STARTERS := [
	{"id": "001", "name": "Arcade Unicorn"},
	{"id": "002", "name": "Spectral Pup"},
	{"id": "003", "name": "Cookie Cat"}
]

var _toast: Label

func _ready() -> void:
	name = "StarterChoiceScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "Choose a Starter Print Unit"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var rule := Label.new()
	rule.text = "You receive the physical unit for battle, but NOT its blueprint instruction."
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(rule)

	root.add_child(_spacer(6))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	for s in STARTERS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(260, 90)
		b.text = "%s" % s["name"]
		b.pressed.connect(_choose.bind(String(s["id"])))
		row.add_child(b)

	root.add_child(_spacer(8))

	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.85
	root.add_child(_toast)

	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(func(): back.emit())
	root.add_child(btn_back)

func _choose(unit_id: String) -> void:
	_toast.text = "Starter selected."
	starter_chosen.emit(unit_id)

func _spacer(px: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, px)
	return s

