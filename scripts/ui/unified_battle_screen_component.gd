class_name UnifiedBattleScreenComponent
extends RefCounted
## Physical portrait battle composition.  It exposes Plan and one Run Cycle
## lever; phase names are status only and never player-operated controls.

const RULES := preload("res://scripts/core/unified_rules.gd")
const STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")
const NAVIGATION := preload("res://scripts/ui/physical_navigation_component.gd")
const CONTROL_FAMILY := preload("res://scripts/ui/physical_control_family.gd")
const PORTRAIT_PRESENTER := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
# Measured inner parchment faces on the 941x1672 battle chassis.  Keep all
# readout anchors derived from this one source rather than hand-tuned fractions.
const HP_SEATS := [Rect2(324.0 / 941.0, 1240.0 / 1672.0, 261.0 / 941.0, 45.0 / 1672.0), Rect2(324.0 / 941.0, 200.0 / 1672.0, 261.0 / 941.0, 49.0 / 1672.0)]
const RESOURCE_SEATS := [Rect2(376.0 / 941.0, 1315.0 / 1672.0, 206.0 / 941.0, 57.0 / 1672.0), Rect2(376.0 / 941.0, 285.0 / 1672.0, 206.0 / 941.0, 50.0 / 1672.0)]
const STATUS_SEAT := Rect2(241.0 / 941.0, 1075.0 / 1672.0, 461.0 / 941.0, 58.0 / 1672.0)
const BATTLE_DESIGN := Vector2(941.0, 1672.0)
const TITLE_SEAT := Rect2(.20, .012, .60, .043)
const TITLE_LARGE_SEAT := Rect2(.15, .002, .70, .063)
const BACK_SEAT := Rect2(.02, .004, .11, .061)
const HAND_SEAT := Rect2(.224, .885, .482, .080)
const ACTION_SEAT := Rect2(.015, .885, .190, .100)
const LEVER_SEAT := Rect2(.76, .875, .20, .095)
const LEVER_LARGE_SEAT := Rect2(.76, .870, .20, .100)
var _stage: PhysicalBattlefieldStage
var _overflow_selected: Array[int] = []
var _overflow_signature := ""

func render_preflight(shell: Control) -> void:
	# Workshop's battle dais opens this browse-only surface.  It reads the existing
	# deck/preprint profile; only Begin delegates to GameManager's validated launch.
	var stage := STAGE.new(); stage.name = "PhysicalChallengeBoard"; stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); stage.configure({"players":[{},{}]}); shell.add_child(stage)
	var deck: Array = GameManager.active_deck_cards()
	var preprints: Array = GameManager.profile.get("preprints", []) if GameManager.profile.get("preprints", []) is Array else []
	# Keep the presentation honest with the authority's deck validator.  A forty
	# card list can still be illegal for ownership, limits, or preprint reasons.
	var legality_reason := str(RULES.deck_reason(GameManager.profile, deck))
	var legal := legality_reason.is_empty()
	var preflight := bool(shell.get_meta("battle_preflight", false))
	var legality_copy := "Legal deck %d/40" % deck.size() if legal else legality_reason
	var copy := "Battle Preflight\n%s · Preprints %d/3\nYour printer: 2,000 HP · Rival: 2,000 HP" % [legality_copy, preprints.size()] if preflight else "Challenge Board\nFirst Layers training\nPublic rival printer: 2,000 HP\nInspect the battle setup"
	# Challenge copy and its physical decision keys occupy deliberately separate
	# material bands.  The prior short plate allowed multi-line facts to cross the
	# button texture at phone scale.
	var title := _add_plate(shell, Rect2(.205, .305, .590, .310), copy, Callable(), "", Color("f1be69")); title.name = "PhysicalBattlePreflight" if preflight else "PhysicalChallengeBoard"
	var body := title.get_child(0) as VBoxContainer
	if not preflight:
		var continue_button: Button = shell.make_button("Review Preflight", func(): shell.set_meta("battle_preflight", true); shell.render(), Color("a86b2e")); continue_button.name = "ChallengeContinuePreflight"; continue_button.custom_minimum_size = Vector2(0,56); body.add_child(continue_button)
		var browse_return: Button = shell.make_button("Return to Workshop", shell.dispatch_back, Color("526e93")); browse_return.name = "ChallengeReturnWorkshop"; browse_return.custom_minimum_size = Vector2(0,48); body.add_child(browse_return); return
	var begin: Button = shell.make_button("Begin Battle" if legal else "Deck is not legal", shell.start_mode.bind("trial_first_layers"), Color("a86b2e")); begin.name = "ChallengeBeginBattle"; begin.disabled = not legal; begin.tooltip_text = "Begin validates the active deck and legal pre-prints." if legal else legality_reason; begin.custom_minimum_size = Vector2(0,56); body.add_child(begin)
	var return_button: Button = shell.make_button("BACK TO CHALLENGE BOARD", shell.dispatch_back, Color("526e93")); return_button.name = "ChallengeReturnWorkshop"; return_button.custom_minimum_size = Vector2(0,48); body.add_child(return_button)

func render_fullscreen(shell: Control) -> void:
	var battle = shell.battle
	if battle == null: return
	var viewer_seat := _viewer_seat(shell, battle)
	var public_view := _physical_public_view(shell, battle, viewer_seat)
	if _stage == null or not is_instance_valid(_stage): _stage = STAGE.new()
	var contact_callback := Callable(self, "_on_attack_contact").bind(shell)
	if not _stage.attack_contact.is_connected(contact_callback):
		_stage.attack_contact.connect(contact_callback)
	var finished_callback := Callable(self, "_on_presentation_finished").bind(shell)
	if not _stage.presentation_finished.is_connected(finished_callback):
		_stage.presentation_finished.connect(finished_callback)
	if _stage.get_parent() != null: _stage.get_parent().remove_child(_stage)
	_stage.name = "PhysicalBattlefieldStage"
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var large_text := int(shell.settings().get("text_scale_bps", 10000)) >= 15000
	_stage.configure(public_view, _physical_receipt(shell, shell.unified_battle_presentation, viewer_seat))
	_stage.set_large_text_layout(large_text)
	shell.add_child(_stage)
	_stage.set_focus(1, int(shell.unified_battle_coordinator.transient_focus))
	_stage.set_selected_slot(0, int(shell.unified_selected_slot))
	var title: Label = shell.label("PRINTFORGE BATTLE\nTurn %d" % int(public_view.get("turn", 0)) if large_text else "PRINTFORGE BATTLE · Turn %d" % int(public_view.get("turn", 0)), 10 if large_text else 15, Color("fff0bb")); title.name = "UnifiedBattleHeading"; title.mouse_filter = Control.MOUSE_FILTER_IGNORE; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if large_text else TextServer.AUTOWRAP_OFF; title.clip_text = true; _place_on_battle_chassis(shell, title, TITLE_LARGE_SEAT if large_text else TITLE_SEAT)
	shell.add_child(title)
	_add_hud(shell, public_view)
	_add_status_plate(shell)
	_add_anchor_controls(shell, public_view)
	_add_synthetic_bottom_overlay(shell)
	var back: Button = shell.make_button("Back", shell.request_back, Color("526e93")); back.name = "UnifiedBattleBack"; NAVIGATION.configure_back(back, "battle pause", Vector2(56, 56)); back.tooltip_text = "Pause battle or choose to concede"; back.accessibility_name = back.tooltip_text; _place_on_battle_chassis(shell, back, BACK_SEAT); shell.add_child(back)
	if bool(shell.battle_back_confirmation):
		_add_back_choice(shell, battle)
		return
	if bool(battle.finished) and not str(shell.unified_battle_presentation.get("kind", "")).is_empty():
		_add_status(shell, "Final contact resolving · controls locked")
		return
	if bool(battle.finished):
		if not shell.battle_settlement_context.is_empty() and not bool(shell.battle_settlement_finished): shell.call_deferred("_settle_finished_unified_battle")
		_add_plate(shell, Rect2(.28, .49, .44, .18), "%s printer broke." % ("Rival" if int(battle.winner) == viewer_seat else "Your"), shell.dispatch_back, "Return to Workshop", Color("a86b2e")); return
	if str(shell.battle_mode) == "local" and bool(shell.unified_local_handoff):
		_add_plate(shell, Rect2(.23, .49, .54, .18), "Pass the device · hands stay hidden", func(): shell.unified_local_handoff = false; shell.render(), "Ready Player %d" % (int(battle.active_seat) + 1), Color("a86b2e")); return
	var seat := int(battle.active_seat)
	if str(shell.battle_mode) != "local" and seat == 1:
		_add_status(shell, "Rival printer is resolving one checked action at a time."); return
	var players: Array = public_view.get("players", []) if public_view.get("players", []) is Array else []
	var active: Dictionary = players[0] if not players.is_empty() and players[0] is Dictionary else {}
	var pending: Dictionary = public_view.get("pending", {}) if public_view.get("pending", {}) is Dictionary else {}
	if not pending.is_empty() or (str(battle.phase) == "collect" and (active.get("hand", []) as Array).size() > 8):
		_add_decision_overlay(shell, active, pending if not pending.is_empty() else {"kind":"overflow"}); return
	if str(shell.toast).contains("snapshot restored"):
		_add_status(shell, str(shell.toast)); return
	var presentation_kind := str(shell.unified_battle_presentation.get("kind", ""))
	if not presentation_kind.is_empty():
		var receipt: Dictionary = shell.unified_battle_presentation
		var attack_copy := "%s → %s · %d damage · armor %d→%d" % [str((receipt.get("source", {}) as Dictionary).get("name", "Attacker")), str((receipt.get("target", {}) as Dictionary).get("name", "Target")), int(receipt.get("damage", 0)), int(receipt.get("armor_before", 0)), int(receipt.get("armor_after", 0))]
		var work: Array = receipt.get("print_events", []) if receipt.get("print_events", []) is Array else []
		var print_copy := "Print resolving · controls locked"
		if not work.is_empty() and work[0] is Dictionary:
			var first_work: Dictionary = work[0]
			print_copy = "Printing %s · %d layers" % [str(RULES.card(str(first_work.get("card_id", ""))).get("name", "blueprint")), int(first_work.get("remaining_before", 0))]
		_add_status(shell, "Awakening · Step-off" if presentation_kind == "deploy" else attack_copy if presentation_kind == "attack" else print_copy)
		return
	if str(public_view.get("phase", "")) == "draw": shell.call_deferred("_enter_unified_plan")
	if str(public_view.get("phase", "")) == "main": _add_plan_overlay(shell, active)
	else: _add_status(shell, "Run Cycle · %s" % str(public_view.get("phase", "")).capitalize())

func _add_back_choice(shell: Control, battle) -> void:
	var bot_turn := str(shell.battle_mode) != "local" and int(battle.active_seat) == 1
	# The modal has one active keyboard/pointer owner. Do not leave the background
	# Back plaque focused or hoverable beneath its shield.
	var background_back := shell.find_child("UnifiedBattleBack", true, false) as Button
	if background_back != null:
		background_back.release_focus()
		background_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_back.disabled = true
	var shield := ColorRect.new()
	shield.name = "UnifiedBattleExitShield"
	shield.color = Color(0.01, 0.03, 0.05, 0.78)
	shield.mouse_filter = Control.MOUSE_FILTER_STOP
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shield.z_index = 19
	shell.add_child(shield)
	var panel := _add_plate(shell, Rect2(.20, .39, .60, .24), "Rival is resolving. Resume safely when ready." if bot_turn else "Pause this battle, or concede this match?", Callable(), "", Color("a86b2e"))
	panel.z_index = 20
	var body := panel.get_child(0) as VBoxContainer
	var resume: Button = shell.make_button("Stay", func(): shell.battle_back_confirmation = false; shell.render(), Color("588d73")); resume.name = "UnifiedBattleResume"; resume.custom_minimum_size = Vector2(0,56); CONTROL_FAMILY.apply(resume, "wide"); body.add_child(resume)
	shell.call_deferred("_deferred_focus_if_ready", resume.get_instance_id())
	var dismiss: Button = shell.make_button("Back", shell.request_back, Color("526e93")); dismiss.name = "UnifiedBattleExitBack"; NAVIGATION.configure_back(dismiss, "battle pause", Vector2(56,56)); _place_on_battle_chassis(shell, dismiss, BACK_SEAT); dismiss.z_index = 21; shell.add_child(dismiss)
	if not bot_turn:
		var concede: Button = shell.make_button("Concede", shell._concede_unified_battle, Color("a86b2e")); concede.name = "UnifiedBattleConcede"; concede.custom_minimum_size = Vector2(0,56); CONTROL_FAMILY.apply(concede, "lever"); body.add_child(concede)

func _viewer_seat(shell: Control, battle) -> int:
	return int(battle.active_seat) if str(shell.battle_mode) == "local" else 0

func _physical_public_view(shell: Control, battle, viewer_seat: int) -> Dictionary:
	var view: Dictionary = shell.unified_battle_coordinator.public_snapshot_for(viewer_seat)
	# Authority has already resolved the receipt, but its old defender and printer
	# values remain the visible truth until the finite contact beat lands.
	var receipt: Dictionary = shell.unified_battle_presentation if shell.unified_battle_presentation is Dictionary else {}
	if str(receipt.get("kind", "")) == "attack" and not bool(receipt.get("contact_reached", false)):
		var actor := int(receipt.get("actor", -1))
		var target_slot := int(receipt.get("target_slot", -1))
		var players: Array = view.get("players", []) if view.get("players", []) is Array else []
		var defender_seat := 1 - actor
		if defender_seat >= 0 and defender_seat < players.size() and players[defender_seat] is Dictionary:
			var defender: Dictionary = players[defender_seat]
			if target_slot >= 0:
				var slots: Array = defender.get("slots", []) if defender.get("slots", []) is Array else []
				if target_slot < slots.size(): slots[target_slot] = receipt.get("target", {})
				defender["slots"] = slots
			else:
				var printer: Dictionary = defender.get("printer", {}) if defender.get("printer", {}) is Dictionary else {}
				printer["hp"] = int(receipt.get("printer_hp_before", printer.get("hp", 0)))
				defender["printer"] = printer
			players[defender_seat] = defender
			view["players"] = players
	# Authority can consume multiple FIFO jobs before emitting one public receipt.
	# During the first finite print beat, keep the native queue gauge aligned with
	# that displayed job instead of jumping to a terminal later queue head.
	var work: Array = receipt.get("print_events", []) if receipt.get("print_events", []) is Array else []
	if not work.is_empty() and work[0] is Dictionary:
		var first_work: Dictionary = work[0]
		var print_seat := int(first_work.get("seat", receipt.get("actor", -1)))
		var players: Array = view.get("players", []) if view.get("players", []) is Array else []
		if print_seat >= 0 and print_seat < players.size() and players[print_seat] is Dictionary:
			var printer_owner: Dictionary = players[print_seat]
			printer_owner["queue"] = [{"card_id":str(first_work.get("card_id", "")), "remaining":maxi(0, int(first_work.get("remaining_before", first_work.get("remaining_after", 0)))), "job_id":str(first_work.get("job_id", ""))}]
			players[print_seat] = printer_owner
			view["players"] = players
	# The player holding the device always owns the lower instruments.  Authority
	# seat numbers remain untouched; only the redacted presentation ordering swaps.
	if viewer_seat == 1:
		var players: Array = view.get("players", []) if view.get("players", []) is Array else []
		if players.size() == 2:
			view["players"] = [players[1], players[0]]
			view["active_seat"] = 0 if int(view.get("active_seat", 0)) == 1 else 1
			var pending: Dictionary = view.get("pending", {}) if view.get("pending", {}) is Dictionary else {}
			if pending.has("seat"): pending["seat"] = 0 if int(pending.get("seat", 0)) == 1 else 1
			view["pending"] = pending
	return view

func _on_attack_contact(shell: Control) -> void:
	if str(shell.unified_battle_presentation.get("kind", "")) != "attack": return
	shell.unified_battle_presentation["contact_reached"] = true
	# Stage emits from _process.  Never detach/reparent that same stage while its
	# frame callback is on the stack; defer the narrow native HUD refresh instead.
	shell.call_deferred("render")

func _on_presentation_finished(token: int, shell: Control) -> void:
	# The stage signal is emitted from the same finite progression used to draw
	# print, awaken, deploy, and contact.  Keep Main as the sole coordinator ack
	# owner while refusing any obsolete stage instance or receipt token.
	if token != int(shell.unified_battle_presentation.get("token", -1)): return
	# Settlement renders the next shell state.  As above, leave the emitting stage
	# process callback before it removes and reattaches the persistent stage node.
	shell.call_deferred("_settle_unified_battle_presentation", token)

func _physical_receipt(shell: Control, receipt: Dictionary, viewer_seat: int) -> Dictionary:
	var physical := receipt.duplicate(true)
	if viewer_seat == 1:
		if physical.has("actor"): physical["actor"] = 0 if int(physical.actor) == 1 else 1
		if physical.has("target_seat"): physical["target_seat"] = 0 if int(physical.target_seat) == 1 else 1
		for key in ["print_events", "deployments"]:
			var seated: Array = physical.get(key, []) if physical.get(key, []) is Array else []
			for entry in seated:
				if entry is Dictionary and (entry as Dictionary).has("seat"):
					(entry as Dictionary)["seat"] = 0 if int((entry as Dictionary).seat) == 1 else 1
	var work: Array = physical.get("print_events", []) if physical.get("print_events", []) is Array else []
	if not work.is_empty() and work[0] is Dictionary:
		physical["print_card_id"] = str((work[0] as Dictionary).get("card_id", ""))
		physical["print_job_id"] = str((work[0] as Dictionary).get("job_id", ""))
	var deployments: Array = physical.get("deployments", []) if physical.get("deployments", []) is Array else []
	if physical.get("print_card_id", "").is_empty() and not deployments.is_empty() and deployments[0] is Dictionary:
		physical["print_card_id"] = str((deployments[0] as Dictionary).get("card_id", ""))
	physical["reduced_motion"] = bool(shell.settings().get("reduced_motion", false))
	return physical

func _add_hud(shell: Control, public_view: Dictionary) -> void:
	var players: Array = public_view.get("players", []) if public_view.get("players", []) is Array else []
	var large_text := int(shell.settings().get("text_scale_bps", 10000)) >= 15000
	var parchment_ink := Color.BLACK if bool(shell.settings().get("high_contrast", false)) else Color("172b3c")
	for seat in 2:
		var player: Dictionary = players[seat] if seat < players.size() and players[seat] is Dictionary else {}; var printer: Dictionary = player.get("printer", {})
		var hp_rect: Rect2 = HP_SEATS[seat]
		var resource_rect: Rect2 = RESOURCE_SEATS[seat]
		# Two player resource lines share the lower cream gauge.  Bias their visual
		# group four authored pixels upward so its second baseline clears the brass.
		if seat == 0: resource_rect.position.y -= 4.0 / BATTLE_DESIGN.y
		var side := "Rival" if seat == 1 else "Your"
		# Both native readouts sit on parchment, so both receive dark ink after any
		# route/global accessibility theme has been applied.
		var hp_copy := "HP %d/%d" % [int(printer.get("hp", 0)), int(printer.get("max_hp", 2000))] if large_text else "%s HP %d/%d" % [side, int(printer.get("hp", 0)), int(printer.get("max_hp", 2000))]
		var hud: Label = shell.label(hp_copy, 12, parchment_ink); hud.name = "PhysicalBattleHud%d" % seat; hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; hud.clip_text = true; hud.tooltip_text = "%s printer HP %d of %d" % [side, int(printer.get("hp", 0)), int(printer.get("max_hp", 2000))]; hud.accessibility_name = hud.tooltip_text; hud.add_theme_color_override("font_color", parchment_ink); _place_on_battle_chassis(shell, hud, hp_rect); shell.add_child(hud)
		var queue: Array = player.get("queue", []) if player.get("queue", []) is Array else []
		var head_name := str(RULES.card(str((queue[0] as Dictionary).get("card_id", ""))).get("name", "—")) if not queue.is_empty() else "—"
		var remaining := int((queue[0] as Dictionary).get("remaining", 0)) if not queue.is_empty() else 0
		var resource_copy := "F %d/%d · Q%d" % [int(player.get("filament", 0)), int(player.get("filament_max", 400)), queue.size()]
		if seat == 0 and not large_text: resource_copy += "\n%s · %dt" % [head_name if not queue.is_empty() else "Idle", remaining]
		var resources: Label = shell.label(resource_copy, 7 if large_text else 9, parchment_ink); resources.name = "PhysicalBattleHud%dResources" % seat; resources.mouse_filter = Control.MOUSE_FILTER_IGNORE; resources.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; resources.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; resources.autowrap_mode = TextServer.AUTOWRAP_OFF; resources.clip_text = true; resources.tooltip_text = "Filament %d of %d · Queue %d · Head %s · %d turn%s left" % [int(player.get("filament", 0)), int(player.get("filament_max", 400)), queue.size(), head_name, remaining, "" if remaining == 1 else "s"]; resources.accessibility_name = resources.tooltip_text; resources.add_theme_color_override("font_color", parchment_ink); _place_on_battle_chassis(shell, resources, resource_rect); shell.add_child(resources)

func _place_on_battle_chassis(shell: Control, node: Control, normalized_seat: Rect2) -> void:
	# The battlefield art uses contain-fit below 2.05 portrait aspect and full fill
	# for the named tall fixture. Mirror that exact rule for its native readouts.
	var rect := _battle_chassis_rect(shell, normalized_seat)
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = rect.position
	node.size = rect.size

func _battle_chassis_rect(shell: Control, normalized_seat: Rect2) -> Rect2:
	var fit := PORTRAIT_PRESENTER.composition_rect(shell.size, BATTLE_DESIGN)
	return Rect2(fit.position + normalized_seat.position * fit.size, normalized_seat.size * fit.size)

func _anchor_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.20, 0.88, 1.0, .06); style.border_color = Color("9af4ff"); style.set_border_width_all(3); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	return style

func _add_status_plate(shell: Control) -> void:
	var parchment_ink := Color.BLACK if bool(shell.settings().get("high_contrast", false)) else Color("172b3c")
	# The measured parchment seat is two lines tall at the 576 reference.  Keep
	# its native message compact and clipped rather than letting a scaled generic
	# status paragraph cross the brass lip onto the printer below.
	var status: Label = shell.label("", 9, parchment_ink); status.name = "PhysicalBattleStatus"; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.max_lines_visible = 2; status.clip_text = true; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; status.add_theme_color_override("font_color", parchment_ink); _place_on_battle_chassis(shell, status, STATUS_SEAT); shell.add_child(status)
	_add_status(shell, str(shell.toast) if not str(shell.toast).is_empty() else "Your Plan · select a blueprint or pull Run Cycle.")

func _add_status(shell: Control, copy: String, full_copy := "") -> void:
	var status := shell.find_child("PhysicalBattleStatus", true, false) as Label
	if status != null:
		status.text = copy
		var metadata_copy := full_copy if not full_copy.is_empty() else copy
		status.tooltip_text = metadata_copy
		status.accessibility_name = metadata_copy
	if not str(shell.toast).is_empty():
		var dismiss: Button = shell.make_button("Dismiss", func(): shell.toast = ""; shell.render(), Color("526e93")); dismiss.name = "PhysicalBattleDismiss"; dismiss.custom_minimum_size = Vector2(48,48); _place_on_battle_chassis(shell, dismiss, Rect2(.77, .635, .14, .05)); shell.add_child(dismiss)
		if str(shell.toast).contains("snapshot restored"):
			status.text = "%s · Rev %d" % [copy, int(shell.unified_battle_coordinator.state.revision)]
			var retry: Button = shell.make_button("Retry", func(): shell.toast = ""; shell._enter_unified_plan(); shell.render(), Color("a86b2e")); retry.name = "PhysicalBattleRetry"; retry.custom_minimum_size = Vector2(48,48); _place_on_battle_chassis(shell, retry, Rect2(.77, .585, .14, .045)); shell.add_child(retry)
		elif str(shell.toast).contains("Rival turn paused safely"):
			var ai_retry: Button = shell.make_button("Retry", func(): shell.toast = ""; shell._queue_unified_ai_if_needed(); shell.render(), Color("a86b2e")); ai_retry.name = "PhysicalBattleRetryAI"; ai_retry.custom_minimum_size = Vector2(48,48); _place_on_battle_chassis(shell, ai_retry, Rect2(.77, .585, .14, .045)); shell.add_child(ai_retry)

func _add_synthetic_bottom_overlay(shell: Control) -> void:
	if not bool(shell.get_meta("synthetic_host_inset_stress", false)): return
	# Capture-only host boundary. Production reserve remains zero; its top stays
	# below the tray/lever so it can never obscure a gameplay rect.
	var band := ColorRect.new(); band.name = "SyntheticHostInsetStress"; band.color = Color("432019"); band.anchor_left = 0; band.anchor_right = 1; band.anchor_top = .97; band.anchor_bottom = 1; band.mouse_filter = Control.MOUSE_FILTER_IGNORE; band.z_index = 60; shell.add_child(band)
	var caption: Label = shell.label("SYNTHETIC HOST INSET · OUTSIDE GAMEPLAY", 10, Color("fff0bb")); caption.name = "SyntheticHostInsetStressLabel"; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); band.add_child(caption)

func _add_anchor_controls(shell: Control, public_view: Dictionary) -> void:
	var source := _stage.anchors()
	var players: Array = public_view.get("players", []) if public_view.get("players", []) is Array else []
	var selected_card := RULES.card(str(shell.unified_selected_card_id)) if not str(shell.unified_selected_card_id).is_empty() else {}
	var selected_kind := str(selected_card.get("type", ""))
	var equip_slot := str(selected_card.get("equipment_slot", ""))
	var pending: Dictionary = public_view.get("pending", {}) if public_view.get("pending", {}) is Dictionary else {}
	var decision_active := not pending.is_empty() or (str(public_view.get("phase", "")) == "collect" and not players.is_empty() and ((players[0] as Dictionary).get("hand", []) as Array).size() > 8)
	for seat in 2:
		var slot_rects: Array = source.player_slots if seat == 0 else source.rival_slots
		for slot in 3:
			var rect: Rect2 = slot_rects[slot]
			var hit: Button = shell.make_button("", func(): pass, Color(0,0,0,0)); hit.name = "PhysicalBattleAnchor%d_%d" % [seat, slot]; hit.tooltip_text = ("Your print anchor" if seat == 0 else "Rival focus anchor") + " %d" % (slot + 1); _place_on_battle_chassis(shell, hit, Rect2(rect.position / BATTLE_DESIGN, rect.size / BATTLE_DESIGN)); hit.custom_minimum_size = Vector2(48,48)
			var player: Dictionary = players[seat] if seat < players.size() and players[seat] is Dictionary else {}
			var slots: Array = player.get("slots", []) if player.get("slots", []) is Array else []
			var occupied := slot < slots.size() and slots[slot] != null
			var target_pick := false
			if selected_kind == "equipment" and equip_slot != "battle_effect":
				target_pick = seat == 0 and occupied and ((slots[slot] as Dictionary).get("equipment", {}).get(equip_slot, {}) as Dictionary).is_empty()
			elif selected_kind == "spell":
				if str(selected_card.get("id", "")) == "layer_melt": target_pick = seat == 1 and occupied
				elif str(selected_card.get("id", "")) == "forge_surge": target_pick = seat == 0 and occupied
			hit.disabled = true if decision_active or selected_kind == "creature" else (not target_pick if selected_kind in ["equipment", "spell"] else not occupied)
			for state_name in ["normal", "hover", "pressed", "disabled"]: hit.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
			hit.add_theme_stylebox_override("focus", _anchor_focus_style())
			if target_pick: hit.pressed.connect(func(): shell.unified_selected_target = slot; shell.render())
			elif seat == 1: hit.pressed.connect(func(): shell._set_unified_focus(slot); _stage.set_focus(1, slot))
			else: hit.pressed.connect(func(): shell.unified_selected_slot = slot; _stage.set_selected_slot(0, slot); shell.render())
			shell.add_child(hit)

func _add_plan_overlay(shell: Control, active: Dictionary) -> void:
	# The pictured bottom tray is a horizontal hand rail, never a three-card slice.
	var large_text := int(shell.settings().get("text_scale_bps", 10000)) >= 15000
	# The selected hand, queued action, and Run Cycle are three separate physical
	# hit regions.  Leave a real gap between their focus edges; a 46px action rail
	# used to clip the Queue label and let its ring cross the hand glyphs.
	# Seat the face-up hand inside the broad parchment rail, below its upper brass
	# lip.  The old 0.85 top anchored a minimum-height card across the hardware.
	var hand_scroll := ScrollContainer.new(); hand_scroll.name = "PhysicalBattleHandScroll"; hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _place_on_battle_chassis(shell, hand_scroll, HAND_SEAT); shell.add_child(hand_scroll)
	var hand_row := HBoxContainer.new(); hand_row.name = "PhysicalBattleHand"; hand_row.add_theme_constant_override("separation", 4); hand_scroll.add_child(hand_row)
	var hand_width := maxi(48, floori(_battle_chassis_rect(shell, HAND_SEAT).size.x)) if large_text else 132
	for id in active.get("hand", []) as Array:
		var card: Button = shell._unified_card_button(str(id)); card.custom_minimum_size = Vector2(hand_width,48); hand_row.add_child(card)
	# Secondary action keys use the dedicated lower-left chassis face, separate from
	# the broad hand parchment and the Run Cycle lever.  This leaves every action a
	# full-height target without stacking two live rows in the same physical rail.
	var action_scroll := ScrollContainer.new(); action_scroll.name = "PhysicalBattlePlanActionScroll"; action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; _place_on_battle_chassis(shell, action_scroll, ACTION_SEAT); action_scroll.get_v_scroll_bar().modulate = Color(1, 1, 1, 0); action_scroll.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE; shell.add_child(action_scroll)
	var row := VBoxContainer.new(); row.name = "PhysicalBattlePlanActions"; row.add_theme_constant_override("separation", 4); action_scroll.add_child(row)
	# Rival physical anchors own focus; no hard-wired fallback button can claim a
	# target the player did not touch.
	if not (active.get("queue", []) as Array).is_empty():
		_add_plan_rail_action(shell, row, "", "CANCEL", shell._submit_unified_intent.bind({"type":"cancel_queue","queue_index":0}), "Cancel queue head and refund half its filament cost.", Color("526e93"))
	var selected_slot := int(shell.unified_selected_slot)
	if selected_slot >= 0 and selected_slot < 3 and active.slots[selected_slot] != null:
		var unit: Dictionary = active.slots[selected_slot]
		_add_plan_rail_action(shell, row, "PhysicalBattleSwitchMode", "MODE", shell._submit_unified_intent.bind({"type":"switch_mode","slot":selected_slot,"mode":"defense" if str(unit.get("mode", "attack")) == "attack" else "attack"}), "Switch selected creature mode.", Color("526e93"))
	if int(active.get("emergency_reprints", 0)) > 0 and not (active.get("graveyard", []) as Array).is_empty():
		_add_plan_rail_action(shell, row, "", "RE\nPRINT", shell._submit_unified_intent.bind({"type":"upgrade_reprint","graveyard_index":0}), "Emergency reprint the first eligible creature.", Color("526e93"))
	# Leave a real 8px inset in the pictured brass mount even when the minimum
	# touch height wins over anchors at a small portrait viewport.
	var lever: Button = shell.make_button("Run\nCycle" if large_text else "Run Cycle", shell._start_unified_run_cycle, Color("a86b2e")); lever.name = "UnifiedRunCycleLever"; lever.custom_minimum_size = Vector2(0, 56); lever.accessibility_name = "Run Cycle. Resolve printing, attacks, and collection."; lever.focus_mode = Control.FOCUS_ALL; _place_on_battle_chassis(shell, lever, LEVER_LARGE_SEAT if large_text else LEVER_SEAT); lever.add_theme_font_size_override("font_size", shell.scaled_font(10) if large_text else shell.scaled_font(15)); shell.add_child(lever)
	if not str(shell.unified_selected_card_id).is_empty() and str(shell.unified_selected_card_id) in (active.get("hand", []) as Array):
		_add_selected_card_controls(shell, active)

func _add_plan_rail_action(shell: Control, row: VBoxContainer, node_name: String, visible_copy: String, action: Callable, tooltip: String, color: Color, disabled := false, primary := false) -> Button:
	# Every action shares the 96px lower-left key rail. Keep the short visual verb
	# inside its painted face; the complete decision remains native in its tooltip
	# and accessibility name.
	var button: Button = shell.make_button(visible_copy, action, color)
	if not node_name.is_empty(): button.name = node_name
	button.custom_minimum_size = Vector2(96, 48)
	button.add_theme_font_size_override("font_size", shell.scaled_font(10))
	button.tooltip_text = tooltip
	button.accessibility_name = tooltip
	button.disabled = disabled
	row.add_child(button)
	if primary: row.move_child(button, 0)
	return button

func _add_selected_card_controls(shell: Control, active: Dictionary) -> void:
	var card_id := str(shell.unified_selected_card_id)
	var card := RULES.card(card_id)
	var kind := str(card.get("type", ""))
	var filament_cost := int(card.get("filament_cost", card.get("cost", 0)))
	if kind != "creature":
		var card_name := str(card.get("name", card_id))
		var card_type := str(card.get("type", "blueprint")).capitalize()
		var full_support_copy := "%s · %d filament · %s · %s" % [card_name, filament_cost, card_type, str(card.get("text", "Use this blueprint."))]
		var support_instruction := "Use selected blueprint"
		if kind == "equipment" and str(card.get("equipment_slot", "")) != "battle_effect":
			support_instruction = "Choose a print to equip" if shell.unified_selected_target < 0 else "Queue equipment"
		elif kind == "spell":
			var needs_target := card_id in ["layer_melt", "forge_surge", "emergency_reprint_spell"]
			if needs_target and shell.unified_selected_target < 0:
				support_instruction = "Choose a reprint, then cast" if card_id == "emergency_reprint_spell" else "Choose a target, then cast"
			else:
				support_instruction = "Cast selected spell"
		elif card_id == "raw_filament":
			support_instruction = "Use selected refill"
		# The hand rail owns the selected card's name/cost. This fixed instruction is
		# the one clear state owner that fits the single-line parchment seat.
		_add_status(shell, support_instruction, full_support_copy)
	var row := shell.find_child("PhysicalBattlePlanActions", true, false) as VBoxContainer
	if row == null: return
	if kind == "creature":
		# The central chassis instrument is the selected-blueprint surface.  Hiding
		# its duplicate status label avoids a second painted strip in the HUD-to-hand
		# gap, while preserving native art/copy and the bottom-tray action controls.
		var status := shell.find_child("PhysicalBattleStatus", true, false) as Label
		if status != null:
			status.text = ""
			status.visible = false
		var card_plate := PanelContainer.new(); card_plate.name = "UnifiedSelectedCreatureBlueprint"; card_plate.clip_contents = true; card_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE; card_plate.add_theme_stylebox_override("panel", StyleBoxEmpty.new()); _place_on_battle_chassis(shell, card_plate, STATUS_SEAT); shell.add_child(card_plate)
		var blueprint_row := HBoxContainer.new(); blueprint_row.clip_contents = true; blueprint_row.alignment = BoxContainer.ALIGNMENT_CENTER; blueprint_row.add_theme_constant_override("separation", 6); card_plate.add_child(blueprint_row)
		var art := TextureRect.new(); art.name = "UnifiedSelectedCreatureBlueprintCard"; art.texture = PhysicalCatalogImprint.blueprint_texture(card); art.custom_minimum_size = Vector2(28, 28); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; blueprint_row.add_child(art)
		var type_copy := str(card.get("type", "blueprint")).capitalize()
		var card_copy: Label = shell.label("%s · %dF · %s · Queue print" % [str(card.get("name", card_id)), filament_cost, type_copy], 9, Color.BLACK if bool(shell.settings().get("high_contrast", false)) else Color("172b3c")); card_copy.name = "UnifiedSelectedCreatureBlueprintCopy"; card_copy.add_theme_font_size_override("font_size", 10); card_copy.add_theme_color_override("font_color", Color.BLACK if bool(shell.settings().get("high_contrast", false)) else Color("172b3c")); card_copy.autowrap_mode = TextServer.AUTOWRAP_OFF; card_copy.clip_text = true; card_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; card_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL; blueprint_row.add_child(card_copy)
		_add_plan_rail_action(shell, row, "UnifiedPlayQueueCreature", "QUEUE", shell._submit_unified_intent.bind({"type":"play_card","card_id":card_id}), "Queue selected creature for printing.", Color("a86b2e"), false, true)
	elif kind == "equipment" and str(card.get("equipment_slot", "")) != "battle_effect":
		var queue_equipment_tooltip: String = "Choose a compatible highlighted player anchor first." if shell.unified_selected_target < 0 else "Queue this equipment for the selected print."
		_add_plan_rail_action(shell, row, "UnifiedPlayQueueEquipment", "QUEUE", shell._submit_unified_intent.bind({"type":"play_card","card_id":card_id,"slot":-1,"target":shell.unified_selected_target}), queue_equipment_tooltip, Color("a86b2e"), shell.unified_selected_target < 0, true)
	elif kind == "spell":
		var targeted := card_id in ["layer_melt", "forge_surge"]
		if card_id == "emergency_reprint_spell":
			var graveyard: Array = active.get("graveyard", []) if active.get("graveyard", []) is Array else []
			for index in graveyard.size():
				var candidate := RULES.card(str(graveyard[index])); if str(candidate.get("type", "")) != "creature": continue
				var selected_mark := "✓ " if shell.unified_selected_target == index else ""
				_add_plan_rail_action(shell, row, "UnifiedSelectReprint%d" % (index + 1), "%sPRINT\n%d" % [selected_mark, index + 1], func(): shell.unified_selected_target = index; shell.render(), "Select eligible reprint %d." % (index + 1), Color("526e93"))
			targeted = true
		var cast_disabled: bool = targeted and shell.unified_selected_target < 0
		var cast_tooltip: String = "Choose a highlighted legal target first." if cast_disabled else "Cast this battle spell."
		_add_plan_rail_action(shell, row, "UnifiedPlayCastCard", "CAST", shell._submit_unified_intent.bind({"type":"play_card","card_id":card_id,"target":shell.unified_selected_target if targeted else -2}), cast_tooltip, Color("a86b2e"), cast_disabled, true)
	else:
		_add_plan_rail_action(shell, row, "UnifiedPlayUseRefill", "USE", shell._submit_unified_intent.bind({"type":"play_card","card_id":card_id,"slot":-1,"target":-2}), "Use this refill blueprint.", Color("a86b2e"), false, true)

func _add_decision_overlay(shell: Control, active: Dictionary, pending: Dictionary) -> void:
	var kind := str(pending.get("kind", ""))
	var source := _stage.anchors()
	if kind == "place":
		_add_status(shell, "Print complete · choose an open anchor and Attack or Defend.")
		for slot in 3:
			var rect: Rect2 = source.player_slots[slot]
			if active.slots[slot] != null: continue
			for mode in ["attack", "defense"]:
				var choice: Button = shell.make_button(mode.capitalize(), shell._submit_required_battle_decision.bind({"type":"place_completed","slot":slot,"mode":mode}), Color("a86b2e")); choice.name = "UnifiedPendingPlaceSlot%d%s" % [slot + 1, mode.capitalize()]; choice.custom_minimum_size = Vector2(48,48); _place_on_battle_chassis(shell, choice, Rect2(Vector2(rect.position.x, rect.position.y + (0 if mode == "attack" else rect.size.y * .48)) / BATTLE_DESIGN, Vector2(rect.size.x, rect.size.y * .48) / BATTLE_DESIGN)); shell.add_child(choice)
	elif kind == "attach":
		var card := RULES.card(str(pending.get("card_id", ""))); var equip_slot := str(card.get("equipment_slot", "")); var equipment_name := str(card.get("name", "Equipment")); var slot_copy := equip_slot.capitalize(); _add_status(shell, "%s complete · choose a compatible living print." % equipment_name)
		var held := PanelContainer.new(); held.name = "UnifiedHeldEquipmentToken"; _place_on_battle_chassis(shell, held, Rect2(.23, .865, .49, .05)); held.add_theme_stylebox_override("panel", shell.panel_style(Color("243d4ee8"), Color("f1be69"))); var held_copy: Label = shell.label("Held: %s · Compatible: %s socket" % [equipment_name, slot_copy], 10, Color("fff0bb")); held_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; held.add_child(held_copy); shell.add_child(held)
		for slot in 3:
			var unit = active.slots[slot]; var compatible := unit != null and (unit.get("equipment", {}).get(equip_slot, {}) as Dictionary).is_empty()
			if not compatible: continue
			var rect: Rect2 = source.player_slots[slot]; var choice: Button = shell.make_button("", shell._submit_required_battle_decision.bind({"type":"attach_completed","slot":slot}), Color("a86b2e")); choice.name = "UnifiedPendingAttachSlot%d" % (slot + 1); choice.accessibility_name = "Attach %s to compatible %s socket" % [equipment_name, slot_copy]; choice.custom_minimum_size = Vector2(48,48); _place_on_battle_chassis(shell, choice, Rect2(Vector2(rect.position.x, rect.position.y + rect.size.y * .35) / BATTLE_DESIGN, Vector2(rect.size.x, rect.size.y * .35) / BATTLE_DESIGN))
			for state_name in ["normal", "hover", "pressed", "disabled"]: choice.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
			choice.add_theme_stylebox_override("focus", _anchor_focus_style())
			shell.add_child(choice)
	else:
		var hand: Array = active.get("hand", []); var count := hand.size() - 8; _add_status(shell, "Discard exactly %d cards to continue." % count)
		var signature := "%d:%s" % [int(shell.unified_battle_coordinator.state.revision), ",".join(hand)]
		if signature != _overflow_signature: _overflow_selected.clear(); _overflow_signature = signature
		var rail := ScrollContainer.new(); rail.name = "UnifiedOverflowChoices"; rail.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; rail.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _place_on_battle_chassis(shell, rail, Rect2(.21, .865, .54, .06)); shell.add_child(rail)
		var row := HBoxContainer.new(); rail.add_child(row)
		_overflow_selected = _overflow_selected.filter(func(index): return index >= 0 and index < hand.size())
		var rail_width_px := _battle_chassis_rect(shell, Rect2(.21, .865, .54, .06)).size.x
		var separation_px := 4.0
		var large_text := int(shell.settings().get("text_scale_bps", 10000)) >= 15000
		var item_width := maxi(48, floori(rail_width_px) if large_text else floori((rail_width_px - separation_px) / 2.0))
		row.add_theme_constant_override("separation", int(separation_px))
		for index in hand.size():
			var id := str(hand[index]); var selected := index in _overflow_selected
			var toggle: Button = shell.make_button(("✓ " if selected else "○ ") + str(RULES.card(id).get("name", id)) + " #%d" % (index + 1), _toggle_overflow.bind(index, shell), Color("588d73") if selected else Color("526e93")); toggle.custom_minimum_size = Vector2(item_width,48); row.add_child(toggle)
		var chosen: Array = []
		for index in _overflow_selected:
			chosen.append(hand[index])
		var confirm: Button = shell.make_button("Discard %d / %d" % [_overflow_selected.size(), count], shell._submit_overflow_discard.bind(chosen), Color("a86b2e")); confirm.name = "UnifiedOverflowDiscardExact"; confirm.disabled = _overflow_selected.size() != count; confirm.custom_minimum_size = Vector2(116,56); _place_on_battle_chassis(shell, confirm, Rect2(.76, .93, .20, .06)); shell.add_child(confirm)

func _toggle_overflow(index: int, shell: Control) -> void:
	if index in _overflow_selected: _overflow_selected.erase(index)
	else: _overflow_selected.append(index)
	shell.render()

func _add_plate(shell: Control, rect: Rect2, caption: String, action: Callable, button_caption: String, color: Color) -> PanelContainer:
	var plate := PanelContainer.new(); _place_on_battle_chassis(shell, plate, rect); plate.z_index = 20; plate.clip_contents = true
	var plate_style: StyleBox = shell.panel_style(Color("102940e8"), color)
	plate_style.content_margin_left = 14.0; plate_style.content_margin_right = 14.0; plate_style.content_margin_top = 12.0; plate_style.content_margin_bottom = 12.0
	plate.add_theme_stylebox_override("panel", plate_style); shell.add_child(plate)
	var box := VBoxContainer.new(); box.name = "ChallengePlateContent"; box.add_theme_constant_override("separation", 10); plate.add_child(box)
	var text: Label = shell.label(caption, 13, Color("fff0bb")); text.name = "ChallengePlateCaption"; text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text.custom_minimum_size = Vector2(0, 72); box.add_child(text)
	if not button_caption.is_empty(): var button: Button = shell.make_button(button_caption, action, color); button.custom_minimum_size = Vector2(0,48); box.add_child(button)
	return plate

func detach() -> void:
	if _stage != null and is_instance_valid(_stage) and _stage.get_parent() != null: _stage.get_parent().remove_child(_stage)

func dispose() -> void:
	# Route rebuilds intentionally detach this expensive stage for safe resume.
	# Only the Main owner teardown releases the detached node and its resources.
	if _stage != null and is_instance_valid(_stage):
		detach()
		_stage.free()
	_stage = null
	_overflow_selected.clear()
	_overflow_signature = ""
