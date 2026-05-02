extends Control

## Industry-standard title flow (offline MVP): one profile file — Continue / New Game / Options / Quit.

signal continue_pressed
signal new_game_confirmed
signal quit_pressed

var _toast: Label
var _root: VBoxContainer
var _btn_continue: Button
var _confirm_new_game: AcceptDialog
var _confirm_delete: AcceptDialog
var _options_panel: PanelContainer
var _chk_music: CheckBox
var _chk_sfx: CheckBox


func _ready() -> void:
	name = "TitleScreen"
	_build_ui()
	EventBus.request_toast.connect(_on_toast)
	call_deferred("_fit_to_viewport")
	call_deferred("_refresh_continue_button")


func _exit_tree() -> void:
	if EventBus.request_toast.is_connected(_on_toast):
		EventBus.request_toast.disconnect(_on_toast)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_fit_to_viewport")


func _fit_to_viewport() -> void:
	var r: Rect2 = get_viewport_rect()
	set_position(Vector2.ZERO)
	set_size(r.size)


func _refresh_continue_button() -> void:
	if _btn_continue != null:
		_btn_continue.disabled = not SaveSystem.has_save()


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
	title.add_theme_font_size_override("font_size", 44)
	_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Collect. Print. Battle."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.85, 0.9, 1.0)
	subtitle.add_theme_font_size_override("font_size", 18)
	_root.add_child(subtitle)

	var ver := Label.new()
	ver.text = "v %s" % ProjectSettings.get_setting("application/config/version", "0.1")
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.modulate.a = 0.65
	ver.add_theme_font_size_override("font_size", 14)
	_root.add_child(ver)

	_root.add_child(_spacer(28))

	_btn_continue = Button.new()
	_btn_continue.text = "Continue"
	_btn_continue.custom_minimum_size = Vector2(320, 52)
	_btn_continue.disabled = not SaveSystem.has_save()
	_btn_continue.pressed.connect(func(): continue_pressed.emit())
	_root.add_child(_btn_continue)

	var btn_play := Button.new()
	btn_play.text = "New Game"
	btn_play.custom_minimum_size = Vector2(320, 52)
	btn_play.pressed.connect(_on_new_game_clicked)
	_root.add_child(btn_play)

	var btn_opts := Button.new()
	btn_opts.text = "Options"
	btn_opts.custom_minimum_size = Vector2(320, 48)
	btn_opts.pressed.connect(_toggle_options)
	_root.add_child(btn_opts)

	_options_panel = _build_options_panel()
	_options_panel.visible = false
	_root.add_child(_options_panel)

	var btn_quit := Button.new()
	btn_quit.text = "Quit"
	btn_quit.custom_minimum_size = Vector2(320, 44)
	btn_quit.pressed.connect(func(): quit_pressed.emit())
	_root.add_child(btn_quit)

	_root.add_child(_spacer(14))

	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.9
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_toast)

	_confirm_new_game = AcceptDialog.new()
	_confirm_new_game.title = "New Game"
	_confirm_new_game.dialog_text = "Start a new game? Your current progress on this device will be replaced."
	add_child(_confirm_new_game)
	_confirm_new_game.confirmed.connect(func(): new_game_confirmed.emit())

	_confirm_delete = AcceptDialog.new()
	_confirm_delete.title = "Delete Progress"
	_confirm_delete.dialog_text = "Erase all saved progress on this device? This cannot be undone."
	add_child(_confirm_delete)
	_confirm_delete.confirmed.connect(_on_delete_progress_confirmed)


func _build_options_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var hdr := Label.new()
	hdr.text = "Options"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 20)
	vb.add_child(hdr)

	var ls: Dictionary = SaveSystem.load_local_settings()
	_chk_music = CheckBox.new()
	_chk_music.text = "Music"
	_chk_music.button_pressed = bool(ls.get("music", true))
	_chk_music.toggled.connect(func(on: bool): _persist_audio("music", on))
	vb.add_child(_chk_music)

	_chk_sfx = CheckBox.new()
	_chk_sfx.text = "Sound Effects"
	_chk_sfx.button_pressed = bool(ls.get("sfx", true))
	_chk_sfx.toggled.connect(func(on: bool): _persist_audio("sfx", on))
	vb.add_child(_chk_sfx)

	var btn_del := Button.new()
	btn_del.text = "Delete all progress…"
	btn_del.pressed.connect(func(): _confirm_delete.popup_centered())
	vb.add_child(btn_del)

	var btn_close := Button.new()
	btn_close.text = "Close"
	btn_close.pressed.connect(func(): _options_panel.visible = false)
	vb.add_child(btn_close)

	return panel


func _toggle_options() -> void:
	_options_panel.visible = not _options_panel.visible
	if _options_panel.visible:
		var ls: Dictionary = SaveSystem.load_local_settings()
		_chk_music.button_pressed = bool(ls.get("music", true))
		_chk_sfx.button_pressed = bool(ls.get("sfx", true))


func _persist_audio(key: String, on: bool) -> void:
	var ls: Dictionary = SaveSystem.load_local_settings()
	ls[key] = on
	SaveSystem.write_local_settings(ls)
	AudioSettings.apply_from_local_settings()
	EventBus.request_toast.emit("Settings saved.")


func _on_delete_progress_confirmed() -> void:
	SaveSystem.delete_save()
	_refresh_continue_button()
	EventBus.request_toast.emit("Progress deleted.")
	_options_panel.visible = false


func _on_new_game_clicked() -> void:
	if SaveSystem.has_save():
		_confirm_new_game.popup_centered()
	else:
		new_game_confirmed.emit()


func _spacer(px: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, px)
	return s


func _on_toast(message: String) -> void:
	_toast.text = message
