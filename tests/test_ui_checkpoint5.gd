extends Node
const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []
func require(value: bool, message: String) -> void: if not value: failures.append(message); push_error(message)
func _ready() -> void:
	var p: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	p.coins = 500; p.blueprints.append("mossmunk")
	var printed := ProgressionRules.print_creature(p, "mossmunk"); p = printed.profile
	GameManager.profile = p
	var main := MAIN.instantiate(); main.screen = "trade"; add_child(main)
	await get_tree().process_frame; await get_tree().process_frame
	var yours: Array = main.local_trade.eligible(main.local_trade.creator); var theirs: Array = main.local_trade.eligible(main.local_trade.partner)
	main.select_trade_choice(0, yours[0]); main.select_trade_choice(1, theirs[0]); main.confirm_local_trade(0)
	await get_tree().process_frame
	require(main.local_trade.creator_confirmed and not main.local_trade.partner_confirmed, "trade confirmation persists through render")
	var revision := int(GameManager.profile.revision); main.confirm_local_trade(1); await get_tree().process_frame
	require(main.local_trade.settled and int(GameManager.profile.revision) == revision + 1 and not bool(main.local_trade.confirm(1, main.local_trade.creator_revision, main.local_trade.partner_revision).ok), "UI trade settles profile exactly once")
	var receipt := main.find_child("*", true, false); var found := false
	for node in main.find_children("*", "Label", true, false): if str((node as Label).text).contains("Settlement receipt"): found = true
	require(found and get_viewport().gui_get_focus_owner() is Button, "receipt and deterministic button focus visible")
	main.screen = "trade"; main.render(); var key := InputEventKey.new(); key.pressed = true; key.keycode = KEY_ESCAPE; main._unhandled_key_input(key)
	require(main.screen == "workshop", "escape returns to workshop")
	main.queue_free(); if failures.is_empty(): print("PASS: checkpoint5 UI trade flow and focus"); call_deferred("finish")
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
