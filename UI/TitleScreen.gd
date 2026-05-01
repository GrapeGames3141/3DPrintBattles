extends Control

## Title screen: three save slots. Signals use untyped args for Godot 4.0 compatibility.

signal start_new_game(slot)
signal continue_game(slot)
signal delete_slot(slot)

var _toast: Label
var _root: VBoxContainer


func _ready() -> void:
	name = "TitleScreen"
	_build_ui()
	EventBus.request_toast.connect(_on_toast)
	call_deferred("_fit_to_viewport")


func _exit_tree() -> void:
	if EventBus.request_toast.is_connected(_on_toast):
		EventBus.request_toast.disconnect(_on_toast)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_fit_to_viewport")


## Main is a Node, not a Control — fill the window explicitly.
func _fit_to_viewport() -> void:
	var r := get_viewport_rect()
	set_position(Vector2.ZERO)
	set_size(r.size)


func _build_ui() -> void:
	_root = VBoxContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_root)

	var title := Label.new()
	title.text = "3D PRINT BATTLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Collect. Print. Battle."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	_root.add_child(subtitle)

	_root.add_child(_spacer(18))

	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 16)
	_root.add_child(slots)

	for s in [1, 2, 3]:
		slots.add_child(_make_slot_panel(s))

	_root.add_child(_spacer(10))

	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.85
	_root.add_child(_toast)


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
	if exists:
		status.text = "Status: Ready"
	else:
		status.text = "Status: Empty"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(status)

	vb.add_child(_spacer(6))

	var btn_new := Button.new()
	if exists:
		btn_new.text = "New Game (Overwrite)"
	else:
		btn_new.text = "New Game"
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
