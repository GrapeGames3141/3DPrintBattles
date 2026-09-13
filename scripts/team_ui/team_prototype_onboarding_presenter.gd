class_name TeamPrototypeOnboardingPresenter
extends RefCounted
## Owns Starter, Forge, and Grant composition. The shell retains navigation,
## persistence requests, and the persistent FirstPrintController.

const CollectionAuthority := preload("res://scripts/team_collection/team_collection_projection.gd")
const Physical := preload("res://scripts/ui/m1_physical_ui_component.gd")
const PrintCompositor := preload("res://scripts/team_ui/team_prototype_print_compositor.gd")
const FirstPrintController := preload("res://scripts/team_ui/team_prototype_first_print_controller.gd")
const FacingCache := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const Sequence := preload("res://scripts/ui/arcane_forge_sequence.gd")

const STARTER := "res://assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png"
const FORGE := "res://assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png"
const RECEIPT := "res://assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png"


func render_starter(shell: Variant) -> void:
	shell._background(STARTER)
	var choices: Array = CollectionAuthority.STARTERS
	var selected := str(choices[shell.chosen_index])
	var definition: Dictionary = shell._definition(selected)
	var blueprint := TextureRect.new()
	blueprint.texture = shell._blueprint_ink_texture(definition)
	blueprint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blueprint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	blueprint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	blueprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Physical.place_design(blueprint, Rect2(261, 278, 418, 418))
	shell._content.add_child(blueprint)
	var inspect: bool = shell.route == "starter_inspect"
	var element := _element_for(selected)
	shell._label("%s BLUEPRINT" % str(definition.get("name", selected.capitalize())).to_upper() if inspect else ("CHOOSE %s?" % str(definition.get("name", selected)).to_upper() if shell.starter_confirmation else "CHOOSE BLUEPRINT"), Rect2(245, 193, 451, 56), 30)
	shell._label(str(definition.get("name", selected.capitalize())), Rect2(247, 737, 448, 49), 30)
	if shell.starter_confirmation:
		var warning: Label = shell._label("Save not confirmed. Retry." if not shell.route_error.is_empty() else "This Blueprint choice cannot change.", Rect2(247, 790, 448, 50), 24)
		warning.name = "StarterSaveRetry" if not shell.route_error.is_empty() else "StarterConfirmationWarning"
		warning.accessibility_name = shell.route_error if not shell.route_error.is_empty() else warning.text
	elif inspect:
		shell._label("BLUEPRINT · %s" % element, Rect2(247, 790, 448, 50), 24)
		shell._label("NOT PRINTED · FREE VOUCHER", Rect2(247, 844, 448, 58), 22)
	else:
		shell._label("%s · COMMON" % element, Rect2(247, 796, 448, 42), 24)
		shell._label("VOUCHER · 0 FILAMENT", Rect2(247, 844, 448, 58), 22)
	if not shell.starter_confirmation and not inspect:
		var previous: Button = shell._button("", Rect2(25, 920, 183, 106), func(): shell.chosen_index = posmod(shell.chosen_index - 1, choices.size()); shell._render(), false, "binding")
		previous.accessibility_name = "Previous blueprint"
		previous.tooltip_text = "Previous blueprint"
		var next: Button = shell._button("", Rect2(733, 920, 183, 106), func(): shell.chosen_index = posmod(shell.chosen_index + 1, choices.size()); shell._render(), false, "binding")
		next.accessibility_name = "Next blueprint"
		next.tooltip_text = "Next blueprint"
	shell._back_at(Rect2(75, 1120, 266, 140), "Workshop")
	if not shell.starter_confirmation and not inspect:
		shell._button("INSPECT", Rect2(600, 1120, 266, 140), func(): shell.navigate("starter_inspect"), false)
	if inspect:
		shell._button("CHOOSE", Rect2(70, 1292, 800, 157), func(): shell.replace_route("starter"); shell._render(), false, "wide", true)
	elif shell.starter_confirmation:
		var choose_caption := "RETRY SAVE" if not shell.route_error.is_empty() else "CHOOSE BLUEPRINT"
		var choose: Button = shell._button(choose_caption, Rect2(70, 1292, 800, 157), func(): shell._choose_starter(selected), false, "wide", true)
		choose.name = "StarterChooseConfirm"
	else:
		shell._button("CHOOSE", Rect2(70, 1292, 800, 157), func(): shell._choose_starter(selected), false, "wide", true)


func render_forge(shell: Variant) -> void:
	shell._background(FORGE)
	shell._back_at(Rect2(29, 33, 134, 80), "Workshop")
	var collection: Dictionary = shell.cached_collection
	var voucher: Dictionary = collection.get("voucher", {})
	var starter_id := str(collection.get("starter_id", "cinderpaw"))
	var state := str(voucher.get("state", "none"))
	var guarantees: Array = CollectionAuthority.GUARANTEES.get(starter_id, []).duplicate()
	var left_id := str(guarantees[0]) if guarantees.size() > 0 else "aquafin"
	var right_id := str(guarantees[1]) if guarantees.size() > 1 else "mossmunk"
	shell._forge_dock(left_id, Rect2(127, 1065, 150, 150))
	shell._forge_dock(starter_id, Rect2(397, 1065, 150, 150))
	shell._forge_dock(right_id, Rect2(665, 1065, 150, 150))
	shell._label("%s\nPRINTED" % _short_id(left_id), Rect2(93, 1353, 224, 149), 27)
	shell._label("%s\nPRINTED" % _short_id(right_id), Rect2(626, 1353, 224, 149), 27)
	if state == "acknowledged":
		shell.replace_route("team")
		return
	if state == "settled":
		if shell.first_print != null and shell.first_print.sequence != null and str(shell.first_print.sequence.phase) != Sequence.AWAKENED:
			var resumed := PrintCompositor.new()
			shell._content.add_child(resumed)
			shell._forge_compositor = resumed
			shell._render_forge_print()
			shell._forge_action = shell._button("", Rect2(359, 1353, 224, 149), shell._forge_action_pressed, false, "wide", true)
			shell._update_forge_action()
			return
		shell.replace_route("grant")
		return
	if state == "available":
		var seed := PrintCompositor.new()
		shell._content.add_child(seed)
		seed.render_state(FacingCache.texture_for_creature(starter_id), FacingCache.safe_source_region_for_creature(starter_id, FacingCache.raw_frame_for_creature(starter_id, 1)), shell._forge_source_root(starter_id), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 0, 0, Vector2.ZERO, bool(shell.settings_draft.reduced_motion), true, 1.0, {"guide":Rect2(145, 359, 490, 139), "head":Rect2(421, 332, 78, 163), "tracking":false})
		shell._forge_action = shell._button("START\nFREE PRINT", Rect2(359, 1353, 224, 149), shell._begin_print, false, "wide", true)
		if shell.first_print != null and not str(shell.first_print.begin_error).is_empty():
			shell._forge_action.text = "SAVE FAILED\nRETRY START"
		return
	var compositor := PrintCompositor.new()
	shell._content.add_child(compositor)
	shell._forge_compositor = compositor
	if shell.first_print == null:
		shell.first_print = FirstPrintController.new()
		shell.first_print.configure(shell.runtime, collection, bool(shell.settings_draft.reduced_motion))
	shell._render_forge_print()
	if state == "printing":
		shell._forge_action = shell._button("", Rect2(359, 1353, 224, 149), shell._forge_action_pressed, false, "wide", true)
		shell._update_forge_action()


func render_grant(shell: Variant) -> void:
	shell._background(RECEIPT)
	shell._back_at(Rect2(25, 22, 118, 100), "Workshop")
	var receipt: Dictionary = shell.cached_collection.get("grant_receipt", {})
	var starter_id := str(receipt.get("starter_id", shell.cached_collection.get("starter_id", "cinderpaw")))
	var granted := [starter_id]
	for guarantee in CollectionAuthority.GUARANTEES.get(starter_id, []):
		granted.append(str(guarantee))
	shell._label("STARTER READY", Rect2(230, 90, 480, 58), 34)
	shell._label("YOUR TEAM IS READY", Rect2(188, 355, 565, 58), 28)
	shell._label("1 starter printed · 2 commons team-ready · Support 15/15", Rect2(188, 425, 565, 130), 24)
	var cards := [Rect2(153.6, 833.6, 163.4, 145.5), Rect2(377.4, 833.6, 174.9, 145.5), Rect2(609.3, 833.6, 191.2, 145.5)]
	for index in mini(3, granted.size()):
		shell._grant_mini(str(granted[index]), cards[index], index == 0)
	shell._label("SUPPORT\n15 / 15", Rect2(210, 1016, 240, 180), 27)
	var acknowledged: Button = shell._button("CONTINUE\nTO TEAM", Rect2(616, 1300, 268, 300), shell._acknowledge_grant, false, "tall", true)
	acknowledged.name = "GrantContinue"
	if not shell.route_error.is_empty():
		acknowledged.text = "RETRY\nCONTINUE"
		acknowledged.tooltip_text = shell.route_error


func _element_for(id: String) -> String:
	match id:
		"cinderpaw": return "FIRE"
		"aquafin": return "WATER"
		"voltwig": return "LIGHTNING"
	return "COMMON"


func _short_id(id: String) -> String:
	match id:
		"cinderpaw": return "CINDER"
		"aquafin": return "AQUA"
		"voltwig": return "VOLT"
		"mossmunk": return "MOSS"
	return id.to_upper()
