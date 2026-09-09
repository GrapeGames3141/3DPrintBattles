extends Node

const STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")
const COMPONENT := preload("res://scripts/ui/unified_battle_screen_component.gd")
const PRESENTER := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
var failures: Array[String] = []

func _ready() -> void:
	var stage: Control = STAGE.new()
	stage.size = Vector2(576, 1024)
	add_child(stage)
	require(stage.anchors().rival_slots.size() == 3 and stage.anchors().player_slots.size() == 3, "Physical stage exposes two printers and six ordered slots.")
	stage.configure({"players":[{"slots":[{"card_id":"cinderpaw","name":"Cinderpaw","hp":100}],"hand":[]},{"slots":[{"card_id":"aquafin","name":"Aquafin","hp":100}],"hand_count":3}]}, {"kind":"attack","actor":0,"source_slot":0,"target_slot":0,"generation":1})
	await get_tree().process_frame
	var sprite := stage.find_child("LivingPrintSlot0", true, false) as TextureRect
	var stable_atlas := sprite.texture
	await get_tree().create_timer(0.12).timeout
	require(not sprite.visible and (stage.find_child("BattleContactPeakOverlay", true, false) as TextureRect).visible and is_same(sprite.texture, stable_atlas), "Attack receipt transfers one source print into the finite contact overlay without reallocating its home atlas.")
	await get_tree().create_timer(0.8).timeout
	require(sprite.visible and sprite.position.is_zero_approx(), "Finite attack presentation returns to one settled source sprite.")
	stage.configure({"players":[{"slots":[{"card_id":"cinderpaw","name":"Cinderpaw","hp":100}]},{"slots":[null,null,null]}]}, {"kind":"attack","actor":0,"source_slot":0,"target_slot":0,"target":{"card_id":"aquafin","name":"Aquafin","hp":0},"generation":2})
	await get_tree().create_timer(0.10).timeout
	require((stage.find_child("LivingPrintSlot3", true, false) as TextureRect).visible, "A defeated defender remains visible through attack contact.")
	await get_tree().create_timer(0.55).timeout
	require(not (stage.find_child("LivingPrintSlot3", true, false) as TextureRect).visible, "The defender is removed only at the finite defeat beat.")
	stage.set_focus(1, 0); stage.set_selected_slot(0, 0); await get_tree().process_frame
	require((stage.find_child("BattleFocusRing3", true, false) as Panel).visible and (stage.find_child("BattleSelectionRing0", true, false) as Panel).visible, "Rival focus and friendly selection rings persist together after rerender.")
	stage.set_focus(-1, -1); await get_tree().process_frame
	require(not (stage.find_child("BattleFocusRing3", true, false) as Panel).visible and (stage.find_child("BattleSelectionRing0", true, false) as Panel).visible, "Friendly selection remains visible when no rival focus exists.")
	stage.configure({"players":[{"slots":[{"card_id":"cinderpaw","job_id":"m11-job-a","name":"Cinderpaw","hp":100},null,null]},{"slots":[null,null,null],"hand_count":2}]}, {"kind":"print","actor":0,"generation":3,"token":3,"presentation_token":3,"presentation_duration":1.50,"print_events":[{"event":"complete","seat":0,"job_id":"m11-job-a","card_id":"cinderpaw","remaining_before":1,"remaining_after":0,"total_work":1}],"deployments":[{"event":"deployed","seat":0,"slot":0,"job_id":"m11-job-a","card_id":"cinderpaw"}],"presentation_beats":[{"kind":"print","duration":0.78,"work":{"event":"complete","seat":0,"job_id":"m11-job-a","card_id":"cinderpaw","remaining_before":1,"remaining_after":0,"total_work":1},"job_id":"m11-job-a","seat":0,"card_id":"cinderpaw"},{"kind":"deploy","duration":0.72,"deployment":{"event":"deployed","seat":0,"slot":0,"job_id":"m11-job-a","card_id":"cinderpaw"},"job_id":"m11-job-a","seat":0,"card_id":"cinderpaw"}]})
	await get_tree().process_frame
	var raw := stage.find_child("BattlePrinterSolidRaw0", true, false) as TextureRect
	var schematic := stage.find_child("BattlePrinterSchematic0", true, false) as TextureRect
	require(raw != null and schematic != null and raw.visible and schematic.visible and not (stage.find_child("LivingPrintSlot0", true, false) as TextureRect).visible and (stage.find_child("BattlePrinterClip0", true, false) as Control).clip_contents, "Sequence-backed printing has clipped raw-solid and shader-schematic layers while the completed creature remains hidden until its own arrival.")
	var stable_raw := raw.texture
	await get_tree().process_frame
	require(is_same(raw.texture, stable_raw), "Printer raw-print texture is cached across visual sync frames.")
	await get_tree().create_timer(0.90).timeout
	await get_tree().create_timer(0.35).timeout
	require((stage.find_child("BattleDeploySprite", true, false) as TextureRect).visible and not (stage.find_child("LivingPrintSlot0", true, false) as TextureRect).visible and not raw.visible and not schematic.visible, "The same receipt transfers ownership from chamber layers to its interpolating print without a manual placement pause.")
	await get_tree().create_timer(0.55).timeout
	require(not (stage.find_child("BattleDeploySprite", true, false) as TextureRect).visible and (stage.find_child("LivingPrintSlot0", true, false) as TextureRect).visible, "The finite receipt sequence settles to exactly one living slot sprite.")
	stage.configure({"players":[{"slots":[{"card_id":"mossmunk","name":"Mossmunk","hp":100}],"hand":[]},{"slots":[null,null,null],"hand_count":1}]}, {"kind":"deploy","actor":0,"card_id":"mossmunk","target_slot":0,"reduced_motion":true,"generation":5})
	await get_tree().process_frame
	require(not (stage.find_child("BattleDeploySprite", true, false) as TextureRect).visible and (stage.find_child("LivingPrintSlot0", true, false) as TextureRect).visible, "Reduced motion settles deploy directly without a duplicate flash.")
	stage.configure({"players":[{"slots":[{"card_id":"cinderpaw","name":"Cinderpaw","hp":100}],"hand":[]},{"slots":[null,null,null],"hand_count":1}]}, {"kind":"attack","actor":0,"source_slot":0,"target_slot":-1,"printer_target":true,"generation":6})
	await get_tree().process_frame
	await get_tree().create_timer(0.14).timeout
	require((stage.find_child("BattleContactPeakOverlay", true, false) as TextureRect).visible and not (stage.find_child("LivingPrintSlot0", true, false) as TextureRect).visible, "A printer-target attack gives one source print ownership to the finite source-to-printer contact overlay.")
	await get_tree().create_timer(0.8).timeout
	require((stage.find_child("LivingPrintSlot0", true, false) as TextureRect).visible, "Printer-target contact returns ownership to the single settled source print.")
	var shadow := stage.find_child("BattleGroundShadow0", true, false) as Panel
	require(shadow != null and shadow.visible and stage.find_child("BattleSlotLip0", true, false) == null, "Living prints use grounded shadows on the open floor, never retired card-lip hardware above their feet.")
	require((stage.find_child("BattlePrinterScanLine0", true, false) as ColorRect).name == "BattlePrinterScanLine0", "Printer owns a native cyan scan-line control at the solid/schematic split.")
	require(COMPONENT.new() != null, "Physical battle component loads.")
	var profile := RULES.ensure(ProfileRules.new_profile()); profile = RULES.choose_starter(profile, "cinderpaw").profile; profile = RULES.print_starter(profile).profile; GameManager.profile = profile
	var shell = MAIN.instantiate(); shell.screen = "proving"; add_child(shell); await get_tree().process_frame; shell.render(); await get_tree().process_frame
	require(shell.find_child("PhysicalChallengeBoard", true, false) != null and shell.find_child("ChallengeContinuePreflight", true, false) != null, "Battle dais begins on its distinct physical Challenge browse surface.")
	shell.set_meta("battle_preflight", true); shell.render(); await get_tree().process_frame
	require(shell.find_child("PhysicalBattlePreflight", true, false) != null and shell.find_child("ChallengeBeginBattle", true, false) != null, "Challenge continue opens the distinct legal Battle Preflight surface.")
	var legal_profile: Dictionary = GameManager.profile.duplicate(true)
	var invalid_profile: Dictionary = GameManager.profile.duplicate(true)
	invalid_profile["decks"] = [{"id":"starter-deck", "name":"Short", "cards":[]}]
	invalid_profile["active_deck_id"] = "starter-deck"
	GameManager.profile = invalid_profile; shell.render(); await get_tree().process_frame
	var invalid_preflight := shell.find_child("PhysicalBattlePreflight", true, false) as PanelContainer
	var invalid_copy := invalid_preflight.get_child(0).get_child(0) as Label if invalid_preflight != null else null
	var invalid_begin := shell.find_child("ChallengeBeginBattle", true, false) as Button
	require(invalid_copy != null and invalid_copy.text.contains(RULES.deck_reason(GameManager.profile, [])) and invalid_begin != null and invalid_begin.disabled and invalid_begin.tooltip_text == RULES.deck_reason(GameManager.profile, []), "Preflight derives legality feedback and Begin disabled state from the existing deck validator.")
	GameManager.profile = legal_profile; shell.render(); await get_tree().process_frame
	# In local hot-seat mode the player who has acknowledged Ready is the only
	# viewer whose hand may be public, and that owner maps to the lower row.
	var hotseat := UnifiedBattleState.create(["cinderpaw"], ["aquafin"], 41)
	hotseat.active_seat = 1; hotseat.phase = "main"; hotseat.player(0).hand = ["cinderpaw"]; hotseat.player(1).hand = ["aquafin"]; hotseat.player(1).filament = 130; hotseat.player(1).queue = [{"card_id":"cinderpaw", "remaining":1}]
	shell.battle = hotseat; shell.battle_mode = "local"; shell.unified_local_handoff = true; shell.screen = "unified_battle"; shell.unified_battle_coordinator.configure(hotseat, 0); shell.render(); await get_tree().process_frame
	shell.unified_local_handoff = false; shell._complete_unified_cycle_handoff()
	require(shell.unified_local_handoff and not shell.unified_ai_pending, "Completed local Run Cycle requests a privacy handoff instead of scheduling rival automation.")
	shell.unified_local_handoff = false; shell.battle_mode = "training"; shell._complete_unified_cycle_handoff()
	require(shell.unified_ai_pending, "Completed non-local Run Cycle schedules one deferred rival intent.")
	# Cancel this test-only deferred callback before yielding again; it must not be
	# able to mutate the constructed hot-seat authority after the assertion.
	shell.unified_battle_coordinator.invalidate_generation(); shell.unified_ai_pending = false; shell.battle_mode = "local"; shell.unified_local_handoff = true; shell.unified_battle_coordinator.configure(hotseat, 0)
	require(shell.find_child("PhysicalBattleHandScroll", true, false) == null, "Local handoff keeps all face-up hand controls hidden before Ready.")
	var hotseat_stage := shell.find_child("PhysicalBattlefieldStage", true, false) as PhysicalBattlefieldStage
	require(hotseat_stage != null and (hotseat_stage.snapshot.get("players", [])[0] as Dictionary).get("hand", []) == ["aquafin"], "Ready owner is mapped to the lower physical row without exposing seat zero's hand.")
	shell.unified_local_handoff = false; shell.render(); await get_tree().process_frame
	require(shell.find_child("UnifiedHandAquafin", true, false) != null and shell.find_child("UnifiedHandCinderpaw", true, false) == null, "After Ready only the active local owner hand is visible and playable.")
	var queue_hud := shell.find_child("PhysicalBattleHud0Resources", true, false) as Label
	require(queue_hud != null and queue_hud.text == "F 130/400 · Q1\nCinderpaw · 1t" and label_lines_fit(queue_hud, 6.0), "Player printer resource face exposes an explicit two-line FIFO head and remaining-turn readout without clipping.")
	hotseat.player(1).hand = ["cinderpaw"]; shell.unified_selected_card_id = "cinderpaw"; shell.unified_battle_coordinator.set_transient_focus(-1); shell.render(); await get_tree().process_frame
	var selected_blueprint := shell.find_child("UnifiedSelectedCreatureBlueprint", true, false) as PanelContainer
	var selected_art := shell.find_child("UnifiedSelectedCreatureBlueprintCard", true, false) as TextureRect
	var selected_copy := shell.find_child("UnifiedSelectedCreatureBlueprintCopy", true, false) as Label
	var selected_status := shell.find_child("PhysicalBattleStatus", true, false) as Label
	require(selected_blueprint != null and selected_art != null and selected_art.texture != null and selected_copy != null and selected_copy.text.contains(str(RULES.card("cinderpaw").get("name", ""))) and selected_copy.text.contains("%dF" % int(RULES.card("cinderpaw").get("filament_cost", RULES.card("cinderpaw").get("cost", 0)))) and selected_status != null and not selected_status.visible and selected_status.text.is_empty() and (shell.find_child("PhysicalBattleAnchor1_0", true, false) as Button).disabled, "Selected creature uses the central native-art blueprint instrument, clears duplicate status copy, and does not target rival anchors.")
	hotseat.player(1).hand = ["aquafin"]; shell.unified_selected_card_id = "aquafin"; shell.render(); await get_tree().process_frame
	selected_copy = shell.find_child("UnifiedSelectedCreatureBlueprintCopy", true, false) as Label
	selected_status = shell.find_child("PhysicalBattleStatus", true, false) as Label
	require(selected_copy != null and selected_copy.text.contains(str(RULES.card("aquafin").get("name", ""))) and selected_copy.text.contains("%dF" % int(RULES.card("aquafin").get("filament_cost", RULES.card("aquafin").get("cost", 0)))) and selected_copy.text.ends_with("Queue print") and selected_status != null and not selected_status.visible and selected_status.text.is_empty(), "Selected blueprint derives Aquafin name/cost from the catalog while its central instrument hides duplicate status copy.")
	hotseat.player(1).hand = ["cinderpaw"]; shell.unified_selected_card_id = "cinderpaw"
	for size in [Vector2(576, 1024), Vector2(720, 1280)]:
		shell.size = size; shell.render(); await get_tree().process_frame
		selected_blueprint = shell.find_child("UnifiedSelectedCreatureBlueprint", true, false) as PanelContainer
		selected_art = shell.find_child("UnifiedSelectedCreatureBlueprintCard", true, false) as TextureRect
		selected_copy = shell.find_child("UnifiedSelectedCreatureBlueprintCopy", true, false) as Label
		var status_instrument := shell.find_child("PhysicalBattleStatus", true, false) as Label
		var resource_hud := shell.find_child("PhysicalBattleHud0Resources", true, false) as Label
		var hand_rail := shell.find_child("PhysicalBattleHandScroll", true, false) as ScrollContainer
		var queue_print := shell.find_child("UnifiedPlayQueueCreature", true, false) as Button
		var hand_card := shell.find_child("UnifiedHandCinderpaw", true, false) as Button
		var selected_rect := selected_blueprint.get_global_rect() if selected_blueprint != null else Rect2()
		var selected_complete := selected_blueprint != null and selected_blueprint.clip_contents and selected_art != null and selected_art.texture != null and selected_copy != null and not selected_copy.text.is_empty() and selected_copy.get_global_rect().size.x > 0.0 and Rect2(Vector2.ZERO, size).encloses(selected_copy.get_global_rect())
		var instruments_present := status_instrument != null and resource_hud != null and hand_rail != null and queue_print != null
		var queue_touch_ok := queue_print != null and queue_print.custom_minimum_size.y >= 48.0
		var hud_copy_ok := resource_hud != null and resource_hud.text == "F 130/400 · Q1\nCinderpaw · 1t" and label_lines_fit(resource_hud, 6.0)
		var contained := Rect2(Vector2.ZERO, size).encloses(selected_rect)
		var in_status_instrument := status_instrument != null and status_instrument.get_global_rect().encloses(selected_rect) and not status_instrument.visible and status_instrument.text.is_empty()
		var clear_of_hud_hand_gap := resource_hud != null and selected_rect.end.y <= resource_hud.get_global_rect().position.y and hand_rail != null and selected_rect.end.y <= hand_rail.get_global_rect().position.y
		var hand_focus := hand_card.get_theme_stylebox("focus") as StyleBoxFlat if hand_card != null else null
		var separated_hand_focus := hand_focus != null and hand_focus.expand_margin_left >= 4.0 and hand_focus.expand_margin_right >= 4.0 and hand_focus.content_margin_left >= 10.0 and hand_focus.content_margin_right >= 10.0 and hand_rail != null and queue_print != null and not hand_rail.get_global_rect().intersects(queue_print.get_global_rect()) and queue_print.get_global_rect().size.y >= 48.0
		require(selected_complete and instruments_present and queue_touch_ok and hud_copy_ok and contained and in_status_instrument and clear_of_hud_hand_gap and separated_hand_focus, "Selected native-art blueprint is contained by the central status instrument with a padded hand focus ring and a separate non-overlapping Queue rail at %dx%d (complete=%s instruments=%s queue48=%s hud_copy=%s contained=%s central=%s clear_gap=%s focus_gap=%s rect=%s)." % [int(size.x), int(size.y), str(selected_complete), str(instruments_present), str(queue_touch_ok), str(hud_copy_ok), str(contained), str(in_status_instrument), str(clear_of_hud_hand_gap), str(separated_hand_focus), str(selected_rect)])
	# All selected-card variants use the same narrow lower-left rail.  Exercise
	# equipment, targeted spell, refill, and emergency-reprint choices at normal
	# and 150% high-contrast text so a long legacy verb cannot widen into the hand.
	hotseat.player(1).slots = [UnifiedBattleState._unit(RULES.card("aquafin")), null, null]
	hotseat.player(0).slots = [UnifiedBattleState._unit(RULES.card("cinderpaw")), null, null]
	hotseat.player(1).queue = []
	hotseat.player(1).graveyard = ["cinderpaw"]
	hotseat.player(1).emergency_reprints = 1
	for accessibility in [{"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}, {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":true}]:
		var accessibility_settings: Dictionary = accessibility
		GameManager.profile.settings = accessibility_settings
		for entry in [{"card":"iron_gem", "node":"UnifiedPlayQueueEquipment", "target":0}, {"card":"layer_melt", "node":"UnifiedPlayCastCard", "target":0}, {"card":"raw_filament", "node":"UnifiedPlayUseRefill", "target":-1}, {"card":"filament_ring", "node":"UnifiedPlayUseRefill", "target":-1}, {"card":"emergency_reprint_spell", "node":"UnifiedPlayCastCard", "target":0}]:
			var scenario: Dictionary = entry
			hotseat.player(1).hand = [str(scenario.get("card", ""))]
			shell.unified_selected_card_id = str(scenario.get("card", ""))
			shell.unified_selected_target = int(scenario.get("target", -1))
			shell.size = Vector2(576, 1024)
			shell.render()
			await get_tree().process_frame
			var action_name := str(scenario.get("node", ""))
			var action_button := shell.find_child(action_name, true, false) as Button
			var support_status := shell.find_child("PhysicalBattleStatus", true, false) as Label
			var support_status_ok := support_status != null and support_status.visible and support_status.max_lines_visible == 2 and support_status.clip_text and support_status.text.split("\n").size() == 1 and label_text_fits(support_status, 6.0) and Rect2(Vector2.ZERO, Vector2(576, 1024)).encloses(support_status.get_global_rect())
			var rail_compact: bool = _plan_action_rail_is_compact(shell, action_button)
			var scenario_diagnostic: String = ""
			if str(scenario.get("card", "")) == "iron_gem" and bool(accessibility_settings.get("high_contrast", false)):
				var iron_gem := RULES.card("iron_gem")
				var expected_instruction: String = "Queue equipment"
				var expected_metadata: String = "%s · %d filament · %s · %s" % [str(iron_gem.get("name", "iron_gem")), int(iron_gem.get("filament_cost", iron_gem.get("cost", 0))), str(iron_gem.get("type", "blueprint")).capitalize(), str(iron_gem.get("text", "Use this blueprint."))]
				var metadata_name_ok: bool = support_status != null and support_status.tooltip_text.contains(str(iron_gem.get("name", "iron_gem")))
				var metadata_filament_ok: bool = support_status != null and support_status.tooltip_text.contains("%d filament" % int(iron_gem.get("filament_cost", iron_gem.get("cost", 0))))
				var metadata_text_ok: bool = support_status != null and support_status.tooltip_text.contains(str(iron_gem.get("text", "Use this blueprint.")))
				var metadata_accessibility_ok: bool = support_status != null and support_status.accessibility_name == support_status.tooltip_text
				var metadata_ok: bool = support_status != null and support_status.tooltip_text == expected_metadata and metadata_name_ok and metadata_filament_ok and metadata_text_ok and metadata_accessibility_ok
				var status_font: Font = support_status.get_theme_font("font") if support_status != null else null
				var status_font_size: int = support_status.get_theme_font_size("font_size") if support_status != null else 0
				var line_width: float = status_font.get_string_size(support_status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, status_font_size).x if status_font != null and support_status != null else -1.0
				var status_rect: Rect2 = support_status.get_global_rect() if support_status != null else Rect2()
				support_status_ok = support_status_ok and support_status.text == expected_instruction and metadata_ok
				scenario_diagnostic = " expected=%s actual=%s font=%d line_width=%.1f rect=%s height=%.1f rail_compact=%s text_fit=%s metadata(name=%s filament=%s text=%s a11y=%s exact=%s) expected_tooltip=%s tooltip=%s" % [expected_instruction, support_status.text if support_status != null else "<missing>", status_font_size, line_width, str(status_rect), status_rect.size.y, str(rail_compact), str(label_text_fits(support_status, 6.0)), str(metadata_name_ok), str(metadata_filament_ok), str(metadata_text_ok), str(metadata_accessibility_ok), str(support_status != null and support_status.tooltip_text == expected_metadata), expected_metadata, support_status.tooltip_text if support_status != null else "<missing>"]
			require(rail_compact and support_status_ok, "Selected %s keeps every rail action inside the 96px physical action rail and its one-line state instruction inside the parchment seat at 576x1024 (text150=%s HC=%s).%s" % [str(scenario.get("card", "")), str(int(accessibility_settings.get("text_scale_bps", 10000)) >= 15000), str(bool(accessibility_settings.get("high_contrast", false))), scenario_diagnostic])
	GameManager.profile.settings = {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}
	hotseat.player(1).hand = ["cinderpaw"]
	hotseat.player(1).queue = [{"card_id":"cinderpaw", "remaining":1}]
	shell.unified_selected_card_id = "cinderpaw"
	shell.unified_selected_target = -1
	# 576x1152 is the near-2:1 contain case. Derive the actual fractional fit
	# from the same presenter rather than rounding the 941x1672 master to pixels.
	# Every Plan owner must derive from that same composition rect, never the raw
	# window anchors used by an older full-bleed-only layout.
	GameManager.profile.settings = {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}; hotseat.phase = "main"; hotseat.player(1).hand = ["cinderpaw"]; shell.unified_selected_card_id = "cinderpaw"; shell.size = Vector2(576, 1152); shell.render(); await get_tree().process_frame
	var contain_frame := PRESENTER.composition_rect(Vector2(576, 1152), Vector2(941, 1672))
	var contain_title := shell.find_child("UnifiedBattleHeading", true, false) as Label
	var contain_back := shell.find_child("UnifiedBattleBack", true, false) as Button
	var contain_hand := shell.find_child("PhysicalBattleHandScroll", true, false) as ScrollContainer
	var contain_actions := shell.find_child("PhysicalBattlePlanActionScroll", true, false) as ScrollContainer
	var contain_queue := shell.find_child("UnifiedPlayQueueCreature", true, false) as Button
	var contain_row := shell.find_child("PhysicalBattlePlanActions", true, false) as VBoxContainer
	var contain_cancel := contain_row.get_child(1) as Button if contain_row != null and contain_row.get_child_count() > 1 else null
	var contain_lever := shell.find_child("UnifiedRunCycleLever", true, false) as Button
	var contain_ok := contain_title != null and contain_back != null and contain_hand != null and contain_actions != null and contain_queue != null and contain_cancel != null and contain_lever != null and contain_frame.encloses(contain_title.get_global_rect()) and contain_frame.encloses(contain_back.get_global_rect()) and contain_frame.encloses(contain_hand.get_global_rect()) and contain_frame.encloses(contain_actions.get_global_rect()) and contain_frame.encloses(contain_lever.get_global_rect()) and not contain_hand.get_global_rect().intersects(contain_actions.get_global_rect()) and not contain_hand.get_global_rect().intersects(contain_lever.get_global_rect()) and contain_queue.get_global_rect().size.y >= 48.0 and contain_cancel.get_global_rect().size.y >= 48.0
	require(contain_ok, "Near-2:1 contained battle maps heading, Back, hand, Queue/Cancel rail, and Run Cycle through the 576x1024 chassis without bottom/top bleed.")
	shell.size = Vector2(1024, 1024); shell.render(); await get_tree().process_frame
	hotseat.player(1).hand = ["aquafin", "aquafin", "aquafin", "aquafin", "aquafin", "aquafin", "aquafin", "aquafin", "aquafin", "aquafin"]
	# M11 auto-deploy retires the player-facing pending-place choice.  The checked
	# M11 integration fixture covers leftmost deployment and its finite arrival;
	# retain this component suite for live anchor and equipment focus behavior.
	hotseat.pending = {"kind":"attach","seat":1,"card_id":"iron_gem","holding_index":0}; hotseat.phase = "print"; hotseat.player(1).slots = [UnifiedBattleState._unit(RULES.card("aquafin")), null, null]; shell.render(); await get_tree().process_frame
	var held_token := shell.find_child("UnifiedHeldEquipmentToken", true, false) as PanelContainer
	var attach_choice := shell.find_child("UnifiedPendingAttachSlot1", true, false) as Button
	require(held_token != null and str((held_token.get_child(0) as Label).text).contains(str(RULES.card("iron_gem").get("name", ""))) and str((held_token.get_child(0) as Label).text).contains("Gem socket") and attach_choice != null and attach_choice.accessibility_name.contains(str(RULES.card("iron_gem").get("name", ""))), "Pending equipment token and anchor accessibility use the actual equipment name and slot.")
	hotseat.pending.clear(); hotseat.phase = "collect"; shell.unified_selected_card_id = ""; shell.render(); await get_tree().process_frame
	var overflow_rail := shell.find_child("UnifiedOverflowChoices", true, false) as ScrollContainer
	var overflow_row := overflow_rail.get_child(0) as HBoxContainer if overflow_rail != null and overflow_rail.get_child_count() > 0 else null
	var overflow_first := overflow_row.get_child(0) as Button if overflow_row != null else null
	var overflow_second := overflow_row.get_child(1) as Button if overflow_row != null and overflow_row.get_child_count() > 1 else null
	var overflow_third := overflow_row.get_child(2) as Button if overflow_row != null and overflow_row.get_child_count() > 2 else null
	require(overflow_first != null and overflow_second != null and overflow_third != null and overflow_first.custom_minimum_size.x == overflow_second.custom_minimum_size.x and overflow_third.position.x >= overflow_rail.size.x, "Overflow uses two whole normal-text occurrence chips per visible rail page; the third begins outside the clip.")
	GameManager.profile.settings = {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":false}; hotseat.phase = "main"; hotseat.player(1).hand = ["cinderpaw", "aquafin"]; hotseat.player(0).hand = ["cinderpaw", "aquafin", "mossmunk", "cinderpaw", "aquafin"]; shell.unified_selected_card_id = "cinderpaw"
	for size in [Vector2(576, 1024), Vector2(720, 1280)]:
		shell.size = size; shell.render(); await get_tree().process_frame
		var accessibility_title := shell.find_child("UnifiedBattleHeading", true, false) as Label
		var accessibility_hand := shell.find_child("PhysicalBattleHandScroll", true, false) as ScrollContainer
		var accessibility_lever := shell.find_child("UnifiedRunCycleLever", true, false) as Button
		var accessibility_row := shell.find_child("PhysicalBattleHand", true, false) as HBoxContainer
		var accessibility_next := accessibility_row.get_child(1) as Control if accessibility_row != null and accessibility_row.get_child_count() > 1 else null
		var accessibility_stage := shell.find_child("PhysicalBattlefieldStage", true, false) as PhysicalBattlefieldStage
		var accessibility_selected := shell.find_child("UnifiedSelectedCreatureBlueprint", true, false) as PanelContainer
		var accessibility_status := shell.find_child("PhysicalBattleStatus", true, false) as Label
		var title_rect := accessibility_title.get_global_rect() if accessibility_title != null else Rect2()
		var viewport_rect := Rect2(Vector2.ZERO, size)
		var card_backs_clear := accessibility_stage != null
		if accessibility_stage != null:
			for index in 5:
				var back := accessibility_stage.find_child("RivalConcealedCard%d" % index, true, false) as TextureRect
				card_backs_clear = card_backs_clear and back != null and back.visible and back.get_global_rect().position.y >= title_rect.end.y + 4.0 and not back.get_global_rect().intersects(title_rect)
		var large_hud := shell.find_child("PhysicalBattleHud0Resources", true, false) as Label
		require(accessibility_title != null and accessibility_title.autowrap_mode != TextServer.AUTOWRAP_OFF and accessibility_title.get_theme_font_size("font_size") >= 15 and viewport_rect.encloses(title_rect) and card_backs_clear and accessibility_hand != null and accessibility_row != null and (accessibility_row.get_child(0) as Control).custom_minimum_size.x <= accessibility_hand.size.x and accessibility_next != null and accessibility_next.position.x >= accessibility_hand.size.x and accessibility_lever != null and accessibility_lever.custom_minimum_size.y >= 56.0 and large_hud != null and viewport_rect.encloses(large_hud.get_global_rect()) and accessibility_selected != null and accessibility_status != null and accessibility_status.get_global_rect().encloses(accessibility_selected.get_global_rect()) and not accessibility_status.visible, "150%% title stays legible in its taller top plate; all rival backs clear it while HUD, whole hand pages, central selected blueprint, and Run Cycle fit at %dx%d." % [int(size.x), int(size.y)])
	GameManager.profile.settings = {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}; hotseat.phase = "main"; hotseat.revision = 13; shell.toast = "Stale revision 12; latest revision 13 · snapshot restored."; shell.render(); await get_tree().process_frame
	var full_hand := shell.find_child("PhysicalBattleHand", true, false) as HBoxContainer
	var recovery_status := shell.find_child("PhysicalBattleStatus", true, false) as Label
	require(full_hand == null and shell.find_child("PhysicalBattleHud1", true, false) != null and shell.find_child("PhysicalBattleDismiss", true, false) != null and shell.find_child("PhysicalBattleRetry", true, false) != null and recovery_status != null and recovery_status.text.contains("Rev 13"), "Recovery locks hand controls while exposing the exact native retry/dismiss revision.")
	shell.toast = "Rival turn paused safely after 48 checked actions. Retry the battle flow."; shell.battle_mode = "training"; hotseat.active_seat = 1; shell.unified_ai_pending = false; shell.render(); await get_tree().process_frame
	require(shell.find_child("PhysicalBattleRetryAI", true, false) != null and shell.find_child("PhysicalBattleDismiss", true, false) != null and shell.find_child("PhysicalBattleHandScroll", true, false) == null and shell.find_child("UnifiedRunCycleLever", true, false) == null, "A bounded rival safety pause exposes native Retry/Dismiss while rival ownership keeps hand and Run Cycle unreachable.")
	if failures.is_empty(): print("PASS: M2 physical battle UI seams")
	get_tree().quit(0 if failures.is_empty() else 1)

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func label_lines_fit(label: Label, margin: float) -> bool:
	if label == null: return false
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null or font_size <= 0: return false
	var rect := label.get_global_rect()
	for line in label.text.split("\n"):
		if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x - margin: return false
	return rect.size.y >= font.get_height(font_size) * 2.0

func label_text_fits(label: Label, margin: float) -> bool:
	if label == null: return false
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null or font_size <= 0: return false
	var rect := label.get_global_rect()
	for line in label.text.split("\n"):
		if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x - margin: return false
	return rect.size.y >= font.get_height(font_size)

func _plan_action_rail_is_compact(shell: Control, primary: Button) -> bool:
	var rail := shell.find_child("PhysicalBattlePlanActionScroll", true, false) as ScrollContainer
	var row := shell.find_child("PhysicalBattlePlanActions", true, false) as VBoxContainer
	var hand := shell.find_child("PhysicalBattleHandScroll", true, false) as ScrollContainer
	if rail == null or row == null or hand == null or primary == null or row.get_child_count() == 0: return false
	if row.get_child(0) != primary or primary.custom_minimum_size != Vector2(96, 48): return false
	for child in row.get_children():
		var action := child as Button
		if action == null or action.custom_minimum_size != Vector2(96, 48): return false
		if action.get_global_rect().size.x > rail.get_global_rect().size.x or action.get_global_rect().intersects(hand.get_global_rect()): return false
	return primary.get_global_rect().size.y >= 48.0
