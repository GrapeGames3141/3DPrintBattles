class_name TeamPrototypeCollectionPresenter
extends RefCounted
## Route composition for Team and Support Kit. Draft transitions stay with the shell.

const TEAM_MASTER := "res://assets/ui/team_prototype/TM-R1-team-support-workbench-text-free-v1.png"
const Navigation := preload("res://scripts/ui/physical_navigation_component.gd")
const CollectionAuthority := preload("res://scripts/team_collection/team_collection_projection.gd")
const TeamData := preload("res://scripts/team_battle/team_battle_data.gd")


func render(shell: Variant, kit_mode: bool) -> void:
	shell._background(TEAM_MASTER)
	var back_button: Button = shell._button("BACK", Rect2(134, 158, 250, 80), shell.back, false, "binding")
	back_button.name = "RouteBack"
	Navigation.configure_back(back_button, "Workshop", Vector2.ONE * shell._minimum_design_hit(), true)
	if shell.draft_team.is_empty():
		shell._load_draft()
	if kit_mode:
		render_kit(shell)
	else:
		render_team(shell)
	if not shell.route_error.is_empty():
		var save_retry: Label = shell._label("Save not confirmed. Retry.", Rect2(133, 760, 674, 44), 24)
		save_retry.name = "CollectionSaveRetry"
		save_retry.accessibility_name = shell.route_error
	if not shell.modal.is_empty():
		render_modal(shell)
		return
	var validation: Dictionary = shell.runtime.preview_loadout(shell.draft_team, shell.draft_priority, shell.draft_kit)
	var apply_caption := "RETRY APPLY" if not shell.route_error.is_empty() else "APPLY"
	var apply: Button = shell._button(apply_caption, Rect2(105, 1358, 350, 110), shell._apply_draft, not bool(validation.get("ok", false)), "wide", true)
	apply.name = "CollectionApply"
	apply.tooltip_text = str(validation.get("error", "Apply Team and Support Kit"))
	shell._button("CANCEL", Rect2(500, 1358, 350, 110), func(): shell._load_draft(); shell.back(), false).name = "CollectionCancel"


func render_team(shell: Variant) -> void:
	shell._label("TEAM", Rect2(557, 158, 237, 80), 27)
	var enlarged := int(shell.settings_draft.get("text_scale_bps", 10000)) == 15000
	var bays := [Rect2(122.54, 284.23, 104.54, 140.50), Rect2(414.95, 284.23, 104.54, 140.50), Rect2(704.72, 284.23, 104.54, 140.50)]
	var roots := [Vector2(174.81, 417.6), Vector2(467.22, 417.6), Vector2(756.99, 417.6)]
	var captions := [Rect2(78.4, 428.29, 204.27, 47), Rect2(369.61, 428.29, 204.27, 47), Rect2(661.14, 428.29, 205.9, 47)]
	for index in 3:
		var member := str(shell.draft_team[index]) if index < shell.draft_team.size() else ""
		var bay: Button = shell._button("", bays[index], func(): shell._open_team_slot(index), false, "binding")
		bay.name = "TeamBay%d" % index
		bay.accessibility_name = "%s, Team slot %d" % [shell._support_name(member), index + 1] if not member.is_empty() else "Empty Team slot %d" % (index + 1)
		if member.is_empty():
			shell._label("EMPTY", captions[index], 24)
			continue
		shell._team_mini(member, roots[index])
		shell._label(shell._grant_token(member) if enlarged else member.capitalize(), captions[index], 26 if enlarged else 27)
	if shell.modal.is_empty():
		var first_to_print := str(shell.draft_priority[0]).capitalize() if not shell.draft_priority.is_empty() else "Choose Team"
		if enlarged:
			shell._label("PRINT ORDER", Rect2(130.69, 534.37, 679.97, 43), 26)
			var priority_label := ("%s FIRST" % shell._grant_token(str(shell.draft_priority[0]))) if not shell.draft_priority.is_empty() else "CHOOSE FIRST"
			var priority: Button = shell._button(priority_label, Rect2(127.42, 591.55, 686.51, 50), shell._open_priority, false, "wide")
			priority.name = "TeamPriority"
			shell._label("TEAM %d / 3 · UNIQUE" % shell.draft_team.size(), Rect2(133.02, 676.25, 673.39, 50), 26)
			if shell.route_error.is_empty():
				shell._label("SUPPORT %d / 15" % shell._kit_total(), Rect2(133.02, 761.18, 673.39, 50), 26)
		else:
			shell._button("PRINT ORDER\n%s FIRST" % first_to_print, Rect2(127.42, 591.55, 686.51, 92), shell._open_priority, false, "wide").name = "TeamPriority"
			shell._label("Team %d/3 · Choose 3 unique Printed companions" % shell.draft_team.size(), Rect2(133, 680, 674, 44), 24)
		render_support_context(shell)


func render_support_context(shell: Variant) -> void:
	var supports: Array = CollectionAuthority.SUPPORTS
	var enlarged := int(shell.settings_draft.get("text_scale_bps", 10000)) == 15000
	for index in mini(4, supports.size()):
		var support := str(supports[index])
		var x: float = [72.0, 221.0, 372.0, 524.0][index]
		shell._support_art(support, Rect2(x, 1056, 139, 105))
		shell._label(shell._support_token(support) if enlarged else shell._support_name(support), Rect2(x, 1162.5, 139, 49 if enlarged else 55), 26 if enlarged else 24)
		shell._label("%d / %d" % [int(shell.draft_kit.get(support, 0)), int(shell.cached_collection.get("support_counts", {}).get(support, 0))], Rect2(x, 1217.5, 139, 49 if enlarged else 34), 26 if enlarged else 24)
	if not enlarged and shell.route_error.is_empty():
		shell._label("SUPPORT %d / 15" % shell._kit_total(), Rect2(133, 732, 674, 42), 24)


func render_kit(shell: Variant) -> void:
	var enlarged := int(shell.settings_draft.get("text_scale_bps", 10000)) == 15000
	shell._label("KIT" if enlarged else "SUPPORT KIT", Rect2(557, 158, 237, 80), 24)
	if not shell.modal.is_empty():
		return
	var supports: Array = CollectionAuthority.SUPPORTS
	var start: int = shell.kit_page * 4
	var chip_rects := [Rect2(71.88, 1042.5, 138.88, 248.4), Rect2(220.58, 1042.5, 143.78, 248.4), Rect2(372.48, 1042.5, 143.78, 248.4), Rect2(524.38, 1042.5, 143.78, 248.4)]
	for slot in 4:
		var support_index: int = start + slot
		if support_index >= supports.size():
			continue
		var support := str(supports[support_index])
		var chip: Button = shell._button("", chip_rects[slot], func(): shell._open_support_inspector(support), false, "binding")
		chip.name = "SupportChip_%s" % support
		chip.accessibility_name = "%s, %d selected of %d owned" % [shell._support_name(support), int(shell.draft_kit.get(support, 0)), int(shell.cached_collection.get("support_counts", {}).get(support, 0))]
		shell._support_art(support, Rect2(chip_rects[slot].position.x, 1055.57, chip_rects[slot].size.x, 104.54))
		var token: String = shell._support_token(support) if enlarged else shell._support_name(support)
		shell._label(token, Rect2(chip_rects[slot].position.x, 1162.5, chip_rects[slot].size.x, 49 if enlarged else 55), 26 if enlarged else 27)
		shell._label("%d / %d" % [int(shell.draft_kit.get(support, 0)), int(shell.cached_collection.get("support_counts", {}).get(support, 0))], Rect2(chip_rects[slot].position.x, 1217.5, chip_rects[slot].size.x, 49 if enlarged else 34), 26 if enlarged else 24)
	if enlarged:
		shell._label("%d / 15 · PAGE %d / 2" % [shell._kit_total(), shell.kit_page + 1], Rect2(245, 880, 453, 92), 26)
	else:
		shell._label("Support %d / 15" % shell._kit_total(), Rect2(245, 880, 453, 44), 27)
		shell._label("Page %d / 2" % (shell.kit_page + 1), Rect2(245, 924, 453, 40), 24)
	var previous: Button = shell._button("‹", Rect2(133, 880, 92, 92), func(): shell.kit_page = max(shell.kit_page - 1, 0); shell._render(), shell.kit_page == 0, "square", false, false)
	previous.name = "KitPrevious"
	previous.accessibility_name = "Previous Support page"
	var next: Button = shell._button("›", Rect2(718, 880, 92, 92), func(): shell.kit_page = min(shell.kit_page + 1, 1); shell._render(), start + 4 >= supports.size(), "square", false, false)
	next.name = "KitNext"
	next.accessibility_name = "Next Support page"
	var recommended: Button = shell._button("✓" if enlarged else "RECOMMENDED", Rect2(715.58, 1228, 171.54, 80), shell._restore_recommended, false, "wide")
	recommended.name = "KitRecommended"
	recommended.accessibility_name = "Recommended Support Kit"
	# The magazine is an authored navy owner, unlike the surrounding parchment
	# cards. Keep its native label readable without adding opaque furniture.
	recommended.add_theme_color_override("font_color", Color("fff0c8"))
	recommended.add_theme_color_override("font_hover_color", Color("fff0c8"))
	recommended.add_theme_color_override("font_pressed_color", Color("ffffff"))
	recommended.add_theme_color_override("font_focus_color", Color("fff0c8"))
	recommended.add_theme_color_override("font_disabled_color", Color("fff0c8", 0.70))
	recommended.add_theme_color_override("font_outline_color", Color("1a0d04"))
	recommended.add_theme_constant_override("outline_size", 3 if enlarged else 2)
	shell._label("Owned Support stays in your collection.", Rect2(133, 680, 674, 44), 24)


func render_modal(shell: Variant) -> void:
	var enlarged := int(shell.settings_draft.get("text_scale_bps", 10000)) == 15000
	var original_back := shell._content.find_child("RouteBack", true, false) as Button
	var back_rect := Rect2(134, 158, 250, 80)
	if original_back != null:
		back_rect = original_back.get_meta("authored_rect", back_rect)
		original_back.visible = false
	for existing in shell._content.find_children("*", "Control", true, false):
		var control := existing as Control
		control.focus_mode = Control.FOCUS_NONE
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blocker := Control.new()
	blocker.name = "CollectionModalBlocker"
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell._content.add_child(blocker)
	var modal_back: Button = shell._button("BACK", back_rect, shell.back, false, "binding")
	modal_back.name = "RouteBackModal"
	Navigation.configure_back(modal_back, "Close sheet", Vector2.ONE * shell._minimum_design_hit(), true)
	if shell.modal == "team_slot":
		shell._label("CHOOSE A PRINTED COMPANION", Rect2(133, 534, 674, 43), 27)
		var printed: Dictionary = shell.cached_collection.get("printed_counts", {})
		var start: int = shell.modal_page * 3
		for local_index in 3:
			var index := start + local_index
			if index >= CollectionAuthority.MEMBERS.size():
				continue
			var member := str(CollectionAuthority.MEMBERS[index])
			var already_used: bool = shell.draft_team.find(member) >= 0 and (shell.modal_slot < 0 or str(shell.draft_team[shell.modal_slot]) != member)
			var eligible: bool = int(printed.get(member, 0)) > 0 and not already_used
			var reason := "Printed companion" if eligible else ("Already selected" if already_used else "Needs a completed Print")
			var short_reason := "PRINTED" if eligible else ("IN TEAM" if already_used else "NEEDS PRINT")
			var caption := "%s · %s" % [shell._grant_token(member), short_reason] if enlarged else "%s\n%s" % [shell._support_name(member).to_upper(), reason]
			var choice: Button = shell._button(caption, Rect2(133, 588 + local_index * 96, 674, 88), func(): shell._select_team_member(member), not eligible, "wide", false, false)
			choice.name = "TeamChoice_%s" % member
			choice.accessibility_name = "%s · %s" % [shell._support_name(member), reason]
		var previous: Button = shell._button("‹", Rect2(133, 880, 92, 92), func(): shell.modal_page = max(shell.modal_page - 1, 0); shell._render(), shell.modal_page == 0, "square", false, false)
		previous.name = "TeamChoicePrevious"
		previous.accessibility_name = "Previous companion page"
		var next: Button = shell._button("›", Rect2(718, 880, 92, 92), func(): shell.modal_page = min(shell.modal_page + 1, 1); shell._render(), start + 3 >= CollectionAuthority.MEMBERS.size(), "square", false, false)
		next.name = "TeamChoiceNext"
		next.accessibility_name = "Next companion page"
		shell._label("PAGE %d / 2" % (shell.modal_page + 1), Rect2(245, 880, 453, 92), 24)
	elif shell.modal == "priority":
		shell._label("PRINT ORDER", Rect2(133, 534, 674, 43), 27)
		var row_step := 90 if enlarged else 96
		var row_rect := Rect2(133, 588, 674 if enlarged else 450, 80 if enlarged else 88)
		for index in shell.draft_priority.size():
			var member := str(shell.draft_priority[index])
			var display_name: String = shell._grant_token(member) if enlarged else shell._support_name(member)
			var row: Button = shell._button("%d. %s" % [index + 1, display_name], Rect2(row_rect.position + Vector2(0, index * row_step), row_rect.size), func(): shell.modal_slot = index; shell._render(), false, "wide", false, false)
			row.name = "Priority_%s" % member
			row.accessibility_name = "%d. %s" % [index + 1, shell._support_name(member)]
		var move_rect_up := Rect2(150, 865, 250, 104) if enlarged else Rect2(608, 588, 177, 88)
		var move_rect_down := Rect2(541, 865, 250, 104) if enlarged else Rect2(608, 684, 177, 88)
		var move_up: Button = shell._button("MOVE UP", move_rect_up, func(): shell._move_priority(shell.modal_slot), shell.modal_slot <= 0, "wide", false, false)
		move_up.tooltip_text = "Already first in print order" if move_up.disabled else "Move selected companion earlier"
		move_up.accessibility_name = move_up.tooltip_text
		move_up.add_theme_color_override("font_disabled_color", Color("fff0c8"))
		var move_down: Button = shell._button("MOVE DOWN", move_rect_down, func(): shell._move_priority_down(shell.modal_slot), shell.modal_slot < 0 or shell.modal_slot >= shell.draft_priority.size() - 1, "wide", false, false)
		move_down.tooltip_text = "Already last in print order" if move_down.disabled else "Move selected companion later"
		move_down.accessibility_name = move_down.tooltip_text
		move_down.add_theme_color_override("font_disabled_color", Color("fff0c8"))
	elif shell.modal == "support" and not shell.selected_support.is_empty():
		var owned := int(shell.cached_collection.get("support_counts", {}).get(shell.selected_support, 0))
		var selected := int(shell.draft_kit.get(shell.selected_support, 0))
		shell._label(shell._support_name(shell.selected_support).to_upper(), Rect2(133, 534, 674, 43), 27)
		var effect_copy := _support_effect_copy(shell.selected_support)
		var details: Label = shell._label("Owned %d · Selected %d\n%s" % [owned, selected, effect_copy], Rect2(180, 622, 581, 110), 26)
		details.name = "SupportEffect_%s" % shell.selected_support
		details.accessibility_name = "%s. Owned %d. Selected %d. %s. Support remains in your collection." % [shell._support_name(shell.selected_support), owned, selected, effect_copy]
		shell._button("−", Rect2(150, 865, 250, 104), func(): shell._adjust_kit(shell.selected_support, -1), selected <= 0, "wide", false, false).name = "SupportMinus_%s" % shell.selected_support
		shell._button("+", Rect2(541, 865, 250, 104), func(): shell._adjust_kit(shell.selected_support, 1), selected >= owned or shell._kit_total() >= 15, "wide", false, false).name = "SupportPlus_%s" % shell.selected_support


func _support_effect_copy(support_id: String) -> String:
	var definition := TeamData.support_definition(support_id)
	if definition.is_empty():
		return "Unavailable Support"
	var cost := int(definition.get("cost", 0))
	match str(definition.get("kind", "")):
		"aid":
			return "Cost %d · Filament +%d" % [cost, int(definition.get("aid", 0))]
		"armor":
			return "Cost %d · Armor +%d · Print %d" % [cost, int(definition.get("effect", 0)), int(definition.get("work", 0))]
		"gem":
			return "Cost %d · Attack +%d · Print %d" % [cost, int(definition.get("effect", 0)), int(definition.get("work", 0))]
		"surge":
			var numerator := int(definition.get("numerator", 0))
			var denominator := maxi(int(definition.get("denominator", 1)), 1)
			return "Cost %d · Attack %d%%" % [cost, roundi(100.0 * float(numerator) / float(denominator))]
	return "Unavailable Support"
