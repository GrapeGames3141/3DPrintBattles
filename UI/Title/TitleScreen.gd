extends Control

signal start_new_game(slot: int)
signal continue_game(slot: int)
signal delete_slot(slot: int)

var _toast: Label

func _ready() -> void:
	name = "TitleScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var title := Label.new()
	title.text = "FILAMENT FIGHTERS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Collect. Print. Battle."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	root.add_child(subtitle)

	root.add_child(_spacer(18))

	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 16)
	root.add_child(slots)

	for s in [1, 2, 3]:
		slots.add_child(_make_slot_panel(s))

	root.add_child(_spacer(10))

	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.85
	root.add_child(_toast)

	EventBus.request_toast.connect(_on_toast)

func _make_slot_panel(slot: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 220)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var header := Label.new()
	header.text = "Save Slot %d" % slot
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	vb.add_child(header)

	var exists := SaveSystem.slot_exists(slot)
	var status := Label.new()
	status.text = exists ? "Status: Ready" : "Status: Empty"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(status)

	vb.add_child(_spacer(6))

	var btn_new := Button.new()
	btn_new.text = exists ? "New Game (Overwrite)" : "New Game"
	btn_new.pressed.connect(func():
		start_new_game.emit(slot)
	)
	vb.add_child(btn_new)

	var btn_continue := Button.new()
	btn_continue.text = "Continue"
	btn_continue.disabled = not exists
	btn_continue.pressed.connect(func():
		continue_game.emit(slot)
	)
	vb.add_child(btn_continue)

	var btn_delete := Button.new()
	btn_delete.text = "Delete"
	btn_delete.disabled = not exists
	btn_delete.pressed.connect(func():
		delete_slot.emit(slot)
	)
	vb.add_child(btn_delete)

	return panel

func _spacer(px: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, px)
	return s

func _on_toast(message: String) -> void:
	_toast.text = message

