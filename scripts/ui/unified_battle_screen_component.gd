class_name UnifiedBattleScreenComponent
extends RefCounted
## Shipped v3 battle controller/presenter. Main supplies navigation and theme
## helpers; this component owns the battle screen composition and interactions.

const RULES := preload("res://scripts/core/unified_rules.gd")

# Kept by the RefCounted presenter rather than the rebuilt shell.  Main detaches
# it before every responsive rebuild and this component mounts it again, so an
# accepted action can finish its finite visual window without touching battle
# authority or being cancelled by a layout refresh.
var _sprite_stage: Control

func detach() -> void:
	if _sprite_stage != null and is_instance_valid(_sprite_stage) and _sprite_stage.get_parent() != null:
		_sprite_stage.get_parent().remove_child(_sprite_stage)

func _mount_sprite_stage(host: Control, shell: Control) -> void:
	if _sprite_stage == null or not is_instance_valid(_sprite_stage):
		_sprite_stage = shell._new_local_battle_stage()
	if _sprite_stage == null:
		return
	if _sprite_stage.get_parent() != null:
		_sprite_stage.get_parent().remove_child(_sprite_stage)
	_sprite_stage.name = "UnifiedBattleSpriteStage"
	# The stage overlays the existing short arena plate rather than adding a new
	# vertical row. This keeps phase/card controls in the tested first fold.
	_sprite_stage.custom_minimum_size = Vector2.ZERO
	_sprite_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sprite_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var presentation: Dictionary = shell.unified_battle_presentation
	var kind := str(presentation.get("kind", ""))
	# Idle boards follow live public slots. Pre-action snapshots are reserved for
	# the finite window only, so a defeated defender does not linger forever.
	var left_unit: Dictionary = shell._unified_first_stage_unit(0) if kind.is_empty() else (presentation.get("left", {}) if presentation.get("left", {}) is Dictionary else {})
	var right_unit: Dictionary = shell._unified_first_stage_unit(1) if kind.is_empty() else (presentation.get("right", {}) if presentation.get("right", {}) is Dictionary else {})
	_sprite_stage.configure(left_unit, right_unit, kind, int(presentation.get("actor", 0)), bool(shell.settings().get("reduced_motion", false)), bool(shell.settings().get("high_contrast", false)), int(presentation.get("token", 0)))
	host.add_child(_sprite_stage)

func _phase_action_label(phase: String) -> String:
	match phase:
		"draw": return "Begin Main"
		"main": return "Start Printing"
		"print": return "Resolve Printing"
		"attack": return "Finish Attacks"
		"collect": return "Collect & End Turn"
	return "Advance phase"

func render(host: Container, shell: Control) -> void:
	var battle = shell.battle
	if battle == null:
		host.add_child(shell.label("No unified battle is active.", 20, Color("fff0a1")))
		host.add_child(shell.make_button("Return to Workshop", shell.navigate_to.bind("workshop"), Color("536c8d")))
		return
	var heading: Label = shell.label("Foundry Battle · %s" % str(shell.battle_mode).capitalize().replace("_", " "), 25, Color("ffd36c"))
	heading.name = "UnifiedBattleHeading"
	host.add_child(heading)
	var arena_shell := Control.new()
	arena_shell.name = "UnifiedBattleArena"
	arena_shell.custom_minimum_size = Vector2(0, 48 if shell.is_portrait_layout() else 44)
	arena_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(arena_shell)
	var arena := TextureRect.new()
	arena.texture = load(shell._unified_battle_background_path())
	arena.custom_minimum_size = Vector2(0, 48 if shell.is_portrait_layout() else 44)
	arena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_shell.add_child(arena)
	_mount_sprite_stage(arena_shell, shell)
	if not str(shell.toast).is_empty(): host.add_child(shell.label(str(shell.toast), 14, Color("fff0a1")))
	var fields: HBoxContainer = HBoxContainer.new()
	fields.name = "UnifiedBattleFields"
	fields.add_theme_constant_override("separation", 8)
	host.add_child(fields)
	var rival_field: Control = shell._unified_side_panel("Rival", battle.player(1), Color("ffaaa1"))
	var player_field: Control = shell._unified_side_panel("Your", battle.player(0), Color("8deaff"))
	rival_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_child(rival_field)
	fields.add_child(player_field)
	if str(shell.battle_mode) == "local" and bool(shell.unified_local_handoff):
		var handoff: VBoxContainer = shell.make_panel(Color("2b213ee8"), Color("f1be69"))
		handoff.name = "UnifiedLocalHandoff"
		host.add_child(handoff.get_parent())
		handoff.add_child(shell.label("Pass the device · Player %d" % (int(battle.active_seat) + 1), 18, Color("fff0a1")))
		handoff.add_child(shell.label("Hands remain concealed until the next player is ready.", 14, Color("e6dfd0")))
		handoff.add_child(shell.make_button("Ready Player %d" % (int(battle.active_seat) + 1), func(): shell.unified_local_handoff = false; shell.unified_hand_page = 0; shell.render(), Color("a86b2e")))
		return
	if bool(battle.finished):
		host.add_child(shell.label("%s printer broke." % ("Rival" if int(battle.winner) == 0 else "Your"), 20, Color("a8e3a5") if int(battle.winner) == 0 else Color("ffaaa1")))
		if not shell.battle_settlement_context.is_empty() and not bool(shell.battle_settlement_finished):
			host.add_child(shell.label("Saving the battle result…", 14, Color("fff0a1")))
			shell.call_deferred("_settle_finished_unified_battle")
		else:
			host.add_child(shell.make_button("Return to Workshop", shell._leave_unified_battle, Color("536c8d")))
		return
	if bool(shell.unified_ai_pending) or (str(shell.battle_mode) != "local" and int(battle.active_seat) == 1):
		host.add_child(shell.label("Rival printer is calculating its turn…", 15, Color("fff0a1")))
		return
	var phase_banner := HBoxContainer.new()
	phase_banner.name = "UnifiedBattlePhaseBanner"
	phase_banner.add_theme_constant_override("separation", 8)
	host.add_child(phase_banner)
	var phase_label: Label = shell.label("Turn %d · %s phase" % [int(battle.turn), str(battle.phase).capitalize()], 16, Color("9beaff"))
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_banner.add_child(phase_label)
	var active: Dictionary = battle.player(int(battle.active_seat))
	var pending: Dictionary = battle.pending
	var pending_for_active_human := not pending.is_empty() and int(pending.get("seat", -1)) == int(battle.active_seat)
	if pending_for_active_human:
		_render_pending_print_decision(host, shell, active, pending)
		var pending_return: Button = shell.make_button("Return to Workshop", shell._leave_unified_battle, Color("536c8d"))
		pending_return.name = "UnifiedBattleWorkshopReturn"
		pending_return.tooltip_text = "Leave this battle and return to the Workshop"
		pending_return.accessibility_name = "Return to Workshop"
		pending_return.focus_mode = Control.FOCUS_ALL
		host.add_child(pending_return)
		return
	var primary_action: Button = shell.make_button(_phase_action_label(str(battle.phase)), shell._submit_unified_intent.bind({"type":"advance_phase"}), Color("2f93a8"))
	primary_action.name = "UnifiedBattlePrimaryAction"
	primary_action.tooltip_text = "Advance from %s phase" % str(battle.phase).capitalize()
	primary_action.accessibility_name = _phase_action_label(str(battle.phase))
	primary_action.focus_mode = Control.FOCUS_ALL
	primary_action.custom_minimum_size = Vector2(176, 44)
	primary_action.size_flags_horizontal = Control.SIZE_SHRINK_END
	phase_banner.add_child(primary_action)
	var hand_title: Label = shell.label("Player %d hand" % (int(battle.active_seat) + 1), 17, Color("ffd36c"))
	hand_title.name = "UnifiedHandHeading"
	host.add_child(hand_title)
	var hand: Array = active.get("hand", [])
	var hand_page_size := 4 if shell.is_portrait_layout() else 7
	var pages := maxi(1, int(ceil(float(hand.size()) / float(hand_page_size))))
	shell.unified_hand_page = clampi(int(shell.unified_hand_page), 0, pages - 1)
	var hand_grid := GridContainer.new()
	hand_grid.name = "UnifiedBattleHandGrid"
	hand_grid.columns = 2 if shell.is_portrait_layout() else 4
	hand_grid.add_theme_constant_override("h_separation", 8)
	hand_grid.add_theme_constant_override("v_separation", 8)
	host.add_child(hand_grid)
	for card_id in hand.slice(int(shell.unified_hand_page) * hand_page_size, mini(hand.size(), (int(shell.unified_hand_page) + 1) * hand_page_size)):
		hand_grid.add_child(shell._unified_card_button(str(card_id)))
	if int(battle.active_seat) == 0 or str(shell.battle_mode) == "local":
		shell._render_unified_play_picker(host, active)
	var pager := HBoxContainer.new()
	pager.name = "UnifiedBattleHandPager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.add_child(pager)
	var hand_prev: Button = shell.make_button("‹", func(): shell.unified_hand_page = posmod(int(shell.unified_hand_page) - 1, pages); shell.render(), Color("536c8d"))
	hand_prev.custom_minimum_size = Vector2(48, 44)
	hand_prev.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hand_prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(hand_prev)
	pager.add_child(shell._compact_pager_label("Hand %d / %d" % [int(shell.unified_hand_page) + 1, pages]))
	var hand_next: Button = shell.make_button("›", func(): shell.unified_hand_page = posmod(int(shell.unified_hand_page) + 1, pages); shell.render(), Color("536c8d"))
	hand_next.custom_minimum_size = Vector2(48, 44)
	hand_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hand_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(hand_next)
	if int(battle.active_seat) == 0 or str(shell.battle_mode) == "local":
		shell._render_unified_attack_picker(host, active)
	host.add_child(shell.make_button("Return to Workshop", shell._leave_unified_battle, Color("536c8d")))

func _render_pending_print_decision(host: Container, shell: Control, active: Dictionary, pending: Dictionary) -> void:
	var panel: VBoxContainer = shell.make_panel(Color("3a241ee8"), Color("f1be69"))
	panel.name = "UnifiedPendingPrintDecision"
	host.add_child(panel.get_parent())
	var kind := str(pending.get("kind", ""))
	if kind == "place":
		var unit: Dictionary = pending.get("unit", {})
		var unit_name := str(unit.get("name", unit.get("card_id", "completed creature")))
		panel.add_child(shell.label("Completed print ready · %s" % unit_name, 17, Color("ffd36c")))
		panel.add_child(shell.label("Choose an open field slot and combat mode before continuing the Print phase.", 13, Color("e6dfd0")))
		var choices := GridContainer.new()
		choices.name = "UnifiedPendingPlaceChoices"
		choices.columns = 2 if shell.is_portrait_layout() else 3
		choices.add_theme_constant_override("h_separation", 8)
		choices.add_theme_constant_override("v_separation", 8)
		panel.add_child(choices)
		for slot in 3:
			if active.slots[slot] != null: continue
			for mode in ["attack", "defense"]:
				var mode_label := str(mode).capitalize()
				var choice: Button = shell.make_button("Slot %d · %s" % [slot + 1, mode_label], shell._submit_unified_intent.bind({"type":"place_completed", "slot":slot, "mode":mode}), Color("a86b2e") if mode == "attack" else Color("526e93"))
				choice.name = "UnifiedPendingPlaceSlot%d%s" % [slot + 1, mode_label]
				choice.tooltip_text = "Place %s in field slot %d in %s mode" % [unit_name, slot + 1, mode_label]
				choice.accessibility_name = "Place %s in slot %d in %s mode" % [unit_name, slot + 1, mode_label]
				choice.focus_mode = Control.FOCUS_ALL
				choice.custom_minimum_size = Vector2(0, 44)
				choices.add_child(choice)
		return
	if kind == "attach":
		var card_id := str(pending.get("card_id", ""))
		var card := RULES.card(card_id)
		var equipment_name := str(card.get("name", card_id))
		var equipment_slot := str(card.get("equipment_slot", "gear"))
		panel.add_child(shell.label("Completed equipment ready · %s" % equipment_name, 17, Color("ffd36c")))
		panel.add_child(shell.label("Choose a creature with an empty %s slot before continuing the Print phase." % equipment_slot.capitalize(), 13, Color("e6dfd0")))
		var choices := GridContainer.new()
		choices.name = "UnifiedPendingAttachChoices"
		choices.columns = 1 if shell.is_portrait_layout() else 3
		choices.add_theme_constant_override("h_separation", 8)
		choices.add_theme_constant_override("v_separation", 8)
		panel.add_child(choices)
		for slot in 3:
			var unit = active.slots[slot]
			if unit == null: continue
			var equipment: Dictionary = unit.get("equipment", {}) if unit.get("equipment", {}) is Dictionary else {}
			var attached: Dictionary = equipment.get(equipment_slot, {}) if equipment.get(equipment_slot, {}) is Dictionary else {}
			if not attached.is_empty(): continue
			var unit_name := str(unit.get("name", "Print"))
			var choice: Button = shell.make_button("Attach to slot %d · %s" % [slot + 1, unit_name], shell._submit_unified_intent.bind({"type":"attach_completed", "slot":slot}), Color("a86b2e"))
			choice.name = "UnifiedPendingAttachSlot%d" % (slot + 1)
			choice.tooltip_text = "Attach %s to %s in field slot %d" % [equipment_name, unit_name, slot + 1]
			choice.accessibility_name = "Attach %s to %s in slot %d" % [equipment_name, unit_name, slot + 1]
			choice.focus_mode = Control.FOCUS_ALL
			choice.custom_minimum_size = Vector2(0, 44)
			choices.add_child(choice)
		return
	panel.add_child(shell.label("A completed print needs a legal decision before the battle can continue.", 15, Color("fff0a1")))
