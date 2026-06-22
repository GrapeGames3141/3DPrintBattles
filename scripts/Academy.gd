# Academy.gd
# Educational math mini-games. Players earn Forge Coins by answering questions.
# Scene file: res://scenes/Academy.tscn
#
# SCENE TREE:
# Academy (Node2D)
# ├── Background (TextureRect)
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer)
# │   │   ├── TitleLabel (Label)       "The Academy"
# │   │   ├── CoinLabel (Label)
# │   │   └── BackBtn (Button)
# │   ├── QuestMenu (VBoxContainer)    — shown when not in a quest
# │   │   └── (quest buttons built dynamically)
# │   └── QuestPanel (Panel)           — shown during active quest, hidden by default
# │       ├── QuestTitle (Label)
# │       ├── QuestionLabel (Label)
# │       ├── AnswerGrid (GridContainer) — 4 answer buttons
# │       ├── FeedbackLabel (Label)
# │       ├── ScoreLabel (Label)        "Score: 7 / 10"
# │       ├── TimerBar (ProgressBar)
# │       ├── GizmoLabel (Label)        "Gizmo says: ..."
# │       └── ExitQuestBtn (Button)     "Quit Quest"

extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
# QUEST DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────
const QUESTS = {
	"counting_forge": {
		"name": "The Counting Forge",
		"description": "Addition & Subtraction (easy)",
		"reward_per_star": 10,
		"max_reward": 15,
		"question_fn": "_gen_addition",
	},
	"measurement_lab": {
		"name": "The Measurement Lab",
		"description": "Multiplication tables",
		"reward_per_star": 15,
		"max_reward": 30,
		"question_fn": "_gen_multiplication",
	},
	"blueprint_solver": {
		"name": "The Blueprint Solver",
		"description": "Division & simple fractions",
		"reward_per_star": 25,
		"max_reward": 50,
		"question_fn": "_gen_division",
	},
	"arcane_calculator": {
		"name": "The Arcane Calculator",
		"description": "Percentages & decimals",
		"reward_per_star": 35,
		"max_reward": 80,
		"question_fn": "_gen_percentage",
	},
}

const QUESTIONS_PER_QUEST = 10
const SECONDS_PER_QUESTION = 30.0

const GIZMO_CORRECT = [
	"Excellent! The forge sparks with power!",
	"That's right! You're a natural!",
	"Perfect answer! Your filament glows brighter!",
	"Correct! Gizmo is impressed!",
]
const GIZMO_WRONG = [
	"Not quite — but don't give up, Apprentice!",
	"Hmm, try to think it through next time!",
	"Close, but the forge needs the right answer!",
	"Keep practicing — you'll get it!",
]

# ─────────────────────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────────────────────
var _active_quest_id = ""
var _questions: Array = []
var _current_question_idx = 0
var _correct_answers = 0
var _question_timer_tween: Tween

@onready var coin_label: Label          = $UI/TopBar/CoinLabel
@onready var quest_menu: VBoxContainer  = $UI/QuestMenu
@onready var quest_panel: Panel         = $UI/QuestPanel
@onready var quest_title: Label         = $UI/QuestPanel/QuestTitle
@onready var question_label: Label      = $UI/QuestPanel/QuestionLabel
@onready var answer_grid: GridContainer = $UI/QuestPanel/AnswerGrid
@onready var feedback_label: Label      = $UI/QuestPanel/FeedbackLabel
@onready var score_label: Label         = $UI/QuestPanel/ScoreLabel
@onready var timer_bar: ProgressBar     = $UI/QuestPanel/TimerBar
@onready var gizmo_label: Label         = $UI/QuestPanel/GizmoLabel

func _ready() -> void:
	quest_panel.visible = false
	_refresh_coin_label()
	_build_quest_menu()

# ─────────────────────────────────────────────────────────────────────────────
# QUEST MENU
# ─────────────────────────────────────────────────────────────────────────────
func _build_quest_menu() -> void:
	for child in quest_menu.get_children():
		child.queue_free()

	var header = Label.new()
	header.text = "Choose a Quest to earn Forge Coins!"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_menu.add_child(header)

	for qid in QUESTS:
		var q = QUESTS[qid]
		var progress = SaveManager.data["academy_progress"].get(qid, {})
		var best_stars: int = progress.get("best_stars", 0)
		var plays_today: int = progress.get("plays_today", 0)
		var diminished = plays_today >= 3

		var hbox = HBoxContainer.new()

		var info_lbl = Label.new()
		info_lbl.text = "%s\n%s\nReward: up to %d 🪙  |  Best: %s  |  Plays today: %d" % [
			q["name"],
			q["description"],
			q["max_reward"],
			"⭐".repeat(best_stars) if best_stars > 0 else "Not attempted",
			plays_today,
		]
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(info_lbl)

		var play_btn = Button.new()
		play_btn.text = "Play" if not diminished else "Play (reduced coins)"
		play_btn.pressed.connect(_start_quest.bind(qid))
		hbox.add_child(play_btn)

		quest_menu.add_child(hbox)

# ─────────────────────────────────────────────────────────────────────────────
# START QUEST
# ─────────────────────────────────────────────────────────────────────────────
func _start_quest(quest_id: String) -> void:
	_active_quest_id = quest_id
	_current_question_idx = 0
	_correct_answers = 0
	_questions = []

	var q = QUESTS[quest_id]
	quest_title.text = q["name"]

	# Generate all questions up front
	for i in range(QUESTIONS_PER_QUEST):
		_questions.append(call(q["question_fn"]))

	quest_menu.visible = false
	quest_panel.visible = true
	feedback_label.text = ""
	gizmo_label.text = "Gizmo says: Ready, Apprentice? Here we go!"
	_show_question()

func _show_question() -> void:
	if _current_question_idx >= _questions.size():
		_end_quest()
		return

	var q = _questions[_current_question_idx]
	question_label.text = "Q%d: %s" % [_current_question_idx + 1, q["question"]]
	score_label.text = "Score: %d / %d" % [_correct_answers, _current_question_idx]
	feedback_label.text = ""

	# Build answer buttons
	for child in answer_grid.get_children():
		child.queue_free()

	for i in range(q["choices"].size()):
		var choice = q["choices"][i]
		var btn = Button.new()
		btn.text = str(choice)
		btn.custom_minimum_size = Vector2(120, 50)
		btn.pressed.connect(_on_answer_selected.bind(choice, q["correct"]))
		answer_grid.add_child(btn)

	# Start timer
	timer_bar.max_value = SECONDS_PER_QUESTION
	timer_bar.value = SECONDS_PER_QUESTION
	if _question_timer_tween:
		_question_timer_tween.kill()
	_question_timer_tween = create_tween()
	_question_timer_tween.tween_property(timer_bar, "value", 0.0, SECONDS_PER_QUESTION)
	_question_timer_tween.tween_callback(_on_question_timeout)

func _on_answer_selected(chosen, correct) -> void:
	if _question_timer_tween:
		_question_timer_tween.kill()
	_disable_answer_buttons()

	if chosen == correct:
		_correct_answers += 1
		feedback_label.text = "✓ Correct!"
		feedback_label.add_theme_color_override("font_color", Color(0.22, 0.88, 0.22))
		gizmo_label.text = "Gizmo says: " + GIZMO_CORRECT[randi() % GIZMO_CORRECT.size()]
	else:
		feedback_label.text = "✗ The answer was %s" % str(correct)
		feedback_label.add_theme_color_override("font_color", Color(0.88, 0.22, 0.22))
		gizmo_label.text = "Gizmo says: " + GIZMO_WRONG[randi() % GIZMO_WRONG.size()]

	_current_question_idx += 1
	await get_tree().create_timer(1.4).timeout
	_show_question()

func _on_question_timeout() -> void:
	_disable_answer_buttons()
	feedback_label.text = "⏰ Time's up! Answer was %s" % str(_questions[_current_question_idx]["correct"])
	feedback_label.add_theme_color_override("font_color", Color(0.88, 0.62, 0.12))
	gizmo_label.text = "Gizmo says: No worries — keep going!"
	_current_question_idx += 1
	await get_tree().create_timer(1.4).timeout
	_show_question()

func _disable_answer_buttons() -> void:
	for btn in answer_grid.get_children():
		btn.disabled = true

# ─────────────────────────────────────────────────────────────────────────────
# END QUEST
# ─────────────────────────────────────────────────────────────────────────────
func _end_quest() -> void:
	var stars = _calculate_stars(_correct_answers, QUESTIONS_PER_QUEST)
	var q = QUESTS[_active_quest_id]
	var base_coins = int(q["max_reward"] * (float(_correct_answers) / float(QUESTIONS_PER_QUEST)))
	base_coins = max(base_coins, 3)  # Always give at least 3 coins

	# Record in save (diminishing returns handled inside SaveManager)
	SaveManager.record_academy_quest(_active_quest_id, stars, base_coins)
	SaveManager.add_xp(stars * 10)

	question_label.text = "Quest Complete!"
	score_label.text = "Final Score: %d / %d  (%s)" % [
		_correct_answers, QUESTIONS_PER_QUEST,
		"⭐".repeat(stars) if stars > 0 else "Keep practicing!"
	]
	gizmo_label.text = "Gizmo says: %s" % _end_message(stars)
	feedback_label.text = "Coins earned: %d 🪙" % base_coins

	for child in answer_grid.get_children():
		child.queue_free()

	var back_btn = Button.new()
	back_btn.text = "Back to Quest Menu"
	back_btn.pressed.connect(_on_back_to_menu)
	answer_grid.add_child(back_btn)

	_refresh_coin_label()

func _calculate_stars(correct: int, total: int) -> int:
	var pct = float(correct) / float(total)
	if pct >= 0.9:  return 3
	if pct >= 0.7:  return 2
	if pct >= 0.5:  return 1
	return 0

func _end_message(stars: int) -> String:
	match stars:
		3: return "Three stars! Masterful work, Apprentice!"
		2: return "Two stars! Great effort — you're improving!"
		1: return "One star! Good start — practice makes perfect!"
		_: return "Don't give up! Every Forge Master started where you are."

func _on_back_to_menu() -> void:
	quest_panel.visible = false
	quest_menu.visible = true
	_build_quest_menu()

# ─────────────────────────────────────────────────────────────────────────────
# QUESTION GENERATORS
# ─────────────────────────────────────────────────────────────────────────────
func _gen_addition() -> Dictionary:
	var a = randi_range(1, 50)
	var b = randi_range(1, 50)
	var op = ["+", "-"][randi() % 2]
	var correct: int
	var question: String
	if op == "+":
		correct = a + b
		question = "%d + %d = ?" % [a, b]
	else:
		# Ensure no negatives for younger players
		if a < b:
			var tmp = a; a = b; b = tmp
		correct = a - b
		question = "%d - %d = ?" % [a, b]
	return _make_question(question, correct, 4, 0, 100)

func _gen_multiplication() -> Dictionary:
	var a = randi_range(2, 12)
	var b = randi_range(2, 12)
	var correct = a * b
	var question = "%d × %d = ?" % [a, b]
	return _make_question(question, correct, 4, 0, 144)

func _gen_division() -> Dictionary:
	var b = randi_range(2, 12)
	var correct = randi_range(2, 12)
	var a = b * correct
	var question = "%d ÷ %d = ?" % [a, b]
	return _make_question(question, correct, 4, 1, 144)

func _gen_percentage() -> Dictionary:
	var percents = [10, 20, 25, 50, 75]
	var pct: int = percents[randi() % percents.size()]
	var base = randi_range(1, 20) * 4  # Multiples of 4 for clean answers
	var correct: int = int(float(pct) / 100.0 * float(base))
	var question = "What is %d%% of %d?" % [pct, base]
	return _make_question(question, correct, 4, 0, base)

func _make_question(question: String, correct: int, num_choices: int,
					min_val: int, max_val: int) -> Dictionary:
	var choices = [correct]
	var attempts = 0
	while choices.size() < num_choices and attempts < 50:
		attempts += 1
		var wrong = correct + randi_range(-10, 10)
		wrong = clamp(wrong, min_val, max_val)
		if wrong != correct and not wrong in choices:
			choices.append(wrong)
	choices.shuffle()
	return {"question": question, "correct": correct, "choices": choices}

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _refresh_coin_label() -> void:
	coin_label.text = "🪙 %d" % SaveManager.get_coins()

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")

func _on_exit_quest_btn_pressed() -> void:
	if _question_timer_tween:
		_question_timer_tween.kill()
	quest_panel.visible = false
	quest_menu.visible = true
	_build_quest_menu()
