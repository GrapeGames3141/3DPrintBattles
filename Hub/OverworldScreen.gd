extends Control

## Progress-gated routes; practice duel uses the same AI battle flow as the Battle Terminal.

signal back
signal request_practice_battle

func _ready() -> void:
	name = "OverworldScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(func(): back.emit())
	top.add_child(btn_back)

	var hdr := Label.new()
	hdr.text = "Overworld — printer routes"
	hdr.add_theme_font_size_override("font_size", 24)
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hdr)

	var wins: int = int(GameState.progress.get("battles_won", 0))
	var sub := Label.new()
	sub.text = "Victories recorded: %d — unlock harder routes by winning hub duels." % wins
	sub.modulate.a = 0.85
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	list.add_child(_route_panel(
		"Practice alley",
		"Same duel flow as the Battle Terminal — try team tweaks here.",
		"Start duel",
		false,
		func(): request_practice_battle.emit()
	))

	var mid_ok := GameRules.overworld_route_unlocked("mid", wins)
	list.add_child(_route_panel(
		"Midtown circuit",
		"Rotate rivals and map props — gated until your first win.",
		"Locked — win %d duel" % GameRules.OVERWORLD_ROUTE_MID_MIN_WINS if not mid_ok else "Preview (soon)",
		not mid_ok,
		func(): EventBus.request_toast.emit("Midtown circuit maps are still on the print bed.")
	))

	var boss_ok := GameRules.overworld_route_unlocked("boss", wins)
	list.add_child(_route_panel(
		"Boss spire",
		"Reserved for pilots with several victories.",
		"Locked — win %d duels" % GameRules.OVERWORLD_ROUTE_BOSS_MIN_WINS if not boss_ok else "Preview (soon)",
		not boss_ok,
		func(): EventBus.request_toast.emit("Boss encounters will tie into story milestones later.")
	))


func _route_panel(title: String, blurb: String, button_text: String, disabled: bool, on_pressed: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 18)
	inner.add_child(t)

	var b := Label.new()
	b.text = blurb
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.modulate.a = 0.92
	inner.add_child(b)

	var btn := Button.new()
	btn.text = button_text
	btn.disabled = disabled
	btn.pressed.connect(on_pressed)
	inner.add_child(btn)

	return panel
