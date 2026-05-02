extends Control

## Educational quests: addition, subtraction, geometry (kid-safe). Rewards once each per profile.

signal back

func _ready() -> void:
	name = "QuestScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(func(): back.emit())
	top.add_child(btn_back)
	var hdr := Label.new()
	hdr.text = "Learning Quests"
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hdr)

	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "Earn coins for correct answers. Each quest pays once per save file."
	root.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 16)
	scroll.add_child(vb)

	var qc: Dictionary = GameState.progress.get("quests_claimed", {}) as Dictionary

	vb.add_child(_make_math_panel(
		"Addition",
		"What is 3 + 4?",
		7,
		GameRules.QUEST_MATH_ADD_COINS,
		"add",
		bool(qc.get("add", false))
	))

	vb.add_child(_make_math_panel(
		"Subtraction",
		"What is 10 − 3?",
		7,
		GameRules.QUEST_MATH_SUB_COINS,
		"sub",
		bool(qc.get("sub", false))
	))

	vb.add_child(_make_math_panel(
		"Geometry",
		"A triangle has 3 sides. How many sides does a square have?",
		4,
		GameRules.QUEST_GEOMETRY_COINS,
		"geo",
		bool(qc.get("geo", false))
	))


func _make_math_panel(title: String, question: String, answer: int, reward: int, quest_key: String, claimed: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)

	var hdr := Label.new()
	hdr.text = title
	hdr.add_theme_font_size_override("font_size", 18)
	inner.add_child(hdr)

	var q := Label.new()
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.text = question
	inner.add_child(q)

	if claimed:
		var done := Label.new()
		done.text = "Completed — reward claimed."
		done.modulate.a = 0.85
		inner.add_child(done)
		return panel

	var entry := LineEdit.new()
	entry.placeholder_text = "Your answer"
	entry.custom_minimum_size.x = 160
	inner.add_child(entry)

	var btn := Button.new()
	btn.text = "Submit (+ %d coins)" % reward
	btn.pressed.connect(func(): _submit_quest(quest_key, answer, reward, entry, btn))
	inner.add_child(btn)

	return panel


func _submit_quest(quest_key: String, expected: int, reward: int, entry: LineEdit, btn: Button) -> void:
	var qc: Dictionary = GameState.progress.get("quests_claimed", {}) as Dictionary
	if bool(qc.get(quest_key, false)):
		return
	var v := int(entry.text.strip_edges())
	if v != expected:
		EventBus.request_toast.emit("Not quite — try again!")
		return
	qc[quest_key] = true
	GameState.progress["quests_claimed"] = qc
	GameState.progress["quest_math_bonus_claimed"] = bool(GameState.progress.get("quest_math_bonus_claimed", false)) or (quest_key == "add")
	GameState.coins += reward
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())
	EventBus.request_toast.emit("Correct! +%d coins." % reward)
	btn.disabled = true
	entry.editable = false
