# Battle.gd
# Main battle scene — connects BattleManager signals to UI.
# Scene file: res://scenes/Battle.tscn
#
# SCENE TREE:
# Battle (Node2D)
# ├── Background (TextureRect)        — forge arena background art
# ├── UI (CanvasLayer)
# │   ├── CoinFlipPanel (Panel)       — shown during flip, hidden after
# │   │   ├── CoinSprite (AnimatedSprite2D)
# │   │   └── FlipResultLabel (Label) "You go first!" / "Opponent goes first!"
# │   │
# │   ├── PlayerSide (VBoxContainer)  — bottom half of screen
# │   │   ├── PrintSprite (ColorRect) — placeholder; swap TextureRect for real sprites
# │   │   ├── PrintNameLabel (Label)
# │   │   ├── HPBar (ProgressBar)
# │   │   ├── HPLabel (Label)         "36 / 36"
# │   │   ├── ForgeBar (ProgressBar)  max=10
# │   │   ├── ForgeLabel (Label)      "Forge: 3.5 / 10"
# │   │   ├── AbilityBtn (Button)     "Use Ability"
# │   │   ├── CardHand (HBoxContainer)— 4 card buttons
# │   │   └── EndTurnBtn (Button)     "End Turn →"
# │   │
# │   ├── AISide (VBoxContainer)      — top half of screen
# │   │   ├── PrintSprite (ColorRect)
# │   │   ├── PrintNameLabel (Label)
# │   │   ├── HPBar (ProgressBar)
# │   │   ├── HPLabel (Label)
# │   │   ├── ForgeBar (ProgressBar)
# │   │   └── ForgeLabel (Label)
# │   │
# │   ├── BenchPanel (HBoxContainer)  — player bench sprites
# │   ├── AIBenchPanel (HBoxContainer)
# │   ├── BattleLog (RichTextLabel)   — scrolling combat log
# │   ├── TurnTimer (ProgressBar)     — 15 second countdown
# │   └── ResultPanel (Panel)         — Win/Lose screen, hidden until battle ends
# │       ├── ResultLabel (Label)
# │       ├── RewardsLabel (Label)
# │       └── ContinueBtn (Button)    "Return to Workshop"

extends Node2D

# ── Node references (assign in editor or via $ paths matching tree above) ──
@onready var coin_flip_panel: Panel      = $UI/CoinFlipPanel
@onready var flip_result_label: Label    = $UI/CoinFlipPanel/FlipResultLabel

@onready var player_sprite: ColorRect    = $UI/PlayerSide/PrintSprite
@onready var player_name_lbl: Label      = $UI/PlayerSide/PrintNameLabel
@onready var player_hp_bar: ProgressBar  = $UI/PlayerSide/HPBar
@onready var player_hp_lbl: Label        = $UI/PlayerSide/HPLabel
@onready var player_forge_bar: ProgressBar = $UI/PlayerSide/ForgeBar
@onready var player_forge_lbl: Label     = $UI/PlayerSide/ForgeLabel
@onready var ability_btn: Button         = $UI/PlayerSide/AbilityBtn
@onready var card_hand: HBoxContainer    = $UI/PlayerSide/CardHand
@onready var end_turn_btn: Button        = $UI/PlayerSide/EndTurnBtn

@onready var ai_sprite: ColorRect        = $UI/AISide/PrintSprite
@onready var ai_name_lbl: Label          = $UI/AISide/PrintNameLabel
@onready var ai_hp_bar: ProgressBar      = $UI/AISide/HPBar
@onready var ai_hp_lbl: Label            = $UI/AISide/HPLabel
@onready var ai_forge_bar: ProgressBar   = $UI/AISide/ForgeBar
@onready var ai_forge_lbl: Label         = $UI/AISide/ForgeLabel

@onready var bench_panel: HBoxContainer  = $UI/BenchPanel
@onready var ai_bench_panel: HBoxContainer = $UI/AIBenchPanel
@onready var battle_log: RichTextLabel   = $UI/BattleLog
@onready var turn_timer: ProgressBar     = $UI/TurnTimer
@onready var result_panel: Panel         = $UI/ResultPanel
@onready var result_label: Label         = $UI/ResultPanel/ResultLabel
@onready var rewards_label: Label        = $UI/ResultPanel/RewardsLabel

# ── State ──
var _player_hand: Array = []     # Array of card_ids currently in hand
var _timer_tween: Tween
var _is_player_turn = false

const TURN_SECONDS = 15.0
const CARD_POOL = ["raw_filament", "heated_spool", "reinforced_layer",
					"emergency_print", "arcane_filament"]

# ─────────────────────────────────────────────────────────────────────────────
# RECEIVE DATA FROM SCENE TRANSITION
# ─────────────────────────────────────────────────────────────────────────────
func receive_data(data: Dictionary) -> void:
	var team: Array = data.get("team", [])
	var trainer: Dictionary = data.get("trainer", {})
	if team.is_empty() or trainer.is_empty():
		SceneTransition.go_to("res://scenes/Workshop.tscn")
		return
	_connect_signals()
	BattleManager.start_battle(team, trainer)

# ─────────────────────────────────────────────────────────────────────────────
# SIGNAL CONNECTIONS
# ─────────────────────────────────────────────────────────────────────────────
func _connect_signals() -> void:
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.coin_flip_result.connect(_on_coin_flip)
	BattleManager.turn_started.connect(_on_turn_started)
	BattleManager.attack_landed.connect(_on_attack_landed)
	BattleManager.ability_used.connect(_on_ability_used)
	BattleManager.card_played.connect(_on_card_played)
	BattleManager.print_hp_changed.connect(_on_hp_changed)
	BattleManager.forge_bar_changed.connect(_on_forge_changed)
	BattleManager.print_defeated.connect(_on_print_defeated)
	BattleManager.next_print_summoned.connect(_on_print_summoned)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.status_effect_applied.connect(_on_status_applied)

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE STARTED
# ─────────────────────────────────────────────────────────────────────────────
func _on_battle_started(player_team: Array, ai_team: Array) -> void:
	result_panel.visible = false
	coin_flip_panel.visible = true
	_set_player_buttons_enabled(false)
	_build_bench(player_team, ai_team)
	_log("Battle begins! %s vs %s" % [
		GameData.CREATURES[player_team[0]["creature_id"]]["name"],
		BattleManager.current_trainer["name"]
	])

# ─────────────────────────────────────────────────────────────────────────────
# COIN FLIP
# ─────────────────────────────────────────────────────────────────────────────
func _on_coin_flip(player_first: bool) -> void:
	flip_result_label.text = "You go first!" if player_first else "Opponent goes first!"
	_log("Coin flip: %s" % flip_result_label.text)
	# Wait 2 seconds then hide panel and begin
	await get_tree().create_timer(2.0).timeout
	coin_flip_panel.visible = false
	BattleManager.begin_first_turn()

# ─────────────────────────────────────────────────────────────────────────────
# TURN STARTED
# ─────────────────────────────────────────────────────────────────────────────
func _on_turn_started(is_player_turn: bool, turn_number: int) -> void:
	_is_player_turn = is_player_turn
	_log("\n— Turn %d: %s —" % [turn_number, "Your turn" if is_player_turn else "Opponent's turn"])

	if is_player_turn:
		_deal_card()
		_set_player_buttons_enabled(true)
		_update_ability_btn()
		_start_turn_timer()
	else:
		_set_player_buttons_enabled(false)
		_stop_turn_timer()
		# AI acts after a short delay for readability
		await get_tree().create_timer(1.2).timeout
		BattleManager.ai_take_turn()

# ─────────────────────────────────────────────────────────────────────────────
# TURN TIMER
# ─────────────────────────────────────────────────────────────────────────────
func _start_turn_timer() -> void:
	turn_timer.max_value = TURN_SECONDS
	turn_timer.value = TURN_SECONDS
	if _timer_tween:
		_timer_tween.kill()
	_timer_tween = create_tween()
	_timer_tween.tween_property(turn_timer, "value", 0.0, TURN_SECONDS)
	_timer_tween.tween_callback(_on_timer_expired)

func _stop_turn_timer() -> void:
	if _timer_tween:
		_timer_tween.kill()
	turn_timer.value = 0

func _on_timer_expired() -> void:
	if _is_player_turn and BattleManager.phase == BattleManager.BattlePhase.PLAYER_TURN:
		_log("Time's up! Turn ends automatically.")
		BattleManager.player_end_turn()

# ─────────────────────────────────────────────────────────────────────────────
# ATTACKS & ABILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _on_attack_landed(attacker_side: String, damage: int, is_super: bool, is_not: bool) -> void:
	var attacker_name = _get_active_name(attacker_side)
	var effectiveness = ""
	if is_super:
		effectiveness = " [Super effective!]"
	elif is_not:
		effectiveness = " [Not very effective...]"
	_log("%s attacks for %d damage!%s" % [attacker_name, damage, effectiveness])
	_animate_hit(attacker_side)

func _on_ability_used(user_side: String, ability_id: String, _result: Dictionary) -> void:
	var ability = GameData.ABILITIES[ability_id]
	var name = _get_active_name(user_side)
	_log("%s uses %s! %s" % [name, ability["name"], ability["description"]])
	_update_ability_btn()

func _on_card_played(card_id: String, result: Dictionary) -> void:
	var card = GameData.FILAMENT_CARDS[card_id]
	_log("Card played: %s — %s" % [card["name"], card["description"]])

# ─────────────────────────────────────────────────────────────────────────────
# HP & FORGE UPDATES
# ─────────────────────────────────────────────────────────────────────────────
func _on_hp_changed(side: String, new_hp: int, max_hp: int) -> void:
	if side == "player":
		player_hp_bar.max_value = max_hp
		player_hp_bar.value = new_hp
		player_hp_lbl.text = "%d / %d" % [new_hp, max_hp]
	else:
		ai_hp_bar.max_value = max_hp
		ai_hp_bar.value = new_hp
		ai_hp_lbl.text = "%d / %d" % [new_hp, max_hp]

func _on_forge_changed(side: String, new_value: float) -> void:
	if side == "player":
		player_forge_bar.value = new_value
		player_forge_lbl.text = "Forge: %.1f / 10" % new_value
	else:
		ai_forge_bar.value = new_value
		ai_forge_lbl.text = "Forge: %.1f / 10" % new_value

# ─────────────────────────────────────────────────────────────────────────────
# PRINT DEFEATED / SUMMONED
# ─────────────────────────────────────────────────────────────────────────────
func _on_print_defeated(side: String, creature_id: String) -> void:
	var name = GameData.CREATURES[creature_id]["name"]
	_log("%s has been defeated! The printer breaks apart!" % name)
	_play_defeat_animation(side)

func _on_print_summoned(side: String, print_data: Dictionary) -> void:
	var creature = GameData.CREATURES[print_data["creature_id"]]
	_log("%s summons %s!" % [
		"You" if side == "player" else BattleManager.current_trainer["name"],
		creature["name"]
	])
	_update_active_sprite(side, print_data)
	# Mark in forgedex if we see an AI creature we haven't seen
	if side == "ai":
		SaveManager.mark_seen(print_data["creature_id"])

# ─────────────────────────────────────────────────────────────────────────────
# STATUS EFFECTS
# ─────────────────────────────────────────────────────────────────────────────
func _on_status_applied(side: String, effect: String, _duration: int) -> void:
	_log("%s is now %s!" % ["You" if side == "player" else "Opponent", effect])

# ─────────────────────────────────────────────────────────────────────────────
# BATTLE ENDED
# ─────────────────────────────────────────────────────────────────────────────
func _on_battle_ended(player_won: bool, rewards: Dictionary) -> void:
	_stop_turn_timer()
	_set_player_buttons_enabled(false)
	result_panel.visible = true

	if player_won:
		result_label.text = "⚙ Victory! ⚙"
		var drop_text = ""
		if rewards.get("drop", "") != "":
			var drop_id: String = rewards["drop"]
			var drop_name = ""
			if drop_id in GameData.CREATURES:
				drop_name = GameData.CREATURES[drop_id]["name"]
			elif drop_id in GameData.EQUIPMENT:
				drop_name = GameData.EQUIPMENT[drop_id]["name"]
			drop_text = "\n🎁 Blueprint Drop: %s!" % drop_name
		rewards_label.text = "+%d XP   +%d Forge Coins%s" % [
			rewards["xp"], rewards["coins"], drop_text
		]
	else:
		result_label.text = "⚙ Defeated! ⚙"
		rewards_label.text = "+%d XP   +%d Forge Coins\nKeep forging — you'll get there!" % [
			rewards["xp"], rewards["coins"]
		]

func _on_continue_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER BUTTONS
# ─────────────────────────────────────────────────────────────────────────────
func _on_ability_btn_pressed() -> void:
	BattleManager.player_use_ability()

func _on_end_turn_btn_pressed() -> void:
	_stop_turn_timer()
	BattleManager.player_end_turn()

func _set_player_buttons_enabled(enabled: bool) -> void:
	ability_btn.disabled = not enabled
	end_turn_btn.disabled = not enabled
	for card_btn in card_hand.get_children():
		card_btn.disabled = not enabled

func _update_ability_btn() -> void:
	var print_inst = BattleManager.get_player_active_print()
	if print_inst == null or print_inst.is_empty():
		ability_btn.text = "No Active Print"
		ability_btn.disabled = true
		return
	var creature = GameData.CREATURES[print_inst["creature_id"]]
	var ability_id: String = creature["ability"]
	var ability = GameData.ABILITIES[ability_id]
	var cd: int = BattleManager.player_ability_cooldowns.get(ability_id, 0)
	if cd > 0:
		ability_btn.text = "%s (CD: %d)" % [ability["name"], cd]
		ability_btn.disabled = true
	else:
		ability_btn.text = ability["name"]
		ability_btn.disabled = false

# ─────────────────────────────────────────────────────────────────────────────
# CARD HAND
# ─────────────────────────────────────────────────────────────────────────────
func _deal_card() -> void:
	if _player_hand.size() >= 4:
		return
	# Pick random card from pool
	var card_id = CARD_POOL[randi() % CARD_POOL.size()]
	_player_hand.append(card_id)
	_rebuild_card_hand()

func _rebuild_card_hand() -> void:
	for child in card_hand.get_children():
		child.queue_free()
	for i in range(_player_hand.size()):
		var cid: String = _player_hand[i]
		var card = GameData.FILAMENT_CARDS[cid]
		var btn = Button.new()
		btn.text = "%s\n%s" % [card["name"], card["description"]]
		btn.custom_minimum_size = Vector2(160, 80)
		btn.pressed.connect(_on_card_btn_pressed.bind(i))
		card_hand.add_child(btn)

func _on_card_btn_pressed(index: int) -> void:
	if index >= _player_hand.size():
		return
	var card_id = _player_hand[index]
	BattleManager.player_play_card(card_id)
	_player_hand.remove_at(index)
	_rebuild_card_hand()

# ─────────────────────────────────────────────────────────────────────────────
# BENCH DISPLAY
# ─────────────────────────────────────────────────────────────────────────────
func _build_bench(player_team: Array, ai_team: Array) -> void:
	for child in bench_panel.get_children():
		child.queue_free()
	for child in ai_bench_panel.get_children():
		child.queue_free()

	for inst in player_team:
		var creature = GameData.CREATURES[inst["creature_id"]]
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(48, 48)
		swatch.color = creature["placeholder_color"]
		swatch.tooltip_text = creature["name"]
		bench_panel.add_child(swatch)

	for inst in ai_team:
		var creature = GameData.CREATURES[inst["creature_id"]]
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(48, 48)
		swatch.color = creature["placeholder_color"]
		swatch.tooltip_text = "???"
		ai_bench_panel.add_child(swatch)

	# Initialize active sprites for the first prints
	if not player_team.is_empty():
		_update_active_sprite("player", player_team[0])
	if not ai_team.is_empty():
		_update_active_sprite("ai", ai_team[0])

# ─────────────────────────────────────────────────────────────────────────────
# SPRITE UPDATES
# ─────────────────────────────────────────────────────────────────────────────
func _update_active_sprite(side: String, print_data: Dictionary) -> void:
	var creature = GameData.CREATURES[print_data["creature_id"]]
	if side == "player":
		player_sprite.color = creature["placeholder_color"]
		player_name_lbl.text = creature["name"]
		var max_hp: int = creature["hp_base"]
		player_hp_bar.max_value = max_hp
		player_hp_bar.value = print_data["hp_current"]
		player_hp_lbl.text = "%d / %d" % [print_data["hp_current"], max_hp]
	else:
		ai_sprite.color = creature["placeholder_color"]
		ai_name_lbl.text = creature["name"]
		var max_hp: int = creature["hp_base"]
		ai_hp_bar.max_value = max_hp
		ai_hp_bar.value = print_data["hp_current"]
		ai_hp_lbl.text = "%d / %d" % [print_data["hp_current"], max_hp]

func _animate_hit(attacker_side: String) -> void:
	# Simple shake tween on the defender sprite
	var target_sprite = ai_sprite if attacker_side == "player" else player_sprite
	var original_pos = target_sprite.position
	var tween = create_tween()
	tween.tween_property(target_sprite, "position",
		original_pos + Vector2(8, 0), 0.05)
	tween.tween_property(target_sprite, "position",
		original_pos - Vector2(8, 0), 0.05)
	tween.tween_property(target_sprite, "position",
		original_pos + Vector2(6, 0), 0.04)
	tween.tween_property(target_sprite, "position",
		original_pos, 0.04)

func _play_defeat_animation(side: String) -> void:
	var sprite = player_sprite if side == "player" else ai_sprite
	var tween = create_tween()
	tween.tween_property(sprite, "modulate",
		Color(1, 1, 1, 0), 0.6)
	tween.tween_callback(func(): sprite.modulate = Color(1, 1, 1, 1))

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _get_active_name(side: String) -> String:
	var inst = BattleManager.get_player_active_print() if side == "player" \
		else BattleManager.get_ai_active_print()
	if inst == null or inst.is_empty():
		return "???"
	return GameData.CREATURES[inst["creature_id"]]["name"]

func _log(text: String) -> void:
	battle_log.append_text("\n" + text)
	battle_log.scroll_to_line(battle_log.get_line_count())
