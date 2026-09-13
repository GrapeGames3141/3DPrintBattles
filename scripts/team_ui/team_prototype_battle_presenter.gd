class_name TeamPrototypeBattlePresenter
extends RefCounted
## Battle route composition. It renders only the controller's cached private-player
## projection and receipt snapshots; persistence/rules stay outside the scene tree.

const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")
const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const Visual := preload("res://scripts/team_ui/team_prototype_battle_visual.gd")
const Seating := preload("res://scripts/team_ui/team_prototype_battle_seating.gd")
const CardView := preload("res://scripts/ui/support_card_view.gd")
const Physical := preload("res://scripts/ui/m1_physical_ui_component.gd")
const V3Catalog := preload("res://scripts/core/v3_catalog.gd")

const BATTLE_MASTER := "res://assets/ui/team_prototype/BA-R1-team-autobattle-chassis-text-free-v1.png"
const RESULT_MASTER := "res://assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png"
const PREFLIGHT_MASTER := "res://assets/ui/physical_ui/m3/ST-01-settings-instrument-text-free-v3.png"


func render_preflight(shell: Variant, controller: Variant) -> void:
	shell._background(PREFLIGHT_MASTER)
	shell._back_at(Rect2(29.40, 32.68, 133.96, 78.50), "Workshop")
	controller.refresh()
	var active: bool = bool(controller.has_current())
	var resumable: bool = bool(controller.match_view.get("resume", false))
	var startable: bool = bool(controller.can_start()) and _saved_loadout_is_valid(controller)
	var header := "BATTLE SAVED" if active and resumable else "BATTLE CHECK"
	var body := "Resume the current match." if active and resumable else ("Team 3/3 · Support 15/15 · Print order ready." if startable else "Apply a valid Team and Support Kit first.")
	var large := _is_large(shell)
	var large_font := 26 if large else 27
	var header_label := _battle_label(shell, "BATTLE" if large else header, Rect2(223.86, 168.27, 253.30, 52.28), large_font, Color("24160b"))
	header_label.accessibility_name = "Battle Preflight. %s" % header
	shell._label(body, Rect2(174.82, 1150.69, 624.13, 215.63), large_font)
	var action := "RESUME" if active and resumable else ("NEW BATTLE" if active and startable else ("START BATTLE" if startable else "OPEN TEAM"))
	var button: Button = shell._button("", Rect2(444.38, 1450, 403.48, 153.56), func(): _start(shell, controller) if (resumable or startable) else shell.navigate("team"), false, "binding", true)
	button.name = "BattleStartResume"
	button.accessibility_name = "%s. %s" % [action, body]
	_battle_label(shell, action, Rect2(628.88, 1481.00, 196.00, 94.00), large_font, Color("fff0c8"))
	if not controller.last_error.is_empty():
		shell._label("Save not confirmed. Retry.", Rect2(174.82, 1090, 624.13, 52), 24)


func render_battle(shell: Variant, controller: Variant) -> void:
	shell._background(BATTLE_MASTER)
	shell._back_at(Rect2(29.40, 32.68, 133.96, 78.50), "Workshop")
	controller.refresh()
	if _show_result(controller):
		shell.route = "result"
		shell._render()
		return
	var snapshot := _presentation_snapshot(controller)
	var visual := Visual.new()
	visual.name = "TeamPrototypeBattleVisual"
	shell._content.add_child(visual)
	shell._battle_visual = visual
	visual.set_previous_projection(controller.previous_stage_snapshot(), _is_large(shell))
	visual.set_previous_stage(controller.previous_stage())
	visual.set_projection(snapshot, bool(shell.settings_draft.get("reduced_motion", false)), _is_large(shell))
	var stage: Dictionary = controller.current_stage()
	if not stage.is_empty():
		visual.set_stage(stage, controller.stage_progress_bps(bool(shell.settings_draft.get("reduced_motion", false))), bool(shell.settings_draft.get("reduced_motion", false)), controller.stage_identity())
	var resolving := not stage.is_empty()
	var enlarged := _is_large(shell)
	var phase := _stage_title(stage, enlarged) if resolving else "PLAN"
	var title := "CYCLE %d · %s" % [int(snapshot.get("cycle", controller.player_view.get("cycle", 1))), phase]
	if enlarged and phase == "ENTER / FIT":
		title = phase
	elif enlarged and str(stage.get("name", "")) == "Replace":
		title = "%d · REPLACE" % int(snapshot.get("cycle", controller.player_view.get("cycle", 1)))
	var title_label := _battle_label(shell, title, Rect2(279.36, 44.11, 382.28, 55.55) if enlarged else Rect2(292.40, 39.20, 369.20, 70.20), 26 if enlarged else 27, Color("241708"))
	if enlarged and str(stage.get("name", "")) == "Enter/Fit":
		title_label.accessibility_name = "Cycle %d. Enter and Fit." % int(snapshot.get("cycle", controller.player_view.get("cycle", 1)))
	elif enlarged and str(stage.get("name", "")) == "Replace":
		title_label.accessibility_name = "Cycle %d. Replace." % int(snapshot.get("cycle", controller.player_view.get("cycle", 1)))
	_render_roster(shell, controller, snapshot, resolving, stage)
	_render_forecast(shell, controller, resolving, stage)
	_render_rival_hand(shell, snapshot)
	_render_player_hand(shell, controller, snapshot, resolving)
	if resolving:
		_render_receipt_controls(shell, controller, stage)
	else:
		_render_plan_controls(shell, controller, snapshot)


func render_result(shell: Variant, controller: Variant) -> void:
	shell._background(RESULT_MASTER)
	shell._back_at(Rect2(25, 22, 118, 100), "Workshop")
	var reward: Dictionary = controller.result_receipt()
	var result := str(reward.get("result", controller.player_view.get("result", "")))
	var outcome: String = str({"Win":"TEAM VICTORY", "Loss":"TEAM DEFEAT", "Draw":"DRAW"}.get(result, "MATCH RESULT"))
	var cause: String = str({"Win":"Rival team defeated.", "Loss":"All 3 companions defeated.", "Draw":"Both Teams fell together."}.get(result, "Result saved."))
	var rewards := "+%d Coins · +%d XP" % [int(reward.get("coins", 0)), int(reward.get("xp", 0))]
	var large := _is_large(shell)
	_result_label(shell, "RESULT", Rect2(230, 90, 480, 58), 26 if large else 27, Color("231708"))
	_result_label(shell, outcome, Rect2(188, 355, 565, 58), 26 if large else 34, Color("24160b"))
	_result_label(shell, cause, Rect2(188, 425, 565, 65), 26, Color("322417"))
	_result_label(shell, rewards, Rect2(188, 490, 565, 65), 26, Color("0a5260"))
	var pending: bool = controller.cursor < controller.stage_count
	var caption := "RETRY" if not controller.last_error.is_empty() else "CONTINUE"
	var action: Button = shell._button("", Rect2(616, 1300, 268, 300), func(): _continue_result(shell, controller), false, "binding", true)
	action.name = "BattleResultContinue"
	action.accessibility_name = "Retry Result acknowledgement" if caption == "RETRY" else "Continue after result"
	if not pending:
		action.disabled = false
		caption = "NEW BATTLE"
		action.accessibility_name = "New Battle"
	_result_label(shell, caption, Rect2(616, 1300, 268, 300), 27, Color("24160b"))
	if not controller.last_error.is_empty():
		shell._label("Result paused. Retry to continue.", Rect2(188, 565, 565, 58), 24)


func _start(shell: Variant, controller: Variant) -> void:
	var result: Dictionary = controller.start_or_resume()
	if bool(result.get("ok", false)):
		shell.replace_route("battle")
	else:
		shell._render()


func _saved_loadout_is_valid(controller: Variant) -> bool:
	if controller == null or controller.runtime == null:
		return false
	var collection: Dictionary = controller.runtime.collection_view()
	if not bool(collection.get("ok", false)):
		return false
	var saved: Dictionary = collection.get("saved_loadout", {})
	if saved.is_empty():
		return false
	var preview: Dictionary = controller.runtime.preview_loadout(saved.get("team", []), saved.get("priority", []), saved.get("kit", {}))
	return bool(preview.get("ok", false))


func _render_plan_controls(shell: Variant, controller: Variant, snapshot: Dictionary) -> void:
	var own: Dictionary = snapshot.get("own", {})
	var selected_support := str(controller.local_plan.get("support_copy_id", ""))
	var selected_swap := str(controller.local_plan.get("swap_id", ""))
	var seating: Dictionary = Seating.project(own)
	var docket_member: Dictionary = seating.get("docket", {})
	if not docket_member.is_empty():
		if str(docket_member.get("status", "")) == "Unspent":
			var docket_id := str(docket_member.get("identity_id", ""))
			var docket: Button = shell._button("", Rect2(29.40, 1053, 215.65, 79), func(): controller.set_fabrication(docket_id); shell._render(), false, "wide", false, true)
			docket.name = "BattleFabrication_%s" % docket_id.replace(":", "_")
			docket.accessibility_name = "%s Unspent. Choose Fabrication." % _name(docket_member)
			_set_selected_ring(docket, str(controller.local_plan.get("fabrication_id", "")) == docket_id, bool(shell.settings_draft.get("high_contrast", false)))
			var docket_label := _battle_label(shell, _name(docket_member), Rect2(29.40, 1053, 215.65, 79), 26, Color("241708"))
			docket_label.accessibility_name = docket.accessibility_name
		else:
			_render_nonliving_record(shell, docket_member, Rect2(29.40, 1053, 215.65, 79), true)
	var records: Array = seating.get("bays", [])
	var player_bay_height := 185.0 if _is_large(shell) else 178.0
	var bay_rects := [Rect2(303.90, 1109, 277.80, player_bay_height), Rect2(611, 1109, 277.80, player_bay_height)]
	for index in mini(2, records.size()):
		var member: Dictionary = records[index]
		var identity := str(member.get("identity_id", ""))
		var status := str(member.get("status", ""))
		var rect: Rect2 = bay_rects[index]
		if status == "Ready":
			var swap: Button = shell._button("", rect, func(): controller.set_swap(identity); shell._render(), not selected_support.is_empty(), "wide", false, true)
			swap.name = "BattleSwap_%s" % identity.replace(":", "_")
			swap.accessibility_name = "%s, Ready, %d HP. %s" % [_name(member), int(member.get("hp", 0)), "Selected swap" if selected_swap == identity else ("Choose 1 Support or 1 swap." if not selected_support.is_empty() else "Swap into Active")]
			_set_selected_ring(swap, selected_swap == identity, bool(shell.settings_draft.get("high_contrast", false)))
			_render_ready_caption(shell, member, rect, "player")
		elif status == "Unspent":
			var fabrication: Button = shell._button("", rect, func(): controller.set_fabrication(identity); shell._render(), false, "wide", false, true)
			fabrication.name = "BattleFabrication_%s" % identity.replace(":", "_")
			fabrication.accessibility_name = "%s Unspent. Choose Fabrication." % _name(member)
			_set_selected_ring(fabrication, str(controller.local_plan.get("fabrication_id", "")) == identity, bool(shell.settings_draft.get("high_contrast", false)))
			_record_token(shell, "%s\nUNSPENT" % _name(member), rect, false)
	var checked: Dictionary = controller.checked_plan()
	var can_run := bool(checked.get("ok", false))
	var run_caption := "RETRY RUN" if not controller.last_error.is_empty() else "RUN\nCYCLE"
	var run: Button = shell._button(run_caption, Rect2(748, 1363, 174, 242), func(): _run(shell, controller), not can_run, "binding", true)
	run.name = "BattleRunCycle"
	run.accessibility_name = "Run Cycle" if can_run else str(checked.get("error", "Review Plan"))
	if not selected_support.is_empty() or not selected_swap.is_empty() or not str(controller.local_plan.get("fabrication_id", "")).is_empty():
		var clear: Button = shell._button("CLEAR PLAN", Rect2(295.70, 1281.20, 599.60, 78.40), func(): controller.clear_plan(); shell._render(), false, "wide", false, false)
		clear.name = "BattleClearPlan"
	if not controller.last_error.is_empty():
		_battle_label(shell, "Save not confirmed. Retry Run.", Rect2(295.70, 1290.60, 599.60, 44.10), 24, Color("f7ebca"))


func _select_support(shell: Variant, controller: Variant, copy_id: String, card_id: String) -> void:
	controller.set_support(copy_id)
	if card_id in ["standard_full_suit", "iron_gem"] and str(controller.local_plan.get("support_copy_id", "")) == copy_id:
		var targets: Array = controller.equipment_targets()
		if not targets.is_empty():
			shell.modal = "battle_equipment"
			shell.modal_return_focus = "BattleSupport_%s" % copy_id.replace(":", "_")
			shell.set_meta("battle_equipment_targets", targets)
			shell.set_meta("battle_equipment_card", card_id)
	shell._render()


func render_equipment_modal(shell: Variant, controller: Variant) -> void:
	var targets: Array = shell.get_meta("battle_equipment_targets", [])
	var card_id := str(shell.get_meta("battle_equipment_card", ""))
	var blocker := ColorRect.new()
	blocker.name = "BattleEquipmentBlocker"
	blocker.color = Color("07111b", 0.72)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell._content.add_child(blocker)
	for child in shell._content.get_children():
		if child is Control and child != blocker:
			(child as Control).focus_mode = Control.FOCUS_NONE
	var heading := _battle_label(shell, "%s — CHOOSE TARGET" % _support_name(card_id).to_upper(), Rect2(281, 441, 622, 82), 27, Color.WHITE if bool(shell.settings_draft.get("high_contrast", false)) else Color("fff0c8"))
	heading.accessibility_name = "%s. Choose an eligible equipment target." % _support_name(card_id)
	var first_target: Button = null
	for index in targets.size():
		var id := str(targets[index])
		var status := _equipment_target_status(controller, id)
		var row: Button = shell._button("%s · %s" % [_member_name(controller.player_view, id), status], Rect2(281, 535 + index * 108, 622, 96), func(): _choose_equipment_target(shell, controller, id), false, "wide", false, false)
		row.name = "BattleEquipmentTarget_%s" % id.replace(":", "_")
		row.accessibility_name = "%s, %s. Eligible equipment target." % [_member_name(controller.player_view, id), status]
		if first_target == null:
			first_target = row
	var cancel: Button = shell._button("", Rect2(654, 859, 249, 82), func(): _cancel_equipment_target(shell, controller), false, "binding", false, false)
	cancel.name = "BattleEquipmentCancel"
	cancel.accessibility_name = "Cancel equipment target selection."
	_battle_label(shell, "CANCEL", Rect2(654, 859, 249, 82), 27, Color.WHITE if bool(shell.settings_draft.get("high_contrast", false)) else Color("fff0c8"))
	if first_target != null:
		first_target.grab_focus()


func _choose_equipment_target(shell: Variant, controller: Variant, identity_id: String) -> void:
	controller.set_equipment_target(identity_id)
	shell.modal = ""
	shell._restore_focus_name = shell.modal_return_focus
	shell.modal_return_focus = ""
	shell._render()
	shell.call_deferred("_restore_saved_focus")


func _cancel_equipment_target(shell: Variant, controller: Variant) -> void:
	controller.set_support("")
	shell.modal = ""
	shell._restore_focus_name = shell.modal_return_focus
	shell.modal_return_focus = ""
	shell._render()
	shell.call_deferred("_restore_saved_focus")


func _render_receipt_controls(shell: Variant, controller: Variant, stage: Dictionary) -> void:
	# The controller acknowledges an ended nonterminal stage automatically. Input is
	# limited to bounded acceleration; no manual NEXT STAGE can bypass its clock.
	var terminal := _stage_has_terminal(stage)
	var caption := "RETRY" if not controller.last_error.is_empty() else "SKIP"
	var skip: Button = shell._button(caption, Rect2(736, 1390, 160, 170), func(): _retry_or_skip(shell, controller), terminal and controller.last_error.is_empty(), "binding", true)
	skip.name = "BattleReceiptSkip"
	if not controller.last_error.is_empty():
		_dark_label(shell, "Progress Paused\nRetry to continue.", Rect2(295.70, 1190, 599.60, 76), 24)


func _continue_result(shell: Variant, controller: Variant) -> void:
	if controller.cursor < controller.stage_count:
		controller.acknowledge_stage()
		shell._render()
	else:
		shell.replace_route("preflight")


func _skip(shell: Variant, controller: Variant) -> void:
	controller.skip_to_result()
	shell._render()


func _retry_or_skip(shell: Variant, controller: Variant) -> void:
	if controller.last_error.is_empty():
		_skip(shell, controller)
	else:
		controller.retry_stage()
		shell._render()


func _run(shell: Variant, controller: Variant) -> void:
	controller.run_cycle()
	shell._render()


func _render_roster(shell: Variant, controller: Variant, snapshot: Dictionary, resolving: bool, stage: Dictionary) -> void:
	var own: Dictionary = snapshot.get("own", {})
	var opponent: Dictionary = snapshot.get("opponent", {})
	var entering := _entering_id_by_seat(stage)
	var show_active_captions := not _attack_captions_hidden(controller, stage)
	var moving_ids := _moving_identity_ids(stage, snapshot)
	var rival_active_rect := Rect2(300.60, 637.14, 339.81, 91.49) if _is_large(shell) else Rect2(279.4, 655.1, 380.7, 58.8)
	var player_active_rect := Rect2(300.60, 931.20, 339.81, 91.49) if _is_large(shell) else Rect2(279.4, 953.9, 380.7, 58.8)
	var rival_active := str(opponent.get("active_member_id", ""))
	var player_active := str(own.get("active_member_id", ""))
	if show_active_captions and not moving_ids.has(rival_active) and str(entering.get("rival", "")) != rival_active:
		_render_active_caption(shell, opponent, rival_active_rect, "RIVAL")
	else:
		_render_active_accessibility(shell, opponent, rival_active_rect, "RIVAL")
	if show_active_captions and not moving_ids.has(player_active) and str(entering.get("player", "")) != player_active:
		_render_active_caption(shell, own, player_active_rect, "TEAM")
	else:
		_render_active_accessibility(shell, own, player_active_rect, "TEAM")
	_render_status_records(shell, opponent, "rival", stage, moving_ids)
	if resolving:
		_render_status_records(shell, own, "player", stage, moving_ids)
	if resolving:
		_battle_label(shell, "HEAD · %s" % _queue_copy(own, stage), Rect2(295.70, 1290.60, 599.60, 44.10), 26 if _is_large(shell) else 27, Color("f7ebca"))


func _render_active_caption(shell: Variant, seat: Dictionary, rect: Rect2, prefix: String) -> void:
	var active := str(seat.get("active_member_id", ""))
	if active.is_empty():
		_battle_label(shell, "%s · WAITING" % prefix, rect, 26, Color("f7ebca"))
		return
	var member := _member(seat, active)
	var detail := "ACTIVE"
	var armor := int(member.get("armor", 0))
	if armor > 0:
		detail = "ARMOR %d" % armor
	if bool(member.get("gem_slot", false)):
		detail += " · GEM +2"
	var enlarged := _is_large(shell)
	var large_detail := "%d HP · Armor %d" % [int(member.get("hp", 0)), armor] if armor > 0 else "%d HP · Active" % int(member.get("hp", 0))
	var copy := "%s\n%s" % [_name(member), large_detail] if enlarged else "%s · %d HP\n%s" % [_name(member), int(member.get("hp", 0)), detail]
	var label := _battle_label(shell, copy, rect, 26 if enlarged else 27, Color("fff0c8") if enlarged else Color("f7ebca"))
	_apply_two_line_metrics(label, rect, 39 if enlarged else 27, 42.48 if enlarged else 26.0)
	label.accessibility_name = "%s, %d HP, %s." % [_name(member), int(member.get("hp", 0)), detail.replace(" · ", ", ")]


func _render_active_accessibility(shell: Variant, seat: Dictionary, rect: Rect2, prefix: String) -> void:
	var active := str(seat.get("active_member_id", ""))
	var member := _member(seat, active)
	var copy := "%s, waiting." % prefix if member.is_empty() else "%s, %d HP, active." % [_name(member), int(member.get("hp", 0))]
	var label := _battle_label(shell, copy, rect, 27, Color.TRANSPARENT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	label.accessibility_name = copy


func _render_ready_caption(shell: Variant, member: Dictionary, parent: Rect2, side: String) -> void:
	var enlarged := _is_large(shell)
	var local := Rect2(0, 91.45 if side == "rival" else 93.39, 277.8, 91.49) if enlarged else Rect2(12, 119.2, 253.8, 58.8)
	var caption := "%s\nReady %d HP" % [_name(member), int(member.get("hp", 0))] if enlarged else "%s\nReady · %d HP" % [_name(member), int(member.get("hp", 0))]
	var caption_rect := Rect2(parent.position + local.position, local.size)
	var label := _battle_label(shell, caption, caption_rect, 26 if enlarged else 27, Color("fff0c8") if enlarged else Color("f7ebca"))
	_apply_two_line_metrics(label, caption_rect, 39 if enlarged else 27, 42.48 if enlarged else 26.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.accessibility_name = "%s, Ready, %d HP." % [_name(member), int(member.get("hp", 0))]


func _render_status_records(shell: Variant, seat: Dictionary, side: String, stage: Dictionary = {}, moving_ids: Dictionary = {}) -> void:
	var docket := Rect2(105, 85, 140, 64) if side == "rival" else Rect2(29.40, 1053, 215.65, 79)
	var enlarged := _is_large(shell)
	var rival_height := 183.0 if enlarged else 178.0
	var player_height := 185.0 if enlarged else 178.0
	var bays := [Rect2(303.90, 163.4, 277.80, rival_height), Rect2(611, 163.4, 277.80, rival_height)] if side == "rival" else [Rect2(303.90, 1109, 277.80, player_height), Rect2(611, 1109, 277.80, player_height)]
	var seating: Dictionary = Seating.project(seat)
	var docket_member: Dictionary = seating.get("docket", {})
	if not docket_member.is_empty() and not moving_ids.has(str(docket_member.get("identity_id", ""))):
		var identity := str(docket_member.get("identity_id", ""))
		if _is_large(shell) and str(docket_member.get("status", "")) == "Printing" and _stage_prints_member(stage, side, identity):
			# The visible docket always names the canonical subject.  The head
			# ordinal remains accessibility-only so a solitary visual "1" cannot
			# be mistaken for another job or companion.
			var print_owner := Rect2(29.40, 115, 215.65, 42.48) if side == "rival" else docket
			var printing_label := _battle_label(shell, _name(docket_member), print_owner, 26, Color("241708"))
			printing_label.accessibility_name = "%s, Printing, current printer head, ordinal 1." % _name(docket_member)
		else:
			_render_nonliving_record(shell, docket_member, docket, true)
	var records: Array = seating.get("bays", [])
	for index in mini(2, records.size()):
		var member: Dictionary = records[index]
		if moving_ids.has(str(member.get("identity_id", ""))):
			continue
		var status := str(member.get("status", ""))
		if status == "Ready":
			_render_ready_caption(shell, member, bays[index], side)
		else:
			_render_nonliving_record(shell, member, bays[index])


func _moving_identity_ids(stage: Dictionary, snapshot: Dictionary) -> Dictionary:
	var moving := {}
	var stage_name := str(stage.get("name", ""))
	if stage_name not in ["Swap", "Replace"]:
		return moving
	for event_value in stage.get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("type", "")) == "swap":
			for identity in [str(event.get("active_member_id", "")), str(event.get("reserve_member_id", ""))]:
				if not identity.is_empty():
					moving[identity] = true
		elif str(event.get("type", "")) == "replacement":
			var replacement := str(event.get("member_identity_id", ""))
			if not replacement.is_empty():
				moving[replacement] = true
	if stage_name == "Replace":
		for seat_key in ["own", "opponent"]:
			var seat: Dictionary = snapshot.get(seat_key, {})
			for member_value in seat.get("members", []):
				if member_value is Dictionary and str((member_value as Dictionary).get("status", "")) == "Defeated":
					moving[str((member_value as Dictionary).get("identity_id", ""))] = true
	return moving


func _render_nonliving_record(shell: Variant, member: Dictionary, owner: Rect2, docket := false) -> void:
	var status := str(member.get("status", "Unspent")).to_upper()
	var copy := _name(member) if docket and _is_large(shell) and status != "PRINTING" else "%s\n%s" % [_name(member), status]
	_record_token(shell, copy, owner, docket)


func _render_forecast(shell: Variant, controller: Variant, resolving: bool, stage: Dictionary) -> void:
	var enlarged := _is_large(shell)
	var row_x := 22.87 if enlarged else 22.90
	var row_width := 230.35 if enlarged else 230.40
	var row_height := 42.48 if enlarged else 33.0
	var row_y := [539.10, 581.58, 624.06, 666.54] if enlarged else [539.10, 572.10, 605.10, 638.10]
	var summary_rect := Rect2(22.87, 709.02, 230.35, 205.78) if enlarged else Rect2(22.90, 671.10, 230.40, 243.70)
	# Widgets scale a base size at the accessibility setting.  26 becomes the
	# registered 39px large text; passing 39 here would incorrectly render 58px.
	var forecast_font := 26 if enlarged else 27
	if resolving:
		# The authority has already advanced to the Run's final state. Receipt
		# playback may expose only the displayed snapshot and event feedback.
		var displayed: Dictionary = _presentation_snapshot(controller)
		var filament := int(displayed.get("own", {}).get("filament", 0))
		_battle_label(shell, "Filament %d" % filament, Rect2(row_x, float(row_y[0]), row_width, row_height), forecast_font, Color("fff0c8") if enlarged else Color("e8f4e6"), HORIZONTAL_ALIGNMENT_LEFT)
		var feedback := _stage_feedback(stage, _is_large(shell))
		if not feedback.is_empty():
			var feedback_label := _battle_label(shell, feedback, summary_rect, forecast_font, Color("fff0c8") if enlarged else Color("e8f4e6"), HORIZONTAL_ALIGNMENT_LEFT)
			var feedback_accessibility := _stage_feedback_accessibility(stage)
			feedback_label.accessibility_name = feedback_accessibility if not feedback_accessibility.is_empty() else feedback
		return
	var checked: Dictionary = controller.checked_plan()
	var forecast: Dictionary = checked.get("forecast", {}) if bool(checked.get("ok", false)) else {}
	var rows := ["Available %d" % int(forecast.get("available_filament", 0)), "Spend %d" % int(forecast.get("complete_cost", 0)), "After %d" % int(forecast.get("post_spend_filament", 0)), "Next %d" % int(forecast.get("next_regeneration", 0))]
	for index in rows.size():
		_battle_label(shell, rows[index], Rect2(row_x, float(row_y[index]), row_width, row_height), forecast_font, Color("fff0c8") if enlarged else Color("e8f4e6"), HORIZONTAL_ALIGNMENT_LEFT)
	var summary := ""
	if not resolving:
		if not bool(checked.get("ok", false)):
			var default_reason := str((checked.get("forecast", {}) as Dictionary).get("default_fabrication_reason", ""))
			summary = default_reason.replace("_", " ").capitalize() if not default_reason.is_empty() else str(checked.get("error", "Choose next fabrication and 1 Support or swap."))
		else:
			var normalized: Dictionary = checked.get("plan", {})
			var next_id := str(normalized.get("fabrication_id", ""))
			if not next_id.is_empty():
				var chosen := next_id == str(controller.local_plan.get("fabrication_id", ""))
				if _is_large(shell) and not chosen:
					summary = "Print Next\n%s\nAuto" % _member_name(controller.player_view, next_id)
				else:
					summary = "Print Next %s · %s" % [_member_name(controller.player_view, next_id), "CHOSEN" if chosen else "AUTO"]
			else:
				summary = "Plan checked · Run Cycle ready."
	if not summary.is_empty():
		var summary_label := _battle_label(shell, summary, summary_rect, forecast_font, Color("fff0c8") if enlarged else Color("e8f4e6"), HORIZONTAL_ALIGNMENT_LEFT)
		if _is_large(shell) and summary.begins_with("Print Next\n"):
			summary_label.accessibility_name = "Default fabrication: %s." % _member_name(controller.player_view, str((checked.get("plan", {}) as Dictionary).get("fabrication_id", "")))


func _stage_feedback(stage: Dictionary, enlarged := false) -> String:
	var damage_rows: Array[String] = []
	var swaps: Dictionary = {}
	var defeats: Dictionary = {}
	for event_value in stage.get("events", []):
		if not event_value is Dictionary:
			continue
		var event_type := str(event_value.get("type", ""))
		if event_type == "hold":
			return "Both hold\nWaiting for\nActive" if enlarged else "BOTH TEAMS HOLD\nWaiting for opposing Active."
		if event_type == "replacement":
			var replacement_name := str(event_value.get("member_identity_id", "")).get_slice(":", 2).capitalize()
			return "%s\nActive\nAuto replace" % replacement_name if enlarged else "%s ENTERS ACTIVE\nReplacement is automatic." % replacement_name.to_upper()
		if event_type == "swap":
			var incoming := str(event_value.get("active_member_id", "")).get_slice(":", 2).capitalize()
			var outgoing := str(event_value.get("reserve_member_id", "")).get_slice(":", 2).capitalize()
			if not incoming.is_empty() and not outgoing.is_empty():
				swaps[str(event_value.get("seat", ""))] = {"incoming":incoming, "outgoing":outgoing}
		if event_type == "defeat":
			var defeated := str(event_value.get("member_identity_id", "")).get_slice(":", 2).capitalize()
			if not defeated.is_empty():
				defeats[str(event_value.get("seat", ""))] = defeated
		if event_type == "equipment_fit":
			var fit_name := _support_name(str(event_value.get("card_id", "")))
			var fit_target := str(event_value.get("target_identity_id", "")).get_slice(":", 2).capitalize()
			return "%s fitted\n%s" % [fit_name, fit_target] if enlarged else "%s FIT · %s" % [fit_name.to_upper(), fit_target.to_upper()]
		if event_type == "equipment_fizzled":
			return "%s FIT FAILED" % _support_name(str(event_value.get("card_id", ""))).to_upper()
		if event_type == "damage":
			var side := "TEAM" if str(event_value.get("seat", "")) == "player" else "RIVAL"
			damage_rows.append("%s %d → %d HP" % [side, int(event_value.get("hp_before", 0)), int(event_value.get("hp_after", 0))])
	if not swaps.is_empty():
		var primary_side := "player" if swaps.has("player") else "rival"
		var primary: Dictionary = swaps.get(primary_side, {})
		var heading := "TEAM SWAP" if primary_side == "player" else "RIVAL SWAP"
		if enlarged:
			# The large summary owner is narrow: keep the full side meaning in the
			# accessible name and reserve the four visible lines for identities.
			return "%s\nActive\n%s\nReady" % [str(primary.get("incoming", "")), str(primary.get("outgoing", ""))]
		var rows: Array[String] = [heading, "%s in" % str(primary.get("incoming", "")), "%s ready" % str(primary.get("outgoing", ""))]
		if swaps.has("player") and swaps.has("rival"):
			var rival: Dictionary = swaps.get("rival", {})
			rows.append("RIVAL SWAP")
			rows.append("%s in" % str(rival.get("incoming", "")))
			rows.append("%s ready" % str(rival.get("outgoing", "")))
		return "\n".join(rows)
	if not defeats.is_empty():
		var rows: Array[String] = []
		if defeats.has("player"):
			rows.append("TEAM DOWN")
			rows.append(str(defeats.get("player", "")))
		if defeats.has("rival"):
			rows.append("RIVAL DOWN")
			rows.append(str(defeats.get("rival", "")))
		return "\n".join(rows)
	return "\n".join(damage_rows)


func _stage_feedback_accessibility(stage: Dictionary) -> String:
	var sentences: Array[String] = []
	for event_value in stage.get("events", []):
		if not event_value is Dictionary:
			continue
		var event_type := str(event_value.get("type", ""))
		if event_type == "swap":
			var incoming := str(event_value.get("active_member_id", "")).get_slice(":", 2).capitalize()
			var outgoing := str(event_value.get("reserve_member_id", "")).get_slice(":", 2).capitalize()
			if not incoming.is_empty() and not outgoing.is_empty():
				sentences.append("%s swaps %s into Active; %s moves to Ready." % ["Team" if str(event_value.get("seat", "")) == "player" else "Rival", incoming, outgoing])
		elif event_type == "defeat":
			var defeated := str(event_value.get("member_identity_id", "")).get_slice(":", 2).capitalize()
			if not defeated.is_empty():
				sentences.append("%s %s is defeated." % ["Team" if str(event_value.get("seat", "")) == "player" else "Rival", defeated])
	return " ".join(sentences)


func _entering_id_by_seat(stage: Dictionary) -> Dictionary:
	var values := {}
	if str(stage.get("name", "")) != "Enter/Fit":
		return values
	for event_value in stage.get("events", []):
		if event_value is Dictionary and str(event_value.get("type", "")) == "companion_entered":
			values[str(event_value.get("seat", ""))] = str(event_value.get("member_identity_id", ""))
	return values


func _render_rival_hand(shell: Variant, snapshot: Dictionary) -> void:
	var opponent: Dictionary = snapshot.get("opponent", {})
	var count := clampi(int(opponent.get("hand_count", 0)), 0, 4)
	if _is_large(shell):
		_battle_label(shell, "Rival ×%d" % count, Rect2(22.87, 359.41, 230.35, 49.01), 26, Color("fff0c8"), HORIZONTAL_ALIGNMENT_LEFT)
	else:
		_battle_label(shell, "RIVAL HAND\n%d HIDDEN" % count, Rect2(32, 360, 194, 72), 24, Color("d9f8fb"), HORIZONTAL_ALIGNMENT_LEFT)
	var back := ResourceLoader.load("res://assets/cards/support_card_back_source_v1.png") as Texture2D
	for index in count:
		var image := TextureRect.new()
		image.texture = back
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_SCALE
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Physical.place_design(image, Rect2(32 + index * 48, 439, 43, 64))
		shell._content.add_child(image)


func _render_player_hand(shell: Variant, controller: Variant, snapshot: Dictionary, resolving: bool) -> void:
	var own: Dictionary = snapshot.get("own", {})
	var selected_support := str(controller.local_plan.get("support_copy_id", ""))
	var selected_swap := str(controller.local_plan.get("swap_id", ""))
	for index in mini(4, own.get("hand", []).size()):
		var copy: Dictionary = own.hand[index]
		var copy_id := str(copy.copy_id)
		var card_id := str(copy.card_id)
		var x: float = float(([51.0, 209.0, 367.0, 525.0] as Array)[index])
		var disabled := resolving or not selected_swap.is_empty()
		var hand: Button = shell._button("", Rect2(x, 1360, 146, 217), func(): _select_support(shell, controller, copy_id, card_id), disabled, "tall", false, false)
		hand.name = "BattleSupport_%s" % copy_id.replace(":", "_")
		hand.accessibility_name = "%s. %s. %s" % [_support_name(card_id), _support_effect(card_id), "Locked during resolution" if resolving else ("Choose 1 Support or 1 swap." if not selected_swap.is_empty() else ("Selected" if selected_support == copy_id else "Use one Support"))]
		if resolving:
			hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hand.focus_mode = Control.FOCUS_NONE
		_set_selected_ring(hand, selected_support == copy_id and not resolving, bool(shell.settings_draft.get("high_contrast", false)))
		var card_art := TextureRect.new()
		card_art.name = "BattleSupportArt_%s" % copy_id.replace(":", "_")
		card_art.texture = CardView.atlas_region(V3Catalog.card(card_id))
		card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Physical.place_design(card_art, Rect2(x + 6, 1367, 134, 89))
		shell._content.add_child(card_art)
		var name_rect := Rect2(x + 4, 1478, 138, 92) if _is_large(shell) else Rect2(x + 4, 1502, 138, 68)
		var name_label := _hand_label(shell, _support_large(card_id) if _is_large(shell) else _support_short(card_id), name_rect, 26 if _is_large(shell) else 27)
		if _is_large(shell):
			_apply_two_line_metrics(name_label, name_rect, 39, 42.48)
		name_label.accessibility_name = hand.accessibility_name


func _presentation_snapshot(controller: Variant) -> Dictionary:
	var stage: Dictionary = controller.current_stage()
	if stage.is_empty():
		return controller.player_view.duplicate(true)
	# Cursor zero is the receipt opening, not the already-advanced Queue snapshot.
	return controller.receipt.get("opening", {}).duplicate(true) if controller.cursor == 0 else stage.get("snapshot", {}).duplicate(true)


func _show_result(controller: Variant) -> bool:
	var stage: Dictionary = controller.current_stage()
	return _stage_has_terminal(stage) or (not str(controller.player_view.get("result", "")).is_empty() and controller.cursor >= controller.stage_count)


func _stage_has_terminal(stage: Dictionary) -> bool:
	if str(stage.get("name", "")) != "Result":
		return false
	for event_value in stage.get("events", []):
		if event_value is Dictionary and str(event_value.get("type", "")) == "terminal":
			return true
	return false


func _member(seat: Dictionary, identity: String) -> Dictionary:
	for value in seat.get("members", []):
		if value is Dictionary and str(value.get("identity_id", "")) == identity:
			return value
	return {}


func _member_name(view: Dictionary, identity: String) -> String:
	var own: Dictionary = _member(view.get("own", {}), identity)
	return _name(own) if not own.is_empty() else "Companion"


func _member_status(view: Dictionary, identity: String) -> String:
	var member: Dictionary = _member(view.get("own", {}), identity)
	return str(member.get("status", ""))


func _equipment_target_status(controller: Variant, identity: String) -> String:
	var member: Dictionary = _member(controller.player_view.get("own", {}), identity)
	var status := str(member.get("status", ""))
	if status == "Printing":
		return "PRINTING"
	if status == "Ready":
		return "READY"
	# Target rows are emitted only from Rules.eligible_equipment_targets. An
	# Unspent row is consequently this same Plan's legal default/explicit print;
	# do not recheck the deliberately target-free provisional support here.
	if status == "Unspent":
		return "NEXT"
	return "ACTIVE" if identity == str(controller.player_view.get("own", {}).get("active_member_id", "")) else status.to_upper()


func _name(member: Dictionary) -> String:
	return str(member.get("member_id", "Companion")).capitalize()


func _queue_copy(seat: Dictionary, stage: Dictionary) -> String:
	var fifo: Array = seat.get("fifo", [])
	if fifo.is_empty():
		return "EMPTY"
	var head: Dictionary = fifo[0]
	var state := "PRINTING" if _stage_prints_seat(stage, "player") else "QUEUED"
	return "%s %s" % [_queue_head_name(head), state]


func _queue_head_name(head: Dictionary) -> String:
	if str(head.get("kind", "")) == "equipment":
		var card_copy: Dictionary = head.get("card_copy", {})
		return _support_name(str(card_copy.get("card_id", head.get("card_id", "")))).to_upper()
	var identity := str(head.get("member_identity_id", ""))
	return identity.get_slice(":", 2).to_upper() if not identity.is_empty() else "COMPANION"


func _stage_prints_seat(stage: Dictionary, seat: String) -> bool:
	if str(stage.get("name", "")) != "Print":
		return false
	for event_value in stage.get("events", []):
		if event_value is Dictionary and str(event_value.get("type", "")) == "print_work" and str(event_value.get("seat", "")) == seat:
			return true
	return false


func _stage_prints_member(stage: Dictionary, seat: String, identity_id: String) -> bool:
	if str(stage.get("name", "")) != "Print":
		return false
	for event_value in stage.get("events", []):
		if event_value is Dictionary and str(event_value.get("type", "")) == "print_work" and str(event_value.get("seat", "")) == seat and str(event_value.get("member_identity_id", "")) == identity_id:
			return true
	return false


func _attack_captions_hidden(controller: Variant, stage: Dictionary) -> bool:
	var name := str(stage.get("name", ""))
	# Keep both fixed caption owners absent for the complete paired beat. This avoids
	# overlap at windup/contact and does not rebuild the native route mid-frame; the
	# next receipt stage restores their full accessible name/HP state at the roots.
	return name == "AttackLock" or name == "Damage"


func _stage_title(stage: Dictionary, enlarged := false) -> String:
	var name := str(stage.get("name", "PLAN"))
	if name != "Enter/Fit" or not enlarged:
		return {"AttackLock":"ATTACK", "Enter/Fit":"ENTER/FIT"}.get(name, name.to_upper())
	var companion := false
	var equipment := false
	for event_value in stage.get("events", []):
		if not event_value is Dictionary:
			continue
		var event_type := str(event_value.get("type", ""))
		companion = companion or event_type == "companion_entered"
		equipment = equipment or event_type in ["equipment_fit", "equipment_fizzled"]
	if companion and equipment:
		return "ENTER / FIT"
	return "ENTER" if companion else "FIT"


func _support_name(card_id: String) -> String:
	return {"raw_filament":"Raw Filament", "heated_spool":"Heated Spool", "standard_full_suit":"Full Suit", "iron_gem":"Iron Gem", "forge_surge":"Forge Surge"}.get(card_id, card_id.capitalize())


func _support_short(card_id: String) -> String:
	var definition: Dictionary = Data.support_definition(card_id)
	var value := int(definition.get("aid", definition.get("cost", 0)))
	var suffix := "+%d" % value if int(definition.get("aid", 0)) > 0 else "%d" % int(definition.get("cost", 0))
	return {"standard_full_suit":"Suit", "iron_gem":"Gem", "forge_surge":"Surge", "raw_filament":"Raw", "heated_spool":"Heated"}.get(card_id, _support_name(card_id)) + " · " + suffix


func _support_large(card_id: String) -> String:
	var definition: Dictionary = Data.support_definition(card_id)
	var value := int(definition.get("aid", 0))
	var number := "+%d" % value if value > 0 else str(int(definition.get("cost", 0)))
	return "%s\n%s" % [{"standard_full_suit":"Suit", "iron_gem":"Gem", "forge_surge":"Surge", "raw_filament":"Raw", "heated_spool":"Heated"}.get(card_id, _support_name(card_id)), number]


func _support_effect(card_id: String) -> String:
	var definition: Dictionary = Data.support_definition(card_id)
	var kind := str(definition.get("kind", ""))
	if kind == "aid":
		return "Cost 0. Filament +%d." % int(definition.get("aid", 0))
	if kind == "armor":
		return "Cost %d. Armor %d after Fit. Print %d." % [int(definition.get("cost", 0)), int(definition.get("effect", 0)), int(definition.get("work", 0))]
	if kind == "gem":
		return "Cost %d. Attack +%d after Fit. Print %d." % [int(definition.get("cost", 0)), int(definition.get("effect", 0)), int(definition.get("work", 0))]
	if kind == "surge":
		return "Cost %d. Attack 150 percent this cycle." % int(definition.get("cost", 0))
	return "Support effect unavailable."


func _is_large(shell: Variant) -> bool:
	return int(shell.settings_draft.get("text_scale_bps", 10000)) == 15000


func _dark_label(shell: Variant, copy: String, rect: Rect2, font_size: int, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	return _battle_label(shell, copy, rect, font_size, Color("fff0c8"), align)


func _result_label(shell: Variant, copy: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label: Label = shell._label(copy, rect, font_size)
	if _is_large(shell):
		label.add_theme_font_size_override("font_size", 39)
		var font: Font = label.get_theme_font("font")
		var font_height: int = font.get_height(39) if font != null else 39
		label.add_theme_constant_override("line_spacing", roundi(42.48 - float(font_height)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	return label


func _battle_label(shell: Variant, copy: String, rect: Rect2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label: Label = shell._label(copy, rect, font_size, align)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("07131d"))
	label.add_theme_constant_override("outline_size", 2 if not bool(shell.settings_draft.get("high_contrast", false)) else 3)
	return label


func _apply_two_line_metrics(label: Label, owner: Rect2, font_size: int, line_advance: float) -> void:
	# Active and Ready text shares fixed registered owners. Derive the line spacing
	# from the fallback font so normal 27/26 and large 39/42.48 copy stays inside
	# hardware without reducing native type or moving a caption seat.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	var font: Font = label.get_theme_font("font")
	var font_height: int = font.get_height(font_size) if font != null else font_size
	label.add_theme_constant_override("line_spacing", roundi(line_advance - float(font_height)))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.set_meta("authored_owner", owner)
	label.set_meta("line_advance", line_advance)


func _hand_label(shell: Variant, copy: String, rect: Rect2, font_size: int) -> Label:
	var label := _battle_label(shell, copy, rect, font_size, Color("fff8d8"))
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color("0d1a25e6")
	backing.corner_radius_top_left = 4
	backing.corner_radius_top_right = 4
	backing.corner_radius_bottom_left = 4
	backing.corner_radius_bottom_right = 4
	label.add_theme_stylebox_override("normal", backing)
	return label


func _set_selected_ring(button: Button, selected: bool, high_contrast: bool) -> void:
	if not selected:
		return
	var ring := Physical.add_inset_button_focus_ring(button, high_contrast)
	ring.name = "BattleSelectedRing"
	if button.focus_exited.is_connected(ring.hide):
		button.focus_exited.disconnect(ring.hide)
	ring.show()


func _record_token(shell: Variant, copy: String, owner: Rect2, compact_docket: bool) -> void:
	if compact_docket:
		var docket_rect := owner
		if _is_large(shell) and owner.position.y < 500.0:
			docket_rect = Rect2(29.40, 115, 215.65, 42.48)
		var docket_label := _battle_label(shell, copy.split("\n")[0], docket_rect, 26, Color("241708"))
		docket_label.accessibility_name = copy.replace("\n", ", ")
		return
	if _is_large(shell):
		var lines := copy.split("\n")
		var large_copy := str(lines[0]) if owner.size.y <= 90.0 and not lines.is_empty() else copy
		var large_local := Rect2(0, 0, owner.size.x - 0.07, owner.size.y) if owner.size.y <= 90.0 else Rect2(0, 28, owner.size.x - 0.07, 91.49)
		var large_label := _battle_label(shell, large_copy, Rect2(owner.position + large_local.position, large_local.size), 26, Color("fff0c8"))
		large_label.accessibility_name = copy.replace("\n", ", ")
		return
	var local := Rect2(30, 43, 218, 84)
	var label := _battle_label(shell, copy, Rect2(owner.position + local.position, local.size), 26, Color("d9f8fb"))
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("163449d9")
	surface.border_color = Color("bb934c")
	surface.set_border_width_all(1)
	surface.corner_radius_top_left = 5
	surface.corner_radius_top_right = 5
	surface.corner_radius_bottom_left = 5
	surface.corner_radius_bottom_right = 5
	label.add_theme_stylebox_override("normal", surface)
