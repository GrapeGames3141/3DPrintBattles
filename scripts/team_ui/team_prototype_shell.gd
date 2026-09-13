class_name TeamPrototypeShell
extends Control
## Native Collection vertical slice. The shell never derives rules: every durable
## change is an explicit TeamPrototypeRuntime request and every route read is cached.

const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const CollectionAuthority := preload("res://scripts/team_collection/team_collection_projection.gd")
const Physical := preload("res://scripts/ui/m1_physical_ui_component.gd")
const Controls := preload("res://scripts/ui/physical_control_family.gd")
const Navigation := preload("res://scripts/ui/physical_navigation_component.gd")
const Imprint := preload("res://scripts/ui/physical_catalog_imprint.gd")
const CardView := preload("res://scripts/ui/support_card_view.gd")
const BattleCatalog := preload("res://scripts/battle/battle_catalog.gd")
const V3Catalog := preload("res://scripts/core/v3_catalog.gd")
const PrintCompositor := preload("res://scripts/team_ui/team_prototype_print_compositor.gd")
const FirstPrintController := preload("res://scripts/team_ui/team_prototype_first_print_controller.gd")

const DESIGN := Vector2(941, 1672)
const WORKSHOP := "res://assets/ui/physical_ui/workshop-backplate-text-free-v1.png"
const STARTER := "res://assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png"
const FORGE := "res://assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png"
const TEAM := "res://assets/ui/team_prototype/TM-R1-team-support-workbench-text-free-v1.png"
const RECEIPT := "res://assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png"
const SETTINGS := "res://assets/ui/physical_ui/m3/ST-01-settings-instrument-text-free-v3.png"
const RECOVERY := "res://assets/ui/physical_ui/m3/SY-02-recovery-ledger-text-free-v2.png"

var runtime: Variant = null
var route := "workshop"
var route_stack: Array[String] = []
var cached_collection: Dictionary = {}
var settings_draft: Dictionary = {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":false}
var chosen_index := 0
var starter_confirmation := false
var draft_team: Array = []
var draft_priority: Array = []
var draft_kit: Dictionary = {}
var retained_requests: Dictionary = {}
var first_print: Variant = null
var _forge_compositor: Variant = null
var _forge_action: Button = null
var _stage: Control
var _content: Control

func configure_runtime(value: Variant) -> void:
	runtime = value
	_refresh_cache()
	_render()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.name = "PrototypeDesignStage"
	_stage.size = DESIGN
	add_child(_stage)
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_content)
	get_viewport().size_changed.connect(_fit)
	_fit()
	_render()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if route != "forge" or first_print == null or first_print.sequence == null:
		return
	var voucher: Dictionary = cached_collection.get("voucher", {})
	if str(first_print.sequence.phase) == ArcaneForgeSequence.AWAKENED:
		_refresh_cache()
		navigate("grant")
		return
	if str(first_print.sequence.phase) == ArcaneForgeSequence.FAILED:
		return
	var update: Dictionary = first_print.advance_delta(_delta, str(voucher.get("print_id", "")))
	if _forge_compositor != null:
		_render_forge_print()
	if str(update.get("phase", "")) == ArcaneForgeSequence.AWAKENED:
		_refresh_cache()
		navigate("grant")

func _notification(what: int) -> void:
	if first_print == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		first_print.set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		first_print.set_paused(false)

func _fit() -> void:
	if _stage == null:
		return
	var viewport := size
	var scale_factor := minf(viewport.x / DESIGN.x, viewport.y / DESIGN.y)
	_stage.scale = Vector2.ONE * scale_factor
	_stage.position = (viewport - DESIGN * scale_factor) * 0.5

func _clear() -> void:
	for child in _content.get_children():
		child.queue_free()

func _render() -> void:
	if not is_node_ready():
		return
	_clear()
	if runtime == null:
		_background(WORKSHOP)
		_label("Loading Collection…", Rect2(250, 760, 440, 64), 30)
		return
	if runtime.is_recovery():
		route = "recovery"
	match route:
		"workshop": _workshop()
		"starter", "starter_inspect": _starter()
		"forge": _forge()
		"grant": _grant()
		"team", "kit": _team()
		"settings": _settings()
		"recovery": _recovery()
		"preflight": _preflight()
		_: _workshop()

func _background(path: String) -> void:
	var image := TextureRect.new()
	image.texture = ResourceLoader.load(path) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(image)

func _label(text: String, rect: Rect2, font_size := 26, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", _scaled_font_size(font_size))
	label.add_theme_color_override("font_color", Color("172b3c"))
	label.add_theme_color_override("font_outline_color", Color("f4e6c4"))
	label.add_theme_constant_override("outline_size", 1)
	Physical.place_design(label, rect)
	_content.add_child(label)
	return label

func _button(caption: String, rect: Rect2, action: Callable, disabled := false, kind := "wide") -> Button:
	var button := Button.new()
	button.text = caption
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_ALL
	button.tooltip_text = caption
	button.accessibility_name = caption
	button.add_theme_font_size_override("font_size", _scaled_font_size(27))
	Physical.place_design(button, rect)
	Controls.apply(button, kind, false, true)
	Physical.add_inset_button_focus_ring(button, bool(settings_draft.high_contrast))
	button.pressed.connect(action)
	_content.add_child(button)
	return button


func _scaled_font_size(base_size: int) -> int:
	return roundi(float(base_size) * (1.5 if int(settings_draft.get("text_scale_bps", 10000)) == 15000 else 1.0))

func _back(destination := "Workshop") -> void:
	var button := _button("BACK", Rect2(29, 33, 134, 80), back, false, "binding")
	Navigation.configure_back(button, destination, Vector2(78, 78), true)

func _workshop() -> void:
	_background(WORKSHOP)
	_label("WORKSHOP", Rect2(280, 75, 380, 60), 34)
	_button("FORGE", Rect2(148, 555, 280, 160), func(): navigate("forge"), false, "tall")
	_button("TEAM", Rect2(56, 248, 120, 192), func(): navigate("team"), false, "tall")
	_button("SUPPORT KIT", Rect2(416, 248, 118, 145), func(): navigate("kit"), false, "tall")
	_button("BATTLE PREFLIGHT", Rect2(414, 405, 134, 119), func(): navigate("preflight"), false, "tall")
	_button("SETTINGS", Rect2(180, 764, 216, 200), func(): navigate("settings"), false, "tall")

func _starter() -> void:
	_background(STARTER)
	var choices: Array = CollectionAuthority.STARTERS
	var selected := str(choices[chosen_index])
	var definition: Dictionary = _definition(selected)
	var blueprint := TextureRect.new()
	blueprint.texture = Imprint.blueprint_texture(definition)
	blueprint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blueprint.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	Physical.place_design(blueprint, Rect2(261, 278, 418, 418))
	_content.add_child(blueprint)
	_label("CHOOSE A BLUEPRINT", Rect2(245, 193, 451, 56), 30)
	_label(str(definition.get("name", selected.capitalize())), Rect2(247, 737, 448, 49), 30)
	_label("STARTER · COMMON", Rect2(247, 796, 448, 42), 24)
	_label("VOUCHER COST · 0 FILAMENT", Rect2(247, 850, 448, 42), 22)
	_button("PREVIOUS", Rect2(25, 920, 183, 106), func(): chosen_index = posmod(chosen_index - 1, choices.size()); _render(), false, "binding")
	_button("NEXT", Rect2(733, 920, 183, 106), func(): chosen_index = posmod(chosen_index + 1, choices.size()); _render(), false, "binding")
	_back("Workshop")
	_button("INSPECT", Rect2(600, 1120, 266, 140), func(): route = "starter_inspect"; _render(), false)
	_button("CHOOSE BLUEPRINT" if starter_confirmation else "CHOOSE", Rect2(70, 1292, 800, 157), func(): _choose_starter(selected), false)
	if starter_confirmation:
		_label("Choose %s as your first companion?" % str(definition.get("name", selected)), Rect2(220, 1050, 500, 52), 24)
	if route == "starter_inspect":
		_label("%s is an eligible starter blueprint. Choosing it binds one free print." % str(definition.get("name", selected)), Rect2(160, 1020, 620, 80), 24)

func _forge() -> void:
	_background(FORGE)
	_back("Workshop")
	var collection := cached_collection
	var voucher: Dictionary = collection.get("voucher", {})
	var starter_id := str(collection.get("starter_id", "cinderpaw"))
	var state := str(voucher.get("state", "none"))
	var guarantees: Array = CollectionAuthority.GUARANTEES.get(starter_id, []).duplicate()
	var left_id := str(guarantees[0]) if guarantees.size() > 0 else "aquafin"
	var right_id := str(guarantees[1]) if guarantees.size() > 1 else "mossmunk"
	_forge_dock(left_id, Rect2(127, 1065, 150, 150))
	_forge_dock(starter_id, Rect2(397, 1065, 150, 150))
	_forge_dock(right_id, Rect2(665, 1065, 150, 150))
	_label("%s\nALREADY PRINTED" % left_id.to_upper(), Rect2(93, 1353, 224, 149), 27)
	_label("%s\nALREADY PRINTED" % right_id.to_upper(), Rect2(626, 1353, 224, 149), 27)
	if state == "acknowledged":
		navigate("workshop")
		return
	if state == "settled":
		if first_print != null and first_print.sequence != null and str(first_print.sequence.phase) != ArcaneForgeSequence.AWAKENED:
			var resumed_compositor := PrintCompositor.new()
			_content.add_child(resumed_compositor)
			_forge_compositor = resumed_compositor
			_render_forge_print()
			_forge_action = _button("", Rect2(359, 1353, 224, 149), _forge_action_pressed, false)
			_update_forge_action()
			return
		navigate("grant")
		return
	if state == "available":
		var seed_compositor := PrintCompositor.new()
		_content.add_child(seed_compositor)
		seed_compositor.render_state(BattleFacingSpriteCache.texture_for_creature(starter_id), BattleFacingSpriteCache.safe_source_region_for_creature(starter_id, BattleFacingSpriteCache.raw_frame_for_creature(starter_id, 1)), _forge_source_root(starter_id), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 0, 0, Vector2.ZERO, bool(settings_draft.reduced_motion), true, 1.0, {"guide":Rect2(145, 359, 490, 139), "head":Rect2(421, 332, 78, 163), "tracking":false})
		_forge_action = _button("START\nFREE PRINT", Rect2(359, 1353, 224, 149), _begin_print, false)
		if first_print != null and not str(first_print.begin_error).is_empty():
			_forge_action.text = "SAVE FAILED\nRETRY START"
		return
	var compositor := PrintCompositor.new()
	_content.add_child(compositor)
	_forge_compositor = compositor
	if first_print == null:
		first_print = FirstPrintController.new()
		first_print.configure(runtime, collection, bool(settings_draft.reduced_motion))
	_render_forge_print()
	if state == "printing":
		_forge_action = _button("", Rect2(359, 1353, 224, 149), _forge_action_pressed, false)
		_update_forge_action()


func _forge_action_pressed() -> void:
	if first_print == null or first_print.sequence == null:
		return
	if str(first_print.sequence.phase) == ArcaneForgeSequence.RAW_COMPLETE:
		_retry_complete()
		return
	if first_print.sequence.skip():
		_render_forge_print()
		_update_forge_action()


func _update_forge_action() -> void:
	if _forge_action == null or first_print == null or first_print.sequence == null:
		return
	var starter_id := str(cached_collection.get("starter_id", "cinderpaw")).to_upper()
	var phase := str(first_print.sequence.phase)
	_forge_action.disabled = false
	_forge_action.mouse_filter = Control.MOUSE_FILTER_STOP
	_forge_action.focus_mode = Control.FOCUS_ALL
	if phase == ArcaneForgeSequence.PRINTING:
		_forge_action.text = "%s\nPRINTING %d%%\nSKIP" % [starter_id, roundi(float(first_print.sequence.layer_reveal_bps()) / 100.0)]
	elif phase == ArcaneForgeSequence.RAW_COMPLETE:
		if not str(first_print.save_error).is_empty():
			_forge_action.text = "SAVE FAILED\nRETRY SAVE"
		else:
			_forge_action.text = "SAVING PRINT"
			_forge_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_forge_action.focus_mode = Control.FOCUS_NONE
	elif phase == ArcaneForgeSequence.RAW_HOLD:
		_forge_action.text = "%s\nRAW COMPLETE\nSKIP" % starter_id
	elif phase == ArcaneForgeSequence.AWAKENING:
		_forge_action.text = "%s\nAWAKENING\nSKIP" % starter_id
	elif phase == ArcaneForgeSequence.DEPARTING:
		_forge_action.text = "%s\nJOINING TEAM" % starter_id
		_forge_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_forge_action.focus_mode = Control.FOCUS_NONE
	else:
		_forge_action.text = "AWAKENED"
		_forge_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_forge_action.focus_mode = Control.FOCUS_NONE

func _grant() -> void:
	_background(RECEIPT)
	_back("Workshop")
	var receipt: Dictionary = cached_collection.get("grant_receipt", {})
	_label("STARTER READY", Rect2(230, 90, 480, 58), 34)
	_label("YOUR TEAM IS READY", Rect2(188, 355, 565, 58), 28)
	_label("1 starter printed · 2 commons team-ready · Support 15/15", Rect2(188, 425, 565, 130), 24)
	for index in 3:
		_label([str(receipt.get("starter_id", "Cinderpaw")), "Aquafin", "Mossmunk"][index].to_upper(), Rect2(154 + index * 228, 834, 163, 146), 20)
	_button("READY TO BATTLE", Rect2(616, 1300, 268, 300), _acknowledge_grant, false, "tall")

func _team() -> void:
	_background(TEAM)
	_back("Workshop")
	var kit_mode := route == "kit"
	_label("SUPPORT KIT" if kit_mode else "BUILD YOUR TEAM", Rect2(133, 534, 674, 43), 28)
	if draft_team.is_empty():
		_load_draft()
	if kit_mode:
		_render_kit()
	else:
		_render_team()
	_button("APPLY", Rect2(105, 1358, 350, 110), _apply_draft, not _draft_valid())
	_button("CANCEL", Rect2(500, 1358, 350, 110), func(): _load_draft(); back(), false)

func _render_team() -> void:
	for index in mini(3, draft_team.size()):
		var member := str(draft_team[index])
		var bay_x: int = int([39, 332, 627][index])
		var portrait := TextureRect.new()
		portrait.texture = Imprint.blueprint_texture(_definition(member))
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Physical.place_design(portrait, Rect2(bay_x + 42, 270, 112, 145))
		_content.add_child(portrait)
		_label("%s\n%s" % [member.capitalize(), "ACTIVE-FIRST" if index == 0 else "RESERVE %d" % index], Rect2(bay_x + 12, 410, 190, 64), 20)
		_label("%d. %s" % [index + 1, member.capitalize()], Rect2(160, 600 + index * 92, 520, 68), 25, HORIZONTAL_ALIGNMENT_LEFT)
		_button("↑", Rect2(700, 600 + index * 92, 86, 68), func(): _move_priority(index), index == 0, "square")
	_label("Three unique printed companions. Priority sets reserve order.", Rect2(140, 895, 660, 42), 20)

func _render_kit() -> void:
	var supports: Array = CollectionAuthority.SUPPORTS
	for index in supports.size():
		var support := str(supports[index])
		var count := int(draft_kit.get(support, 0))
		_label("%s × %d" % [support.replace("_", " ").capitalize(), count], Rect2(150, 590 + index * 65, 420, 56), 22, HORIZONTAL_ALIGNMENT_LEFT)
		_button("−", Rect2(590, 590 + index * 65, 76, 56), func(): _adjust_kit(support, -1), count <= 0, "square")
		_button("+", Rect2(680, 590 + index * 65, 76, 56), func(): _adjust_kit(support, 1), _kit_total() >= 15, "square")
		if index < 4:
			var card := CardView.new()
			card.configure(V3Catalog.card(support), count, "", false, true, true)
			Physical.place_design(card, Rect2(72 + index * 149, 1042, 139, 248))
			_content.add_child(card)
	_label("Kit %d / 15" % _kit_total(), Rect2(150, 925, 360, 48), 24, HORIZONTAL_ALIGNMENT_LEFT)
	_button("RESTORE", Rect2(650, 915, 150, 64), func(): draft_kit = cached_collection.get("recommended_kit", {}).duplicate(true); _render(), false)

func _settings() -> void:
	_background(SETTINGS)
	_back("Workshop")
	_label("SETTINGS", Rect2(210, 120, 520, 60), 32)
	_button("TEXT %d%%" % (int(settings_draft.text_scale_bps) / 100), Rect2(210, 180, 290, 140), func(): settings_draft.text_scale_bps = 15000 if int(settings_draft.text_scale_bps) == 10000 else 10000; _render(), false, "square")
	_button("HIGH CONTRAST: %s" % ("ON" if bool(settings_draft.high_contrast) else "OFF"), Rect2(210, 756, 610, 140), func(): settings_draft.high_contrast = not bool(settings_draft.high_contrast); _render(), false)
	_button("REDUCED MOTION: %s" % ("ON" if bool(settings_draft.reduced_motion) else "OFF"), Rect2(210, 920, 610, 140), func(): settings_draft.reduced_motion = not bool(settings_draft.reduced_motion); _render(), false)
	_button("APPLY", Rect2(447, 1500, 360, 130), _apply_settings, false)

func _recovery() -> void:
	_background(RECOVERY)
	_label("RECOVERY REQUIRED", Rect2(95, 290, 752, 80), 34)
	_label("%s\nThis prototype is read-only until the stored files are reviewed." % runtime.view().recovery, Rect2(95, 370, 752, 150), 24)
	_button("BACK", Rect2(157, 1280, 288, 149), back, false)

func _preflight() -> void:
	_background(WORKSHOP)
	_back("Workshop")
	var match: Dictionary = runtime.view().get("match", {})
	_label("BATTLE PREFLIGHT", Rect2(200, 650, 540, 70), 34)
	_label("%s" % ("Resume Battle is available." if bool(match.get("resume", false)) else "Apply a valid Team and Support Kit before starting."), Rect2(160, 750, 620, 100), 26)

func navigate(next: String) -> void:
	if route != next:
		route_stack.append(route)
		route = next
	_render()

func back() -> void:
	if route == "forge" and str(cached_collection.get("voucher", {}).get("state", "")) == "settled":
		# A durable completion reopens as its existing receipt. It never restarts
		# a local presentation or submits Complete a second time.
		first_print = null
	if route in ["team", "kit"]:
		_load_draft()
	if route_stack.is_empty():
		route = "workshop"
	else:
		route = route_stack.pop_back()
	_render()

func _refresh_cache() -> void:
	if runtime == null:
		return
	cached_collection = runtime.collection_view()
	settings_draft = runtime.settings_view()

func _request(action: String, payload: Dictionary) -> Dictionary:
	var request_id := str(retained_requests.get(action, "ui-%s-%d" % [action, Time.get_ticks_msec()]))
	retained_requests[action] = request_id
	var result: Dictionary = runtime.collection_request(action, request_id, payload)
	if bool(result.get("ok", false)):
		_refresh_cache()
	return result

func _choose_starter(id: String) -> void:
	if not starter_confirmation:
		starter_confirmation = true
		_render()
		return
	if bool(_request("choose_starter", {"starter_id":id}).get("ok", false)):
		starter_confirmation = false
		navigate("forge")

func _begin_print() -> void:
	if first_print == null:
		first_print = FirstPrintController.new()
		first_print.configure(runtime, cached_collection, bool(settings_draft.reduced_motion))
	var result: Dictionary = first_print.start()
	if bool(result.get("ok", false)):
		_refresh_cache()
		_render()
	elif _forge_action != null:
		_forge_action.text = "SAVE FAILED\nRETRY START"
		_forge_action.tooltip_text = str(result.get("error", "First Print could not be saved."))

func _retry_complete() -> void:
	var print_id := str(cached_collection.get("voucher", {}).get("print_id", ""))
	if bool(first_print.retry(print_id).get("ok", false)):
		_refresh_cache()
		_render()

func _render_forge_print() -> void:
	if _forge_compositor == null or first_print == null or first_print.sequence == null:
		return
	var creature := str(cached_collection.get("starter_id", "cinderpaw"))
	var phase := str(first_print.sequence.phase)
	var blend := 0
	var departure := Vector2.ZERO
	if phase == ArcaneForgeSequence.AWAKENING:
		blend = first_print.sequence.phase_progress_bps()
	elif phase == ArcaneForgeSequence.DEPARTING:
		var depart_progress := float(first_print.sequence.phase_progress_bps()) / 10000.0
		blend = 10000
		var eased := depart_progress * depart_progress * (3.0 - 2.0 * depart_progress)
		departure = Vector2(30.0 * eased, 110.0 * eased)
	elif phase == ArcaneForgeSequence.AWAKENED:
		blend = 10000
	var presentation_visible := phase != ArcaneForgeSequence.AWAKENED
	var presentation_opacity := 1.0
	if phase == ArcaneForgeSequence.DEPARTING:
		var fade_progress := float(first_print.sequence.phase_progress_bps()) / 10000.0
		presentation_opacity = 1.0 - clampf((fade_progress - 0.60) / 0.40, 0.0, 1.0)
	_forge_compositor.render_state(BattleFacingSpriteCache.texture_for_creature(creature), BattleFacingSpriteCache.safe_source_region_for_creature(creature, BattleFacingSpriteCache.raw_frame_for_creature(creature, 1)), _forge_source_root(creature), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), first_print.sequence.layer_reveal_bps(), blend, departure, bool(settings_draft.reduced_motion), presentation_visible, presentation_opacity, {"guide":Rect2(145, 359, 490, 139), "head":Rect2(421, 332, 78, 163), "tracking":phase == ArcaneForgeSequence.PRINTING})
	_update_forge_action()

func _forge_source_root(creature: String) -> Vector2:
	match creature:
		"cinderpaw": return Vector2(190, 473)
		"aquafin": return Vector2(190, 485)
		"voltwig": return Vector2(190, 453)
		"mossmunk": return Vector2(190, 484)
	return Vector2(190, 473)

func _forge_dock(creature: String, rect: Rect2) -> void:
	var ink := TextureRect.new()
	ink.texture = Imprint.blueprint_texture(_definition(creature))
	ink.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ink.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ink.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var ink_material := ShaderMaterial.new()
	ink_material.shader = Imprint.INK_SHADER
	ink_material.set_shader_parameter("ink_strength", 1.0)
	ink_material.set_shader_parameter("ink_tint", Color("402313"))
	ink.material = ink_material
	Physical.place_design(ink, rect)
	_content.add_child(ink)

func _acknowledge_grant() -> void:
	var receipt_id := str(cached_collection.get("voucher", {}).get("receipt_id", ""))
	if bool(_request("acknowledge_grant", {"receipt_id":receipt_id}).get("ok", false)):
		_load_draft()
		navigate("team")

func _load_draft() -> void:
	var saved: Dictionary = cached_collection.get("saved_loadout", {})
	draft_team = (saved.get("team", cached_collection.get("recommended_team", [])) as Array).duplicate()
	draft_priority = (saved.get("priority", draft_team) as Array).duplicate()
	draft_kit = (saved.get("kit", cached_collection.get("recommended_kit", {})) as Dictionary).duplicate(true)

func _move_priority(index: int) -> void:
	if index > 0:
		var member: Variant = draft_team.pop_at(index)
		draft_team.insert(index - 1, member)
		draft_priority = draft_team.duplicate()
		_render()

func _adjust_kit(id: String, delta: int) -> void:
	draft_kit[id] = clampi(int(draft_kit.get(id, 0)) + delta, 0, 15)
	_render()

func _kit_total() -> int:
	var total := 0
	for value in draft_kit.values(): total += int(value)
	return total

func _draft_valid() -> bool:
	return runtime != null and bool(runtime.preview_loadout(draft_team, draft_priority, draft_kit).get("ok", false))

func _apply_draft() -> void:
	if bool(_request("apply_loadout", {"team":draft_team, "priority":draft_priority, "kit":draft_kit}).get("ok", false)):
		navigate("workshop")

func _apply_settings() -> void:
	if bool(runtime.apply_settings(settings_draft).get("ok", false)):
		_refresh_cache()
		back()

func _definition(id: String) -> Dictionary:
	return BattleCatalog.creature(id)
