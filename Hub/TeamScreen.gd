extends Control

signal back

var _toast: Label
var _team_box: VBoxContainer
var _owned_box: VBoxContainer

func _ready() -> void:
	name = "TeamScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)

	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(func(): back.emit())
	top.add_child(btn_back)

	var title := Label.new()
	title.text = "Team Manager (MVP)"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	_toast = Label.new()
	_toast.text = "Pick up to %d units — they are your battle summon options." % GameRules.TEAM_MAX_UNITS
	_toast.modulate.a = 0.85
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_panel(_toast))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	var team_lbl := Label.new()
	team_lbl.text = "Active Team"
	team_lbl.add_theme_font_size_override("font_size", 18)
	left.add_child(team_lbl)

	_team_box = VBoxContainer.new()
	_team_box.add_theme_constant_override("separation", 8)
	left.add_child(_team_box)

	var btn_clear := Button.new()
	btn_clear.text = "Clear Team"
	btn_clear.pressed.connect(_clear_team)
	left.add_child(btn_clear)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)

	var owned_lbl := Label.new()
	owned_lbl.text = "Owned Blueprints"
	owned_lbl.add_theme_font_size_override("font_size", 18)
	right.add_child(owned_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)

	_owned_box = VBoxContainer.new()
	_owned_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_owned_box)

	_refresh()

func _refresh() -> void:
	for c in _team_box.get_children():
		c.queue_free()
	for c in _owned_box.get_children():
		c.queue_free()

	for id in GameState.active_team:
		_team_box.add_child(_team_row(id))

	for id in GameState.owned_blueprints:
		_owned_box.add_child(_owned_row(id))

func _team_row(unit_id: String) -> Control:
	var defn: Dictionary = UnitDatabase.get_unit(unit_id)
	var display_name: String = str(defn.get("name", unit_id))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = display_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var btn := Button.new()
	btn.text = "Remove"
	btn.pressed.connect(func():
		GameState.active_team.erase(unit_id)
		_save()
		_refresh()
	)
	row.add_child(btn)

	return _panel(row)

func _owned_row(unit_id: String) -> Control:
	var defn: Dictionary = UnitDatabase.get_unit(unit_id)
	var display_name: String = str(defn.get("name", unit_id))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var lbl := Label.new()
	lbl.text = display_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var btn := Button.new()
	btn.text = "Add"
	btn.disabled = GameState.active_team.has(unit_id) or GameState.active_team.size() >= GameRules.TEAM_MAX_UNITS
	btn.pressed.connect(func():
		if GameRules.can_add_team_member(GameState.active_team.size()) and not GameState.active_team.has(unit_id):
			GameState.active_team.append(unit_id)
			_save()
			_refresh()
	)
	row.add_child(btn)

	return _panel(row)

func _clear_team() -> void:
	GameState.active_team.clear()
	_save()
	_refresh()

func _save() -> void:
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())

func _panel(content: Control) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("content_margin_left", 10)
	p.add_theme_constant_override("content_margin_right", 10)
	p.add_theme_constant_override("content_margin_top", 10)
	p.add_theme_constant_override("content_margin_bottom", 10)
	p.add_child(content)
	return p

