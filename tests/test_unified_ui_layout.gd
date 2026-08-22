extends Node

## Accessibility/UI contract for the shipped v3 screen. It deliberately tests
## control semantics and hot-seat privacy rather than obsolete 0.7 fixed-layout
## geometry; the battle component responds to portrait/landscape itself.
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _legal_profile() -> Dictionary:
	var profile := RULES.ensure(ProfileRules.new_profile())
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	profile.settings = {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":true}
	return profile

func _button_named(node: Node, fragment: String) -> Button:
	if node is Button and fragment.to_lower() in (node as Button).text.to_lower(): return node as Button
	for child in node.get_children():
		var found := _button_named(child, fragment)
		if found != null: return found
	return null

func _exercise(viewport: Vector2) -> void:
	GameManager.profile = _legal_profile()
	var subviewport := SubViewport.new()
	subviewport.size = Vector2i(viewport)
	subviewport.size_2d_override = Vector2i(viewport)
	subviewport.size_2d_override_stretch = true
	subviewport.disable_3d = true
	add_child(subviewport)
	var canvas := Control.new()
	canvas.position = Vector2.ZERO
	canvas.size = viewport
	subviewport.add_child(canvas)
	var main := MAIN.instantiate()
	var deck: Array = GameManager.active_deck_cards()
	main.battle = STATE.create(deck, deck, 81)
	main.battle_mode = "local"
	main.unified_local_handoff = true
	main.screen = "unified_battle"
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.get_script().resource_path == "res://scripts/ui/main.gd", "Shipped battle shell is main.gd at %s." % viewport)
	require(main.find_child("UnifiedBattleHeading", true, false) != null, "Battle heading renders at %s." % viewport)
	require(main.find_child("UnifiedLocalHandoff", true, false) != null, "Hot-seat privacy handoff renders at %s." % viewport)
	require(main.find_child("UnifiedBattleHandGrid", true, false) == null, "Hidden hand is omitted during hot-seat handoff at %s." % viewport)
	require(_button_named(main, "Ready Player") != null, "Handoff has an explicit ready action at %s." % viewport)
	main.unified_local_handoff = false
	main.render()
	await get_tree().process_frame
	require(main.find_child("UnifiedBattleHandGrid", true, false) != null, "Owner hand renders after handoff at %s." % viewport)
	require(main.find_child("UnifiedBattlePhaseActions", true, false) != null, "Explicit phase controls render at %s." % viewport)
	require(_button_named(main, "Advance phase") != null, "Phase advance is keyboard-focusable button at %s." % viewport)
	require(main.is_portrait_layout() == (viewport.y > viewport.x), "Battle component detects orientation at %s." % viewport)
	main.queue_free()
	await get_tree().process_frame
	subviewport.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	for viewport in [Vector2(1280, 720), Vector2(576, 1024)]:
		await _exercise(viewport)
	if failures.is_empty(): print("PASS: v3 battle accessibility and responsive handoff matrix")
	get_tree().quit(0 if failures.is_empty() else 1)
