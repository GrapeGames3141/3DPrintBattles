extends Control

## Runtime-safe workshop presentation; final character art remains approval-gated.
const REFERENCE_TEXTURE := preload("res://assets/ui/workshop/workshop-theme-reference-fallback.jpg")
const WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_landscape_v4.png")
const WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE := preload("res://assets/ui/workshop/workshop_overview_portrait_v4.png")
const WORKSHOP_AMBIENT_LAYER := preload("res://scripts/ui/workshop_ambient_layer.gd")
const WORKSHOP_HOTSPOT_OVERLAY := preload("res://scripts/ui/workshop_hotspot_overlay.gd")
const WORKSHOP_PAN_AFFORDANCE := preload("res://scripts/ui/workshop_pan_affordance.gd")
const TOUCH_SCROLL_CONTAINER := preload("res://scripts/ui/touch_scroll_container.gd")
const SUPPORT_CARD_PRESENTER_PATH := "res://scripts/ui/support_card_presenter.gd"
const SUPPORT_CARD_VIEW_PATH := "res://scripts/ui/support_card_view.gd"
const BATTLE_FEEDBACK_PRESENTER_PATH := "res://scripts/ui/battle_feedback_presenter.gd"
const EQUIPMENT_WORKBENCH_VIEW_PATH := "res://scripts/ui/equipment_workbench_view.gd"
# TieredArmorRoster remains species-neutral and is loaded only by the Equipment
# Workbench path, so the workshop's first frame never parses its preview graph.
const TIERED_ARMOR_ROSTER_PATH := "res://scripts/ui/tiered_armor_roster.gd"
const TIERED_ARMOR_PREVIEW_PATH := "res://scripts/ui/tiered_armor_palette_preview.gd"
const BLUEPRINT_TRAY_VIEW := preload("res://scripts/ui/blueprint_tray_view.gd")
const FORGE_SCREEN_COMPONENT_PATH := "res://scripts/ui/arcane_forge_screen_component.gd"
const BATTLE_SPRITE_STAGE_PATH := "res://scripts/ui/battle_sprite_stage.gd"
const UNIFIED_BATTLE_SCREEN_COMPONENT_PATH := "res://scripts/ui/unified_battle_screen_component.gd"
const ARCANE_FOUNDRY_THEME_KIT := preload("res://scripts/ui/arcane_foundry_theme_kit.gd")
const UNIFIED_BATTLE_RULES := preload("res://scripts/battle/unified_battle_rules.gd")
const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_AI := preload("res://scripts/battle/unified_ai_opponent.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const REVIEW_BUILD_LABEL := "0.8.0-v3-canonical-refactor"
const ELEMENT_COLORS := {"Fire":"f17e5b", "Water":"5fb9f5", "Lightning":"efd862", "Nature":"7bcf89", "Ice":"a5ecff", "Stone":"b7a48b", "Wind":"a6d7c8"}
# Approved perspective-matched workshop station close-ups. Each keeps its visible
# props aligned with the normalized, accessible object hotspots below.
const WORKSHOP_CLOSEUP_PATHS := {
	"printer": "res://assets/ui/workshop/workshop_printer_closeup_v2.png",
	"maker": "res://assets/ui/workshop/workshop_maker_closeup_v2.png",
	"terminal": "res://assets/ui/workshop/workshop_terminal_closeup_v2.png",
	"proving": "res://assets/ui/workshop/workshop_proving_closeup_v2.png",
	"yard": "res://assets/ui/workshop/workshop_yard_closeup_v2.png"
}

var screen := "workshop"
var workshop_selected := "printer"
var workshop_view := "overview"
var workshop_drawer_object := ""
var printer_picker_open := false
var printer_blueprint_selected_id := ""
var workshop_return_view := "overview"
var pending_starter_id := ""
var starter_inspector_id := ""
var starter_page := 0
var shop_day_key := ""
var team_draft: Array = []
var deck_draft: Array = []
var deck_selected_card_id := ""
var deck_slot_id := ProgressionRules.STARTER_DECK_ID
var card_archive_owned_only := false
var card_archive_detail_id := ""
# `battle` is deliberately untyped so the shell can recover an interrupted
# session, but every shipped launch now stores a canonical v3 snapshot here.
# The older active-unit renderer remains isolated for historical test fixtures
# and is no longer an entry point from Workshop, Daily Training, Trials, or
# local hot-seat play.
var battle
var battle_settlement_context: Dictionary = {}
var battle_settlement_finished := false
var toast := ""
var unified_hand_page := 0
var unified_selected_card_id := ""
var unified_selected_slot := -2
var unified_selected_target := -2
var unified_attack_slot := -1
var unified_attack_target := -2
var unified_ai_pending := false
var unified_local_handoff := false
var unified_arrival_presented: Dictionary = {}
var unified_page := 0
var unified_deck_draft: Array = []
var unified_preprint_draft: Array = []
var unified_printer_draft: Array = []
var unified_printer_page := 0
var unified_codex_page := 0
var unified_inspector_id := ""
var unified_inspector_tab := "card"
var unified_reveal_page := 0
var unified_market_tab := "blueprints"
var body: VBoxContainer
var status: Label
var battle_mode := "training"
var training_contract_id := ""
var trial_encounter_id := ""
var local_trade: LocalTradeAuthority
var trade_creator_choice := ""
var trade_partner_choice := ""
var printer_sequence: ArcaneForgeSequence
var printer_creature_id := ""
var printer_armor_id := ""
var printer_is_armor := false
var printer_is_core := false
var equipment_selected_creature_id := ""
var equipment_mode := "suits"
var equipment_selected_id := "standard"
var printer_price := 0
var printer_tick_accumulator := 0.0
var printer_presentation_seconds := 0.0
var printer_capture_freeze := false
var printer_failure := ""
var printer_return_screen := "collection"
var printer_progress_label: Label
var team_draft_dirty := false
var calibration_values: Array[int] = [50, 50, 50]
var calibration_step := 0
var _focus_after_render := true
var workshop_ambient_capture_freeze := false
var workshop_station_live_capture_progress := -1
var workshop_station_live_capture_seed := 17
var overview_layout_portrait := false
var _workshop_screen_component := WorkshopScreenComponent.new()
var _blueprint_tray_view := BLUEPRINT_TRAY_VIEW.new()
# Battle, Forge, cards, and equipment are intentionally absent from the first
# workshop frame. Their resources now load only when their screen is requested.
var _unified_battle_screen_component = null
var _forge_screen_component = null
var _audio_director := AudioDirector.new()

func settings() -> Dictionary:
	return GameManager.profile.get("settings", AccessibilityRules.defaults())

func scaled_font(base: int) -> int:
	return maxi(12, (base * int(settings().get("text_scale_bps", 10000))) / 10000)

func is_portrait_layout() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.y > viewport_size.x

func _optional_script(path: String, feature_name: String):
	var script = ResourceLoader.load(path)
	if script == null:
		push_error("%s resource could not load: %s" % [feature_name, path])
		_toast("%s could not load. The Workshop remains available." % feature_name)
	return script

func _unified_battle_component():
	if _unified_battle_screen_component == null:
		var script = _optional_script(UNIFIED_BATTLE_SCREEN_COMPONENT_PATH, "Foundry battle screen")
		if script == null: return null
		_unified_battle_screen_component = script.new()
	return _unified_battle_screen_component

func _forge_component():
	if _forge_screen_component == null:
		var script = _optional_script(FORGE_SCREEN_COMPONENT_PATH, "Forge presentation")
		if script == null: return null
		_forge_screen_component = script.new()
	return _forge_screen_component

func _new_support_card_view():
	var script = _optional_script(SUPPORT_CARD_VIEW_PATH, "Support card view")
	return null if script == null else script.new()

func _new_local_battle_stage():
	var script = _optional_script(BATTLE_SPRITE_STAGE_PATH, "Local battle presentation")
	return null if script == null else script.new()

func _ready() -> void:
	print("PRINTFORGE_STARTUP marker=ui_ready renderer=%s platform=%s" % [RenderingServer.get_current_rendering_method(), OS.get_name()])
	if shop_day_key.is_empty(): shop_day_key = Time.get_date_string_from_system()
	GameManager.profile_changed.connect(render)
	GameManager.toast_requested.connect(_toast)
	add_child(_audio_director)
	_audio_director.configure(settings(), false)
	# A capture harness may select a non-default destination before this node enters
	# the tree. Normal launches use the workshop default and route from profile state.
	if screen == "workshop": screen = OnboardingState.screen_for_profile(GameManager.profile)
	render()
	call_deferred("_emit_first_frame_marker")

func _emit_first_frame_marker() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	print("PRINTFORGE_STARTUP marker=first_frame screen=%s viewport=%dx%d" % [screen, int(viewport_size.x), int(viewport_size.y)])

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		# Containers handle ordinary resize. An orientation flip needs its matching
		# v3 overview plate and fresh normalized hotspot layout.
		if screen == "workshop" and workshop_view == "overview" and is_portrait_layout() != overview_layout_portrait:
			call_deferred("render")
		queue_redraw()

func _process(delta: float) -> void:
	if printer_capture_freeze: return
	if screen != "printer" or printer_sequence == null: return
	if printer_sequence.phase not in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING]: return
	if not printer_sequence.reduced_motion: printer_presentation_seconds += delta
	printer_tick_accumulator += delta
	if printer_tick_accumulator < ArcaneForgeSequence.presentation_interval_seconds(printer_sequence.reduced_motion): return
	printer_tick_accumulator = 0.0
	var phase_before := printer_sequence.phase
	printer_sequence.advance(ArcaneForgeSequence.presentation_step_bps(printer_sequence.reduced_motion, phase_before))
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		_commit_printer_once()
		render()
	elif printer_sequence.phase != phase_before:
		# A phase change changes controls/status hierarchy, so rebuild the shell.
		render()
	else:
		# Same-phase progress is visual-only. Keep the surrounding shell and the
		# persistent compositor alive while updating their presentation in place.
		_refresh_printer_presentation()

func navigate_to(target: String) -> void:
	# Foundry hotspots now resolve to the unified card surfaces. Legacy routes
	# remain available to retained screens under their explicit legacy ids.
	var unified_targets := {"shop":"unified_market", "archive":"unified_library", "armor":"unified_library", "deck":"unified_deck", "team":"unified_deck", "calibration":"unified_upgrades", "codex":"unified_forgedex", "collection":"unified_forgedex", "yard":"unified_market"}
	if unified_targets.has(target): target = str(unified_targets[target])
	if screen == "workshop" and target != "workshop":
		workshop_return_view = workshop_view
	if target == "workshop":
		workshop_view = workshop_return_view
		workshop_drawer_object = ""
	screen = target
	# Daily snapshots are a launch/navigation transition, never a render side
	# effect. This avoids recursive profile_changed -> render rebuilds.
	if target == "proving": GameManager.prepare_daily_training(shop_day_key)
	render()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE): return
	_focus_after_render = true
	if screen == "workshop":
		if not workshop_drawer_object.is_empty():
			close_workshop_drawer()
		elif workshop_view != "overview":
			open_workshop_view("overview")
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen == "printer":
		if printer_sequence != null and printer_sequence.phase == ArcaneForgeSequence.IDLE:
			cancel_printer_preview()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen != "onboarding" and screen != "workshop":
		screen = "workshop"
		workshop_view = workshop_return_view
		workshop_drawer_object = ""
		render()
		get_viewport().set_input_as_handled()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		if child == _audio_director: continue
		node.remove_child(child)
		child.queue_free()

func _foundry_surface(color: Color, strength := 0.11) -> Color:
	var steel := Color("171918")
	var semantic := Color(color.r, color.g, color.b, 1.0)
	var result := steel.lerp(semantic, strength)
	result.a = maxf(0.90, color.a)
	return result

func _foundry_text_color(color: Color) -> Color:
	if bool(settings().get("high_contrast", false)): return Color.WHITE
	# Recast the ubiquitous cool body copy as warm ivory without touching semantic
	# red/green/cyan/gold messaging supplied by individual screens.
	for legacy in [Color("dce8f4"), Color("e1eef9"), Color("dbe9f6"), Color("b9d3e8"), Color("d6f7ff"), Color("edf7ff"), Color("c6d7e8")]:
		if color.is_equal_approx(legacy): return Color("e6dfd0")
	return color

func panel_style(color: Color, border: Color = Color("6bd6ed")) -> StyleBox:
	var role := "surface"
	if border.is_equal_approx(Color("f1be69")) or border.is_equal_approx(Color("ffd36c")): role = "commit"
	elif border.is_equal_approx(Color("ffaaa1")): role = "danger"
	elif border.is_equal_approx(Color("7142a8")): role = "arcane"
	return ARCANE_FOUNDRY_THEME_KIT.panel(role, bool(settings().get("high_contrast", false)))

func inset_style(color: Color, border: Color = Color("6bd6ed")) -> StyleBox:
	var role := "surface"
	if border.is_equal_approx(Color("f1be69")) or border.is_equal_approx(Color("ffd36c")): role = "commit"
	elif border.is_equal_approx(Color("ffaaa1")): role = "danger"
	elif border.is_equal_approx(Color("7142a8")): role = "arcane"
	return ARCANE_FOUNDRY_THEME_KIT.inset(role, bool(settings().get("high_contrast", false)))

func make_panel(color := Color("172942cc"), border := Color("6bd6ed")) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", panel_style(color, border))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return content

func button_style(accent: Color, state: String) -> StyleBox:
	var role := "primary"
	if accent.is_equal_approx(Color("a86b2e")): role = "commit"
	elif accent.is_equal_approx(Color("536c8d")) or accent.is_equal_approx(Color("526e93")): role = "secondary"
	elif accent.is_equal_approx(Color("7142a8")): role = "arcane"
	elif accent.is_equal_approx(Color("588d73")): role = "success"
	return ARCANE_FOUNDRY_THEME_KIT.button(role, state, bool(settings().get("high_contrast", false)))

func make_button(text_value: String, callback: Callable, accent := Color("2f93a8")) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", scaled_font(15))
	button.add_theme_font_override("font", ARCANE_FOUNDRY_THEME_KIT.display_font())
	button.add_theme_color_override("font_color", Color.WHITE if bool(settings().get("high_contrast", false)) else Color("f0e8d8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff2d2"))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("aaa69c"))
	button.add_theme_stylebox_override("normal", button_style(accent, "normal"))
	button.add_theme_stylebox_override("hover", button_style(accent, "hover"))
	button.add_theme_stylebox_override("pressed", button_style(accent, "pressed"))
	button.add_theme_stylebox_override("focus", button_style(accent, "focus"))
	button.add_theme_stylebox_override("disabled", button_style(accent, "disabled"))
	button.gui_input.connect(func(event: InputEvent):
		if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
			_focus_after_render = true)
	button.pressed.connect(func():
		_audio_director.cue("press")
		callback.call())
	return button

func workshop_hotspot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func label(text_value: String, size := 16, color := Color.WHITE) -> Label:
	var value := Label.new()
	value.text = text_value
	value.add_theme_font_size_override("font_size", scaled_font(size))
	if size >= 18: value.add_theme_font_override("font", ARCANE_FOUNDRY_THEME_KIT.display_font())
	value.add_theme_color_override("font_color", _foundry_text_color(color))
	if size >= 24:
		value.add_theme_color_override("font_outline_color", Color("080909"))
		value.add_theme_constant_override("outline_size", 1)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return value

func render() -> void:
	_audio_director.configure(settings(), printer_capture_freeze or workshop_ambient_capture_freeze)
	_audio_director.route("battle" if screen == "unified_battle" else ("forge" if screen == "printer" else "workshop"))
	_detach_persistent_screen_components()
	clear_children(self)
	var backdrop := TextureRect.new()
	backdrop.texture = REFERENCE_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.72, 0.63, 0.50, 0.48)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var steel_overlay := ColorRect.new()
	steel_overlay.color = Color("0d0e0de0")
	steel_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	steel_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(steel_overlay)
	var warm_glow := ColorRect.new()
	warm_glow.color = Color("8d4a2038")
	warm_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	warm_glow.offset_bottom = 260
	warm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm_glow)
	var cyan_balance := ColorRect.new()
	cyan_balance.color = Color("0b495426")
	cyan_balance.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cyan_balance.offset_top = -120
	cyan_balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cyan_balance)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var portrait := size.y > size.x
	margin.add_theme_constant_override("margin_left", 14 if portrait else 26)
	margin.add_theme_constant_override("margin_right", 14 if portrait else 26)
	margin.add_theme_constant_override("margin_top", 14 if portrait else 20)
	margin.add_theme_constant_override("margin_bottom", 14 if portrait else 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Unified battle is a first-fold control surface. Its compact landscape
	# rhythm preserves the explicit phase and return actions at 125% text.
	root.add_theme_constant_override("separation", 6 if screen == "unified_battle" and not portrait else 12)
	margin.add_child(root)
	if screen != "unified_battle": render_header(root)
	if GameManager.is_save_read_only():
		render_save_recovery(root)
		return
	# Unified matches are presented by the shipped Foundry shell, not by the
	# retired compact test harness. They are a first-fold, no-scroll surface.
	if screen == "unified_battle":
		render_unified_battle_fullscreen(root)
		if _focus_after_render:
			_focus_after_render = false
			call_deferred("focus_first_button")
		return
	if screen == "onboarding":
		render_onboarding_fullscreen(root)
		if _focus_after_render:
			_focus_after_render = false
			call_deferred("focus_first_button")
		return
	# `codex` is retained as a legacy navigation token for old callers, but its
	# player-facing presentation is now the bounded unified Forgedex.
	if screen == "codex":
		screen = "unified_forgedex"
	if screen in ["unified_market", "unified_library", "unified_deck", "unified_upgrades", "unified_forgedex"]:
		render_unified_foundry_surface(root)
		if _focus_after_render:
			_focus_after_render = false
			call_deferred("focus_first_button")
		return
	var scroll := TOUCH_SCROLL_CONTAINER.new()
	scroll.name = "TouchFirstScroll"
	scroll.custom_minimum_size = Vector2(0, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	if bool(get_meta("capture_scroll_trials", false)) and screen == "trials":
		call_deferred("_capture_scroll_trials", scroll)
	status = label("", 15, Color("fff0a1"))
	body.add_child(status)
	match screen:
		"onboarding": render_onboarding()
		"shop": render_shop()
		"codex": render_codex()
		"collection": render_collection()
		"team": render_team()
		"armor": render_armor()
		"deck": render_deck()
		"archive": render_card_archive()
		"yard": render_print_yard()
		"calibration": render_calibration_bench()
		"printer": render_printer()
		"settings": render_settings()
		"proving": render_proving_door()
		"trials": render_trials()
		"trade": render_local_trade()
		_: render_workshop()
	if _focus_after_render:
		_focus_after_render = false
		call_deferred("focus_first_button")

func _detach_persistent_screen_components() -> void:
	# Main's shell is intentionally rebuilt for responsive text/contrast. Detach
	# expensive presentation nodes first so their imported textures and animation
	# state survive the ancestor queue_free operation.
	if _forge_screen_component != null: _forge_screen_component.detach()
	_workshop_screen_component.detach()

func focus_first_button() -> void:
	for node in find_children("*", "Button", true, false):
		var button := node as Button
		if button and button.is_visible_in_tree() and button.disabled == false:
			button.grab_focus()
			return

func _capture_scroll_trials(scroll: ScrollContainer) -> void:
	if is_instance_valid(scroll): scroll.scroll_vertical = 260

func render_save_recovery(root: VBoxContainer) -> void:
	var panel := make_panel(Color("2f1f2be8"), Color("ffaaa1"))
	root.add_child(panel.get_parent())
	panel.add_child(label("Save opened read-only", 25, Color("ffcfbf")))
	panel.add_child(label(GameManager.save_recovery_message(), 17, Color("fff3df")))
	panel.add_child(label("Install the newer build that created this save, or copy the profile and backup files before trying an older build. This session has not changed your local save.", 15, Color("dce8f4")))
	panel.add_child(label("No workshop, battle, or purchase actions are available while compatibility is blocked.", 14, Color("b9d3e8")))

func render_header(root: VBoxContainer) -> void:
	var header_box := PanelContainer.new()
	header_box.name = "WorkshopHeader"
	var portrait := size.y > size.x
	header_box.custom_minimum_size = Vector2(0, 126 if portrait else 90)
	header_box.add_theme_stylebox_override("panel", panel_style(Color("25211be8"), Color("c39450")))
	root.add_child(header_box)
	var header: BoxContainer = VBoxContainer.new() if portrait else HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 100 if portrait else 64)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)
	header_box.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.custom_minimum_size = Vector2(0 if portrait else 560, 58)
	header.add_child(titles)
	titles.add_child(label("Makers Guild Workshop", 25, Color("ffd36c")))
	titles.add_child(label("Forge console · blueprints · battle prep", 14, Color("9beaff")))
	if GameManager.is_save_read_only():
		var compatibility := label("READ-ONLY COMPATIBILITY MODE\nSave schema is newer than this build", 15, Color("ffcfbf"))
		compatibility.name = "ReadOnlyCompatibilityHeader"
		compatibility.custom_minimum_size = Vector2(0 if portrait else 250, 40 if portrait else 58)
		compatibility.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		compatibility.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		compatibility.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(compatibility)
	elif GameManager.has_selected_starter():
		var account := label("Forge Coins  %d\nSpool Level  %d / 100" % [int(GameManager.profile.get("forge_coins", 0)), int(GameManager.profile.get("spool_level", 1))], 16, Color("d6f7ff"))
		account.custom_minimum_size = Vector2(0 if portrait else 190, 40 if portrait else 58)
		account.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		account.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		account.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(account)
	else:
		var ceremony := label("AWAKENING CEREMONY", 15, Color("fff0a1"))
		ceremony.custom_minimum_size = Vector2(0 if portrait else 220, 40 if portrait else 58)
		ceremony.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		ceremony.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
		ceremony.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(ceremony)

func _compact_pager_label(text_value: String) -> Label:
	var value := label(text_value, 14, Color("e6dfd0"))
	value.custom_minimum_size = Vector2(72, 44)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return value

func render_onboarding_fullscreen(host: Container) -> void:
	var intro := make_panel(Color("182d49ed"), Color("f1be69")); host.add_child(intro.get_parent())
	intro.add_child(label("Choose a first blueprint", 25, Color("ffd36c")))
	intro.add_child(label("Tap a print for its base card. Your first Forge print is free.", 14, Color("e1eef9")))
	var choices := UNIFIED_RULES.STARTER_IDS
	var visible: Array = choices if not is_portrait_layout() else [choices[clampi(starter_page, 0, choices.size() - 1)]]
	var cards := GridContainer.new(); cards.name = "StarterChoiceGrid"; cards.columns = 3 if not is_portrait_layout() else 1; cards.add_theme_constant_override("h_separation", 14); host.add_child(cards)
	for starter_id in visible:
		var creature := Catalog.creature(str(starter_id)); var element_color := Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))
		var card := make_panel(Color("15263fe8"), element_color if pending_starter_id == starter_id else Color("5e7f9b")); cards.add_child(card.get_parent())
		var portrait := TextureRect.new(); portrait.texture = _creature_idle_atlas(str(starter_id)); portrait.custom_minimum_size = Vector2(190, 150 if not is_portrait_layout() else 210); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; card.add_child(portrait)
		card.add_child(label(str(creature.name), 23, element_color)); card.add_child(label("%s · %d HP · %d ATK" % [creature.element, int(creature.hp), int(creature.attack)], 14, Color("dbe9f6")))
		card.add_child(make_button("Selected" if pending_starter_id == starter_id else "View card", show_starter_inspector.bind(str(starter_id)), element_color.darkened(0.35)))
	if is_portrait_layout():
		var pager := HBoxContainer.new(); pager.name = "StarterPager"; pager.alignment = BoxContainer.ALIGNMENT_CENTER; pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER; host.add_child(pager)
		var prev := make_button("‹", func(): starter_page = posmod(starter_page - 1, choices.size()); render(), Color("536c8d")); prev.custom_minimum_size = Vector2(48, 44); prev.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER; pager.add_child(prev)
		pager.add_child(_compact_pager_label("%d / %d" % [starter_page + 1, choices.size()]))
		var next := make_button("›", func(): starter_page = posmod(starter_page + 1, choices.size()); render(), Color("536c8d")); next.custom_minimum_size = Vector2(48, 44); next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; next.size_flags_vertical = Control.SIZE_SHRINK_CENTER; pager.add_child(next)
	var confirmation := make_panel(Color("352719ed"), Color("f1be69")); host.add_child(confirmation.get_parent())
	confirmation.add_child(label("Blueprint choice", 18, Color("fff0a1")))
	if pending_starter_id.is_empty(): confirmation.add_child(label("Choose a card to enable its Forge blueprint.", 14, Color("c6d7e8")))
	else: confirmation.add_child(make_button("Forge %s blueprint" % Catalog.creature(pending_starter_id).name, confirm_starter, Color("a86b2e")))
	if not starter_inspector_id.is_empty(): render_starter_inspector()

func render_onboarding() -> void:
	var intro := make_panel(Color("182d49ed"), Color("f1be69"))
	body.add_child(intro.get_parent())
	intro.add_child(label("Choose a first blueprint", 25, Color("ffd36c")))
	intro.add_child(label("Tap a print for its base card. Confirming grants three blue blueprints; the first Forge print is free.", 15, Color("e1eef9")))
	var cards := GridContainer.new()
	cards.columns = 3 if size.x >= 900 else 1
	cards.add_theme_constant_override("h_separation", 14)
	cards.add_theme_constant_override("v_separation", 14)
	body.add_child(cards)
	for starter_id in ProfileRules.STARTER_IDS:
		var creature := Catalog.creature(starter_id)
		var element_color := Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))
		var card := make_panel(Color("15263fe8"), element_color if pending_starter_id == starter_id else Color("5e7f9b"))
		cards.add_child(card.get_parent())
		var portrait := TextureRect.new()
		portrait.texture = _creature_idle_atlas(starter_id)
		portrait.custom_minimum_size = Vector2(190, 150)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		card.add_child(label(str(creature.name), 24, element_color))
		card.add_child(label("%s · %d HP · %d ATK" % [creature.element, int(creature.hp), int(creature.attack)], 15, Color("dbe9f6")))
		card.add_child(make_button("Selected" if pending_starter_id == starter_id else "View card", show_starter_inspector.bind(starter_id), element_color.darkened(0.35)))
	var confirmation := make_panel(Color("352719ed"), Color("f1be69"))
	body.add_child(confirmation.get_parent())
	confirmation.add_child(label("Blueprint choice", 19, Color("fff0a1")))
	if pending_starter_id.is_empty():
		confirmation.add_child(label("Select one card above to enable confirmation.", 15, Color("c6d7e8")))
	else:
		confirmation.add_child(make_button("Forge %s blueprint" % Catalog.creature(pending_starter_id).name, confirm_starter, Color("a86b2e")))
	if not starter_inspector_id.is_empty(): render_starter_inspector()

func show_starter_inspector(starter_id: String) -> void:
	if Catalog.creature(starter_id).is_empty(): return
	starter_inspector_id = starter_id
	render()

func render_starter_inspector() -> void:
	var creature := Catalog.creature(starter_inspector_id)
	if creature.is_empty(): return
	var modal := ColorRect.new()
	modal.name = "StarterCardInspector"
	modal.color = Color("07111bf0")
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(minf(760, size.x - 28), minf(640, size.y - 28))
	shell.add_theme_stylebox_override("panel", panel_style(Color("102940f8"), Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))))
	center.add_child(shell)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	shell.add_child(content)
	var art := TextureRect.new()
	art.texture = _creature_idle_atlas(starter_inspector_id)
	art.custom_minimum_size = Vector2(300, 300 if is_portrait_layout() else 260)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(art)
	content.add_child(label(str(creature.name), 27, Color(ELEMENT_COLORS.get(str(creature.element), "9beaff"))))
	content.add_child(label("Card · %s · %s" % [str(creature.element), str(Catalog.rarity(str(creature.rarity)).name)], 15, Color("dce8f4")))
	content.add_child(label("HP %d · Bend %d\n%s" % [int(creature.hp), int(creature.bend), str(creature.ability)], 17, Color("fff9df")))
	content.add_child(make_button("Select this blueprint", func(): pending_starter_id = starter_inspector_id; starter_inspector_id = ""; render(), Color("a86b2e")))
	content.add_child(make_button("Close", func(): starter_inspector_id = ""; render(), Color("536c8d")))

func confirm_starter() -> void:
	if not OnboardingState.can_confirm(GameManager.profile, pending_starter_id):
		_toast("Choose one Forge Trio companion first.")
		return
	# The free print remains a separate, required completion seam. Choose before
	# changing screens: the journaled profile signal can render synchronously.
	if GameManager.choose_starter(pending_starter_id):
		printer_return_screen = "workshop"
		screen = "printer"
		open_printer(pending_starter_id)
		pending_starter_id = ""
		return
	screen = "onboarding"
	render()

func render_workshop() -> void:
	var used_today := 0
	if workshop_view == "overview":
		render_workshop_overview(used_today)
	else:
		render_workshop_closeup(used_today)
	if str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected":
		var starter_id := str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
		var starter_prompt := make_panel(Color("352719ed"), Color("f1be69"))
		body.add_child(starter_prompt.get_parent())
		starter_prompt.add_child(label("Blue blueprint ready", 20, Color("fff0a1")))
		starter_prompt.add_child(label("Your first %s print is free. Complete it at the Arcane Forge to enter the workshop." % str(Catalog.creature(starter_id).get("name", "starter")), 15, Color("fff9df")))
		starter_prompt.add_child(make_button("Continue free Forge print", open_printer.bind(starter_id), Color("a86b2e")))
	return

func _workshop_views() -> Array:
	return [
		{"id":"printer", "name":"Printer Bench", "callout":"Workshop Models and Collection", "description":"Review learned blueprints and print display models with Forge Coins.", "rect":Rect2(0.08, 0.32, 0.28, 0.44), "objects":[{"id":"forge_machine", "name":"Workshop Model Forge", "description":"Choose an owned blueprint and print a collection model.", "target":"unified_forgedex", "rect":Rect2(0.34, 0.27, 0.36, 0.56)}, {"id":"collection_case", "name":"Collection Case", "description":"Review owned blueprints and printed models.", "target":"unified_forgedex", "rect":Rect2(0.08, 0.06, 0.25, 0.66)}]},
		{"id":"maker", "name":"Maker Bench", "callout":"Pre-prints, decks, equipment cards", "description":"Set your active deck, Pre-Print loadout, and battle equipment cards.", "rect":Rect2(0.03, 0.68, 0.31, 0.26), "objects":[{"id":"team_board", "name":"Pre-Print Board", "description":"Choose creature copies from the active deck to start in Defense Mode.", "target":"unified_deck", "rect":Rect2(0.02, 0.47, 0.27, 0.28)}, {"id":"deck_blueprints", "name":"Deck Blueprint Rack", "description":"Edit one of three fixed legal 40-card deck slots.", "target":"deck", "rect":Rect2(0.38, 0.26, 0.24, 0.40)}, {"id":"card_archive", "name":"Card Archive", "description":"Browse battle cards, rules, and owned copies.", "target":"archive", "rect":Rect2(0.26, 0.52, 0.28, 0.18)}, {"id":"armor_tools", "name":"Equipment Cards", "description":"Browse full suits, combat gems, and the Filament Ring for battle decks.", "target":"unified_library", "rect":Rect2(0.58, 0.15, 0.24, 0.55)}, {"id":"calibration_dial", "name":"Upgrade Forge", "description":"Open Workshop upgrades and in-battle Upgrade Cards.", "target":"calibration", "rect":Rect2(0.80, 0.40, 0.16, 0.32)}]},
		{"id":"terminal", "name":"Forge Terminal", "callout":"Offers, Forgedex, Guild Trade", "description":"Browse fixed daily offers, records, and a local kid-safe trade demo.", "rect":Rect2(0.65, 0.30, 0.23, 0.34), "objects":[{"id":"offer_screen", "name":"Forge Offers", "description":"Review today's deterministic blueprint, card, and armor offers.", "target":"shop", "rect":Rect2(0.57, 0.35, 0.10, 0.29)}, {"id":"forgedex_screen", "name":"Forgedex Terminal", "description":"Track every discovered creature blueprint.", "target":"codex", "rect":Rect2(0.67, 0.35, 0.11, 0.29)}, {"id":"trade_terminal", "name":"Guild Trade Table", "description":"Open a credential-free two-profile escrow demonstration.", "target":"trade", "rect":Rect2(0.78, 0.35, 0.12, 0.29)}]},
		{"id":"proving", "name":"Battle Arena", "callout":"Daily Training, Trials, Local Versus", "description":"Enter the Battle Arena for daily training, ordered Workshop Trials, or a private hot-seat match.", "rect":Rect2(0.45, 0.18, 0.20, 0.50), "objects":[{"id":"training_door", "name":"Battle Arena", "description":"Choose a repeatable daily rival or an ordered Workshop Trial with fixed first-clear rewards.", "target":"proving", "rect":Rect2(0.42, 0.39, 0.23, 0.27)}, {"id":"versus_marker", "name":"Local Versus", "description":"Pass the device between two private players. No rewards are granted.", "target":"local_vs", "rect":Rect2(0.48, 0.64, 0.16, 0.17)}]},
		{"id":"yard", "name":"Print Yard", "callout":"Daily filament lesson", "description":"Visit printed companions for one calm, limited XP lesson each day.", "rect":Rect2(0.37, 0.63, 0.27, 0.29), "objects":[{"id":"yard_companions", "name":"Daily Print Yard", "description":"Share today's local filament lesson with your current collection.", "target":"yard", "rect":Rect2(0.31, 0.44, 0.34, 0.28)}]}
	]

func _workshop_view_data(view_id: String) -> Dictionary:
	for view in _workshop_views():
		if str(view.id) == view_id: return view
	return {}

func _workshop_overview_texture() -> Texture2D:
	return WORKSHOP_OVERVIEW_PORTRAIT_TEXTURE if is_portrait_layout() else WORKSHOP_OVERVIEW_LANDSCAPE_TEXTURE

func _workshop_overview_hotspots() -> Array:
	# The v6 plates are full-room compositions. Each transparent target follows a
	# pictured physical object, so the overview goes straight to its destination.
	if is_portrait_layout():
		return [
			{"id":"printer", "name":"Workshop Model Forge", "description":"Review owned blueprints and print collection models.", "target":"unified_forgedex", "rect":Rect2(0.03, 0.45, 0.30, 0.15)},
			{"id":"collection", "name":"Printer Drawers", "description":"Review owned blueprints and printed models.", "target":"unified_forgedex", "rect":Rect2(0.06, 0.60, 0.28, 0.18)},
			{"id":"team", "name":"Pre-Print Board", "description":"Set a v3 deck and creature Pre-Print loadout.", "target":"unified_deck", "rect":Rect2(0.18, 0.10, 0.43, 0.13)},
			{"id":"armor", "name":"Equipment Cards", "description":"Browse battle full suits, combat gems, and the Filament Ring.", "target":"unified_library", "rect":Rect2(0.62, 0.10, 0.16, 0.20)},
			{"id":"battle_arena", "name":"Battle Arena", "description":"Choose daily training, Workshop Trials, or Local Versus.", "target":"proving", "rect":Rect2(0.24, 0.39, 0.54, 0.14)},
			{"id":"card_archive", "name":"Support Card Deck", "description":"Browse the Support Card Archive.", "target":"archive", "rect":Rect2(0.72, 0.69, 0.17, 0.13)},
			{"id":"shop", "name":"Forge Offers Panel", "description":"Review today's deterministic Forge Offers.", "target":"shop", "rect":Rect2(0.68, 0.50, 0.09, 0.13)},
			{"id":"codex", "name":"Forgedex Panel", "description":"Track discovered creature blueprints.", "target":"codex", "rect":Rect2(0.77, 0.50, 0.09, 0.13)},
			{"id":"trade", "name":"Guild Trade Panel", "description":"Open the credential-free local trade table.", "target":"trade", "rect":Rect2(0.86, 0.50, 0.10, 0.13)},
			{"id":"upgrade_forge", "name":"Upgrade Forge", "description":"Browse permanent Workshop upgrades and Upgrade Cards.", "target":"calibration", "rect":Rect2(0.29, 0.53, 0.07, 0.07)}
		]
	return [
			{"id":"printer", "name":"Workshop Model Forge", "description":"Review owned blueprints and print collection models.", "target":"unified_forgedex", "rect":Rect2(0.07, 0.43, 0.20, 0.27)},
			{"id":"collection", "name":"Printer Drawers", "description":"Review owned blueprints and printed models.", "target":"unified_forgedex", "rect":Rect2(0.22, 0.66, 0.12, 0.24)},
			{"id":"team", "name":"Pre-Print Board", "description":"Set a v3 deck and creature Pre-Print loadout.", "target":"unified_deck", "rect":Rect2(0.32, 0.08, 0.25, 0.16)},
			{"id":"armor", "name":"Equipment Cards", "description":"Browse battle full suits, combat gems, and the Filament Ring.", "target":"unified_library", "rect":Rect2(0.58, 0.08, 0.13, 0.20)},
		{"id":"battle_arena", "name":"Battle Arena", "description":"Choose daily training, Workshop Trials, or Local Versus.", "target":"proving", "rect":Rect2(0.31, 0.47, 0.40, 0.22)},
		{"id":"card_archive", "name":"Support Card Deck", "description":"Browse the Support Card Archive.", "target":"archive", "rect":Rect2(0.78, 0.76, 0.11, 0.13)},
		{"id":"shop", "name":"Forge Offers Panel", "description":"Review today's deterministic Forge Offers.", "target":"shop", "rect":Rect2(0.73, 0.47, 0.07, 0.16)},
		{"id":"codex", "name":"Forgedex Panel", "description":"Track discovered creature blueprints.", "target":"codex", "rect":Rect2(0.80, 0.47, 0.07, 0.16)},
		{"id":"trade", "name":"Guild Trade Panel", "description":"Open the credential-free local trade table.", "target":"trade", "rect":Rect2(0.87, 0.47, 0.07, 0.16)},
		{"id":"upgrade_forge", "name":"Upgrade Forge", "description":"Browse permanent Workshop upgrades and Upgrade Cards.", "target":"calibration", "rect":Rect2(0.25, 0.63, 0.05, 0.07)}
	]

func _workshop_texture(view_id: String) -> Texture2D:
	var path: String = str(WORKSHOP_CLOSEUP_PATHS.get(view_id, "res://assets/ui/workshop/workshop-theme-reference-fallback.jpg"))
	var resource := load(path)
	return resource as Texture2D if resource is Texture2D else REFERENCE_TEXTURE

func _workshop_station_texture(view_id: String) -> Texture2D:
	if view_id in ["printer", "maker"]:
		return _workshop_overview_texture()
	return _workshop_texture(view_id)

func _workshop_station_focus(view_id: String) -> Vector2:
	if view_id == "printer":
		return Vector2(0.26, 0.52) if is_portrait_layout() else Vector2(0.25, 0.63)
	if view_id == "maker":
		return Vector2(0.75, 0.52) if is_portrait_layout() else Vector2(0.80, 0.78)
	return Vector2(0.5, 0.5)

func _workshop_station_zoom(view_id: String) -> float:
	if view_id not in ["printer", "maker"]:
		return 1.0
	if is_portrait_layout():
		return 1.50
	return 1.70 if view_id == "printer" else 2.00

func _add_workshop_station_live(art_plane: Control) -> void:
	if workshop_view not in ["printer", "maker"]:
		return
	_workshop_screen_component.refresh(GameManager.profile, workshop_view, is_portrait_layout(), bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), workshop_station_live_capture_seed, workshop_station_live_capture_progress >= 0 or workshop_ambient_capture_freeze, workshop_station_live_capture_progress)
	_workshop_screen_component.attach(art_plane)

func _workshop_surface(name_value: String, texture: Texture2D, minimum_height: float, host: Control = null, cover_art := false, ambient_view := "overview", cover_backdrop := false, allow_portrait_pan := true, focus := Vector2(0.5, 0.5), art_zoom := 1.0) -> Control:
	var map_frame := PanelContainer.new()
	map_frame.custom_minimum_size = Vector2(0, minimum_height)
	map_frame.add_theme_stylebox_override("panel", panel_style(Color("071526e8"), Color("6bd6ed")))
	(host if host != null else body).add_child(map_frame)
	var map := Control.new()
	map.name = name_value
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.clip_contents = true
	map_frame.add_child(map)
	if cover_backdrop:
		var cover_image := TextureRect.new()
		cover_image.name = "WorkshopCoverBackdrop"
		cover_image.texture = texture
		cover_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cover_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover_image.modulate = Color(0.58, 0.75, 0.96, 0.60)
		cover_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(cover_image)
		var cover_shade := ColorRect.new()
		cover_shade.color = Color("07132670")
		cover_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(cover_shade)
	var art_plane := Control.new()
	art_plane.name = "%sArtPlane" % name_value
	# Empty room pixels pass drag input to the clipped map; child prop Buttons
	# retain their own click/focus behavior and forward drag gestures explicitly.
	art_plane.mouse_filter = Control.MOUSE_FILTER_PASS
	map.add_child(art_plane)
	var texture_size := texture.get_size()
	map.set_meta("workshop_art_aspect", texture_size.x / texture_size.y if texture_size.y > 0.0 else 1.5)
	map.set_meta("workshop_art_cover", cover_art)
	map.set_meta("workshop_stage_texture", texture.resource_path)
	map.set_meta("workshop_pan_enabled", cover_art and allow_portrait_pan and is_portrait_layout())
	map.set_meta("workshop_art_focus", focus)
	map.set_meta("workshop_art_zoom", art_zoom)
	map.resized.connect(_fit_workshop_art_plane.bind(map, art_plane))
	if bool(map.get_meta("workshop_pan_enabled", false)):
		map.gui_input.connect(_on_workshop_pan_gui_input.bind(map, art_plane))
		_add_workshop_pan_affordance(map, art_plane)
	call_deferred("_fit_workshop_art_plane", map, art_plane)
	var image := TextureRect.new()
	image.name = "WorkshopArtTexture"
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover_art else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.modulate = Color(0.94, 0.97, 1.0, 0.96)
	art_plane.add_child(image)
	var tint := ColorRect.new()
	tint.color = Color("07132618")
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_plane.add_child(tint)
	if ambient_view != "overview":
		var ambient := WORKSHOP_AMBIENT_LAYER.new()
		ambient.name = "WorkshopAmbientLayer"
		ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ambient.configure(ambient_view, not bool(settings().get("reduced_motion", false)) and not workshop_ambient_capture_freeze, 0.35)
		art_plane.add_child(ambient)
	if ambient_view != "overview" and not bool(settings().get("reduced_motion", false)) and not workshop_ambient_capture_freeze:
		var veil := ColorRect.new()
		veil.color = Color("b7efff80")
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_plane.add_child(veil)
		var tween := create_tween()
		tween.tween_property(veil, "modulate:a", 0.0, 0.18)
	return art_plane

func _fit_workshop_art_plane(map: Control, art_plane: Control) -> void:
	var available := map.size
	if available.x <= 0.0 or available.y <= 0.0: return
	var aspect: float = float(map.get_meta("workshop_art_aspect", 1.5))
	var fitted_width := maxf(available.x, available.y * aspect) if bool(map.get_meta("workshop_art_cover", false)) else minf(available.x, available.y * aspect)
	var fitted_size := Vector2(fitted_width, fitted_width / aspect)
	fitted_size *= float(map.get_meta("workshop_art_zoom", 1.0))
	art_plane.size = fitted_size
	var focus: Vector2 = map.get_meta("workshop_art_focus", Vector2(0.5, 0.5))
	var centered_position := available * 0.5 - fitted_size * focus
	if not bool(map.get_meta("workshop_art_cover", false)):
		centered_position = (available - fitted_size) * 0.5
	else:
		centered_position.x = clampf(centered_position.x, available.x - fitted_size.x, 0.0)
		centered_position.y = clampf(centered_position.y, available.y - fitted_size.y, 0.0)
	art_plane.position = centered_position
	if bool(map.get_meta("workshop_pan_enabled", false)):
		var saved_pan: float = float(map.get_meta("workshop_pan_x", centered_position.x))
		_set_workshop_pan(map, art_plane, saved_pan)

func _set_workshop_pan(map: Control, art_plane: Control, next_x: float) -> void:
	var minimum_x := minf(0.0, map.size.x - art_plane.size.x)
	var maximum_x := 0.0
	art_plane.position.x = clampf(next_x, minimum_x, maximum_x)
	map.set_meta("workshop_pan_x", art_plane.position.x)

func _on_workshop_pan_gui_input(event: InputEvent, map: Control, art_plane: Control) -> void:
	if not bool(map.get_meta("workshop_pan_enabled", false)):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_workshop_pan(map, art_plane, event.position)
		else:
			_end_workshop_pan(map)
	elif event is InputEventMouseMotion and bool(map.get_meta("workshop_pan_tracking", false)):
		_move_workshop_pan(map, art_plane, event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_workshop_pan(map, art_plane, event.position)
		else:
			_end_workshop_pan(map)
	elif event is InputEventScreenDrag:
		_move_workshop_pan(map, art_plane, event.position)

func _begin_workshop_pan(map: Control, art_plane: Control, pointer: Vector2) -> void:
	map.set_meta("workshop_pan_tracking", true)
	map.set_meta("workshop_pan_dragged", false)
	map.set_meta("workshop_pan_start_pointer", pointer)
	map.set_meta("workshop_pan_start_x", art_plane.position.x)

func _move_workshop_pan(map: Control, art_plane: Control, pointer: Vector2) -> void:
	var start_pointer: Vector2 = map.get_meta("workshop_pan_start_pointer", pointer)
	var delta_x := pointer.x - start_pointer.x
	if absf(delta_x) < 10.0 and not bool(map.get_meta("workshop_pan_dragged", false)):
		return
	map.set_meta("workshop_pan_dragged", true)
	_set_workshop_pan(map, art_plane, float(map.get_meta("workshop_pan_start_x", art_plane.position.x)) + delta_x)

func _end_workshop_pan(map: Control) -> void:
	map.set_meta("workshop_pan_tracking", false)

func _on_workshop_hotspot_gui_input(event: InputEvent, button: Button) -> void:
	var art_plane := button.get_parent() as Control
	var map := _workshop_scene_map(art_plane)
	if map == null or not bool(map.get_meta("workshop_pan_enabled", false)):
		return
	var was_dragged := bool(map.get_meta("workshop_pan_dragged", false))
	_on_workshop_pan_gui_input(event, map, art_plane)
	if was_dragged or bool(map.get_meta("workshop_pan_dragged", false)):
		button.set_meta("workshop_pan_cancelled", true)

func _pan_workshop_hotspot_into_view(button: Button) -> void:
	var art_plane := button.get_parent() as Control
	var map := _workshop_scene_map(art_plane)
	if map == null or not bool(map.get_meta("workshop_pan_enabled", false)):
		return
	var map_rect := map.get_global_rect()
	var hotspot_rect := button.get_global_rect()
	var padding := 18.0
	var adjustment := 0.0
	if hotspot_rect.position.x < map_rect.position.x + padding:
		adjustment = map_rect.position.x + padding - hotspot_rect.position.x
	elif hotspot_rect.end.x > map_rect.end.x - padding:
		adjustment = map_rect.end.x - padding - hotspot_rect.end.x
	if not is_zero_approx(adjustment):
		_set_workshop_pan(map, art_plane, art_plane.position.x + adjustment)

func _toggle_workshop_pan(map: Control, art_plane: Control) -> void:
	var minimum_x := minf(0.0, map.size.x - art_plane.size.x)
	var target_x := minimum_x if art_plane.position.x > minimum_x * 0.5 else 0.0
	_set_workshop_pan(map, art_plane, target_x)

func _add_workshop_pan_affordance(map: Control, art_plane: Control) -> void:
	var button := Button.new()
	button.name = "WorkshopPanAffordance"
	button.text = ""
	button.tooltip_text = "Swipe the workshop view to reach more tools"
	button.accessibility_name = "Swipe the workshop view to reach more tools"
	button.anchor_left = 0.45; button.anchor_right = 0.55
	button.anchor_top = 0.82; button.anchor_bottom = 0.88
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(44, 30)
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	var glyph := WORKSHOP_PAN_AFFORDANCE.new()
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	button.pressed.connect(_toggle_workshop_pan.bind(map, art_plane))
	map.add_child(button)

func _workshop_overview_hotspot_node_suffix(hotspot_id: String) -> String:
	var suffixes := {"battle_arena":"BattleArena", "card_archive":"CardArchive"}
	return str(suffixes.get(hotspot_id, hotspot_id.capitalize()))

func _workshop_overview_hotspot_button(hotspot: Dictionary) -> Button:
	var rect: Rect2 = hotspot.rect
	var button := Button.new()
	button.name = "WorkshopHotspot%s" % _workshop_overview_hotspot_node_suffix(str(hotspot.id))
	button.text = ""
	button.tooltip_text = "%s: %s" % [str(hotspot.name), str(hotspot.description)]
	button.accessibility_name = str(hotspot.name)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(44, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("workshop_target", str(hotspot.target))
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	# Overview targets deliberately have no visual hover/focus treatment: their
	# pictured prop is the affordance, while tooltip, focus, and cursor retain
	# discoverability without drawing a box over the v6 art.
	button.pressed.connect(activate_workshop_overview_hotspot.bind(str(hotspot.id)))
	return button

func _workshop_object_rect(object: Dictionary) -> Rect2:
	var object_id := str(object.id)
	# v3 live stations use landmark rectangles on the same cropped art plane as
	# their drawn printer/team display, so focus glow never crosses a live figure.
	if workshop_view == "printer":
		if object_id == "forge_machine":
			return Rect2(0.10, 0.38, 0.34, 0.26) if is_portrait_layout() else Rect2(0.08, 0.42, 0.24, 0.42)
		if object_id == "collection_case":
			return Rect2(0.02, 0.18, 0.20, 0.22) if is_portrait_layout() else Rect2(0.02, 0.18, 0.22, 0.24)
	if workshop_view == "maker":
		if object_id == "team_board":
			return Rect2(0.57, 0.43, 0.36, 0.17) if is_portrait_layout() else Rect2(0.63, 0.61, 0.31, 0.25)
		if object_id == "deck_blueprints":
			return Rect2(0.48, 0.34, 0.13, 0.12) if is_portrait_layout() else Rect2(0.53, 0.28, 0.12, 0.12)
		if object_id == "armor_tools":
			return Rect2(0.76, 0.36, 0.14, 0.13) if is_portrait_layout() else Rect2(0.84, 0.24, 0.12, 0.14)
		if object_id == "calibration_dial":
			return Rect2(0.63, 0.42, 0.12, 0.11) if is_portrait_layout() else Rect2(0.68, 0.34, 0.12, 0.12)
	return object.rect

func _workshop_object_button(object: Dictionary) -> Button:
	var rect: Rect2 = _workshop_object_rect(object)
	var button := Button.new()
	button.name = "WorkshopObject%s" % str(object.id).capitalize()
	button.text = ""
	button.tooltip_text = "%s: %s" % [str(object.name), str(object.description)]
	button.accessibility_name = str(object.name)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.custom_minimum_size = Vector2(44, 44)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", workshop_hotspot_style())
	button.add_theme_stylebox_override("hover", workshop_hotspot_style())
	button.add_theme_stylebox_override("focus", workshop_hotspot_style())
	button.add_theme_stylebox_override("pressed", workshop_hotspot_style())
	_add_workshop_hotspot_overlay(button, Color("ffd36c"))
	button.gui_input.connect(_on_workshop_hotspot_gui_input.bind(button))
	button.focus_entered.connect(_pan_workshop_hotspot_into_view.bind(button))
	button.pressed.connect(_select_workshop_object_if_not_dragged.bind(str(object.id), button))
	return button

func _select_workshop_object_if_not_dragged(object_id: String, button: Button) -> void:
	if bool(button.get_meta("workshop_pan_cancelled", false)):
		button.set_meta("workshop_pan_cancelled", false)
		return
	select_workshop_object(object_id)

func _add_workshop_hotspot_overlay(button: Button, color: Color) -> void:
	var overlay := WORKSHOP_HOTSPOT_OVERLAY.new()
	overlay.name = "WorkshopHotspotOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.configure(color, not bool(settings().get("reduced_motion", false)) and not workshop_ambient_capture_freeze, 0.25)
	button.add_child(overlay)
	button.mouse_entered.connect(overlay.set_emphasis.bind(0.65))
	button.mouse_exited.connect(overlay.set_emphasis.bind(0.0))
	button.focus_entered.connect(overlay.set_emphasis.bind(1.0))
	button.focus_exited.connect(overlay.set_emphasis.bind(0.0))
	button.button_down.connect(overlay.set_emphasis.bind(1.0))

func _workshop_settings_button() -> Button:
	var button := make_button("\u2699", navigate_to.bind("settings"), Color("536c8d"))
	button.name = "WorkshopSettingsButton"
	button.tooltip_text = "Settings: text scale, contrast, motion, and training difficulty"
	button.accessibility_name = "Workshop settings"
	button.anchor_left = 0.91; button.anchor_top = 0.035; button.anchor_right = 0.975; button.anchor_bottom = 0.145
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.add_theme_font_size_override("font_size", scaled_font(23))
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	return button

func _printer_picker_button() -> Button:
	var button := make_button("Open Arcane Forge", open_printer_picker, Color("a86b2e"))
	button.name = "PrinterBlueprintTrayButton"
	button.tooltip_text = "Open the Arcane Forge and choose a learned creature blueprint"
	button.accessibility_name = "Open Arcane Forge"
	# Keep selection reachable in the physical Printer station without covering the
	# presentation-only Forge. The right floor/cabinet stays clear in both crops.
	button.anchor_left = 0.70; button.anchor_right = 0.88
	button.anchor_top = 0.72 if is_portrait_layout() else 0.76
	button.anchor_bottom = button.anchor_top
	button.offset_left = 0; button.offset_right = 0
	button.offset_top = 0; button.offset_bottom = 48
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button

func _workshop_overview_button() -> Button:
	var button := make_button("\u2190", open_workshop_view.bind("overview"), Color("536c8d"))
	button.name = "WorkshopOverviewButton"
	button.tooltip_text = "Return to the full workshop overview"
	button.accessibility_name = "Return to Workshop Overview"
	button.anchor_left = 0.025; button.anchor_top = 0.035; button.anchor_right = 0.09; button.anchor_bottom = 0.145
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0
	button.add_theme_font_size_override("font_size", scaled_font(23))
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return button

func render_workshop_overview(used_today: int) -> void:
	overview_layout_portrait = is_portrait_layout()
	# Reserve enough portrait space for the bottom-row direct-object targets; the
	# prior 215px allowance clipped the Support Card Deck target on 576x1024.
	var viewport_height := get_viewport().get_visible_rect().size.y
	var overview_height := maxf(620.0, viewport_height - 235.0) if overview_layout_portrait else (maxf(360.0, viewport_height - 210.0) if viewport_height <= 600.0 else maxf(500.0, viewport_height - 150.0))
	# v6 overview plates are aspect-specific, static full-room shots. They never
	# host mutable-looking printer/team overlays or motion; those belong in stations.
	# Landscape keeps the complete orientation-matched foreground plane for its
	# normalized hotspot map, with a dim covered backdrop and modest zoom to
	# reduce empty side pillars without losing any pictured direct-object target.
	var landscape := not overview_layout_portrait
	var map := _workshop_surface("WorkshopMap", _workshop_overview_texture(), overview_height, null, false, "overview", landscape, false, Vector2(0.5, 0.5), 1.12 if landscape else 1.0)
	map.add_child(_workshop_settings_button())
	for hotspot in _workshop_overview_hotspots(): map.add_child(_workshop_overview_hotspot_button(hotspot))
	_add_workshop_overview_status(map, used_today)

func render_workshop_closeup(used_today: int) -> void:
	var view := _workshop_view_data(workshop_view)
	if view.is_empty():
		open_workshop_view("overview")
		return
	# `printer_picker_open` is retained as a serialized/caller compatibility bit,
	# never as a visible intermediate route. Creature selection lives in Forge.
	var picker_open := false
	# A selected tool gets a dedicated right-hand blueprint tray on desktop.
	# Portrait deliberately keeps the proven art-over-tray composition instead.
	if not is_portrait_layout() and (not workshop_drawer_object.is_empty() or picker_open):
		var split := HBoxContainer.new()
		split.name = "WorkshopCloseupSplit"
		split.custom_minimum_size = Vector2(0, 500)
		split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		split.add_theme_constant_override("separation", 16)
		body.add_child(split)
		var art_column := VBoxContainer.new()
		art_column.name = "WorkshopCloseupArt"
		art_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_column.size_flags_stretch_ratio = 6.0 if picker_open else 7.0
		split.add_child(art_column)
		var tray_column := VBoxContainer.new()
		tray_column.name = "WorkshopBlueprintTrayColumn"
		tray_column.custom_minimum_size = Vector2(420 if picker_open else 300, 0)
		tray_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tray_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tray_column.size_flags_stretch_ratio = 4.0 if picker_open else 3.0
		split.add_child(tray_column)
		var split_map := _workshop_surface("WorkshopCloseupMap", _workshop_station_texture(workshop_view), 500, art_column, true, workshop_view, false, true, _workshop_station_focus(workshop_view), _workshop_station_zoom(workshop_view))
		_add_workshop_station_live(split_map)
		var split_chrome := _workshop_scene_map(split_map)
		split_chrome.add_child(_workshop_overview_button())
		split_chrome.add_child(_workshop_settings_button())
		if workshop_view == "printer" and not picker_open:
			split_chrome.add_child(_printer_picker_button())
		for object in view.objects: split_map.add_child(_workshop_object_button(object))
		if picker_open:
			render_printer_blueprint_tray(tray_column)
		else:
			render_workshop_drawer(view, tray_column)
		return
	var portrait := is_portrait_layout()
	var closeup_height := 430.0 if portrait else 330.0
	if picker_open and portrait:
		# Leave enough room for the first picker tiles on small Android portrait
		# screens while retaining an unobscured live Printer Bench above them.
		closeup_height = 320.0
	elif workshop_drawer_object.is_empty():
		closeup_height = maxf(720.0, get_viewport().get_visible_rect().size.y - 250.0) if portrait else 560.0
	var live_station := workshop_view in ["printer", "maker"]
	var map := _workshop_surface("WorkshopCloseupMap", _workshop_station_texture(workshop_view), closeup_height, null, portrait or live_station, workshop_view, false, true, _workshop_station_focus(workshop_view), _workshop_station_zoom(workshop_view))
	_add_workshop_station_live(map)
	var chrome := _workshop_scene_map(map)
	chrome.add_child(_workshop_overview_button())
	chrome.add_child(_workshop_settings_button())
	if workshop_view == "printer" and not picker_open:
		chrome.add_child(_printer_picker_button())
	for object in view.objects: map.add_child(_workshop_object_button(object))
	# The Blueprint Tray owns the nearby explanatory space. Leaving the station
	# status strip underneath it creates a narrow, unreadable duplicate band.
	if not picker_open:
		_add_workshop_scene_status(map, view, used_today)
	if picker_open:
		render_printer_blueprint_tray()
		return
	if workshop_drawer_object.is_empty():
		return
	render_workshop_drawer(view)

func _add_workshop_scene_status(art_plane: Control, view: Dictionary, used_today: int) -> void:
	var scene_map := _workshop_scene_map(art_plane)
	if scene_map == null:
		return
	var strip := PanelContainer.new()
	strip.name = "WorkshopSceneStatus"
	strip.anchor_left = 0.025; strip.anchor_right = 0.975
	if workshop_view == "maker" and not is_portrait_layout():
		# The landscape three-plinth row rises into the upper-right. Keep its
		# compact explanatory tray on the unused lower-left rug/floor instead.
		strip.anchor_left = 0.04; strip.anchor_right = 0.40
		strip.anchor_top = 0.78; strip.anchor_bottom = 0.78
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = 0; strip.offset_bottom = 72
	elif workshop_view in ["printer", "maker"]:
		# Live v3 station scenes reserve their lower landmarks for the printer bed or
		# three plinths. A compact top strip leaves both controls and prop bases clear.
		strip.anchor_left = 0.14; strip.anchor_right = 0.84
		strip.anchor_top = 0.025; strip.anchor_bottom = 0.025
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = 0; strip.offset_bottom = 72
	else:
		strip.anchor_top = 1.0; strip.anchor_bottom = 1.0
		strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = -94; strip.offset_bottom = -14
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", inset_style(Color("102940e8"), Color("f1be69")))
	scene_map.add_child(strip)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	strip.add_child(content)
	content.add_child(label("%s - %s" % [str(view.name), str(view.callout)], 16, Color("ffd36c")))
	var detail := "Focus a highlighted tool to open its Blueprint Tray."
	if workshop_view == "maker": detail = "Choose a fixed deck, Pre-Print loadout, equipment cards, or Workshop upgrade."
	elif workshop_view == "yard": detail = "%d Workshop models are on display." % GameManager.profile.get("printed_models", {}).size()
	content.add_child(label(detail, 13, Color("dce8f4")))

func _add_workshop_overview_status(art_plane: Control, used_today: int) -> void:
	var scene_map := _workshop_scene_map(art_plane)
	if scene_map == null:
		return
	var strip := PanelContainer.new()
	strip.name = "WorkshopProgressionStrip"
	strip.anchor_left = 0.025; strip.anchor_right = 0.975
	strip.anchor_top = 1.0; strip.anchor_bottom = 1.0
	strip.offset_left = 0; strip.offset_right = 0; strip.offset_top = -94; strip.offset_bottom = -14
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", panel_style(Color("102940e8"), Color("6bd6ed")))
	scene_map.add_child(strip)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	strip.add_child(content)
	content.add_child(label("Explore the Workshop", 16, Color("9beaff")))
	content.add_child(label("Select a pictured tool or display to use it directly. Spool Level %d / 100 · %d XP toward next level." % [int(GameManager.profile.get("spool_level", 1)), int(GameManager.profile.get("spool_xp", 0))], 13, Color("dce8f4")))

func _workshop_scene_map(art_plane: Control) -> Control:
	return art_plane.get_parent() as Control

func _workshop_object_data(view: Dictionary, object_id: String) -> Dictionary:
	for object in view.objects:
		if str(object.id) == object_id: return object
	return {}

func render_workshop_drawer(view: Dictionary, host: Control = null) -> void:
	var object := _workshop_object_data(view, workshop_drawer_object)
	if object.is_empty():
		workshop_drawer_object = ""
		return
	var drawer := make_panel(Color("15344bea"), Color("f1be69"))
	drawer.get_parent().name = "WorkshopContextDrawer"
	(host if host != null else body).add_child(drawer.get_parent())
	drawer.add_child(label("Blueprint Tray - %s" % str(object.name), 20, Color("ffd36c")))
	drawer.add_child(label(str(object.description), 15, Color("e4edf7")))
	var target: String = str(object.target)
	var action_tiles := GridContainer.new()
	action_tiles.name = "WorkshopDrawerActions"
	action_tiles.columns = 2
	action_tiles.add_theme_constant_override("h_separation", 10)
	action_tiles.add_theme_constant_override("v_separation", 10)
	drawer.add_child(action_tiles)
	action_tiles.add_child(make_button(_workshop_action_label(target), _run_workshop_station.bind(target), Color("a86b2e") if target in ["printer", "calibration", "proving", "local_vs"] else Color("2f93a8")))
	action_tiles.add_child(make_button("Close Tray", close_workshop_drawer, Color("536c8d")))

func printer_blueprint_ids() -> Array[String]:
	# Retained facade for callers outside the integrated selector.
	return _blueprint_tray_view.blueprint_ids(GameManager.profile)

func select_printer_blueprint(creature_id: String) -> void:
	# Main owns the selected ID and dormant Forge preview; this remains
	# authority-neutral until the existing commit seam reaches raw completion.
	if printer_is_armor or printer_sequence == null or printer_sequence.phase != ArcaneForgeSequence.IDLE:
		return
	if creature_id not in printer_blueprint_ids():
		return
	printer_blueprint_selected_id = creature_id
	printer_creature_id = creature_id
	var definition := Catalog.creature(creature_id)
	printer_price = int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20))
	render()

func render_printer_blueprint_tray(host: Control = null) -> void:
	# Compatibility name: the former separate tray is now cards embedded directly
	# in the Arcane Forge. It deliberately owns no preview or close action.
	printer_blueprint_selected_id = _blueprint_tray_view.render(host if host != null else body, printer_blueprint_selected_id, {
		"profile": GameManager.profile,
		"portrait": is_portrait_layout(),
		"reduced_motion": bool(settings().get("reduced_motion", false)),
		"label": label,
		"make_button": make_button,
		"make_panel": make_panel,
		"inset_style": inset_style,
		"cartridge_style": func(selected: bool) -> StyleBox: return ARCANE_FOUNDRY_THEME_KIT.cartridge(selected, bool(settings().get("high_contrast", false))),
		"select_blueprint": select_printer_blueprint,
		"open_offers": navigate_to.bind("shop")
	})

func _workshop_action_label(target: String) -> String:
	var names := {"printer":"Open Model Forge", "collection":"Open Model Collection", "unified_forgedex":"Open Model Collection", "team":"Open Pre-Print Loadout", "unified_deck":"Open Pre-Print & Decks", "deck":"Edit Fixed Deck Slots", "archive":"Open Card Library", "unified_library":"Open Equipment Cards", "armor":"Open Equipment Cards", "calibration":"Open Upgrade Forge", "unified_upgrades":"Open Upgrade Forge", "shop":"Open Filament Market", "codex":"Open Forgedex", "trade":"Open Guild Trade", "proving":"Open Battle Arena", "trials":"Open Workshop Trials", "local_vs":"Start Local Versus", "yard":"Open Daily Quests"}
	return str(names.get(target, "Open Station"))

func open_workshop_view(view_id: String) -> void:
	# This is intentional station navigation, unlike a touch-driven draft refresh.
	# Restore a deterministic keyboard/controller target for the new location.
	_focus_after_render = true
	workshop_view = view_id if view_id == "overview" or not _workshop_view_data(view_id).is_empty() else "overview"
	workshop_selected = workshop_view
	workshop_drawer_object = ""
	printer_picker_open = false
	render()

func select_workshop_object(object_id: String) -> void:
	var object := _workshop_object_data(_workshop_view_data(workshop_view), object_id)
	if object.is_empty(): return
	workshop_drawer_object = object_id
	_toast(str(object.name))
	render()

func close_workshop_drawer() -> void:
	if workshop_drawer_object.is_empty(): return
	workshop_drawer_object = ""
	render()

func open_printer_picker() -> void:
	# Legacy facade: route straight into the unified creature Forge. There is no
	# visible intermediate close-up or Blueprint Tray state.
	var ids := printer_blueprint_ids()
	if printer_blueprint_selected_id not in ids:
		printer_blueprint_selected_id = str(ids[0]) if not ids.is_empty() else ""
	open_printer(printer_blueprint_selected_id)

func _focus_printer_picker_origin() -> void:
	if screen != "printer" or printer_is_armor or printer_sequence == null or printer_sequence.phase != ArcaneForgeSequence.IDLE: return
	# The outer vertical scroller can retain focus-driven offset from the previous
	# shell. Reset it even in landscape, which has no nested cartridge strip.
	var outer_scroll := find_child("TouchFirstScroll", true, false) as ScrollContainer
	if outer_scroll != null:
		outer_scroll.follow_focus = false
		outer_scroll.scroll_vertical = 0
	var cartridge_scroll := find_child("PrinterBlueprintCartridgeStrip", true, false) as ScrollContainer
	if cartridge_scroll != null:
		cartridge_scroll.follow_focus = false
		cartridge_scroll.scroll_horizontal = 0
	await get_tree().process_frame
	if screen != "printer": return
	if is_instance_valid(outer_scroll): outer_scroll.scroll_vertical = 0
	if is_instance_valid(cartridge_scroll): cartridge_scroll.scroll_horizontal = 0
	var first := find_child("PrinterSelectCinderpaw", true, false) as Button
	if first != null and first.is_visible_in_tree(): first.grab_focus()
	await get_tree().process_frame
	if screen != "printer": return
	if is_instance_valid(outer_scroll): outer_scroll.scroll_vertical = 0
	if is_instance_valid(cartridge_scroll): cartridge_scroll.scroll_horizontal = 0

func close_printer_picker() -> void:
	# Deprecated facade retained for old callers. The integrated screen uses its
	# normal idle Back action rather than exposing a tray close action.
	printer_picker_open = false
	if screen == "printer" and printer_sequence != null and printer_sequence.phase == ArcaneForgeSequence.IDLE:
		cancel_printer_preview()

func _workshop_stations() -> Array:
	return [
		{"id":"forge","name":"Printer Bench","description":"Review owned blueprints and print Workshop display models with Forge Coins.","actions":[{"label":"Open Model Collection","target":"unified_forgedex"}],"rect":Rect2(0.05,0.48,0.17,0.23)},
		{"id":"maker","name":"Maker Bench","description":"Set a fixed legal deck, choose Pre-Print creatures, browse Equipment Cards, and install Workshop upgrades.","actions":[{"label":"Open Pre-Print & Decks","target":"unified_deck"},{"label":"Open Equipment Cards","target":"unified_library"},{"label":"Open Upgrade Forge","target":"unified_upgrades"}],"rect":Rect2(0.27,0.68,0.25,0.17)},
		{"id":"terminal","name":"Forge Terminal","description":"Browse deterministic offers, track creature records, or open the kid-safe local trade table.","actions":[{"label":"Open Forge Offers","target":"shop"},{"label":"Open Forgedex","target":"codex"},{"label":"Open Trade Table","target":"trade"}],"rect":Rect2(0.76,0.50,0.19,0.23)},
		{"id":"door","name":"Battle Arena","description":"Challenge today’s deterministic training rival or pass the device for a local match.","actions":[{"label":"Start Training","target":"proving"},{"label":"Start Local Versus","target":"local_vs"}],"rect":Rect2(0.41,0.25,0.19,0.33)},
		{"id":"yard","name":"Print Yard","description":"Visit companions for one daily XP filament lesson.","actions":[{"label":"Visit Print Yard","target":"yard"}],"rect":Rect2(0.05,0.77,0.18,0.13)},
		{"id":"settings","name":"Settings","description":"Adjust text, contrast, motion, and AI training difficulty.","actions":[{"label":"Open Settings","target":"settings"}],"rect":Rect2(0.84,0.08,0.12,0.11)}]

func _workshop_station(id: String) -> Dictionary:
	for station in _workshop_stations():
		if str(station.id) == id: return station
	return _workshop_stations()[0]

func _workshop_hotspot(station: Dictionary) -> Button:
	var rect: Rect2 = station.rect
	var button := Button.new(); button.text = str(station.name); button.tooltip_text = str(station.description)
	button.anchor_left = rect.position.x; button.anchor_top = rect.position.y; button.anchor_right = rect.end.x; button.anchor_bottom = rect.end.y
	button.offset_left = 0; button.offset_top = 0; button.offset_right = 0; button.offset_bottom = 0; button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_size_override("font_size", scaled_font(13))
	var chosen := str(station.id) == workshop_selected
	button.add_theme_stylebox_override("normal", panel_style(Color("a86b2ed0") if chosen else Color("142840d8"), Color("fff0a1") if chosen else Color("8deaff")))
	button.add_theme_stylebox_override("hover", panel_style(Color("2f93a8ed"), Color("ffffff")))
	button.pressed.connect(func(): workshop_selected = str(station.id); render())
	return button

func activate_workshop_overview_hotspot(hotspot_id: String) -> void:
	# Kept as a callable seam for keyboard/UI tests. The overview is a direct
	# object map; it never opens legacy station close-ups before routing.
	for hotspot in _workshop_overview_hotspots():
		if str(hotspot.id) != hotspot_id:
			continue
		_run_workshop_station(str(hotspot.target))
		return
	push_error("Unknown workshop overview hotspot: %s" % hotspot_id)

func claim_overview_calibration() -> void:
	# Compatibility entry point for older UI tests. The active v3 dial is the
	# Upgrade Forge; it never grants retired calibration coins.
	navigate_to("calibration")

func _run_workshop_station(id: String) -> void:
	match id:
		"printer": open_printer_picker()
		"collection", "shop", "codex", "team", "deck", "archive", "armor", "settings", "unified_forgedex", "unified_deck", "unified_library", "unified_upgrades": navigate_to(id)
		"proving": navigate_to("proving")
		"trials": navigate_to("trials")
		"local_vs": start_local_vs()
		"trade": local_trade = null; trade_creator_choice = ""; trade_partner_choice = ""; navigate_to("trade")
		"yard", "calibration": navigate_to(id)

func start_local_vs() -> void:
	# Hot-seat uses the same public v3 snapshot and seat-redacted hands as solo.
	# The rival deck defaults to the active legal deck, making both seats play the
	# same owned-card composition until second-deck selection is authored.
	_launch_unified_mode("local", {}, 20260814)

func _guildmate_profile() -> Dictionary:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "aquafin").profile
	profile.coins = 0
	profile.blueprints.append("voltwig")
	var printed := ProgressionRules.print_creature({"coins":99,"blueprints":["voltwig"],"creatures":[],"armor":[],"discovered":[],"team":[],"next_instance_nonce":7,"onboarding":profile.onboarding,"support_cards":{},"decks":[],"active_deck_id":"","armor_blueprints":[],"shop":[]}, "voltwig")
	profile.creatures.append(printed.profile.creatures[0]); profile.creatures[-1].bound = false; profile.creatures[-1].tradable = true
	return profile

func render_local_trade() -> void:
	var panel := make_panel(Color("19334de8"), Color("a8edff")); body.add_child(panel.get_parent())
	panel.add_child(label("Guild Trade Table", 25, Color("a8edff")))
	if local_trade == null: local_trade = LocalTradeAuthority.create(GameManager.profile, _guildmate_profile())
	panel.add_child(label("Local demo pairing code: %s" % local_trade.code, 17, Color("fff0a1")))
	panel.add_child(label("Two revision locks, two confirmations, one atomic settlement. The guildmate remains session-only.", 15, Color("dce8f4")))
	if local_trade.settled:
		panel.add_child(label("Settlement receipt", 19, Color("a8e3a5")))
		panel.add_child(label("You received %s for %s. Audit %s. Your profile was updated; the guildmate was not saved." % [_trade_name(GameManager.profile, local_trade.requested_id), _trade_name(local_trade.partner, local_trade.offered_id), str(local_trade.audit.back().code)], 15, Color("dce8f4")))
		body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
		return
	var yours := local_trade.eligible(local_trade.creator); var theirs := local_trade.eligible(local_trade.partner)
	panel.add_child(label("Your eligible prints", 18, Color("ffd36c")))
	if yours.is_empty(): panel.add_child(label("Print an extra unbound, unequipped copy before local trade.", 15, Color("ffaaa1")))
	for id in yours: panel.add_child(make_button("Offer %s" % _trade_name(local_trade.creator, id), func(): select_trade_choice(0, id), Color("4d7898")))
	panel.add_child(label("Guildmate eligible prints", 18, Color("a8edff")))
	for id in theirs: panel.add_child(make_button("Request %s" % _trade_name(local_trade.partner, id), func(): select_trade_choice(1, id), Color("4d7898")))
	if not local_trade.offered_id.is_empty() and not local_trade.requested_id.is_empty() and not local_trade.settled:
		panel.add_child(label("Escrow draft: %s for %s" % [_trade_name(local_trade.creator, local_trade.offered_id), _trade_name(local_trade.partner, local_trade.requested_id)], 16, Color("fff0a1")))
		panel.add_child(label("Creator: %s  |  Guildmate: %s" % ["Confirmed" if local_trade.creator_confirmed else "Awaiting confirmation", "Confirmed" if local_trade.partner_confirmed else "Awaiting confirmation"], 15, Color("a8e3a5") if local_trade.creator_confirmed and local_trade.partner_confirmed else Color("dce8f4")))
		panel.add_child(make_button("Creator Confirm" if not local_trade.creator_confirmed else "Creator Confirmed", func(): confirm_local_trade(0), Color("a86b2e")))
		panel.add_child(make_button("Guildmate Confirm" if not local_trade.partner_confirmed else "Guildmate Confirmed", func(): confirm_local_trade(1), Color("588d73")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func confirm_local_trade(seat: int) -> void:
	var result := local_trade.confirm(seat, local_trade.creator_revision, local_trade.partner_revision)
	if not bool(result.ok): _toast(str(result.error)); return
	if bool(result.get("settled", false)):
		# A terminal keyboard/controller action should regain a predictable target.
		# Ordinary touch-driven drafts deliberately leave focus untouched.
		_focus_after_render = true
		GameManager.settle_local_trade(result.creator, result.audit)
	else: render()

func select_trade_choice(seat: int, instance_id: String) -> void:
	if local_trade == null or local_trade.settled: return
	if seat == 0: trade_creator_choice = instance_id
	else: trade_partner_choice = instance_id
	if not trade_creator_choice.is_empty() and not trade_partner_choice.is_empty():
		var draft := local_trade.choose(trade_creator_choice, trade_partner_choice)
		if not bool(draft.ok): _toast(str(draft.error))
	render()

func _trade_name(profile: Dictionary, instance_id: String) -> String:
	for creature in profile.get("creatures", []):
		if str(creature.get("instance_id", "")) == instance_id: return str(Catalog.creature(str(creature.get("creature_id", ""))).get("name", "Printed companion"))
	return "Printed companion"

func render_shop() -> void:
	var intro := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(intro.get_parent())
	intro.add_child(label("Extruder Forge", 25, Color("ffd36c")))
	intro.add_child(label("Offline rotation for %s. Prices are listed by the Forge and repeat deterministically for this day." % shop_day_key, 15, Color("dce8f4")))
	var grid := GridContainer.new(); grid.columns = 3 if size.x >= 900 else 1; body.add_child(grid)
	for offer in GameManager.daily_shop(shop_day_key):
		var card := make_panel(Color("152842e8"), Color("7dd7ef")); grid.add_child(card.get_parent())
		if str(offer.get("kind", "")) == "support_card":
			var definition := Catalog.support_card(str(offer.get("item_id", "")))
			var preview = _new_support_card_view()
			if preview != null:
				preview.configure(definition, int(GameManager.profile.support_cards.get(str(offer.get("item_id", "")), 0)), "", false, false, false); preview.name = "ShopCard%s" % str(offer.get("item_id", "")).capitalize(); card.add_child(preview)
		card.add_child(label(str(offer.name), 19, Color("8deaff")))
		card.add_child(label(str(offer.kind).replace("_", " ").capitalize() + " • " + str(offer.price) + " FC", 14, Color("dce8f4")))
		card.add_child(make_button("Acquire", func(): GameManager.buy_shop_offer(shop_day_key, str(offer.offer_id))))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_print_yard() -> void:
	var panel := make_panel(Color("19334de8"), Color("7bcf89")); body.add_child(panel.get_parent())
	panel.add_child(label("Print Yard", 25, Color("a8e3a5")))
	panel.add_child(label("Choose one calm, deterministic drill for today. Each choice can be claimed only once.", 16, Color("dce8f4")))
	panel.add_child(label("Companions present: %d | Current XP: %d | Pending warmup: +%d starting filament" % [GameManager.profile.creatures.size(), int(GameManager.profile.xp), int(GameManager.profile.get("pending_spool_warmup", 0))], 15, Color("9beaff")))
	var already := str(GameManager.profile.get("last_yard_day", "")) == shop_day_key
	var chosen := str(GameManager.profile.get("yard_choice", ""))
	panel.add_child(label("Today's drill: %s" % (chosen.replace("_", " ").capitalize() if already else "Choose one below"), 15, Color("a8e3a5") if already else Color("fff0a1")))
	for drill_id in ["field_practice", "team_bond", "spool_warmup"]:
		var unavailable: bool = drill_id == "spool_warmup" and GameManager.filament_cap() <= 3
		var copy: String = str({"field_practice":"Field Practice - +12 account XP", "team_bond":"Team Bond - +5 mastery to each saved team print", "spool_warmup":"Spool Warmup - +1 starting filament for next solo match (Requires spool capacity 4+)" if unavailable else "Spool Warmup - +1 starting filament for next solo match"}[drill_id])
		var drill_button := make_button(copy, run_print_yard_drill.bind(drill_id), Color("588d73") if not already and not unavailable else Color("536c8d"))
		drill_button.disabled = already or unavailable
		panel.add_child(drill_button)
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func run_print_yard_drill(drill_id: String) -> void:
	var before := int(GameManager.profile.get("revision", 0))
	GameManager.visit_print_yard(shop_day_key, drill_id)
	if int(GameManager.profile.get("revision", 0)) > before: _toast("Print Yard drill complete.")

func render_calibration_bench() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	var used: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	panel.add_child(label("Calibration Bench", 25, Color("ffd36c")))
	var targets: Array = ProgressionRules.calibration_pattern(shop_day_key, used)
	if calibration_step >= 3 or used >= ProgressionRules.DAILY_CALIBRATION_LIMIT: calibration_step = 0; calibration_values = [50, 50, 50]
	panel.add_child(label("Today: %d / %d patterns complete. Confirm all three values to score this pattern." % [used, ProgressionRules.DAILY_CALIBRATION_LIMIT], 15, Color("9beaff")))
	if used < ProgressionRules.DAILY_CALIBRATION_LIMIT:
		var target: int = int(targets[calibration_step])
		var value: int = int(calibration_values[calibration_step])
		panel.add_child(label("Step %d / 3 - target band %d to %d | selected %d" % [calibration_step + 1, maxi(0, target - 5), mini(100, target + 5), value], 18, Color("fff0a1")))
		var adjust := HBoxContainer.new(); panel.add_child(adjust)
		adjust.add_child(make_button("-10", adjust_calibration.bind(-10), Color("536c8d")))
		adjust.add_child(make_button("+10", adjust_calibration.bind(10), Color("2f93a8")))
		panel.add_child(make_button("Confirm Step %d" % (calibration_step + 1), confirm_calibration_step, Color("a86b2e")))
	else: panel.add_child(label("All three calibration patterns are complete for today.", 16, Color("a8e3a5")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func adjust_calibration(delta: int) -> void:
	calibration_values[calibration_step] = clampi(int(calibration_values[calibration_step]) + delta, 0, 100)
	render()

func confirm_calibration_step() -> void:
	calibration_step += 1
	if calibration_step < 3:
		render()
		return
	var used: int = int(GameManager.profile.daily_job_count) if str(GameManager.profile.last_job_day) == shop_day_key else 0
	var performance := ProgressionRules.calibration_performance(ProgressionRules.calibration_pattern(shop_day_key, used), calibration_values)
	var reward := GameManager.complete_workshop_job(performance, shop_day_key)
	if reward > 0: _toast("Calibration result %d%%: +%d Forge Coins." % [performance, reward])
	calibration_step = 0; calibration_values = [50, 50, 50]

func render_settings() -> void:
	var panel := make_panel(Color("19334de8"), Color("ffd36c")); body.add_child(panel.get_parent())
	var current := settings()
	panel.add_child(label("Workshop Settings", 25, Color("ffd36c")))
	panel.add_child(label("Installed review build: " + REVIEW_BUILD_LABEL, 13, Color("9beaff")))
	panel.add_child(label("Settings are saved to this profile. Text, contrast, and motion controls never change battle rules.", 15, Color("dce8f4")))
	for scale in AccessibilityRules.TEXT_SCALES:
		panel.add_child(make_button("Text size %d%%" % (int(scale) / 100), func(): GameManager.save_settings({"text_scale_bps":scale}), Color("588d73") if int(current.text_scale_bps) == int(scale) else Color("2f93a8")))
	panel.add_child(make_button("High contrast: %s" % ("On" if bool(current.high_contrast) else "Off"), func(): GameManager.save_settings({"high_contrast":not bool(current.high_contrast)})))
	panel.add_child(make_button("Reduced motion: %s" % ("On" if bool(current.reduced_motion) else "Off"), func(): GameManager.save_settings({"reduced_motion":not bool(current.reduced_motion)})))
	panel.add_child(label("Audio mix - procedural workshop tones only. Captions remain visible for gameplay cues.", 15, Color("9beaff")))
	for audio_key in ["master_bps", "music_bps", "sfx_bps"]:
		var title: String = str({"master_bps":"Master", "music_bps":"Music", "sfx_bps":"SFX"}[audio_key])
		panel.add_child(label("%s: %s" % [title, AudioSettings.label_for(int(current.get(audio_key, 0)))], 15, Color("dce8f4")))
		var row := HBoxContainer.new(); panel.add_child(row)
		row.add_theme_constant_override("separation", 8)
		var lower := make_button("Lower", adjust_audio_setting.bind(audio_key, -1), Color("536c8d"))
		lower.name = "Audio%sLower" % title
		lower.custom_minimum_size = Vector2(120, 48)
		lower.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(lower)
		var raise := make_button("Raise", adjust_audio_setting.bind(audio_key, 1), Color("2f93a8"))
		raise.name = "Audio%sRaise" % title
		raise.custom_minimum_size = Vector2(120, 48)
		raise.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.add_child(raise)
	panel.add_child(label("Daily contract difficulty is fixed by the Guild: Apprentice, Craftsman, and Master. The legacy Training AI setting remains saved for compatibility but is no longer selectable.", 14, Color("9beaff")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
	# The shared keyboard-first focus pass targets the first text-scale button.
	# On a short landscape viewport Godot can then retain that button's old scroll
	# offset and hide the Settings heading. Reset only the initial route origin;
	# later keyboard/touch focus still uses the normal ScrollContainer behavior.
	call_deferred("_restore_settings_scroll_origin")

func _restore_settings_scroll_origin() -> void:
	await get_tree().process_frame
	if screen != "settings": return
	var scroll := find_child("TouchFirstScroll", true, false) as ScrollContainer
	if is_instance_valid(scroll): scroll.scroll_vertical = 0

func adjust_audio_setting(key: String, direction: int) -> void:
	var levels: Array[int] = AudioSettings.LEVELS
	var current: int = int(settings().get(key, 0))
	var index := levels.find(current)
	if index < 0: index = levels.find(5000)
	index = clampi(index + direction, 0, levels.size() - 1)
	GameManager.save_settings({key:levels[index]})
	_audio_director.configure(settings(), false)

func open_printer(creature_id: String) -> void:
	var free_starter := str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and creature_id == str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
	if not creature_id.is_empty() and (Catalog.creature(creature_id).is_empty() or (not bool(GameManager.profile.get("owned_blueprints", {}).get(creature_id, false)) and not free_starter)):
		_toast("That blueprint is not learned yet.")
		return
	printer_creature_id = creature_id
	printer_blueprint_selected_id = creature_id
	printer_armor_id = ""
	printer_is_armor = false
	printer_is_core = false
	var definition := Catalog.creature(creature_id)
	printer_price = 0 if free_starter else (int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)) if not definition.is_empty() else 0)
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)))
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	printer_failure = ""
	# Re-selecting from an existing Forge (for tests or future keyboard routing)
	# must preserve its original caller instead of making Back a no-op.
	if screen != "printer":
		printer_return_screen = screen
	# Creature Forge entry from any Workshop surface always returns to the direct
	# overview. The old printer close-up is no longer part of this route.
	if screen == "workshop": workshop_return_view = "overview"
	printer_picker_open = false
	screen = "printer"
	render()
	call_deferred("_focus_printer_picker_origin")

func render_printer() -> void:
	var definition := Catalog.creature(printer_creature_id)
	if printer_sequence == null:
		cancel_printer_preview()
		return
	printer_progress_label = null
	var panel := make_panel(Color("152d49ec"), Color("f1be69"))
	body.add_child(panel.get_parent())
	panel.add_child(label("Arcane Forge", 27, Color("ffd36c")))
	var print_name := (str(ArmorCoreDefinitions.core_blueprint_definition(printer_armor_id).get("name", "Core")) if printer_is_core else str(ProgressionRules.armor_def(printer_armor_id).get("name", "Full Suit"))) if printer_is_armor else str(definition.get("name", "No learned blueprint selected"))
	var print_type := ("Printed Core" if printer_is_core else "Complete suit") if printer_is_armor else str(definition.get("element", "Creature blueprint"))
	var portrait := is_portrait_layout()
	var layout: Control = VBoxContainer.new() if portrait else HBoxContainer.new()
	layout.name = "IntegratedForgeLayout"
	layout.add_theme_constant_override("separation", 14)
	panel.add_child(layout)
	var printer_column := VBoxContainer.new()
	printer_column.name = "ArcaneForgePrinterColumn"
	printer_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	printer_column.size_flags_stretch_ratio = 1.35 if not portrait else 1.0
	layout.add_child(printer_column)
	var forge_component = _forge_component()
	if forge_component != null:
		forge_component.refresh(printer_creature_id, bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), printer_sequence.phase, printer_sequence.progress_bps, printer_sequence.phase_progress_bps(), printer_presentation_seconds, 500 if portrait else 330, printer_armor_id if printer_is_armor else "", printer_armor_id if printer_is_core else "")
		forge_component.attach(printer_column)
	else:
		printer_column.add_child(label("Forge preview is unavailable, but this screen remains safe to exit without changing your profile.", 14, Color("ffcfbf")))
	var action_column: VBoxContainer = printer_column if portrait else VBoxContainer.new()
	if not portrait:
		action_column.name = "ArcaneForgeSelectorColumn"
		action_column.custom_minimum_size = Vector2(330, 0)
		action_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(action_column)
	if not printer_is_armor and printer_sequence.phase == ArcaneForgeSequence.IDLE:
		var facts := make_panel(Color("102940ec"), Color("6bd6ed"))
		facts.get_parent().name = "PrinterSelectionFacts"
		action_column.add_child(facts.get_parent())
		facts.add_child(label("%s - %s - %d Forge Coins" % [print_name, print_type, printer_price], 17, Color("9beaff")))
		facts.add_child(label("Owned prints: %d | Available Forge Coins: %d" % [_blueprint_tray_view.owned_count(GameManager.profile, printer_creature_id), int(GameManager.profile.get("forge_coins", 0))], 14, Color("e6dfd0")))
		facts.add_child(label("Selecting a cartridge updates this dormant build plate only. Coins and inventory change only at the secured completion seam.", 13, Color("dce8f4")))
		render_printer_blueprint_tray(action_column)
	else:
		action_column.add_child(label("%s - %s - %d Forge Coins" % [print_name, print_type, printer_price], 16, Color("9beaff")))
		action_column.add_child(label("Available Forge Coins: %d. The profile changes only when the raw print completes." % int(GameManager.profile.get("forge_coins", 0)), 15, Color("dce8f4")))
	match printer_sequence.phase:
		ArcaneForgeSequence.IDLE:
			if printer_is_armor:
				action_column.add_child(label("Preview the dormant print on the build plate. Begin only when ready.", 16, Color("fff0a1")))
			elif definition.is_empty():
				action_column.add_child(label("No learned creature blueprints are ready. Visit Forge Offers to learn a pattern, then return to this Forge.", 16, Color("fff0a1")))
				var offers := make_button("Open Forge Offers", navigate_to.bind("shop"), Color("2f93a8"))
				offers.name = "PrinterBlueprintEmptyOffers"
				action_column.add_child(offers)
			else:
				action_column.add_child(label("Choose a blueprint, then begin when ready.", 16, Color("fff0a1")))
				var starter_free := str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and printer_creature_id == str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
				var begin := make_button("Print starter free" if starter_free else "Begin Print (%d FC)" % printer_price, begin_printer, Color("a86b2e"))
				begin.name = "BeginCreaturePrint"
				action_column.add_child(begin)
			var back := make_button("Back to Workshop Overview" if printer_return_screen == "workshop" else "Back to Collection", cancel_printer_preview, Color("536c8d"))
			back.name = "ArcaneForgeBack"
			action_column.add_child(back)
		ArcaneForgeSequence.PRINTING:
			printer_progress_label = label(_printer_progress_text(), 16, Color("9beaff"))
			printer_progress_label.name = "PrinterProgressStatus"
			action_column.add_child(printer_progress_label)
			action_column.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.RAW_COMPLETE:
			action_column.add_child(label("Raw print complete. Securing the Forge transaction...", 16, Color("fff0a1")))
		ArcaneForgeSequence.RAW_HOLD:
			var hold_text := ("Completed Core rests for a moment before transfer to the Equipment Workbench." if printer_is_core else "Completed full suit rests for a moment before transfer to the Equipment Workbench.") if printer_is_armor else "Raw print complete. The Forge record is secure; the dormant form rests for a moment before awakening."
			action_column.add_child(label(hold_text, 16, Color("fff0a1")))
			action_column.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENING:
			action_column.add_child(label("Filament awakening in progress. The new print is already safely recorded.", 16, Color("9beaff")))
			action_column.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.DEPARTING:
			var departing_name := print_name
			action_column.add_child(label("%s leaves the build plate for the workbench." % departing_name, 16, Color("a8e3a5")))
			action_column.add_child(make_button("Skip Animation", skip_printer, Color("526e93")))
		ArcaneForgeSequence.AWAKENED:
			var completion_text := ("Core secured: %s is ready for the Equipment Workbench." if printer_is_core else "Full suit secured: %s is ready for the Equipment Workbench.") % print_name if printer_is_armor else "Welcome, %s! Your living print is ready for the Collection." % str(definition.name)
			action_column.add_child(label(completion_text, 20, Color("a8e3a5")))
			action_column.add_child(make_button("Print Another" if not printer_is_armor else "Print Another Equipment Item", return_to_printer_picker, Color("a86b2e")))
			action_column.add_child(make_button(("Return to Workshop Overview" if printer_return_screen == "workshop" else "Return to Collection") if not printer_is_armor else "Return to Equipment Workbench", return_to_printer_station, Color("536c8d")))
		ArcaneForgeSequence.FAILED:
			action_column.add_child(label("The Forge could not complete this print: %s" % printer_failure, 17, Color("ffaaa1")))
			action_column.add_child(make_button("Return to Collection", navigate_to.bind("collection"), Color("536c8d")))
		_:
			action_column.add_child(label("Preview closed without changing your profile.", 16, Color("dce8f4")))

func _printer_progress_text() -> String:
	if printer_sequence == null: return ""
	return "Printing layers: %d%%. The nozzle and reveal are presentation only." % (printer_sequence.layer_reveal_bps() / 100)

func _refresh_printer_presentation() -> void:
	if screen != "printer" or printer_sequence == null: return
	var forge_component = _forge_component()
	if forge_component != null:
		forge_component.refresh(printer_creature_id, bool(settings().get("reduced_motion", false)), bool(settings().get("high_contrast", false)), printer_sequence.phase, printer_sequence.progress_bps, printer_sequence.phase_progress_bps(), printer_presentation_seconds, 540 if size.y > size.x else 330, printer_armor_id if printer_is_armor else "", printer_armor_id if printer_is_core else "")
	if is_instance_valid(printer_progress_label):
		printer_progress_label.text = _printer_progress_text()

func begin_printer() -> void:
	if printer_sequence == null or not printer_sequence.begin(): return
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	render()

func advance_printer_for_test(step_bps: int) -> void:
	if printer_sequence == null: return
	var phase_before := printer_sequence.phase
	printer_sequence.advance(step_bps)
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		_commit_printer_once()
		render()
	elif printer_sequence.phase != phase_before:
		render()
	else:
		_refresh_printer_presentation()

func _commit_printer_once() -> void:
	if printer_sequence == null or not printer_sequence.request_commit(): return
	var is_free_starter := not printer_is_armor and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and printer_creature_id == str(GameManager.profile.get("onboarding", {}).get("starter_id", ""))
	var success := false
	if is_free_starter: success = GameManager.print_selected_starter()
	elif printer_is_armor: success = GameManager.print_core(printer_armor_id) if printer_is_core else GameManager.print_suit(printer_armor_id)
	else: success = bool(GameManager.print_workshop_model_v3(printer_creature_id, "forge-animation-%d" % Time.get_ticks_msec()).get("ok", false))
	if not success: printer_failure = "The blueprint, coins, or inventory no longer passed validation."
	printer_sequence.resolve_commit(success)

func skip_printer() -> void:
	if printer_sequence == null or not printer_sequence.skip(): return
	if printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE: _commit_printer_once()
	render()

func cancel_printer_preview() -> void:
	if printer_sequence != null: printer_sequence.cancel()
	printer_creature_id = ""
	printer_armor_id = ""
	printer_is_armor = false
	printer_is_core = false
	screen = printer_return_screen
	if screen == "workshop": workshop_view = workshop_return_view
	render()

func return_to_printer_station() -> void:
	if printer_return_screen == "armor":
		navigate_to("armor")
		return
	if printer_return_screen == "workshop":
		screen = "workshop"
		workshop_view = "overview"
		workshop_selected = "printer"
		workshop_drawer_object = ""
		render()
		return
	navigate_to("collection")

func return_to_printer_picker() -> void:
	if printer_return_screen == "armor":
		open_armor_printer(printer_armor_id)
		return
	# Keep creature printing in the same integrated Forge. This is presentation
	# state only and deliberately does not touch profile, coins, or revision.
	var ids := printer_blueprint_ids()
	if printer_blueprint_selected_id not in ids:
		printer_blueprint_selected_id = str(ids[0]) if not ids.is_empty() else ""
	printer_creature_id = printer_blueprint_selected_id
	var definition := Catalog.creature(printer_creature_id)
	printer_price = int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)) if not definition.is_empty() else 0
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)))
	printer_tick_accumulator = 0.0
	printer_presentation_seconds = 0.0
	printer_failure = ""
	screen = "printer"
	render()
	call_deferred("_focus_printer_picker_origin")

func render_collection() -> void:
	# Legacy callers can still name this screen, but v3 profiles have no printed
	# creature-instance array. Route them to the model/blueprint collection.
	if not GameManager.profile.has("creatures"):
		screen = "unified_forgedex"
		render()
		return
	var intro := make_panel(Color("19334de8"), Color("8deaff")); body.add_child(intro.get_parent())
	intro.add_child(label("Collection & Print Yard", 25, Color("8deaff")))
	intro.add_child(label("%d printed creature instances are safely stored in your workshop. Every learned blueprint can be printed here." % GameManager.profile.creatures.size(), 15, Color("dce8f4")))
	for blueprint_id in GameManager.profile.blueprints:
		var blueprint := Catalog.creature(str(blueprint_id))
		if not blueprint.is_empty():
			var price: int = int(Catalog.rarity(str(blueprint.rarity)).print)
			intro.add_child(make_button("Print %s (%d FC)" % [str(blueprint.name), price], func(): open_printer(str(blueprint.id)), Color("a86b2e")))
	for creature in GameManager.profile.creatures:
		var row := make_panel(Color("152842e8"), Color("5e99b4")); body.add_child(row.get_parent())
		var instance_id := str(creature.get("instance_id", ""))
		row.add_child(label("%s - %s%s - Mastery %d" % [str(Catalog.creature(str(creature.creature_id)).name), "Bound" if bool(creature.get("bound", false)) else "Printed", " - Full suit fitted" if not str(creature.get("suit_instance_id", "")).is_empty() else "", GameManager.creature_mastery(instance_id)], 16, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_team() -> void:
	var intro := make_panel(Color("19334de8"), Color("8deaff")); body.add_child(intro.get_parent())
	intro.add_child(label("Three-Slot Team Builder", 25, Color("8deaff")))
	if not team_draft_dirty: team_draft = Array(GameManager.profile.get("team", [])).duplicate()
	intro.add_child(label("Draft training team: %d / 3. Every selected print is unique; a team needs one to three companions." % team_draft.size(), 15, Color("dce8f4")))
	for creature in GameManager.profile.creatures:
		var instance_id := str(creature.get("instance_id", ""))
		if instance_id.is_empty(): continue
		var selected: bool = instance_id in team_draft
		var creature_name := str(Catalog.creature(str(creature.get("creature_id", ""))).get("name", "Unknown"))
		var roster = _optional_script(TIERED_ARMOR_ROSTER_PATH, "Armor preview")
		if roster != null and roster.has_master(str(creature.get("creature_id", ""))) and not str(creature.get("suit_instance_id", "")).is_empty():
			var loadout := EquipmentRules.suit_loadout(GameManager.profile, instance_id)
			var preview_script = _optional_script(TIERED_ARMOR_PREVIEW_PATH, "Armor preview")
			if preview_script != null:
				var portrait = preview_script.new(); portrait.custom_minimum_size = Vector2(160, 160); portrait.configure_creature(str(creature.get("creature_id", ""))); portrait.configure_tier(str(loadout.get("tier_id", "standard"))); portrait.configure_core(str(loadout.get("core_id", ""))); intro.add_child(portrait)
			intro.add_child(label("%s • %s" % [str(ArmorCoreDefinitions.suit_definition(str(loadout.get("tier_id", ""))).get("name", "Full Suit")), str(ArmorCoreDefinitions.definition(str(loadout.get("core_id", ""))).get("name", "No Core"))], 13, Color("f1be69")))
		intro.add_child(make_button(("Remove " if selected else "Add ") + "%s (Mastery %d)" % [creature_name, GameManager.creature_mastery(instance_id)], toggle_team_draft_member.bind(instance_id), Color("588d73") if selected else Color("2f93a8")))
	intro.add_child(make_button("Save Team", save_team_draft, Color("a86b2e")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func toggle_team_draft_member(instance_id: String) -> void:
	if instance_id in team_draft:
		if team_draft.size() > 1: team_draft.erase(instance_id)
		else: _toast("A training team needs at least one companion.")
	elif team_draft.size() < 3:
		team_draft.append(instance_id)
	else:
		_toast("A team can hold only three companions.")
	team_draft_dirty = true
	render()

func save_team_draft() -> void:
	var draft: Array = team_draft.duplicate()
	# Reset before the synchronous profile_changed signal so its render sees the
	# saved profile rather than a stale draft.
	team_draft_dirty = false
	if GameManager.save_team(draft):
		team_draft = Array(GameManager.profile.get("team", [])).duplicate()
		_toast("Team saved. Maker shelf and training bench are updated.")
	else:
		team_draft_dirty = true

func render_armor() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	if equipment_selected_creature_id.is_empty() and not GameManager.profile.get("creatures", []).is_empty(): equipment_selected_creature_id = str(GameManager.profile.creatures[0].get("instance_id", ""))
	var workbench = _optional_script(EQUIPMENT_WORKBENCH_VIEW_PATH, "Equipment Workbench")
	if workbench == null:
		panel.add_child(label("The Equipment Workbench could not load. Return to the Workshop and try again; your profile has not changed.", 15, Color("ffcfbf")))
	else:
		panel.add_child(workbench.build(GameManager.profile, equipment_selected_creature_id, equipment_mode, equipment_selected_id, not is_portrait_layout(), {"select_creature":equipment_select_creature,"select_mode":equipment_select_mode,"select_item":equipment_select_item,"suit_action":equipment_suit_action,"core_action":equipment_core_action,"fit_suit":equipment_fit_suit,"remove_suit":equipment_remove_suit,"remove_core":equipment_remove_core,"socket_core":equipment_socket_core}, bool(settings().get("high_contrast", false))))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func equipment_select_creature(instance_id: String) -> void: equipment_selected_creature_id = instance_id; render()
func equipment_select_mode(next_mode: String) -> void:
	equipment_mode = next_mode
	if next_mode == "cores": equipment_selected_id = str(EquipmentRules.suit_loadout(GameManager.profile, equipment_selected_creature_id).get("core_id", ""))
	else: equipment_selected_id = "standard"
	render()
func equipment_select_item(item_id: String) -> void: equipment_selected_id = item_id; render()
func equipment_suit_action(tier_id: String) -> void:
	if tier_id in GameManager.profile.get("suit_blueprints", []): open_armor_printer(tier_id)
	else: GameManager.learn_suit_blueprint(tier_id)
func equipment_core_action(core_id: String) -> void:
	if core_id in GameManager.profile.get("core_blueprints", []): open_core_printer(core_id)
	else: GameManager.learn_core_blueprint(core_id)
func equipment_fit_suit(creature_id: String, suit_id: String) -> void: GameManager.move_suit(creature_id, suit_id)
func equipment_remove_suit() -> void: GameManager.remove_suit(equipment_selected_creature_id)
func equipment_remove_core(suit_id: String) -> void: GameManager.remove_core(suit_id)
func equipment_socket_core(suit_id: String, core_id: String) -> void: GameManager.move_core(suit_id, core_id)

func open_armor_printer(armor_id: String) -> void:
	var definition := ProgressionRules.armor_def(armor_id)
	if definition.is_empty() or armor_id not in GameManager.profile.get("suit_blueprints", []):
		_toast("That full-suit blueprint is not learned yet.")
		return
	printer_is_armor = true
	printer_is_core = false
	printer_armor_id = armor_id
	printer_creature_id = _selected_equipment_creature_species()
	printer_price = int(definition.get("print", 0))
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)), true)
	printer_tick_accumulator = 0.0; printer_presentation_seconds = 0.0; printer_failure = ""
	printer_return_screen = "armor"
	screen = "printer"
	render()

func open_core_printer(core_id: String) -> void:
	var definition := ArmorCoreDefinitions.core_blueprint_definition(core_id)
	if definition.is_empty() or core_id not in GameManager.profile.get("core_blueprints", []):
		_toast("That Core blueprint is not learned yet."); return
	printer_is_armor = true; printer_is_core = true; printer_armor_id = core_id; printer_creature_id = _selected_equipment_creature_species(); printer_price = int(definition.print)
	printer_sequence = ArcaneForgeSequence.create(bool(settings().get("reduced_motion", false)), true)
	printer_tick_accumulator = 0.0; printer_presentation_seconds = 0.0; printer_failure = ""; printer_return_screen = "armor"; screen = "printer"; render()

func _selected_equipment_creature_species() -> String:
	for creature in GameManager.profile.get("creatures", []):
		if str(creature.get("instance_id", "")) == equipment_selected_creature_id:
			var species_id := str(creature.get("creature_id", ""))
			if Catalog.creature(species_id).is_empty() == false:
				return species_id
	return "cinderpaw"

func centered_card_gallery(host: Container, gallery_name: String, columns: int) -> GridContainer:
	# Card fronts deliberately retain their authored silhouette and native spacing.
	# Give a narrow portrait gallery a full-width host, then center the natural
	# two-column bounds inside it instead of stretching cards into dead space.
	var gallery_host := CenterContainer.new()
	gallery_host.name = gallery_name + "Host"
	gallery_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_host.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	host.add_child(gallery_host)
	var cards := GridContainer.new()
	cards.name = gallery_name
	cards.columns = columns
	cards.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.add_theme_constant_override("h_separation", 8)
	cards.add_theme_constant_override("v_separation", 8)
	gallery_host.add_child(cards)
	return cards

func render_deck() -> void:
	var panel := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(panel.get_parent())
	if deck_slot_id.is_empty(): deck_slot_id = str(GameManager.profile.get("active_deck_id", ProgressionRules.STARTER_DECK_ID))
	if deck_draft.is_empty(): deck_draft = GameManager.active_deck_cards()
	panel.add_child(label("15-Card Deck Builder", 25, Color("d3a7ff")))
	panel.add_child(label("Selected slot: %s | Draft: %d / 15. Only owned support cards can be saved." % [_saved_deck_name(deck_slot_id), deck_draft.size()], 15, Color("dce8f4")))
	for slot_id in ProgressionRules.DECK_SLOT_IDS:
		var saved_cards: Array = _saved_deck_cards(slot_id)
		var exists := _saved_deck_exists(slot_id)
		var action := "Active" if str(GameManager.profile.active_deck_id) == slot_id else "Select"
		var slot_copy := "%d cards - %s" % [saved_cards.size(), action] if exists else "Available slot"
		var slot_button := make_button("%s: %s" % [_saved_deck_name(slot_id), slot_copy], select_deck_slot.bind(slot_id), Color("588d73") if str(GameManager.profile.active_deck_id) == slot_id else Color("526e93"))
		slot_button.name = "DeckSlot%s" % slot_id.capitalize()
		panel.add_child(slot_button)
	if Catalog.support_card(deck_selected_card_id).is_empty():
		for candidate in Catalog.SUPPORT_CARDS:
			if int(GameManager.profile.support_cards.get(str(candidate.id), 0)) > 0:
				deck_selected_card_id = str(candidate.id)
				break
	var selected := Catalog.support_card(deck_selected_card_id)
	if not selected.is_empty():
		var selected_tray := make_panel(Color("10273ad8"), Color("ffd36c")); selected_tray.get_parent().add_theme_stylebox_override("panel", inset_style(Color("10273ad8"), Color("ffd36c"))); panel.add_child(selected_tray.get_parent()); selected_tray.name = "DeckSelectedCardTray"
		var selected_owned: int = int(GameManager.profile.support_cards.get(deck_selected_card_id, 0)); var selected_copies: int = deck_draft.count(deck_selected_card_id)
		selected_tray.add_child(label("Selected: %s" % str(selected.name), 19, Color("fff0a1")))
		selected_tray.add_child(label("Owned: %d | Draft copies: %d / %d | %d Filament" % [selected_owned, selected_copies, selected_owned, int(selected.cost)], 14, Color("9beaff")))
		var card_presenter = _optional_script(SUPPORT_CARD_PRESENTER_PATH, "Support card details")
		if card_presenter != null:
			selected_tray.add_child(label(card_presenter.effect_text(selected) + "\nTarget: " + card_presenter.target_text(selected), 14, Color("dce8f4")))
		var selected_actions := HBoxContainer.new(); selected_tray.add_child(selected_actions)
		var selected_remove := make_button("Remove selected", change_deck_draft.bind(deck_selected_card_id, false), Color("536c8d")); selected_remove.name = "DeckSelectedRemove"; selected_remove.disabled = selected_copies <= 0; selected_actions.add_child(selected_remove)
		var selected_add := make_button("Add selected (%d/%d)" % [selected_copies, selected_owned], change_deck_draft.bind(deck_selected_card_id, true), Color("2f93a8")); selected_add.name = "DeckSelectedAdd"; selected_add.disabled = deck_draft.size() >= 15 or selected_copies >= selected_owned; selected_actions.add_child(selected_add)
	var cards := centered_card_gallery(panel, "DeckCardGallery", 2 if is_portrait_layout() else 4)
	for card in Catalog.SUPPORT_CARDS:
		var card_id := str(card.id); var owned: int = int(GameManager.profile.support_cards.get(card_id, 0))
		if owned <= 0: continue
		var view = _new_support_card_view()
		if view != null:
			view.configure(card, owned, ""); view.name = "DeckCard%s" % card_id.capitalize(); view.pressed.connect(select_deck_card.bind(card_id)); cards.add_child(view)
	panel.add_child(make_button("Save %s as active (%d / 15)" % [_saved_deck_name(deck_slot_id), deck_draft.size()], save_active_deck_draft, Color("a86b2e")))
	var missing_slot := ""
	for candidate in ProgressionRules.DECK_SLOT_IDS:
		if candidate == ProgressionRules.STARTER_DECK_ID: continue
		if not _saved_deck_exists(candidate): missing_slot = candidate; break
	if not missing_slot.is_empty(): panel.add_child(make_button("Create %s Slot" % str(ProgressionRules.DECK_SLOT_NAMES.get(missing_slot, "Forge Deck")), create_deck_slot.bind(missing_slot), Color("2f93a8")))
	if not missing_slot.is_empty() and _saved_deck_exists(deck_slot_id) and not _saved_deck_cards(deck_slot_id).is_empty():
		panel.add_child(make_button("Duplicate Selected into %s" % str(ProgressionRules.DECK_SLOT_NAMES.get(missing_slot, "Forge Deck")), duplicate_selected_deck.bind(missing_slot), Color("2f93a8")))
	if deck_slot_id != ProgressionRules.STARTER_DECK_ID:
		panel.add_child(make_button("Delete Selected Slot", delete_selected_deck, Color("9a5b6f")))
		for fixed_name in ProgressionRules.DECK_NAME_OPTIONS:
			panel.add_child(make_button("Rename as %s" % fixed_name, rename_selected_deck.bind(fixed_name), Color("526e93")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_card_archive() -> void:
	var panel := make_panel(Color("19334de8"), Color("78cfe5")); body.add_child(panel.get_parent())
	panel.add_child(label("Support Card Archive", 25, Color("9beaff")))
	panel.add_child(label("30 offline tactical cards. Non-turn-ending; no reshuffle.", 15, Color("dce8f4")))
	panel.add_child(label("Deck 15 / opening 4 / hand cap 4 / draw 1 per turn.", 15, Color("dce8f4")))
	var edit_deck := make_button("Edit Deck", navigate_to.bind("deck"), Color("a86b2e"))
	edit_deck.name = "ArchiveEditDeck"
	panel.add_child(edit_deck)
	var filters := HBoxContainer.new(); panel.add_child(filters)
	var all_filter := make_button("All cards", func(): card_archive_owned_only = false; render(), Color("2f93a8") if not card_archive_owned_only else Color("536c8d")); all_filter.name = "ArchiveFilterAll"; filters.add_child(all_filter)
	var owned_filter := make_button("Owned only", func(): card_archive_owned_only = true; render(), Color("2f93a8") if card_archive_owned_only else Color("536c8d")); owned_filter.name = "ArchiveFilterOwned"; filters.add_child(owned_filter)
	var cards := centered_card_gallery(panel, "CardArchiveGallery", 2 if is_portrait_layout() else 4)
	for card in Catalog.SUPPORT_CARDS:
		var owned := int(GameManager.profile.support_cards.get(str(card.id), 0))
		if card_archive_owned_only and owned <= 0: continue
		var view = _new_support_card_view()
		if view != null:
			view.configure(card, owned); view.name = "ArchiveCard%s" % str(card.id).capitalize(); view.pressed.connect(show_card_archive_detail.bind(card)); cards.add_child(view)
	if not card_archive_detail_id.is_empty(): _append_card_archive_detail(panel, Catalog.support_card(card_archive_detail_id))
	body.add_child(make_button("Back to Maker Bench", navigate_to.bind("workshop"), Color("536c8d")))

func show_card_archive_detail(card: Dictionary) -> void:
	card_archive_detail_id = str(card.get("id", ""))
	render()

func _append_card_archive_detail(host: Container, card: Dictionary) -> void:
	var panel := make_panel(Color("10273ad8"), Color("ffd36c")); host.add_child(panel.get_parent())
	panel.name = "CardArchiveDetail"
	panel.add_child(label(str(card.get("name", "Support Card")), 21, Color("fff0a1")))
	panel.add_child(label("%s • %s • %d Filament" % [str(card.get("role", "utility")).capitalize(), str(card.get("rarity", "common")).capitalize(), int(card.get("cost", 0))], 15, Color("9beaff")))
	var card_presenter = _optional_script(SUPPORT_CARD_PRESENTER_PATH, "Support card details")
	if card_presenter != null:
		panel.add_child(label(card_presenter.effect_text(card) + "\nTarget: " + card_presenter.target_text(card) + "\nOwned: %d" % int(GameManager.profile.support_cards.get(str(card.id), 0)), 15, Color("dce8f4")))

func _saved_deck_cards(deck_id: String) -> Array:
	for saved in GameManager.profile.get("decks", []):
		if saved is Dictionary and str(saved.get("id", "")) == deck_id:
			var cards = saved.get("cards", [])
			return cards.duplicate() if cards is Array else []
	return []

func _saved_deck_exists(deck_id: String) -> bool:
	for saved in GameManager.profile.get("decks", []):
		if saved is Dictionary and str(saved.get("id", "")) == deck_id: return true
	return false

func _saved_deck_name(deck_id: String) -> String:
	for saved in GameManager.profile.get("decks", []):
		if saved is Dictionary and str(saved.get("id", "")) == deck_id:
			return str(saved.get("name", ProgressionRules.DECK_SLOT_NAMES.get(deck_id, "Forge Deck")))
	return str(ProgressionRules.DECK_SLOT_NAMES.get(deck_id, "Forge Deck"))

func select_deck_slot(deck_id: String) -> void:
	deck_slot_id = deck_id
	var saved_cards := _saved_deck_cards(deck_id)
	deck_draft = saved_cards.duplicate() if not saved_cards.is_empty() else GameManager.active_deck_cards()
	if not saved_cards.is_empty():
		GameManager.select_deck(deck_id)
	else:
		render()

func select_deck_card(card_id: String) -> void:
	if Catalog.support_card(card_id).is_empty(): return
	deck_selected_card_id = card_id
	render()

func change_deck_draft(card_id: String, add: bool) -> void:
	var owned: int = int(GameManager.profile.get("support_cards", {}).get(card_id, 0))
	if add:
		if deck_draft.size() < 15 and deck_draft.count(card_id) < owned: deck_draft.append(card_id)
	else:
		deck_draft.erase(card_id)
	render()

func save_active_deck_draft() -> void:
	GameManager.save_deck_slot(deck_draft.duplicate(), deck_slot_id)

func create_deck_slot(deck_id: String) -> void:
	deck_slot_id = deck_id; deck_draft = []
	if not GameManager.create_deck(deck_id, str(ProgressionRules.DECK_SLOT_NAMES.get(deck_id, "Forge Deck"))): render()

func duplicate_selected_deck(target_id: String) -> void:
	if GameManager.duplicate_deck(deck_slot_id, target_id):
		deck_slot_id = target_id; deck_draft = _saved_deck_cards(target_id)
	else: render()

func delete_selected_deck() -> void:
	var deleted := deck_slot_id
	deck_slot_id = ProgressionRules.STARTER_DECK_ID; deck_draft = GameManager.active_deck_cards()
	if not GameManager.delete_deck(deleted): render()

func rename_selected_deck(name: String) -> void:
	if not GameManager.rename_deck(deck_slot_id, name): render()

func render_codex() -> void:
	var intro := make_panel(Color("19334de8"), Color("b88bff")); body.add_child(intro.get_parent())
	intro.add_child(label("Forgedex", 25, Color("d3a7ff")))
	intro.add_child(label("%d blueprints have been discovered." % GameManager.profile.discovered.size(), 15, Color("dce8f4")))
	var grid := GridContainer.new(); grid.columns = 4 if size.x >= 1100 else 2; body.add_child(grid)
	for creature in Catalog.CREATURES:
		var known: bool = creature.id in GameManager.profile.discovered
		var card := make_panel(Color("152842e8"), Color(Catalog.rarity(creature.rarity).color if known else "4b5d72")); grid.add_child(card.get_parent())
		card.add_child(label(str(creature.name) if known else "???", 17, Color(Catalog.rarity(creature.rarity).color if known else "8492a1")))
		var mastery_total := 0; var owned_count := 0
		for owned in GameManager.profile.get("creatures", []):
			if owned is Dictionary and str(owned.get("creature_id", "")) == str(creature.id): mastery_total += GameManager.creature_mastery(str(owned.get("instance_id", ""))); owned_count += 1
		var print_count := int(GameManager.profile.get("print_history", {}).get("creatures", {}).get(str(creature.id), 0))
		card.add_child(label("%s | HP %d | Attack %d | Speed %d\nOwned %d | Mastery %d | Printed %d" % [str(creature.element), int(creature.hp), int(creature.attack), int(creature.speed), owned_count, mastery_total, print_count] if known else "Undiscovered", 13, Color("dce8f4")))
		if known:
			card.add_child(label("%s: %s" % [str(creature.ability), Catalog.signature_description(str(creature.id))], 12, Color("b9d3e8")))
	intro.add_child(label("Full suits and Cores", 20, Color("ffd36c")))
	for suit in Catalog.SUITS:
		var tier_id := str(suit.id); var owned := 0
		for row in GameManager.profile.get("suits", []): if row is Dictionary and str(row.get("tier_id", "")) == tier_id: owned += 1
		var printed := int(GameManager.profile.get("print_history", {}).get("suits", {}).get(tier_id, 0))
		intro.add_child(label("%s - +%d HP | +%d speed | %d guard | owned %d | printed %d" % [str(suit.name), int(suit.hp), int(suit.speed), int(suit.armor), owned, printed], 14, Color("dce8f4")))
	for core in Catalog.CORE_BLUEPRINTS:
		var core_id := str(core.id); var core_owned := 0
		for row in GameManager.profile.get("cores", []): if row is Dictionary and str(row.get("core_id", "")) == core_id: core_owned += 1
		intro.add_child(label("%s - %s | owned %d" % [str(core.name), str(ArmorCoreDefinitions.definition(core_id).get("effect", "")), core_owned], 14, Color("dce8f4")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_proving_door() -> void:
	var panel := make_panel(Color("19334de8"), Color("f1be69")); body.add_child(panel.get_parent())
	panel.add_child(label("Battle Arena Hub", 25, Color("ffd36c")))
	panel.add_child(label("Choose a frozen daily contract, a fixed Workshop Trial ladder, or a private local match.", 15, Color("dce8f4")))
	panel.add_child(label("Daily Training Contracts", 20, Color("8deaff")))
	var contracts := GameManager.daily_training_contracts()
	if contracts.is_empty():
		panel.add_child(label("Daily contracts are prepared when the Battle Arena opens. Return to the workshop and reopen the Battle Arena if needed.", 14, Color("fff0a1")))
	for contract in contracts:
		var claimed: bool = str(contract.get("id", "")) in GameManager.profile.get("daily_training", {}).get("claimed_ids", [])
		var contract_panel := make_panel(Color("12314be8"), Color("70dcea") if not claimed else Color("588d73")); panel.add_child(contract_panel.get_parent())
		var team_names: Array[String] = []
		for entry in contract.get("team", []):
			var unit := Catalog.creature(str(entry.get("creature_id", ""))); team_names.append(str(unit.get("name", "Print")))
		contract_panel.add_child(label("%s - %s%s" % [str(contract.get("name", "Contract")), str(contract.get("difficulty", "Apprentice")), " (Practice)" if claimed else ""], 18, Color("a9ecff") if not claimed else Color("a8e3a5")))
		contract_panel.add_child(_contract_portrait_strip(contract.get("team", [])))
		var tactics := str(contract.get("tactics", ""))
		var tactics_text := " | %s tactics" % tactics.capitalize() if not tactics.is_empty() else ""
		contract_panel.add_child(label("Rivals: %s | %s deck%s | prepared %d / 400 filament | rating %d vs %d" % [", ".join(team_names), str(contract.get("deck_role", "balanced")).capitalize(), tactics_text, int(contract.get("rival_starting_filament", 200)), int(contract.get("rating", 0)), int(contract.get("player_rating", 0))], 13, Color("dce8f4")))
		var target_note := "Rated target met" if bool(contract.get("within_target", false)) else "Closest legal rating"
		contract_panel.add_child(label("Field: %s | %s | %s" % [_contract_loadout_text(contract.get("team", [])), str(contract.get("tag", "Daily")), target_note], 12, Color("b9d3e8")))
		if str(contract.get("equipment_reason", "policy_primary")) != "policy_primary": contract_panel.add_child(label("Rival plan: %s." % str(contract.get("equipment_reason", "")).replace("_", " "), 11, Color("fff0a1")))
		var reward: Dictionary = contract.get("reward", {})
		contract_panel.add_child(label("Reward claimed; replays are practice only." if claimed else "First victory: %d Forge Coins, %d XP." % [int(reward.get("coins", 0)), int(reward.get("xp", 0))], 12, Color("fff0a1")))
		var launch := make_button("Practice %s" % str(contract.get("name", "Contract")) if claimed else "Accept %s" % str(contract.get("name", "Contract")), start_battle.bind(str(contract.get("id", ""))), Color("588d73") if claimed else Color("2f93a8")); launch.name = "DailyContract%s" % str(contract.get("id", "")); contract_panel.add_child(launch)
	panel.add_child(label("Workshop Trials", 20, Color("ffd36c")))
	var campaign: Dictionary = GameManager.profile.get("solo_campaign", {})
	panel.add_child(label("Five authored tiers, 20 fixed encounters. Tier %d is currently available; first clears grant one-time Forge Coins plus Spool and Season XP." % int(campaign.get("unlocked_tier", 1)), 14, Color("dce8f4")))
	var trials := make_button("Browse Workshop Trials", navigate_to.bind("trials"), Color("a86b2e"))
	trials.name = "OpenWorkshopTrials"
	panel.add_child(trials)
	panel.add_child(make_button("Start Local Versus", start_local_vs, Color("526e93")))
	body.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))

func render_trials() -> void:
	var intro := make_panel(Color("19334de8"), Color("ffd36c")); body.add_child(intro.get_parent())
	intro.add_child(label("Workshop Trials", 25, Color("ffd36c")))
	intro.add_child(label("Each tier unlocks in order. Clear three encounters, then the boss, to open the next workshop test. First-clear rewards are claimed only on victory.", 15, Color("dce8f4")))
	var lineup := _trial_lineup_preview()
	intro.add_child(label(str(lineup.get("text", "Trial lineup: choose a Team Builder lineup.")), 14, Color("a9ecff") if not bool(lineup.get("temporary", false)) else Color("fff0a1")))
	var edit_team := make_button("Open Pre-Print & Decks", navigate_to.bind("unified_deck"), Color("526e93"))
	edit_team.name = "EditCurrentTrialTeam"
	intro.add_child(edit_team)
	for tier in Catalog.WORKSHOP_TRIAL_TIERS:
		var tier_number: int = int(tier.get("tier", 0))
		var card := make_panel(Color("142b42e8"), Color("f1be69") if tier_number <= int(GameManager.profile.get("solo_campaign", {}).get("unlocked_tier", 1)) else Color("536273"))
		body.add_child(card.get_parent())
		card.add_child(label("Tier %d - %s" % [tier_number, str(tier.get("name", "Workshop Trial"))], 20, Color("ffd36c")))
		for encounter in tier.get("encounters", []):
			var encounter_id := str(encounter.get("id", ""))
			var state := GameManager.campaign_encounter_state(encounter_id)
			var unlocked: bool = bool(state.get("unlocked", false))
			var completed: bool = bool(state.get("completed", false))
			var reward: Dictionary = state.get("reward", {})
			var rival_names: Array[String] = []
			for entry in encounter.get("team", []):
				var creature_id := str(entry.get("creature_id", "")) if entry is Dictionary else str(entry)
				rival_names.append(str(Catalog.creature(creature_id).get("name", creature_id)))
			var best_turns: int = int(GameManager.profile.get("solo_campaign", {}).get("best_turn_counts", {}).get(encounter_id, 0))
			var status_text := ("Complete - best %d turns" % best_turns) if completed and best_turns > 0 else ("Complete" if completed else ("Ready" if unlocked else "Locked - clear the prior encounter"))
			card.add_child(label("%s%s - %s" % ["Boss: " if bool(encounter.get("boss", false)) else "", str(encounter.get("name", "Encounter")), status_text], 16, Color("a8e3a5") if completed else (Color("dce8f4") if unlocked else Color("8492a1"))))
			card.add_child(label("Rival: %s | %s AI | %s deck | 200 / 400 filament" % [", ".join(rival_names), str(encounter.get("ai", "Apprentice")), str(encounter.get("deck_role", "Balanced"))], 13, Color("b9d3e8")))
			card.add_child(label("First clear: %d Forge Coins and %d Spool/Season XP." % [int(reward.get("coins", 0)), int(reward.get("xp", 0))], 13, Color("fff0a1")))
			var start := make_button("Replay %s" % str(encounter.get("name", "Trial")) if completed else "Start %s" % str(encounter.get("name", "Trial")), start_trial.bind(encounter_id), Color("588d73") if completed else Color("a86b2e"))
			start.name = "TrialStart%s" % encounter_id
			start.disabled = not unlocked
			card.add_child(start)
	body.add_child(make_button("Back to Battle Arena", navigate_to.bind("proving"), Color("536c8d")))

func _trial_lineup_preview() -> Dictionary:
	# Preview and launch intentionally use the same factory contract: no separate
	# UI-only normalization can advertise a lineup BattleState will not receive.
	var fallback := SoloBattleFactory.preview(GameManager.profile)
	var temporary: Array = fallback.get("team", [])
	if not temporary.is_empty():
		if bool(fallback.get("temporary_repair", false)):
			return {"text":"Trial lineup: available catalog prints will be used temporarily: %s. Save a Pre-Print deck loadout after the match." % _trial_lineup_names(temporary), "temporary":true}
		return {"text":"Trial lineup: %s" % _trial_lineup_names(temporary), "temporary":false}
	return {"text":"Trial lineup: No catalog-valid owned print is ready. Add creature cards to a fixed deck, then choose Pre-Prints.", "temporary":true}

func _trial_lineup_names(lineup: Array) -> String:
	var names: Array[String] = []
	for entry in lineup:
		var creature_id := str(entry.get("creature_id", "")) if entry is Dictionary else str(entry)
		var definition := Catalog.creature(creature_id)
		if not definition.is_empty(): names.append(str(definition.get("name", creature_id)))
	return ", ".join(names)

func _contract_loadout_text(lineup: Array) -> String:
	var pieces: Array[String] = []
	for entry in lineup:
		if not entry is Dictionary: continue
		var creature_id := str(entry.get("creature_id", ""))
		var creature_name := str(Catalog.creature(creature_id).get("name", creature_id.capitalize()))
		pieces.append(creature_name)
	return ", ".join(pieces) if not pieces.is_empty() else "No field creatures"

func _daily_contract(contract_id: String) -> Dictionary:
	for raw in GameManager.daily_training_contracts():
		if str(raw.get("id", "")) == contract_id: return raw
	return {}

func _contract_portrait_strip(lineup: Array) -> Control:
	var strip := HBoxContainer.new(); strip.name = "DailyContractPortraits"; strip.add_theme_constant_override("separation", 8)
	for entry in lineup:
		if not entry is Dictionary: continue
		var creature_id := str(entry.get("creature_id", ""))
		var frame := TextureRect.new(); frame.custom_minimum_size = Vector2(64, 64)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var portrait := AtlasTexture.new()
		portrait.atlas = CreatureSpriteCache.texture_for_creature(creature_id)
		portrait.region = CreatureSpriteCache.safe_source_region(0)
		frame.texture = portrait
		frame.tooltip_text = "%s - %s" % [str(Catalog.creature(creature_id).get("name", creature_id)), _contract_loadout_text([entry])]
		strip.add_child(frame)
	return strip

func start_trial(encounter_id: String) -> void:
	_launch_unified_mode("trial", {"encounter_id":encounter_id}, _trial_seed(encounter_id))

func start_battle(contract_id := "") -> void:
	_launch_unified_mode("daily", {"contract_id":contract_id,"day_key":shop_day_key}, _training_seed(shop_day_key + contract_id))

func _training_seed(day_key: String) -> int:
	var seed := 0
	for byte in day_key.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed

func _trial_seed(encounter_id: String) -> int:
	var seed := 97
	for byte in encounter_id.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed

## Public launch bridge for the deterministic card-battle modes.  This is kept
## beside the existing Trial/Daily entry points so workshop buttons, tests, and
## future Foundry-styled cards all share GameManager's launch snapshot rather
## than instantiating the retired prototype screen.
func start_mode(mode: String) -> void:
	_launch_unified_mode(mode, {}, 43 + mode.length())

func _launch_unified_mode(mode: String, opponent_setup: Dictionary, seed: int) -> void:
	battle = null
	battle_settlement_context.clear()
	battle_settlement_finished = false
	var setup: Dictionary = GameManager.create_unified_battle(mode, opponent_setup, seed)
	if not bool(setup.get("ok", false)):
		_toast(str(setup.get("error", "Unable to launch this battle.")))
		return
	battle = setup.get("battle", null)
	if battle == null:
		_toast("The battle snapshot could not be created.")
		return
	battle_mode = str(setup.get("mode", mode))
	battle_settlement_context = setup.get("settlement_context", {}).duplicate(true) if setup.get("settlement_context", {}) is Dictionary else {}
	unified_hand_page = 0
	unified_selected_card_id = ""
	unified_selected_slot = -2
	unified_selected_target = -2
	unified_attack_slot = -1
	unified_attack_target = -2
	unified_ai_pending = false
	unified_local_handoff = battle_mode == "local"
	unified_arrival_presented.clear()
	if screen == "workshop": workshop_return_view = workshop_view
	screen = "unified_battle"
	render()

func _unified_side_panel(title: String, state: Dictionary, color: Color) -> Control:
	var panel := make_panel(Color("132b3be8"), color)
	panel.name = "Unified%sField" % title.capitalize()
	var compact := not is_portrait_layout()
	panel.add_child(label(title + (" printer" if compact else ""), 14 if compact else 18, color))
	var printer: Dictionary = state.get("printer", {})
	panel.add_child(label(("%d/%d HP · %d/%d filament" if compact else "3D PRINTER  ·  %d / %d HP  ·  filament %d/%d") % [int(printer.get("hp", 0)), int(printer.get("max_hp", 2000)), int(state.get("filament", 0)), int(state.get("filament_max", 400))], 12 if compact else 14, Color("e6dfd0")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for slot in 3:
		var unit = state.get("slots", [])[slot]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(112, 50 if compact else 68)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", inset_style(Color("102735"), color))
		var text := "Slot %d\nOpen" % (slot + 1)
		if unit != null:
			var equipment: Dictionary = unit.get("equipment", {}) if unit.get("equipment", {}) is Dictionary else {}
			var gear: Array[String] = []
			for key in ["armor", "gem"]:
				var attached: Dictionary = equipment.get(key, {}) if equipment.get(key, {}) is Dictionary else {}
				if not attached.is_empty(): gear.append(str(attached.get("name", key.capitalize())))
			text = "%s · %s\n%d HP%s%s" % [str(unit.get("name", "Print")), str(unit.get("mode", "defense")).capitalize(), int(unit.get("hp", 0)), " · ready" if bool(unit.get("ready", false)) else "", (" · " + "/".join(gear)) if not gear.is_empty() else ""]
		var caption := label(text, 11 if compact else 13, Color("e6dfd0"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(caption)
		row.add_child(card)
		if unit != null and bool(unit.get("arriving", false)):
			card.name = "UnifiedArrival_%s_%d" % [title, slot]
			call_deferred("_present_unified_arrival", card, "%d:%s:%d:%s" % [int(battle.seed), title, slot, str(unit.get("card_id", "print"))])
	var queue: Array = state.get("queue", [])
	var queue_parts: Array[String] = []
	for job in queue: queue_parts.append("%s · %d turns" % [str(job.get("card_id", "print")), int(job.get("remaining", 0))])
	panel.add_child(label("Queue: " + ("empty" if queue_parts.is_empty() else " | ".join(queue_parts)), 13, Color("fff0a1")))
	if bool(state.get("filament_ring_active", false)):
		panel.add_child(label("Filament Ring active · +20 filament during Collect", 12, Color("ffd36c")))
	var trap: Dictionary = state.get("trap", {}) if state.get("trap", {}) is Dictionary else {}
	panel.add_child(label("Trap zone: " + ("set" if not trap.is_empty() else "empty"), 12, Color("e6dfd0")))
	if not state.get("staging", []).is_empty() or not state.get("holding", []).is_empty(): panel.add_child(label("Staging %d · Holding %d · Graveyard %d" % [(state.get("staging", []) as Array).size(), (state.get("holding", []) as Array).size(), (state.get("graveyard", []) as Array).size()], 12, Color("e6dfd0")))
	return panel.get_parent()

func _present_unified_arrival(card: Control, arrival_key: String) -> void:
	# Presentation-only event consumption: neither the authoritative state nor a
	# turn flag changes here. A rebuild therefore cannot replay the same walk-on.
	if unified_arrival_presented.has(arrival_key) or not is_instance_valid(card): return
	unified_arrival_presented[arrival_key] = true
	if bool(settings().get("reduced_motion", false)): return
	var destination := card.position
	card.position = destination + Vector2(-72.0, 12.0)
	card.modulate.a = 0.15
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", destination, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.32)

func _unified_cards_page(cards: Array, on_select: Callable) -> Control:
	var column := VBoxContainer.new()
	var per_page := 2 if is_portrait_layout() else 4
	var pages := maxi(1, int(ceil(float(cards.size()) / float(per_page))))
	unified_page = clampi(unified_page, 0, pages - 1)
	var grid := GridContainer.new()
	grid.name = "UnifiedFoundryCardGrid"
	grid.columns = 2 if is_portrait_layout() else 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for definition in cards.slice(unified_page * per_page, mini(cards.size(), (unified_page + 1) * per_page)):
		var card: Dictionary = definition
		var id := str(card.get("id", ""))
		var copies := int(GameManager.profile.get("owned_cards", {}).get(id, 0))
		var market_price := int(card.get("market_price", -1))
		var status := "x%d in deck" % int(card.get("deck_count", 0)) if card.has("deck_count") else ""
		var view := UNIFIED_CARD_VIEW.new()
		view.name = "UnifiedCardView%s" % id.capitalize()
		view.configure(card, copies, market_price, status, true, true)
		view.pressed.connect(on_select.bind(id))
		grid.add_child(view)
	var pager := HBoxContainer.new()
	pager.name = "UnifiedFoundryPager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_child(pager)
	var previous := make_button("Previous", func(): unified_page = posmod(unified_page - 1, pages); render(), Color("536c8d"))
	previous.custom_minimum_size = Vector2(48, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [unified_page + 1, pages]))
	var next := make_button("Next", func(): unified_page = posmod(unified_page + 1, pages); render(), Color("536c8d"))
	next.custom_minimum_size = Vector2(48, 44)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(next)
	return column

func _unified_card_thumbnail(card: Dictionary) -> Texture2D:
	return UNIFIED_CARD_VIEW.art_for_definition(card)

func _unified_battle_background_path() -> String:
	var arena := "daily_arena"
	if battle_mode.begins_with("trial_"): arena = battle_mode.trim_prefix("trial_")
	elif battle_mode == "local": arena = "element_bench"
	return "res://assets/ui/battle_backgrounds/%s_%s_v1.png" % [arena, "portrait" if is_portrait_layout() else "landscape"]

func _creature_idle_atlas(creature_id: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = CreatureSpriteCache.texture_for_creature(creature_id)
	atlas.region = CreatureSpriteCache.safe_source_region(0)
	return atlas

func _render_unified_inspector() -> void:
	if unified_inspector_id.is_empty(): return
	var card := UNIFIED_RULES.card(unified_inspector_id)
	if card.is_empty(): return
	var modal := ColorRect.new(); modal.name = "UnifiedCardInspector"; modal.color = Color("07111bf0"); modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.mouse_filter = Control.MOUSE_FILTER_STOP; add_child(modal)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal.add_child(center)
	var shell := PanelContainer.new(); shell.custom_minimum_size = Vector2(minf(760, size.x - 28), minf(620, size.y - 28)); shell.add_theme_stylebox_override("panel", panel_style(Color("102940f8"), Color("8deaff"))); center.add_child(shell)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation", 10); shell.add_child(content)
	content.add_child(label(str(card.get("name", unified_inspector_id)), 26, Color("ffd36c")))
	var thumbnail := _unified_card_thumbnail(card)
	if thumbnail != null:
		var art := TextureRect.new(); art.texture = thumbnail; art.custom_minimum_size = Vector2(270, 250); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; content.add_child(art)
	var tabs := HBoxContainer.new(); content.add_child(tabs)
	for tab in ["card", "stats"]:
		tabs.add_child(make_button(tab.capitalize(), func(): unified_inspector_tab = tab; render(), Color("588d73") if tab == unified_inspector_tab else Color("536c8d")))
	if unified_inspector_tab == "card":
		content.add_child(label("Card · %s · %s · %d filament" % [str(card.get("type", "card")).capitalize(), str(card.get("rarity", "common")).capitalize(), int(card.get("cost", 0))], 16, Color("e6dfd0")))
	elif unified_inspector_tab == "stats":
		content.add_child(label("HP %d · Attack %d · Print %d" % [int(card.get("hp", 0)), int(card.get("attack", 0)), int(card.get("print_ticks", 0))], 16, Color("fff0a1")))
	content.add_child(make_button("Close", func(): unified_inspector_id = ""; render(), Color("536c8d")))

func _render_unified_forgedex_page(host: Container) -> void:
	var creatures: Array = []
	for definition in UNIFIED_RULES.all_cards():
		if str(definition.get("type", "")) == "creature": creatures.append(definition)
	var per_page := 2 if is_portrait_layout() else 4
	var pages := maxi(1, int(ceil(float(creatures.size()) / float(per_page))))
	unified_codex_page = clampi(unified_codex_page, 0, pages - 1)
	host.add_child(label("Creature blueprints · %d / %d owned" % [GameManager.profile.get("owned_blueprints", {}).size(), creatures.size()], 15, Color("dce8f4")))
	var grid := GridContainer.new()
	grid.name = "UnifiedForgedexGrid"
	grid.columns = 2 if is_portrait_layout() else 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	host.add_child(grid)
	for definition in creatures.slice(unified_codex_page * per_page, mini(creatures.size(), (unified_codex_page + 1) * per_page)):
		var creature_id := str(definition.get("id", ""))
		var known: bool = bool(GameManager.profile.get("owned_blueprints", {}).get(creature_id, false))
		var printed := 0
		for model in GameManager.profile.get("printed_models", {}).values():
			if model is Dictionary and str(model.get("blueprint_id", "")) == creature_id: printed += 1
		var status := ("Blueprint" if known else "Not owned") + " · Printed %d" % printed
		var view := UNIFIED_CARD_VIEW.new()
		view.name = "UnifiedForgedexCard%s" % creature_id.capitalize()
		view.configure(definition, int(GameManager.profile.get("owned_cards", {}).get(creature_id, 0)), -1, status, true, known, not known)
		if known: view.pressed.connect(func(): unified_inspector_id = creature_id; unified_inspector_tab = "stats"; render())
		grid.add_child(view)
		if known:
			grid.add_child(make_button("Workshop print · %d FC" % int(UNIFIED_RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), 20)), func(): var result = GameManager.print_workshop_model_v3(creature_id); _toast("Model printed." if bool(result.get("ok", false)) else str(result.get("error", "Print unavailable."))); render(), Color("a86b2e")))
	var pager := HBoxContainer.new()
	pager.name = "UnifiedForgedexPager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.add_child(pager)
	var previous := make_button("Previous", func(): unified_codex_page = posmod(unified_codex_page - 1, pages); render(), Color("536c8d"))
	previous.custom_minimum_size = Vector2(48, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [unified_codex_page + 1, pages]))
	var next := make_button("Next", func(): unified_codex_page = posmod(unified_codex_page + 1, pages); render(), Color("536c8d"))
	next.custom_minimum_size = Vector2(48, 44)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(next)
	host.add_child(label("Equipment Cards are stored with your battle card collection.", 14, Color("b9d3e8")))
	host.add_child(make_button("Open Equipment Cards", navigate_to.bind("archive"), Color("526e93")))

func render_unified_foundry_surface(host: Container) -> void:
	var title_map := {"unified_market":"Foundry Market", "unified_library":"Card Library", "unified_deck":"Deck Blueprint Rack", "unified_upgrades":"Printer Upgrade Grid", "unified_forgedex":"Forgedex"}
	host.add_child(label(str(title_map.get(screen, "Foundry")), 25, Color("ffd36c")))
	var coins := int(GameManager.profile.get("forge_coins", GameManager.profile.get("coins", 0)))
	host.add_child(label("Forge Coins %d · Sparks %d" % [coins, int(GameManager.profile.get("sparks", 0))], 14, Color("9beaff")))
	if not toast.is_empty(): host.add_child(label(toast, 14, Color("fff0a1")))
	if screen == "unified_market":
		var tabs := HBoxContainer.new(); tabs.name = "V3MarketTabs"; host.add_child(tabs)
		for tab in [["blueprints","Blueprint Stall"],["cards","Card Shop"],["packs","Pack Emporium"],["upgrades","Upgrade Forge"],["cosmetics","Cosmetic Atelier"]]: tabs.add_child(make_button(str(tab[1]), func(): unified_market_tab = str(tab[0]); unified_page = 0; render(), Color("588d73") if unified_market_tab == str(tab[0]) else Color("526e93")))
		var market := GameManager.market_snapshot()
		var daily: Dictionary = market.get("daily_deal", {})
		host.add_child(label("Daily Deal: %s · 20%% off" % str(daily.get("id", "loading")), 14, Color("fff0a1")))
		var rewards := HBoxContainer.new(); rewards.name = "V3Rewards"; host.add_child(rewards)
		rewards.add_child(make_button("Daily quests", func(): var r = GameManager.daily_quests_v3(); _toast("Quests ready." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("526e93")))
		rewards.add_child(make_button("Season %d / 50" % UNIFIED_RULES.season_level(GameManager.profile), func(): var r = GameManager.claim_season_level_v3(UNIFIED_RULES.season_level(GameManager.profile), false); _toast("Season reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "No reward ready."))); render(), Color("588d73")))
		var quest_day := Time.get_date_string_from_system(); var quest_result := GameManager.daily_quests_v3(quest_day)
		if bool(quest_result.get("ok", false)):
			var quest_state: Dictionary = GameManager.profile.get("quest_state", {})
			host.add_child(label("Daily Quests · %d free reroll" % int(quest_state.get("rerolls", 0)), 14, Color("9beaff")))
			for index in (quest_state.get("quests", []) as Array).size():
				var quest: Dictionary = quest_state.quests[index]; var quest_id := str(quest.get("id", ""))
				host.add_child(make_button("%s · %d/%d%s" % [str(quest.get("objective", "")).replace("_", " ").capitalize(), int(quest.get("progress", 0)), int(quest.get("target", 1)), " · claim" if bool(quest.get("completed", false)) else ""], func():
					var r = GameManager.claim_daily_quest_v3(quest_day, quest_id) if bool(quest.get("completed", false)) else GameManager.reroll_daily_quest_v3(quest_day, index)
					_toast("Quest reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "Quest unavailable."))); render(), Color("588d73") if bool(quest.get("completed", false)) else Color("526e93")))
		var season: Dictionary = GameManager.profile.get("season", {})
		host.add_child(label("Season track · %d XP · level %d / 50%s" % [int(season.get("xp", 0)), UNIFIED_RULES.season_level(GameManager.profile), " · paid" if bool(season.get("paid", false)) else " · free"], 14, Color("fff0a1")))
		var level := UNIFIED_RULES.season_level(GameManager.profile)
		if level > 0:
			host.add_child(make_button("Claim free level %d" % level, func(): var r = GameManager.claim_season_level_v3(level, false); _toast("Free Season reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "No reward ready."))); render(), Color("588d73")))
			if bool(season.get("paid", false)): host.add_child(make_button("Claim paid level %d" % level, func(): var r = GameManager.claim_season_level_v3(level, true); _toast("Paid Season reward claimed." if bool(r.get("ok", false)) else str(r.get("error", "No reward ready."))); render(), Color("7b5a9b")))
		if unified_market_tab == "blueprints":
			host.add_child(label("Blueprint Stall · 12 daily slots · rarity unlocked by Spool Level", 15, Color("e6dfd0")))
			var newcomer_items: Array = market.get("newcomer", {}).get("blueprints", []) if market.get("newcomer", {}) is Dictionary else []
			if not newcomer_items.is_empty():
				host.add_child(label("Newcomer Shelf · three half-price Common blueprints", 14, Color("fff0a1")))
				for offer in newcomer_items:
					var newcomer_id := str(offer.get("id", "")); host.add_child(make_button("Newcomer: %s · %d FC" % [newcomer_id, int(offer.get("price", 0))], func(): var r = GameManager.buy_blueprint_v3(newcomer_id); _toast("Blueprint purchased." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("a86b2e")))
			for offer in (market.get("blueprints", []) as Array):
				var blueprint_id := str(offer.get("id", ""))
				host.add_child(make_button("%s · %d FC" % [blueprint_id, int(offer.get("price", 0))], func(): var r = GameManager.buy_blueprint_v3(blueprint_id); _toast("Blueprint purchased." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("a86b2e")))
				host.add_child(make_button(("Remove wishlist: " if blueprint_id in GameManager.profile.get("wishlist", []) else "Wishlist: ") + blueprint_id, func(): var r = GameManager.set_wishlist_v3(blueprint_id, blueprint_id not in GameManager.profile.get("wishlist", [])); _toast("Wishlist updated." if bool(r.get("ok", false)) else str(r.get("error", "Wishlist full."))); render(), Color("526e93")))
		elif unified_market_tab == "cards":
			host.add_child(label("Card Shop · typed stock refreshes every 48 hours", 15, Color("e6dfd0")))
			for offer in (market.get("cards", []) as Array):
				var market_card_id := str(offer.get("id", ""))
				host.add_child(make_button("%s · %d FC" % [market_card_id, int(offer.get("price", 0))], func(): var r = GameManager.buy_market_card_v3(market_card_id); _toast("Card purchased." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("2f93a8")))
				host.add_child(make_button(("Remove wishlist: " if market_card_id in GameManager.profile.get("wishlist", []) else "Wishlist: ") + market_card_id, func(): var r = GameManager.set_wishlist_v3(market_card_id, market_card_id not in GameManager.profile.get("wishlist", [])); _toast("Wishlist updated." if bool(r.get("ok", false)) else str(r.get("error", "Wishlist full."))); render(), Color("526e93")))
		elif unified_market_tab == "packs":
			host.add_child(label("Pack Emporium · pity progress persists per pack type", 15, Color("e6dfd0")))
			for pack_id in UNIFIED_RULES.PACKS: host.add_child(make_button("%s · %d FC · pity %d/50" % [str(pack_id).capitalize(), int(UNIFIED_RULES.PACKS[pack_id].get("price", 0)), int(GameManager.profile.get("pack_pity", {}).get(pack_id, 0))], _buy_unified_pack.bind(str(pack_id)), Color("a86b2e")))
		elif unified_market_tab == "upgrades":
			host.add_child(label("Upgrade Forge · permanent Workshop upgrades and battle cards", 15, Color("e6dfd0")))
			for upgrade_id in UNIFIED_RULES.WORKSHOP_UPGRADES: host.add_child(make_button("Workshop: %s · %d FC" % [str(upgrade_id).replace("_", " "), int(UNIFIED_RULES.WORKSHOP_UPGRADES[upgrade_id].get("cost", 0))], func(): var r = GameManager.buy_workshop_upgrade_v3(str(upgrade_id)); _toast("Upgrade installed." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("588d73")))
			for upgrade_id in UNIFIED_RULES.UPGRADE_CARDS: host.add_child(make_button("Card: %s · %d FC" % [str(upgrade_id).replace("_", " "), int(UNIFIED_RULES.UPGRADE_CARDS[upgrade_id].get("cost", 0))], func(): var r = GameManager.buy_upgrade_card_v3(str(upgrade_id)); _toast("Upgrade Card added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("526e93")))
		else:
			host.add_child(label("Cosmetic Atelier · visual items never change battle rules", 15, Color("e6dfd0")))
			for cosmetic_id in UNIFIED_RULES.COSMETICS:
				var cosmetic_name := str(UNIFIED_RULES.COSMETICS[cosmetic_id].get("name", cosmetic_id)); var cosmetic_price := int(UNIFIED_RULES.COSMETICS[cosmetic_id].get("coins", 0))
				host.add_child(make_button("%s · %d Forge Coins" % [cosmetic_name, cosmetic_price], func(): var r = GameManager.buy_cosmetic_v3(str(cosmetic_id), "forge_coins"); _toast("Cosmetic added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("7b5a9b")))
				host.add_child(make_button("%s · %d Sparks" % [cosmetic_name, cosmetic_price], func(): var r = GameManager.buy_cosmetic_v3(str(cosmetic_id), "sparks"); _toast("Cosmetic added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("526e93")))
			host.add_child(make_button("Local test purchase: Forge Boost (1,200 Sparks)", func(): var r = GameManager.fake_store_purchase_v3("ui-%d" % Time.get_ticks_msec(), "forge_boost"); _toast("Sparks added." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("a86b2e")))
			host.add_child(make_button("Unlock paid Season Track · 1,200 Sparks", func(): var r = GameManager.buy_paid_season_v3(); _toast("Season Track unlocked." if bool(r.get("ok", false)) else str(r.get("error", "Unavailable."))); render(), Color("588d73")))
	elif screen == "unified_library":
		var owned: Array = []
		for definition in UNIFIED_RULES.all_cards():
			if int(GameManager.profile.get("owned_cards", {}).get(str(definition.get("id", "")), 0)) > 0: owned.append(definition)
		host.add_child(label("Owned cards only.", 15, Color("e6dfd0")))
		host.add_child(_unified_cards_page(owned, func(id): unified_inspector_id = id; unified_inspector_tab = "card"; render()))
		var library_deck := make_button("Open Deck Blueprint Rack", navigate_to.bind("deck"), Color("a86b2e"))
		library_deck.name = "UnifiedLibraryDeck"
		host.add_child(library_deck)
	elif screen == "unified_deck":
		if unified_deck_draft.is_empty(): unified_deck_draft = GameManager.active_deck_cards()
		var deck_slots := HBoxContainer.new(); deck_slots.name = "V3DeckSlots"; host.add_child(deck_slots)
		for slot in UNIFIED_RULES.DECK_SLOTS:
			var slot_id := str(slot.get("id", "")); var is_active := slot_id == str(GameManager.profile.get("active_deck_id", ""))
			deck_slots.add_child(make_button(("✓ " if is_active else "") + str(slot.get("name", slot_id)), func():
				var selected = GameManager.select_unified_deck(slot_id)
				if selected: unified_deck_draft = GameManager.active_deck_cards(); unified_preprint_draft = GameManager.profile.get("preprints", []).duplicate()
				else: _toast("That fixed deck slot needs a legal 40-card deck.")
				render(), Color("588d73") if is_active else Color("526e93")))
		var creatures := 0
		for card_id in unified_deck_draft:
			if str(UNIFIED_RULES.card(str(card_id)).get("type", "")) == "creature": creatures += 1
		host.add_child(label("%d cards · minimum 40 · %d creatures · copies limited by ownership" % [unified_deck_draft.size(), creatures], 15, Color("fff0a1")))
		var owned_deck: Array = []
		for definition in UNIFIED_RULES.all_cards():
			if int(GameManager.profile.get("owned_cards", {}).get(str(definition.get("id", "")), 0)) > 0: owned_deck.append(definition)
		for definition in owned_deck: definition["name"] = "%s · x%d in deck" % [str(definition.get("name", "")), unified_deck_draft.count(str(definition.get("id", "")))]
		for definition in owned_deck:
			var definition_id := str(definition.get("id", ""))
			definition["name"] = str(UNIFIED_RULES.card(definition_id).get("name", definition_id))
			definition["deck_count"] = unified_deck_draft.count(definition_id)
		host.add_child(_unified_cards_page(owned_deck, func(id):
			if id in unified_deck_draft: unified_deck_draft.erase(id)
			elif unified_deck_draft.count(id) < int(GameManager.profile.get("owned_cards", {}).get(id, 0)): unified_deck_draft.append(id)
			render()))
		host.add_child(make_button("Save active fixed deck", func(): GameManager.save_unified_deck(unified_deck_draft, str(GameManager.profile.get("active_deck_id", "starter-deck"))); render(), Color("588d73")))
		if unified_preprint_draft.is_empty(): unified_preprint_draft = GameManager.profile.get("preprints", []).duplicate()
		var slots := UNIFIED_RULES.preprint_slots(GameManager.profile)
		host.add_child(label("Pre-Print loadout · %d / %d slots · consumes exact active deck creature copies" % [unified_preprint_draft.size(), slots], 15, Color("9beaff")))
		var preprint_options: Array = []
		for id in unified_deck_draft:
			if str(UNIFIED_RULES.card(str(id)).get("type", "")) == "creature" and id not in preprint_options: preprint_options.append(id)
		for creature_id in preprint_options:
			var chosen := unified_preprint_draft.count(creature_id)
			var available := unified_deck_draft.count(creature_id)
			host.add_child(make_button(("✓ " if chosen > 0 else "○ ") + "%s · %d/%d selected" % [str(UNIFIED_RULES.card(creature_id).get("name", creature_id)), chosen, available], func():
				if chosen > 0: unified_preprint_draft.erase(creature_id)
				elif unified_preprint_draft.size() < slots and unified_preprint_draft.count(creature_id) < available: unified_preprint_draft.append(creature_id)
				render(), Color("588d73") if chosen > 0 else Color("526e93")))
		host.add_child(make_button("Save Pre-Print loadout", func(): var saved = GameManager.save_preprints_v3(unified_preprint_draft); _toast("Pre-Print loadout saved." if saved else "Pre-Print loadout is not legal."); render(), Color("a86b2e")))
	elif screen == "unified_forgedex":
		_render_unified_forgedex_page(host)
	else:
		host.add_child(label("Printer skill nodes were retired. Workshop Upgrades and Upgrade Cards are available in the Filament Market.", 15, Color("fff0a1")))
		host.add_child(make_button("Open Upgrade Forge", func(): screen = "unified_market"; unified_market_tab = "upgrades"; render(), Color("588d73")))
	host.add_child(make_button("Back to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
	_render_unified_inspector()
	if screen == "unified_market": _render_unified_pack_reveal()

func _buy_unified_pack(pack_id: String) -> void:
	var result := GameManager.buy_card_pack(pack_id)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "Pack unavailable.")))
	else:
		unified_reveal_page = 0
		_toast("Pack opened. Review each card before keeping it.")
	render()

func _buy_unified_market_card(card_id: String) -> void:
	# Retained only for legacy buttons that still route here; all unified Market
	# purchases now use the canonical 48-hour typed Card Shop transition.
	var result := GameManager.buy_market_card_v3(card_id)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "Market offer unavailable.")))
	else:
		var card := UNIFIED_RULES.card(card_id)
		var message := "%s added to your Library." % str(card.get("name", card_id))
		_toast(message)
	render()

func _render_unified_pack_reveal() -> void:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
	var cards: Array = pending.get("cards", []) if pending is Dictionary else []
	var bonus_cards: Array = pending.get("bonus_cards", []) if pending is Dictionary else []
	if not bonus_cards.is_empty(): cards.append_array(bonus_cards)
	if cards.is_empty(): return
	var modal := ColorRect.new()
	modal.name = "UnifiedPackReveal"
	modal.color = Color("07111bf2")
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var shell := PanelContainer.new()
	var reveal_height := 470.0 if is_portrait_layout() else 460.0
	shell.custom_minimum_size = Vector2(minf(1040, size.x - 24), minf(reveal_height, size.y - 24))
	shell.add_theme_stylebox_override("panel", panel_style(Color("102940fa"), Color("f1be69")))
	center.add_child(shell)
	var content := VBoxContainer.new()
	content.name = "UnifiedPackRevealContent"
	content.add_theme_constant_override("separation", 8)
	shell.add_child(content)
	content.add_child(label("Foundry pack reveal", 24, Color("ffd36c")))
	var unlocks: Array = pending.get("blueprint_unlocks", []) if pending is Dictionary else []
	content.add_child(label("%d cards%s · duplicates are kept%s" % [cards.size(), " including %d Rare Reward bonus cards" % bonus_cards.size() if not bonus_cards.is_empty() else "", " · blueprint unlocked" if not unlocks.is_empty() else ""], 14, Color("dce8f4")))
	var per_page := 2 if is_portrait_layout() else 4
	var pages := maxi(1, int(ceil(float(cards.size()) / float(per_page))))
	unified_reveal_page = clampi(unified_reveal_page, 0, pages - 1)
	# Keep a short reveal centered in its ceremonial panel instead of leaving a
	# large, accidental-looking empty rail on the right at desktop widths.
	var grid_center := CenterContainer.new()
	grid_center.name = "UnifiedPackRevealCardCenter"
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid_center)
	var grid := GridContainer.new()
	grid.name = "UnifiedPackRevealGrid"
	grid.columns = 2 if is_portrait_layout() else 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_center.add_child(grid)
	for card_id in cards.slice(unified_reveal_page * per_page, mini(cards.size(), (unified_reveal_page + 1) * per_page)):
		var id := str(card_id)
		var view := UNIFIED_CARD_VIEW.new()
		view.name = "UnifiedPackCardView%s" % id.capitalize()
		var note := "Blueprint unlocked" if id in unlocks else "Awarded now"
		view.configure(UNIFIED_RULES.card(id), int(GameManager.profile.get("owned_cards", {}).get(id, 0)), -1, note, true, false)
		grid.add_child(view)
	var pager := HBoxContainer.new()
	pager.name = "UnifiedPackRevealPager"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(pager)
	var previous := make_button("Previous", func(): unified_reveal_page = posmod(unified_reveal_page - 1, pages); render(), Color("536c8d"))
	previous.custom_minimum_size = Vector2(48, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(previous)
	pager.add_child(_compact_pager_label("%d / %d" % [unified_reveal_page + 1, pages]))
	var next := make_button("Next", func(): unified_reveal_page = posmod(unified_reveal_page + 1, pages); render(), Color("536c8d"))
	next.custom_minimum_size = Vector2(48, 44)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pager.add_child(next)
	content.add_child(make_button("Keep cards", _keep_unified_pack_cards, Color("588d73")))

func _keep_unified_pack_cards() -> void:
	var kept := GameManager.claim_pending_pack_reveal()
	if kept.is_empty(): _toast("There are no pack cards waiting to keep.")
	else: _toast("Kept %d cards in your Library." % kept.size())
	render()

func _submit_unified_intent(intent: Dictionary) -> void:
	if battle == null or battle.finished: return
	var previous_seat := int(battle.active_seat)
	var result: Dictionary = UNIFIED_BATTLE_RULES.apply_intent(battle, int(battle.active_seat), intent)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("error", "That action is not legal.")))
		return
	unified_selected_card_id = ""
	unified_selected_slot = -2
	unified_selected_target = -2
	unified_attack_slot = -1
	unified_attack_target = -2
	if battle_mode != "local" and int(battle.active_seat) == 1 and not battle.finished:
		unified_ai_pending = true
	if battle_mode == "local" and int(battle.active_seat) != previous_seat:
		unified_local_handoff = true
	render()
	if unified_ai_pending: call_deferred("_run_unified_ai")

func _run_unified_ai() -> void:
	if not unified_ai_pending or battle == null or battle.finished: return
	# Yield one composed frame so a player print arriving after Collect is visible
	# before the rival response. This is presentation scheduling only.
	var wait_seconds := 0.0 if bool(settings().get("reduced_motion", false)) else 0.52
	if wait_seconds > 0.0: await get_tree().create_timer(wait_seconds).timeout
	else: await get_tree().process_frame
	if battle != null and not battle.finished and int(battle.active_seat) == 1:
		UNIFIED_AI.take_turn(battle, 1)
	unified_ai_pending = false
	render()

func _settle_finished_unified_battle() -> void:
	if battle == null or battle_settlement_context.is_empty() or battle_settlement_finished: return
	battle_settlement_finished = true
	var settled: Dictionary = GameManager.settle_unified_mode_battle(battle_settlement_context, battle, int(battle.winner) == 0)
	_toast("Result saved." if bool(settled.get("ok", false)) else str(settled.get("error", "Result could not be saved.")))
	render()

func _unified_card_button(card_id: String) -> Button:
	var card := UNIFIED_RULES.card(card_id)
	var button := make_button(("✓ " if card_id == unified_selected_card_id else "") + str(card.get("name", card_id)) + " · %dF" % int(card.get("cost", 0)), func(): unified_selected_card_id = card_id; unified_selected_slot = -2; unified_selected_target = -2; render(), Color("588d73") if card_id == unified_selected_card_id else Color("2f93a8"))
	button.custom_minimum_size = Vector2(0, 58)
	button.name = "UnifiedHand%s" % card_id.capitalize()
	var art := _unified_card_thumbnail(card)
	if art != null:
		button.icon = art
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 42)
	return button

func _render_unified_play_picker(host: Container, active: Dictionary) -> void:
	if unified_selected_card_id.is_empty() or unified_selected_card_id not in active.get("hand", []): return
	var card := UNIFIED_RULES.card(unified_selected_card_id)
	var panel := make_panel(Color("17394ee8"), Color("8deaff"))
	panel.name = "UnifiedPlayTargetPicker"
	host.add_child(panel.get_parent())
	panel.add_child(label("%s · choose its legal target" % str(card.get("name", unified_selected_card_id)), 15, Color("fff0a1")))
	var kind := str(card.get("type", ""))
	var picks := HBoxContainer.new()
	picks.add_theme_constant_override("separation", 7)
	panel.add_child(picks)
	if kind == "creature":
		panel.add_child(label("Creatures enter the public FIFO queue now; choose a slot and mode when printing completes.", 13, Color("e6dfd0")))
		panel.add_child(make_button("Queue creature", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id}), Color("a86b2e")))
	elif kind == "equipment":
		if str(card.get("equipment_slot", "")) == "battle_effect":
			panel.add_child(label("This is worn by the player for this battle. It does not print or use a creature gear slot.", 13, Color("e6dfd0")))
			panel.add_child(make_button("Activate player effect", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id}), Color("a86b2e")))
		else:
			for slot in 3:
				if active.slots[slot] != null:
					picks.add_child(make_button(("✓ " if unified_selected_target == slot else "") + "Your slot %d" % (slot + 1), func(): unified_selected_target = slot; render(), Color("588d73") if unified_selected_target == slot else Color("526e93")))
			if unified_selected_target >= 0: panel.add_child(make_button("Queue equipment", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id,"slot":-1,"target":unified_selected_target}), Color("a86b2e")))
	elif kind == "spell":
		# Targeted spells use slots; queue and filament spells resolve without one.
		for slot in 3:
			if battle.player(1 - int(battle.active_seat)).slots[slot] != null:
				picks.add_child(make_button(("✓ " if unified_selected_target == slot else "") + "Enemy %d" % (slot + 1), func(): unified_selected_target = slot; render(), Color("588d73") if unified_selected_target == slot else Color("526e93")))
		panel.add_child(make_button("Cast card", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id,"target":unified_selected_target}), Color("a86b2e")))
	else:
		panel.add_child(make_button("Use refill", _submit_unified_intent.bind({"type":"play_card","card_id":unified_selected_card_id,"slot":-1,"target":-2}), Color("a86b2e")))

func _render_unified_attack_picker(host: Container, active: Dictionary) -> void:
	if str(battle.phase) != "attack": return
	var panel := make_panel(Color("3a241ee8"), Color("f1be69"))
	panel.name = "UnifiedAttackTargetPicker"
	host.add_child(panel.get_parent())
	panel.add_child(label("Attack · choose a ready print, then a legal target", 15, Color("fff0a1")))
	var attackers := HBoxContainer.new(); panel.add_child(attackers)
	for slot in 3:
		if active.slots[slot] != null and bool(active.slots[slot].get("ready", false)):
			attackers.add_child(make_button(("✓ " if unified_attack_slot == slot else "") + str(active.slots[slot].get("name", "Print")), func(): unified_attack_slot = slot; unified_attack_target = -2; render(), Color("a86b2e") if unified_attack_slot == slot else Color("526e93")))
	if unified_attack_slot < 0: return
	var targets := HBoxContainer.new(); panel.add_child(targets)
	var foe: Dictionary = battle.player(1 - int(battle.active_seat)); var guarded := false
	for slot in 3:
		if foe.slots[slot] != null:
			guarded = true
			targets.add_child(make_button(("✓ " if unified_attack_target == slot else "") + "Enemy %d" % (slot + 1), func(): unified_attack_target = slot; render(), Color("588d73") if unified_attack_target == slot else Color("526e93")))
	if not guarded: targets.add_child(make_button(("✓ " if unified_attack_target == -1 else "") + "Rival printer", func(): unified_attack_target = -1; render(), Color("588d73") if unified_attack_target == -1 else Color("526e93")))
	if unified_attack_target >= -1: panel.add_child(make_button("Confirm attack", _submit_unified_intent.bind({"type":"attack","slot":unified_attack_slot,"target":unified_attack_target}), Color("a86b2e")))

func render_unified_battle_fullscreen(host: Container) -> void:
	var component = _unified_battle_component()
	if component != null:
		component.render(host, self)
		return
	# Fallback keeps a damaged optional component from blanking the Workshop
	# shell. Normal shipped presentation is owned by UnifiedBattleScreenComponent.
	if battle == null:
		host.add_child(label("No unified battle is active.", 20, Color("fff0a1")))
		host.add_child(make_button("Return to Workshop", navigate_to.bind("workshop"), Color("536c8d")))
		return
	var heading := label("Foundry Battle · %s" % battle_mode.capitalize().replace("_", " "), 25, Color("ffd36c"))
	heading.name = "UnifiedBattleHeading"
	host.add_child(heading)
	var arena := TextureRect.new(); arena.texture = load(_unified_battle_background_path()); arena.custom_minimum_size = Vector2(0, 74 if is_portrait_layout() else 72); arena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; arena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; arena.mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(arena)
	if not toast.is_empty(): host.add_child(label(toast, 14, Color("fff0a1")))
	host.add_child(label("Turn %d · %s phase" % [int(battle.turn), str(battle.phase).capitalize()], 16, Color("9beaff")))
	host.add_child(_unified_side_panel("Rival", battle.player(1), Color("ffaaa1")))
	host.add_child(_unified_side_panel("Your", battle.player(0), Color("8deaff")))
	if battle_mode == "local" and unified_local_handoff:
		var handoff := make_panel(Color("2b213ee8"), Color("f1be69"))
		handoff.name = "UnifiedLocalHandoff"
		host.add_child(handoff.get_parent())
		handoff.add_child(label("Pass the device · Player %d" % (int(battle.active_seat) + 1), 18, Color("fff0a1")))
		handoff.add_child(label("Hands remain concealed until the next player is ready.", 14, Color("e6dfd0")))
		handoff.add_child(make_button("Ready Player %d" % (int(battle.active_seat) + 1), func(): unified_local_handoff = false; unified_hand_page = 0; render(), Color("a86b2e")))
		return
	if battle.finished:
		host.add_child(label("%s printer broke." % ("Rival" if int(battle.winner) == 0 else "Your"), 20, Color("a8e3a5") if int(battle.winner) == 0 else Color("ffaaa1")))
		if not battle_settlement_context.is_empty() and not battle_settlement_finished:
			host.add_child(label("Saving the battle result…", 14, Color("fff0a1")))
			call_deferred("_settle_finished_unified_battle")
		else:
			host.add_child(make_button("Return to Workshop", func(): battle = null; battle_settlement_context.clear(); screen = "workshop"; render(), Color("536c8d")))
		return
	if unified_ai_pending:
		host.add_child(label("Rival printer is calculating its turn…", 15, Color("fff0a1")))
		return
	var active: Dictionary = battle.player(int(battle.active_seat))
	var hand_title := label("Player %d hand" % (int(battle.active_seat) + 1), 17, Color("ffd36c"))
	hand_title.name = "UnifiedHandHeading"
	host.add_child(hand_title)
	var hand: Array = active.get("hand", [])
	var hand_page_size := 4 if is_portrait_layout() else 7
	var pages := maxi(1, int(ceil(float(hand.size()) / float(hand_page_size))))
	unified_hand_page = clampi(unified_hand_page, 0, pages - 1)
	var hand_grid := GridContainer.new()
	hand_grid.name = "UnifiedBattleHandGrid"
	hand_grid.columns = 2 if is_portrait_layout() else 4
	hand_grid.add_theme_constant_override("h_separation", 8)
	hand_grid.add_theme_constant_override("v_separation", 8)
	host.add_child(hand_grid)
	for card_id in hand.slice(unified_hand_page * hand_page_size, mini(hand.size(), (unified_hand_page + 1) * hand_page_size)):
		hand_grid.add_child(_unified_card_button(str(card_id)))
	var pager := HBoxContainer.new(); pager.name = "UnifiedBattleHandPager"; pager.alignment = BoxContainer.ALIGNMENT_CENTER; pager.size_flags_vertical = Control.SIZE_SHRINK_CENTER; host.add_child(pager)
	var hand_prev := make_button("‹", func(): unified_hand_page = posmod(unified_hand_page - 1, pages); render(), Color("536c8d")); hand_prev.custom_minimum_size = Vector2(48, 44); hand_prev.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; hand_prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER; pager.add_child(hand_prev)
	var hand_label := _compact_pager_label("Hand %d / %d" % [unified_hand_page + 1, pages]); pager.add_child(hand_label)
	var hand_next := make_button("›", func(): unified_hand_page = posmod(unified_hand_page + 1, pages); render(), Color("536c8d")); hand_next.custom_minimum_size = Vector2(48, 44); hand_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; hand_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER; pager.add_child(hand_next)
	if int(battle.active_seat) == 0 or battle_mode == "local":
		_render_unified_play_picker(host, active)
		_render_unified_attack_picker(host, active)
	var actions := HBoxContainer.new()
	actions.name = "UnifiedBattlePhaseActions"
	actions.add_theme_constant_override("separation", 8)
	host.add_child(actions)
	# The full legal target/card picker is added by the Foundry battle component;
	# these phase controls are intentionally explicit and never infer a target.
	actions.add_child(make_button("Advance phase", _submit_unified_intent.bind({"type":"advance_phase"}), Color("2f93a8")))
	if str(battle.phase) == "collect":
		actions.add_child(label("Scrap collection is automatic when you advance this phase.", 13, Color("e6dfd0")))
	host.add_child(make_button("Return to Workshop", func(): battle = null; battle_settlement_context.clear(); screen = "workshop"; render(), Color("536c8d")))

func _toast(message: String) -> void:
	toast = message
	if status:
		status.visible = not message.is_empty()
		status.text = message
