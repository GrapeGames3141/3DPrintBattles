class_name TeamPrototypeShell
extends Control
## Native Collection vertical slice. The shell never derives rules: every durable
## change is an explicit TeamPrototypeRuntime request and every route read is cached.

const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Physical := preload("res://scripts/ui/m1_physical_ui_component.gd")
const Navigation := preload("res://scripts/ui/physical_navigation_component.gd")
const Imprint := preload("res://scripts/ui/physical_catalog_imprint.gd")
const CardView := preload("res://scripts/ui/support_card_view.gd")
const BattleCatalog := preload("res://scripts/battle/battle_catalog.gd")
const V3Catalog := preload("res://scripts/core/v3_catalog.gd")
const PrintCompositor := preload("res://scripts/team_ui/team_prototype_print_compositor.gd")
const FirstPrintController := preload("res://scripts/team_ui/team_prototype_first_print_controller.gd")
const Chassis := preload("res://scripts/team_ui/team_prototype_chassis.gd")
const Widgets := preload("res://scripts/team_ui/team_prototype_native_widgets.gd")
const SystemPresenter := preload("res://scripts/team_ui/team_prototype_system_presenter.gd")
const CollectionPresenter := preload("res://scripts/team_ui/team_prototype_collection_presenter.gd")
const OnboardingPresenter := preload("res://scripts/team_ui/team_prototype_onboarding_presenter.gd")

const DESIGN := Vector2(941, 1672)
const WORKSHOP := "res://assets/ui/physical_ui/workshop-backplate-text-free-v1.png"

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
var modal := ""
var modal_slot := -1
var modal_page := 0
var modal_return_focus := ""
var kit_page := 0
var selected_support := ""
var route_error := ""
var leave_confirmation := false
var recovery_details := false
var first_print: Variant = null
var _forge_compositor: Variant = null
var _forge_action: Button = null
var _stage: Control
var _content: Control
var _team_atlases: Dictionary = {}
var _blueprint_mipmap_cache: Dictionary = {}
var _system_presenter := SystemPresenter.new()
var _collection_presenter := CollectionPresenter.new()
var _onboarding_presenter := OnboardingPresenter.new()
var _back_dispatch_queued := false
var synthetic_safe_insets := Rect2(Vector2.ZERO, Vector2.ZERO)
var synthetic_safe_insets_enabled := false
var _fit_rebuild_queued := false
var _restore_focus_name := ""

func configure_runtime(value: Variant) -> void:
	runtime = value
	_refresh_cache()
	_render()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var prototype_theme := Theme.new()
	prototype_theme.default_font = ThemeDB.fallback_font
	theme = prototype_theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Contain-fit leaves intentional safe-area letterbox at tall aspect ratios.
	# Make it inert prototype navy rather than the engine's diagnostic gray.
	var surround := ColorRect.new()
	surround.name = "PrototypeSafeAreaSurround"
	surround.color = Color("07131d")
	surround.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surround.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(surround)
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
		_queue_back_dispatch()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_queue_back_dispatch()
		return
	if first_print == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		first_print.set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		first_print.set_paused(false)

func _process(_delta: float) -> void:
	if route != "forge" or first_print == null or first_print.sequence == null:
		return
	var voucher: Dictionary = cached_collection.get("voucher", {})
	if str(first_print.sequence.phase) == ArcaneForgeSequence.AWAKENED:
		_refresh_cache()
		replace_route("grant")
		return
	if str(first_print.sequence.phase) == ArcaneForgeSequence.FAILED:
		return
	var update: Dictionary = first_print.advance_delta(_delta, str(voucher.get("print_id", "")))
	if _forge_compositor != null:
		_render_forge_print()
	if str(update.get("phase", "")) == ArcaneForgeSequence.AWAKENED:
		_refresh_cache()
		replace_route("grant")

func _fit() -> void:
	if _stage == null:
		return
	var previous_scale := _stage.scale
	var previous_position := _stage.position
	var insets := synthetic_safe_insets if synthetic_safe_insets_enabled else Chassis.mobile_safe_insets(size)
	Chassis.fit_design(_stage, size, insets)
	if not is_node_ready() or _content.get_child_count() == 0:
		return
	if previous_scale.is_equal_approx(_stage.scale) and previous_position.is_equal_approx(_stage.position):
		return
	var focused := get_viewport().gui_get_focus_owner()
	_restore_focus_name = focused.name if focused != null and is_ancestor_of(focused) else ""
	if not _fit_rebuild_queued:
		_fit_rebuild_queued = true
		call_deferred("_rebuild_after_fit")


func _rebuild_after_fit() -> void:
	_fit_rebuild_queued = false
	_render()
	_restore_saved_focus()


func _restore_saved_focus() -> void:
	if not _restore_focus_name.is_empty():
		var restored := find_child(_restore_focus_name, true, false)
		if restored is Button and restored.visible and not restored.disabled and restored.focus_mode != Control.FOCUS_NONE:
			restored.grab_focus()
	_restore_focus_name = ""

func _clear() -> void:
	# Route-owned presentation nodes are removed by the chassis below. Clear their
	# references before the next renderer can update a stale queued-for-free node;
	# the durable FirstPrintController deliberately survives route changes.
	_forge_action = null
	_forge_compositor = null
	Chassis.remove_route_children(_content)

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
		"starter", "starter_inspect": _onboarding_presenter.render_starter(self)
		"forge": _onboarding_presenter.render_forge(self)
		"grant": _onboarding_presenter.render_grant(self)
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
	return Widgets.label(_content, text, rect, font_size, int(settings_draft.get("text_scale_bps", 10000)), bool(settings_draft.get("high_contrast", false)), align)

func _button(caption: String, rect: Rect2, action: Callable, disabled := false, kind := "wide", primary := false, transparent_hit := true) -> Button:
	var required_final_hit := 56.0 if primary else 48.0
	var minimum_design_hit := _minimum_design_hit(required_final_hit)
	var button := Widgets.button(_content, caption, rect, action, disabled, kind, int(settings_draft.get("text_scale_bps", 10000)), bool(settings_draft.get("high_contrast", false)), minimum_design_hit, transparent_hit)
	button.set_meta("required_final_hit", required_final_hit)
	return button


func _minimum_design_hit(final_pixels := 48.0) -> float:
	var stage_scale := _stage.scale.x if _stage != null else 1.0
	return final_pixels / maxf(stage_scale, 0.001)


func _scaled_font_size(base_size: int) -> int:
	return Widgets.scaled_font_size(base_size, int(settings_draft.get("text_scale_bps", 10000)))

func _back(destination := "Workshop") -> void:
	_back_at(Rect2(29, 33, 134, 80), destination)


func _back_at(rect: Rect2, destination := "Workshop") -> void:
	var button := _button("BACK", rect, back, false, "binding")
	button.name = "RouteBack"
	Navigation.configure_back(button, destination, Vector2.ONE * _minimum_design_hit(), true)

func _workshop() -> void:
	if leave_confirmation:
		_system_presenter.render_root_leave_confirmation(self)
		return
	_background(WORKSHOP)
	_back_at(Rect2(26.14, 35.94, 133.96, 78.50), "Workshop")
	# These are the registered 941-space hardware seats, converted once from the
	# accepted 576 review anchors. Labels remain native and hits are transparent.
	_workshop_parchment("TEAM", Rect2(91, 405, 196, 314), func(): navigate("team"), "WorkshopTeam")
	_workshop_parchment("SUPPORT\nKIT", Rect2(680, 405, 193, 237), func(): navigate("kit"), "WorkshopSupport")
	_workshop_parchment("SOLO\nBATTLE", Rect2(676, 661, 219, 194), func(): navigate("preflight"), "WorkshopBattle")
	_workshop_parchment("FORGE", Rect2(242, 906, 457, 261), func(): _open_forge(), "WorkshopForge")
	_workshop_parchment("SETTINGS", Rect2(294, 1248, 353, 327), func(): navigate("settings"), "WorkshopSettings")


func _workshop_parchment(caption: String, rect: Rect2, action: Callable, node_name: String) -> void:
	var button := _button(caption, rect, action, false, "tall")
	button.name = node_name
	button.add_theme_color_override("font_color", Color("24160b"))
	button.add_theme_color_override("font_hover_color", Color("24160b"))
	button.add_theme_color_override("font_pressed_color", Color("24160b"))
	button.add_theme_color_override("font_focus_color", Color("24160b"))
	button.add_theme_color_override("font_disabled_color", Color("24160b", 0.65))


func _open_forge() -> void:
	var voucher: Dictionary = cached_collection.get("voucher", {})
	match str(voucher.get("state", "none")):
		"none": navigate("starter")
		"settled": navigate("grant")
		"acknowledged": navigate("team")
		_: navigate("forge")


func _queue_back_dispatch() -> void:
	if _back_dispatch_queued:
		return
	_back_dispatch_queued = true
	call_deferred("_dispatch_back")


func _dispatch_back() -> void:
	_back_dispatch_queued = false
	back()


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
	var starter_name := _support_name(starter_id.to_lower())
	var enlarged := int(settings_draft.get("text_scale_bps", 10000)) == 15000
	var phase := str(first_print.sequence.phase)
	var accessibility_copy := "%s. %s." % [starter_name, phase.capitalize()]
	_forge_action.disabled = false
	_forge_action.mouse_filter = Control.MOUSE_FILTER_STOP
	_forge_action.focus_mode = Control.FOCUS_ALL
	if phase == ArcaneForgeSequence.PRINTING:
		var percent := roundi(float(first_print.sequence.layer_reveal_bps()) / 100.0)
		_forge_action.text = "PRINTING\n%d%%\nSKIP" % percent if enlarged else "%s\nPRINTING %d%%\nSKIP" % [starter_id, percent]
		accessibility_copy = "%s. Printing %d percent. Skip." % [starter_name, percent]
	elif phase == ArcaneForgeSequence.RAW_COMPLETE:
		if not str(first_print.save_error).is_empty():
			_forge_action.text = "RETRY\nSAVE" if enlarged else "SAVE FAILED\nRETRY SAVE"
			accessibility_copy = "%s. Print save failed. Retry save." % starter_name
		else:
			_forge_action.text = "SAVING PRINT"
			accessibility_copy = "%s. Saving completed print." % starter_name
			_forge_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_forge_action.focus_mode = Control.FOCUS_NONE
	elif phase == ArcaneForgeSequence.RAW_HOLD:
		_forge_action.text = "RAW\nCOMPLETE\nSKIP" if enlarged else "%s\nRAW COMPLETE\nSKIP" % starter_id
		accessibility_copy = "%s. Raw print complete. Skip." % starter_name
	elif phase == ArcaneForgeSequence.AWAKENING:
		_forge_action.text = "AWAKEN\nSKIP" if enlarged else "%s\nAWAKENING\nSKIP" % starter_id
		accessibility_copy = "%s. Awakening. Skip." % starter_name
	elif phase == ArcaneForgeSequence.DEPARTING:
		_forge_action.text = "JOINING\nTEAM" if enlarged else "%s\nJOINING TEAM" % starter_id
		accessibility_copy = "%s. Joining Team." % starter_name
		_forge_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_forge_action.focus_mode = Control.FOCUS_NONE
	else:
		_forge_action.text = "AWAKENED"
		accessibility_copy = "%s. Awakened." % starter_name
		_forge_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_forge_action.focus_mode = Control.FOCUS_NONE
	_forge_action.accessibility_name = accessibility_copy
	_forge_action.tooltip_text = accessibility_copy

func _team() -> void:
	_collection_presenter.render(self, route == "kit")

func _render_team() -> void:
	_collection_presenter.render_team(self)

func _team_mini(creature: String, root: Vector2) -> void:
	var frame := BattleFacingSpriteCache.raw_frame_for_creature(creature, 1)
	var region := BattleFacingSpriteCache.safe_source_region_for_creature(creature, frame)
	var texture := BattleFacingSpriteCache.texture_for_creature(creature)
	if texture == null or region.size.x <= 1.0 or region.size.y <= 1.0:
		return
	var key := "%s:%d" % [creature, frame]
	var atlas: AtlasTexture = _team_atlases.get(key, null)
	if atlas == null:
		atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		_team_atlases[key] = atlas
	var scale := 104.54 / 380.0
	var source_root := _forge_source_root(creature)
	var origin := root - source_root * scale
	var mini := TextureRect.new()
	mini.texture = atlas
	mini.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini.stretch_mode = TextureRect.STRETCH_SCALE
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Physical.place_design(mini, Rect2(origin, region.size * scale))
	_content.add_child(mini)


func _grant_mini(creature: String, card: Rect2, first: bool) -> void:
	var enlarged := int(settings_draft.get("text_scale_bps", 10000)) == 15000
	var card_index := 0
	if card.position.x > 560.0:
		card_index = 2
	elif card.position.x > 300.0:
		card_index = 1
	var frame := BattleFacingSpriteCache.raw_frame_for_creature(creature, 1)
	var region := BattleFacingSpriteCache.safe_source_region_for_creature(creature, frame)
	var texture := BattleFacingSpriteCache.texture_for_creature(creature)
	if texture != null and region.size.x > 1.0 and region.size.y > 1.0:
		var key := "%s:%d" % [creature, frame]
		var atlas: AtlasTexture = _team_atlases.get(key, null)
		if atlas == null:
			atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			_team_atlases[key] = atlas
		var icon := TextureRect.new()
		icon.texture = atlas
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_rect := Rect2(card.position.x + (card.size.x - 52.3) * 0.5, card.position.y + 16.3, 52.3, 70.2)
		if enlarged:
			var icon_rects := [Rect2(217, 838.6, 36.6, 49), Rect2(446.55, 838.6, 36.6, 49), Rect2(686.6, 838.6, 36.6, 49)]
			icon_rect = icon_rects[card_index]
		Physical.place_design(icon, icon_rect)
		_content.add_child(icon)
	var compact := _grant_token(creature) if enlarged else _support_name(creature)
	var caption_rect := Rect2(card.position.x, card.position.y + 86.6, card.size.x, 58.8)
	if enlarged:
		var caption_rects := [Rect2(153.6, 890.6, 163.4, 86), Rect2(377.4, 890.6, 174.9, 86), Rect2(609.3, 890.6, 191.2, 86)]
		caption_rect = caption_rects[card_index]
	_label("%s\n%s" % [compact.to_upper(), "FIRST" if first else "PRINTED"], caption_rect, 26)


func _support_art(support: String, rect: Rect2) -> void:
	var definition: Dictionary = V3Catalog.card(support)
	if definition.is_empty():
		return
	var card_texture := CardView.atlas_region(definition)
	if card_texture == null:
		return
	var art := TextureRect.new()
	art.texture = card_texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Physical.place_design(art, rect)
	_content.add_child(art)


func _support_name(support: String) -> String:
	match support:
		"raw_filament": return "Raw Filament"
		"heated_spool": return "Heated Spool"
		"standard_full_suit": return "Full Suit"
		"iron_gem": return "Iron Gem"
		"forge_surge": return "Forge Surge"
		"cinderpaw": return "Cinderpaw"
		"aquafin": return "Aquafin"
		"voltwig": return "Voltwig"
		"mossmunk": return "Mossmunk"
	return support.capitalize()


func _support_token(support: String) -> String:
	match support:
		"raw_filament": return "RAW"
		"heated_spool": return "HEAT"
		"standard_full_suit": return "SUIT"
		"iron_gem": return "GEM"
		"forge_surge": return "SURGE"
	return _support_name(support).to_upper()


func _grant_token(creature: String) -> String:
	match creature:
		"cinderpaw": return "CINDER"
		"aquafin": return "AQUA"
		"voltwig": return "VOLT"
		"mossmunk": return "MOSS"
	return creature.to_upper()


func _restore_recommended() -> void:
	retained_requests.erase("apply_loadout")
	draft_kit = (cached_collection.get("recommended_kit", {}) as Dictionary).duplicate(true)
	route_error = ""
	_render()


func _open_team_slot(index: int) -> void:
	modal = "team_slot"
	modal_slot = index
	modal_page = 0
	modal_return_focus = "TeamBay%d" % index
	route_error = ""
	_render()


func _open_priority() -> void:
	modal = "priority"
	modal_slot = 0
	modal_return_focus = "TeamPriority"
	route_error = ""
	_render()


func _open_support_inspector(support: String) -> void:
	modal = "support"
	selected_support = support
	modal_return_focus = "SupportChip_%s" % support
	route_error = ""
	_render()


func _render_collection_modal(_kit_mode: bool) -> void:
	_collection_presenter.render_modal(self)

func _select_team_member(member: String) -> void:
	if modal_slot < 0 or modal_slot >= 3:
		return
	while draft_team.size() < 3:
		draft_team.append("")
	var replaced := str(draft_team[modal_slot])
	draft_team[modal_slot] = member
	retained_requests.erase("apply_loadout")
	var priority_index := draft_priority.find(replaced)
	if priority_index >= 0:
		draft_priority[priority_index] = member
	elif draft_priority.find(member) < 0:
		draft_priority.append(member)
	modal = ""
	_render()


func _move_priority_down(index: int) -> void:
	if index >= 0 and index < draft_priority.size() - 1:
		var member: Variant = draft_priority.pop_at(index)
		draft_priority.insert(index + 1, member)
		retained_requests.erase("apply_loadout")
		modal_slot = index + 1
		_render()

func _settings() -> void:
	_system_presenter.render_settings(self)

func _recovery() -> void:
	_system_presenter.render_recovery(self)

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


func replace_route(next: String) -> void:
	route = next
	_render()


func _return_to_workshop() -> void:
	route_stack.clear()
	route = "workshop"
	_render()

func back() -> void:
	if leave_confirmation:
		leave_confirmation = false
		_render()
		return
	# Recovery is deliberately read-only. Its Back owner opens the same explicit
	# Leave/Stay confirmation as the Workshop root instead of briefly routing to
	# Workshop and having _render() force Recovery again.
	if runtime != null and runtime.is_recovery():
		if recovery_details:
			recovery_details = false
			_render()
			return
		leave_confirmation = true
		_render()
		return
	if not modal.is_empty():
		_restore_focus_name = modal_return_focus
		modal_return_focus = ""
		modal = ""
		modal_slot = -1
		selected_support = ""
		_render()
		call_deferred("_restore_saved_focus")
		return
	if starter_confirmation:
		starter_confirmation = false
		_render()
		return
	if route == "forge" and str(cached_collection.get("voucher", {}).get("state", "")) == "settled":
		# A durable completion reopens as its existing receipt. It never restarts
		# a local presentation or submits Complete a second time.
		first_print = null
	if route in ["team", "kit"]:
		retained_requests.erase("apply_loadout")
		_load_draft()
	if route == "settings":
		settings_draft = runtime.settings_view()
	if route_stack.is_empty():
		if route == "workshop":
			leave_confirmation = true
		else:
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
	var envelope: Dictionary = retained_requests.get(action, {})
	if envelope.is_empty():
		envelope = {"id": _new_request_id(action), "payload": payload.duplicate(true)}
		retained_requests[action] = envelope
	var result: Dictionary = runtime.collection_request(action, str(envelope.id), envelope.payload)
	if bool(result.get("ok", false)):
		retained_requests.erase(action)
		route_error = ""
		_refresh_cache()
	else:
		route_error = str(result.get("error", "Save not confirmed. Nothing new was applied."))
	return result


func _new_request_id(action: String) -> String:
	var entropy := Crypto.new().generate_random_bytes(16).hex_encode()
	return "team-ui-%s-%d-%s" % [action, Time.get_unix_time_from_system(), entropy]

func _choose_starter(id: String) -> void:
	if not starter_confirmation:
		starter_confirmation = true
		_render()
		return
	if bool(_request("choose_starter", {"starter_id":id}).get("ok", false)):
		starter_confirmation = false
		replace_route("forge")
	else:
		_render()

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
	ink.texture = _blueprint_ink_texture(_definition(creature))
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


func _blueprint_ink_texture(definition: Dictionary) -> Texture2D:
	var source := Imprint.blueprint_texture(definition)
	if source == null:
		return null
	var cache_key := source.get_instance_id()
	if _blueprint_mipmap_cache.has(cache_key):
		return _blueprint_mipmap_cache[cache_key] as Texture2D
	var image := source.get_image()
	if image == null or image.is_empty():
		_blueprint_mipmap_cache[cache_key] = source
		return source
	if not image.has_mipmaps() and image.generate_mipmaps() != OK:
		_blueprint_mipmap_cache[cache_key] = source
		return source
	var mipmapped := ImageTexture.create_from_image(image)
	if mipmapped == null:
		_blueprint_mipmap_cache[cache_key] = source
		return source
	_blueprint_mipmap_cache[cache_key] = mipmapped
	return mipmapped

func _acknowledge_grant() -> void:
	var receipt_id := str(cached_collection.get("voucher", {}).get("receipt_id", ""))
	var result := _request("acknowledge_grant", {"receipt_id":receipt_id})
	if bool(result.get("ok", false)):
		_load_draft()
		replace_route("team")
	else:
		_render()

func _load_draft() -> void:
	var saved: Dictionary = cached_collection.get("saved_loadout", {})
	draft_team = (saved.get("team", cached_collection.get("recommended_team", [])) as Array).duplicate()
	draft_priority = (saved.get("priority", draft_team) as Array).duplicate()
	draft_kit = (saved.get("kit", cached_collection.get("recommended_kit", {})) as Dictionary).duplicate(true)

func _move_priority(index: int) -> void:
	if index > 0:
		var member: Variant = draft_priority.pop_at(index)
		draft_priority.insert(index - 1, member)
		retained_requests.erase("apply_loadout")
		modal_slot = index - 1
		_render()

func _adjust_kit(id: String, delta: int) -> void:
	var owned := int(cached_collection.get("support_counts", {}).get(id, 0))
	var maximum := mini(owned, 15)
	draft_kit[id] = clampi(int(draft_kit.get(id, 0)) + delta, 0, maximum)
	retained_requests.erase("apply_loadout")
	_render()

func _kit_total() -> int:
	var total := 0
	for value in draft_kit.values(): total += int(value)
	return total

func _draft_valid() -> bool:
	return runtime != null and bool(runtime.preview_loadout(draft_team, draft_priority, draft_kit).get("ok", false))

func _apply_draft() -> void:
	if bool(_request("apply_loadout", {"team":draft_team, "priority":draft_priority, "kit":draft_kit}).get("ok", false)):
		_return_to_workshop()
	else:
		_render()

func _apply_settings() -> void:
	var result: Dictionary = runtime.apply_settings(settings_draft)
	if bool(result.get("ok", false)):
		_refresh_cache()
		back()
	else:
		route_error = str(result.get("error", "Settings could not be saved."))
		_render()

func _definition(id: String) -> Dictionary:
	return BattleCatalog.creature(id)
