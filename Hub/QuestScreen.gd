extends Control

## Kid-safe math bonus (once per profile).

signal back

var _answer: LineEdit
var _submit_btn: Button

func _ready() -> void:
	name = "QuestScreen"
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
	hdr.text = "Learning Quests"
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hdr)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Solve a quick addition problem to earn bonus coins (one-time reward per save)."
	root.add_child(info)

	if bool(GameState.progress.get("quest_math_bonus_claimed", false)):
		var done := Label.new()
		done.text = "You already claimed this quest bonus. Fight battles for more coins!"
		root.add_child(done)
		return

	var q := Label.new()
	q.text = "What is 3 + 4?"
	q.add_theme_font_size_override("font_size", 18)
	root.add_child(q)

	_answer = LineEdit.new()
	_answer.placeholder_text = "Answer"
	_answer.custom_minimum_size.x = 140
	root.add_child(_answer)

	_submit_btn = Button.new()
	_submit_btn.text = "Submit"
	_submit_btn.pressed.connect(_on_submit)
	root.add_child(_submit_btn)


func _on_submit() -> void:
	if bool(GameState.progress.get("quest_math_bonus_claimed", false)):
		return
	var v := int(_answer.text.strip_edges())
	if v != 7:
		EventBus.request_toast.emit("Not quite — try again!")
		return
	GameState.progress["quest_math_bonus_claimed"] = true
	GameState.coins += GameRules.QUEST_MATH_BONUS_COINS
	if GameState.session_active:
		SaveSystem.write_save(GameState.to_save())
	EventBus.request_toast.emit("Correct! +%d coins." % GameRules.QUEST_MATH_BONUS_COINS)
	_submit_btn.disabled = true
	_answer.editable = false
