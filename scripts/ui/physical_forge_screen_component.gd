class_name PhysicalForgeScreenComponent
extends RefCounted
## Route-wide M9 Forge station. Main remains the transaction/sequence owner; this
## component only composes the approved enclosure with native, reachable controls.

const PLATE := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const CONTROLS := preload("res://scripts/ui/physical_control_family.gd")
const NAVIGATION := preload("res://scripts/ui/physical_navigation_component.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const PARCHMENT_BLUEPRINT_INK_SHADER := preload("res://scripts/ui/physical_catalog_imprint.gdshader")
const STATION_PATH := "res://assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png"
const DESIGN_SIZE := Vector2(941.0, 1672.0)

var _station_texture: Texture2D
# Test-only fault seam: harnesses may prove a missing promoted layer enters the
# caller-safe presentation without mutating or deleting durable approved assets.
var test_missing_layer := ""
var _safe_unavailable := false

func blocks_presentation_advance() -> bool:
	return _safe_unavailable

static func refresh_native(main: Control) -> void:
	## Same-phase progress deliberately keeps the persistent chamber attached. Only
	## its native facts change; no render refresh can allocate a second sequence.
	if main.printer_sequence == null:
		return
	var percent: int = 0 if main.printer_sequence.phase == ArcaneForgeSequence.IDLE else main.printer_sequence.layer_reveal_bps() / 100
	var layer := main.find_child("ForgeLayerInstrument", true, false) as Label
	if layer != null:
		layer.text = "LAYER\n%d%%" % percent
	if is_instance_valid(main.printer_progress_label):
		main.printer_progress_label.text = "LAYER\n%d%%" % percent
	var state := main.find_child("ForgeStateInstrument", true, false) as Label
	if state != null:
		state.text = "%s\n%s" % [_phase_text_static(main.printer_sequence.phase), _eta_text_static(main)]
	var status := main.find_child("ForgeStationStatus", true, false) as Label
	if status != null:
		if main.printer_sequence.phase == ArcaneForgeSequence.FAILED:
			# The failure well is the sole concise visible owner. Never replace it with
			# generic phase copy during a same-phase native refresh; accessibility keeps
			# the complete existing persistence/eligibility reason.
			status.text = _compact_failure_text(main.printer_failure)
		elif main.printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
			status.text = "SECURING\nRECORD"
		else:
			status.text = "%s · %s" % [str(_definition_static(main).get("element", "Forge blueprint")).to_upper(), _phase_text_static(main.printer_sequence.phase)]

func refresh_presentation(main: Control) -> void:
	# Same-phase process ticks update the already attached chamber and native facts.
	# They never reload this script, rebuild the fitted station, or introduce a
	# legacy minimum-height projection.
	if _safe_unavailable or main.printer_sequence == null:
		return
	var forge = main._forge_component()
	if forge == null or forge.stage == null:
		return
	var sequence = main.printer_sequence
	forge.refresh(
		main.printer_creature_id,
		bool(main.settings().get("reduced_motion", false)),
		bool(main.settings().get("high_contrast", false)),
		sequence.phase,
		sequence.progress_bps,
		sequence.phase_progress_bps(),
		main.printer_presentation_seconds,
		forge.stage.custom_minimum_size.y,
		main.printer_armor_id if main.printer_is_armor else "",
		main.printer_armor_id if main.printer_is_core else "",
		true
	)
	refresh_native(main)

static func _definition_static(main: Control) -> Dictionary:
	if main.printer_is_armor:
		return ArmorCoreDefinitions.core_blueprint_definition(main.printer_armor_id) if main.printer_is_core else ProgressionRules.armor_def(main.printer_armor_id)
	return Catalog.creature(main.printer_creature_id)

static func _phase_text_static(phase: String) -> String:
	match phase:
		ArcaneForgeSequence.IDLE: return "READY"
		ArcaneForgeSequence.PRINTING: return "PRINTING"
		ArcaneForgeSequence.RAW_COMPLETE: return "SECURING"
		ArcaneForgeSequence.RAW_HOLD: return "RAW HOLD"
		ArcaneForgeSequence.AWAKENING: return "AWAKEN"
		ArcaneForgeSequence.DEPARTING: return "DEPART"
		ArcaneForgeSequence.AWAKENED: return "DONE"
		ArcaneForgeSequence.FAILED: return "FAILED"
	return "FORGE"

static func _eta_text_static(main: Control) -> String:
	if main.printer_sequence.phase == ArcaneForgeSequence.IDLE:
		return "READY NOW"
	if main.printer_sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		return "RECORD PENDING"
	if main.printer_sequence.phase == ArcaneForgeSequence.FAILED:
		return "NOT SAVED"
	match main.printer_sequence.phase:
		ArcaneForgeSequence.RAW_HOLD: return "RESTING"
		ArcaneForgeSequence.AWAKENING: return "FORMING"
		ArcaneForgeSequence.DEPARTING: return "TRANSFER"
		ArcaneForgeSequence.AWAKENED: return "COMPLETE"
	var remaining := maxi(0, ArcaneForgeSequence.PRINT_COMPLETE_BPS - main.printer_sequence.progress_bps)
	var step := ArcaneForgeSequence.presentation_step_bps(bool(main.settings().get("reduced_motion", false)), ArcaneForgeSequence.PRINTING)
	var seconds := ceili(float(remaining) / float(step)) * ArcaneForgeSequence.presentation_interval_seconds(bool(main.settings().get("reduced_motion", false)))
	return "%ds ETA" % ceili(seconds)

func render(main: Control) -> void:
	var sequence = main.printer_sequence
	_safe_unavailable = false
	if sequence == null:
		main.cancel_printer_preview()
		return
	if _station_texture == null:
		_station_texture = ResourceLoader.load(STATION_PATH) as Texture2D
	if _station_texture == null:
		_safe_unavailable = true
		_render_safe_unavailable(main)
		return
	# Neither the retired humanoid suit raw nor a core blueprint identity card has
	# M9A promotion authority. Equipment callers therefore retain caller-safe native
	# Back before Start; the core's legacy raw remains stage-test-only evidence.
	if main.printer_is_armor:
		_safe_unavailable = true
		_render_safe_unavailable(main)
		return
	var forge = main._forge_component()
	if forge == null:
		_safe_unavailable = true
		_render_safe_unavailable(main)
		return
	forge.refresh(main.printer_creature_id, bool(main.settings().get("reduced_motion", false)), bool(main.settings().get("high_contrast", false)), sequence.phase, sequence.progress_bps, sequence.phase_progress_bps(), main.printer_presentation_seconds, 1.0, main.printer_armor_id if main.printer_is_armor else "", main.printer_armor_id if main.printer_is_core else "", true)
	if not test_missing_layer.is_empty() or forge.stage == null or not forge.stage.continuity_assets_ready():
		_safe_unavailable = true
		_render_safe_unavailable(main)
		return
	var surface := Control.new()
	surface.name = "ForgeContinuitySurface"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(surface)
	var plate: PhysicalPortraitPlatePresenter = PLATE.new()
	plate.name = "ForgeContinuityStation"
	plate.configure(_station_texture)
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(plate)
	main._apply_presentation_safe_area(plate)
	var content := plate.content_layer()
	content.name = "ForgeContinuityNativeFrame"
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	_attach_stage(main, content)
	_add_dial_readouts(main, content)
	_add_cartridge_readout(main, content)
	_add_actions(main, content)
	# Forge feedback belongs in its authored instrument wells. A generic route toast
	# floats over the brass/circular material and makes a normal element/status read
	# like detached machine copy.

func _attach_stage(main: Control, content: Control) -> void:
	var forge = main._forge_component()
	if forge == null:
		return
	var sequence = main.printer_sequence
	forge.refresh(
		main.printer_creature_id,
		bool(main.settings().get("reduced_motion", false)),
		bool(main.settings().get("high_contrast", false)),
		sequence.phase,
		sequence.progress_bps,
		sequence.phase_progress_bps(),
		main.printer_presentation_seconds,
		content.size.y,
		main.printer_armor_id if main.printer_is_armor else "",
		main.printer_armor_id if main.printer_is_core else "",
		true
	)
	var aperture := Control.new()
	aperture.name = "ForgeContinuityChamberAperture"
	aperture.clip_contents = true
	aperture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(aperture, ArcaneForgeStage.STATION_CHAMBER)
	content.add_child(aperture)
	forge.attach(aperture)
	if forge.stage != null:
		forge.stage.name = "ForgeContinuityChamber"
		forge.stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
		forge.stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sync_stage_geometry(forge.stage, aperture, content)
		# The fitted portrait plate may change its content rect for a tall window or
		# a real top safe area without rebuilding Main. Keep this one accepted stage
		# attached and registered to the new clipped aperture; never allocate a job,
		# timer, or replacement chamber for geometry alone.
		content.resized.connect(_sync_stage_geometry.bind(forge.stage, aperture, content))

func _sync_stage_geometry(stage: ArcaneForgeStage, aperture: Control, content: Control) -> void:
	if stage == null or not is_instance_valid(stage) or not is_instance_valid(aperture) or not is_instance_valid(content):
		return
	stage.position = -aperture.position
	stage.size = content.size

func _add_dial_readouts(main: Control, content: Control) -> void:
	var definition := _definition_static(main)
	var sequence = main.printer_sequence
	# Keep the authored dial face intact at large text: a title-case recipe name
	# can wrap inside its native well instead of colliding with the brass rim.
	var first := _native_label(main, "%s\n%s" % [str(definition.get("name", "Blueprint")), _price_text(main)], 11, Color("172b3c"))
	first.name = "ForgeRecipeInstrument"
	_place(first, Rect2(128, 1080, 156, 116))
	content.add_child(first)
	var percent: int = 0 if sequence.phase == ArcaneForgeSequence.IDLE else sequence.layer_reveal_bps() / 100
	var middle := _native_label(main, "LAYER\n%d%%" % percent, 13, Color("172b3c"))
	middle.name = "ForgeLayerInstrument"
	_place(middle, Rect2(391, 1080, 156, 116))
	content.add_child(middle)
	main.printer_progress_label = middle
	var phase := _phase_text_static(sequence.phase)
	var eta := _native_label(main, "%s\n%s" % [phase, _eta_text_static(main)], 11, Color("172b3c"))
	eta.name = "ForgeStateInstrument"
	_place(eta, Rect2(660, 1080, 156, 116))
	content.add_child(eta)

func _add_cartridge_readout(main: Control, content: Control) -> void:
	var definition := _definition_static(main)
	var blueprint_host := Control.new()
	blueprint_host.name = "ForgeBlueprintCartridgeAperture"
	blueprint_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# This is the exact existing First Print parchment face, kept clipped so the
	# approved transparent blueprint ink never spills onto the navy cartridge.
	_place(blueprint_host, Rect2(793, 380, 94, 236))
	content.add_child(blueprint_host)
	var blueprint := IMPRINT.add_blueprint_card(blueprint_host, "ForgeBlueprintCartridgeInk", main._blueprint_card_texture(definition), Rect2(0, 0, 1, 1))
	var parchment_ink := ShaderMaterial.new()
	parchment_ink.shader = PARCHMENT_BLUEPRINT_INK_SHADER
	parchment_ink.set_shader_parameter("ink_tint", Color("47331f"))
	parchment_ink.set_shader_parameter("ink_strength", 0.82)
	parchment_ink.set_shader_parameter("remove_dark_matte", false)
	blueprint.material = parchment_ink
	var label := _native_label(main, "READY" if int(main.settings().get("text_scale_bps", 10000)) >= 15000 else "LOADED", 10, Color("172b3c"))
	label.name = "ForgeBlueprintCartridgeLabel"
	label.tooltip_text = "Blueprint loaded and ready to print"
	_place(label, Rect2(793, 548, 94, 42))
	content.add_child(label)
	if not main.printer_is_armor and main.printer_sequence.phase == ArcaneForgeSequence.IDLE:
		_add_selector(main, content)

func _add_actions(main: Control, content: Control) -> void:
	var sequence = main.printer_sequence
	var back := _button(main, "ArcaneForgeBack", _back_text(main), main.request_back, "binding")
	back.accessibility_name = main._forge_back_accessibility()
	back.tooltip_text = back.accessibility_name
	if sequence.phase == ArcaneForgeSequence.RAW_COMPLETE:
		back.disabled = true
		back.text = "SECURING"
		back.tooltip_text = "Forge record is securing. Back is temporarily unavailable until the commit resolves."
		back.accessibility_name = back.tooltip_text
	_place(back, Rect2(70, 1362, 220, 112))
	content.add_child(back)
	match sequence.phase:
		ArcaneForgeSequence.IDLE:
			var start := _button(main, "BeginCreaturePrint", "START\n%s" % _price_text(main), main.begin_printer, "wide")
			start.accessibility_name = "Start %s" % str(_definition_static(main).get("name", "selected blueprint"))
			var eligible: bool = bool(main.printer_is_armor) or main.printer_creature_id in main.printer_blueprint_ids()
			var affordable: bool = int(main.printer_price) <= int(GameManager.profile.get("forge_coins", 0)) or int(main.printer_price) == 0
			start.disabled = not eligible or not affordable
			if not eligible:
				start.tooltip_text = "Choose a learned creature blueprint before starting."
			elif not affordable:
				start.tooltip_text = "You need %d Forge Coins to start this print." % main.printer_price
			_place(start, Rect2(356, 1362, 230, 112))
			content.add_child(start)
			var ready_text := "%d FC" % int(GameManager.profile.get("forge_coins", 0))
			if not eligible:
				ready_text = "CHOOSE\nBLUEPRINT"
			elif not affordable:
				ready_text = "NEED\n%d FC" % main.printer_price
			var ready := _native_label(main, ready_text, 11, Color("172b3c"))
			ready.name = "ForgeActionStatus"
			ready.tooltip_text = start.tooltip_text if start.disabled else "Available Forge Coins: %d" % int(GameManager.profile.get("forge_coins", 0))
			_place(ready, Rect2(653, 1382, 214, 72))
			content.add_child(ready)
		ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING:
			var skip := _button(main, "SkipPrinterAnimation", "SKIP", main.skip_printer, "wide")
			skip.accessibility_name = "Skip the current Forge presentation without bypassing its commit"
			_place(skip, Rect2(356, 1362, 230, 112))
			content.add_child(skip)
			var active := _native_label(main, "%d FC" % int(GameManager.profile.get("forge_coins", 0)), 11, Color("172b3c"))
			active.name = "ForgeActionStatus"
			_place(active, Rect2(653, 1382, 214, 72))
			content.add_child(active)
		ArcaneForgeSequence.AWAKENED:
			var primary_callback: Callable = main.return_to_printer_picker
			var primary_text := "PRINT\nANOTHER"
			if not main.printer_is_armor and int(GameManager.profile.get("starter_pack_rewards", {}).get("opened", 0)) < int(GameManager.profile.get("starter_pack_rewards", {}).get("entitled", 0)):
				primary_callback = main._open_next_starter_pack
				primary_text = "OPEN\nPACK"
			var done := _button(main, "ForgeTerminalPrimary", primary_text, primary_callback, "wide")
			_place(done, Rect2(356, 1362, 230, 112))
			content.add_child(done)
			var returned := _button(main, "ReturnAfterPrint", "RETURN", main.request_back, "binding")
			_place(returned, Rect2(653, 1362, 214, 112))
			content.add_child(returned)
		ArcaneForgeSequence.FAILED:
			var retry := _button(main, "ReturnFailedPrint", "RETURN", main.request_back, "wide")
			retry.accessibility_name = "Return after failed Forge print. %s" % main.printer_failure
			retry.tooltip_text = retry.accessibility_name
			_place(retry, Rect2(356, 1362, 230, 112))
			content.add_child(retry)
			var failed := _native_label(main, _compact_failure_text(main.printer_failure), 11, Color("172b3c"))
			failed.name = "ForgeStationStatus"
			failed.tooltip_text = main.printer_failure
			_place(failed, Rect2(653, 1382, 214, 72))
			content.add_child(failed)
		ArcaneForgeSequence.RAW_COMPLETE:
			# The legal commit boundary is still in flight. Do not falsely call the
			# record secure until Main has resolved the existing transaction.
			var securing := _native_label(main, "SECURING\nRECORD", 11, Color("172b3c"))
			securing.name = "ForgeStationStatus"
			_place(securing, Rect2(653, 1382, 214, 72))
			content.add_child(securing)
		_:
			var secure := _native_label(main, "RECORD SECURE", 11, Color("172b3c"))
			_place(secure, Rect2(653, 1382, 214, 72))
			content.add_child(secure)

func _price_text(main: Control) -> String:
	return "FREE" if main.printer_price == 0 else "%d FC" % main.printer_price

static func _compact_failure_text(reason: String) -> String:
	if reason.is_empty():
		return "RECORD\nFAILED"
	var normalized := reason.to_lower()
	if "storage" in normalized or "persist" in normalized or "record" in normalized:
		return "RECORD\nNOT SAVED"
	return "PRINT\nFAILED"

func _back_text(main: Control) -> String:
	if int(main.settings().get("text_scale_bps", 10000)) >= 15000:
		return "BACK"
	return main._forge_back_label().replace(" TO ", " TO\n")

func _native_label(main: Control, text: String, font_size: int, color: Color) -> Label:
	var result: Label = main.label(text, font_size, color)
	# The master leaves cream instrument faces text-free. Their runtime ink stays
	# dark even under the broader high-contrast helper so this copy never washes
	# out into the physical paper.
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _button(main: Control, node_name: String, text: String, callback: Callable, kind: String) -> Button:
	var result: Button = main._visual_button(node_name, text, callback, Color("f3e5c9"), true)
	result.focus_mode = Control.FOCUS_ALL
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The approved master already owns every physical well. Buttons are semantic
	# transparent hit/focus layers; no opaque texture may cover the baked hardware.
	CONTROLS.apply(result, kind, false, true)
	if node_name == "ArcaneForgeBack":
		NAVIGATION.configure_back(result, main._forge_back_label().replace("BACK TO ", ""), Vector2(56, 56), true)
		# The control-family focus StyleBox is the visible ring. Keep a named native
		# owner under this Back target so focus audits do not have to infer it from a
		# shared cached theme resource.
		var focus_owner := Control.new()
		focus_owner.name = "PhysicalInsetFocusRing"
		focus_owner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		result.add_child(focus_owner)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		result.add_theme_color_override(key, Color("172b3c"))
	return result

func _add_selector(main: Control, content: Control) -> void:
	var ids: Array[String] = main.printer_blueprint_ids()
	if ids.is_empty():
		var missing := _native_label(main, "NO LEARNED\nBLUEPRINT", 10, Color("172b3c"))
		_place(missing, Rect2(752, 632, 130, 62))
		content.add_child(missing)
		return
	var index: int = ids.find(main.printer_creature_id)
	if index < 0:
		index = 0
	# One cartridge jewel affords both directions. Stack the real >=48 logical-px
	# native targets rather than leaving two dark-on-dark arrows beside the cartridge.
	var previous := _button(main, "PrinterSelectPrevious", "‹", func(): main.select_printer_blueprint(ids[posmod(index - 1, ids.size())]), "square")
	previous.add_theme_font_size_override("font_size", main.scaled_font(22))
	_apply_cartridge_chevron_ink(previous)
	previous.accessibility_name = "Previous learned Forge blueprint"
	previous.tooltip_text = previous.accessibility_name
	_place(previous, Rect2(772, 620, 96, 80))
	content.add_child(previous)
	var next := _button(main, "PrinterSelectNext", "›", func(): main.select_printer_blueprint(ids[posmod(index + 1, ids.size())]), "square")
	next.add_theme_font_size_override("font_size", main.scaled_font(22))
	_apply_cartridge_chevron_ink(next)
	next.accessibility_name = "Next learned Forge blueprint"
	next.tooltip_text = next.accessibility_name
	_place(next, Rect2(772, 716, 96, 80))
	content.add_child(next)

func _apply_cartridge_chevron_ink(button: Button) -> void:
	# These two transparent controls sit on the navy/brass cartridge jewel, not a
	# cream well. Their final state-specific ink must therefore be ivory with a
	# navy outline; every actual cream-well control retains _button's dark ink.
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(key, Color("fff0cf") if key != "font_disabled_color" else Color("fff0cf", 0.52))
	button.add_theme_color_override("font_outline_color", Color("10283a"))
	button.add_theme_constant_override("outline_size", 3)

func _place(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x / DESIGN_SIZE.x
	control.anchor_top = rect.position.y / DESIGN_SIZE.y
	control.anchor_right = rect.end.x / DESIGN_SIZE.x
	control.anchor_bottom = rect.end.y / DESIGN_SIZE.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

func _render_safe_unavailable(main: Control) -> void:
	var surface := Control.new()
	surface.name = "ForgeContinuitySafeUnavailable"
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(surface)
	var backdrop := ColorRect.new()
	backdrop.name = "ForgeSafeUnavailableNavyBackdrop"
	backdrop.color = Color("071521")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(backdrop)
	# No continuity plate is available in this fault seam, so the only Back owner
	# sits on a deliberately contrasting native navy/brass emergency instrument.
	# This cannot resemble a cream-well dark-ink label floating on an absent plate.
	var emergency := Panel.new()
	emergency.name = "ForgeSafeUnavailableInstrument"
	emergency.add_theme_stylebox_override("panel", main._visual_style(Color("10283a"), Color("bd8a43"), 14, 2))
	emergency.set_anchors_preset(Control.PRESET_CENTER)
	emergency.position = Vector2(-220, -142)
	emergency.size = Vector2(440, 284)
	surface.add_child(emergency)
	var safe_notice := "FORGE VISUAL LAYER UNAVAILABLE\nYour print record is unchanged. You can safely return."
	if main.printer_is_core:
		safe_notice = "CORE BLUEPRINT ART UNAVAILABLE\nNo approved Core identity art is installed. Your print record is unchanged."
	# Main.label owns accessibility scaling. Pass the design size once so the
	# safe fallback remains legible rather than double-growing at 150% text.
	var notice: Label = main.label(safe_notice, 16, Color("fff0cf"))
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.set_anchors_preset(Control.PRESET_CENTER)
	notice.position = Vector2(-190, -104)
	notice.size = Vector2(380, 100)
	surface.add_child(notice)
	var back := _button(main, "ArcaneForgeBack", "BACK", main.request_back, "binding")
	back.set_anchors_preset(Control.PRESET_CENTER)
	back.position = Vector2(-80, 42)
	back.size = Vector2(160, 56)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(key, Color("fff0cf"))
	surface.add_child(back)
