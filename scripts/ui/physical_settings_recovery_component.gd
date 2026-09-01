class_name PhysicalSettingsRecoveryComponent
extends RefCounted
## Owns Settings drafts and Recovery ledger controls over the shared M3 plate.

func render_settings(main: Control, surface: Control, margin: Callable, heading: Callable) -> void:
	main._m3_ensure_settings_draft()
	# ST-01 is a physical instrument: controls are seated on its dials and plates,
	# with only the live values and accessibility copy authored by Godot.
	var host := Control.new(); host.name = "M3SettingsInstrument"; host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(host)
	var caller := "Title" if main.settings_return_screen == "title" else "Workshop"
	_settings_hud(main, host, caller)
	var draft: Dictionary = main.m3_settings_draft
	var text_plate := _settings_plate(main, "SettingsTextScalePlate", Rect2(0.222, 0.085, 0.285, 0.120)); host.add_child(text_plate)
	var text_title: Label = main.label("TEXT SCALE", 13, Color("47331f")); text_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _settings_rect(text_title, Rect2(0.04, 0.28, 0.92, 0.30)); text_plate.add_child(text_title)
	var text_dial := Control.new(); text_dial.name = "SettingsTextScaleDial"; _settings_rect(text_dial, Rect2(0.545, 0.085, 0.320, 0.120)); host.add_child(text_dial)
	var text_value: Label = main.label("%d%%" % (int(draft.get("text_scale_bps", 10000)) / 100), 16, Color("f3e5c9")); text_value.name = "SettingsTextScaleValue"; text_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _settings_rect(text_value, Rect2(0.05, 0.04, 0.90, 0.28)); text_dial.add_child(text_value)
	for index in 3:
		var scale: int = [10000, 12500, 15000][index]; var button := _settings_transparent_button("SettingsText%d" % scale, "%d" % (scale / 100), main._m3_set_setting.bind("text_scale_bps", scale), int(draft.get("text_scale_bps", 10000)) == scale); _settings_rect(button, Rect2(0.03 + index * 0.325, 0.42, 0.30, 0.52)); button.custom_minimum_size = Vector2(48, 48); text_dial.add_child(button)
	_settings_dial_row(main, host, "master_bps", "MASTER VOLUME", Rect2(0.222, 0.250, 0.646, 0.145), draft)
	_settings_toggle_row(main, host, "high_contrast", "HIGH CONTRAST", Rect2(0.222, 0.452, 0.646, 0.090), draft)
	_settings_toggle_row(main, host, "reduced_motion", "REDUCED MOTION", Rect2(0.222, 0.551, 0.646, 0.090), draft)
	var preview := _settings_plate(main, "SettingsLivePreviewPlate", Rect2(0.160, 0.670, 0.700, 0.185)); host.add_child(preview)
	# PanelContainer lays direct children out as a single fill item.  Keep one
	# deliberate content layer inside it so the three preview bands retain their
	# authored positions rather than being stacked on top of one another.
	var preview_content := Control.new(); preview_content.name = "SettingsLivePreviewContent"; preview_content.clip_contents = true; preview_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); preview.add_child(preview_content)
	var sample: Label = main.label("LIVE PREVIEW · Forged for clear reading", 16, Color("47331f")); sample.name = "SettingsLivePreviewText"; sample.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sample.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; sample.autowrap_mode = TextServer.AUTOWRAP_OFF; sample.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _settings_rect(sample, Rect2(0.05, 0.064, 0.90, 0.296)); preview_content.add_child(sample)
	_settings_preview_audio(main, preview_content, "music_bps", "MUSIC", Rect2(0.08, 0.370, 0.84, 0.290), draft)
	_settings_preview_audio(main, preview_content, "sfx_bps", "SFX", Rect2(0.08, 0.670, 0.84, 0.290), draft)
	# Buttons centre their label within these exposed hardware hit zones by default;
	# the slightly tighter vertical seating keeps the baseline on the authored plate.
	var cancel := _settings_transparent_button("SettingsCancel", "CANCEL", main._m3_cancel_settings); _settings_rect(cancel, Rect2(0.165, 0.902, 0.215, 0.078)); cancel.custom_minimum_size = Vector2(56, 56); cancel.tooltip_text = "Cancel settings and return to %s" % caller; cancel.accessibility_name = cancel.tooltip_text; host.add_child(cancel)
	var apply := _settings_transparent_button("SettingsApply", "APPLY", main._m3_apply_settings, true); _settings_rect(apply, Rect2(0.474, 0.900, 0.386, 0.080)); apply.custom_minimum_size = Vector2(56, 56); apply.tooltip_text = "Apply settings"; apply.accessibility_name = apply.tooltip_text; host.add_child(apply)

func _settings_hud(main: Control, host: Control, caller: String) -> void:
	var rail := Control.new(); rail.name = "SettingsCompactHud"; rail.anchor_left = 0.120; rail.anchor_top = 0.012; rail.anchor_right = 0.880; rail.anchor_bottom = 0.070; host.add_child(rail)
	var back := _settings_button("UnifiedFoundryWorkshopReturn", "Back", main._m3_cancel_settings); _settings_rect(back, Rect2(0.0, 0.08, 0.145, 0.84)); back.custom_minimum_size = Vector2(54, 48); back.tooltip_text = "Cancel settings and return to %s" % caller; back.accessibility_name = back.tooltip_text; rail.add_child(back)
	for entry in [["SettingsHudLevel", "Level %d" % int(GameManager.profile.get("level", 1)), Rect2(0.19, 0.08, 0.205, 0.84)], ["SettingsHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.43, 0.08, 0.205, 0.84)], ["SettingsHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.68, 0.08, 0.30, 0.84)]]:
		var label: Label = main.label(str(entry[1]), 12, Color("f3e5c9")); label.name = str(entry[0]); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size = Vector2(112, 48) if str(entry[0]) == "SettingsHudCoins" else Vector2(64, 48); _settings_rect(label, entry[2]); rail.add_child(label)

func _settings_dial_row(main: Control, host: Control, key: String, title: String, rect: Rect2, draft: Dictionary) -> void:
	var row := Control.new(); row.name = "SettingsMasterVolumeRow" if key == "master_bps" else "SettingsDial" + key.capitalize(); _settings_rect(row, rect); host.add_child(row)
	var title_label: Label = main.label(title, 12, Color("47331f")); title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _settings_rect(title_label, Rect2(0.02, 0.31, 0.44, 0.38)); row.add_child(title_label)
	var value: Label = main.label("%d%%" % (int(draft.get(key, 5000)) / 100), 18, Color("f3e5c9")); value.name = "SettingsValue" + key; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _settings_rect(value, Rect2(0.57, 0.16, 0.30, 0.30)); row.add_child(value)
	var lower := _settings_transparent_button("SettingsLower" + key, "−", main._m3_adjust_setting.bind(key, -1)); _settings_rect(lower, Rect2(0.04, 0.54, 0.22, 0.40)); lower.custom_minimum_size = Vector2(48, 48); lower.add_theme_font_size_override("font_size", 20); lower.add_theme_color_override("font_color", Color("47331f")); lower.tooltip_text = "Lower %s" % title.to_lower(); lower.accessibility_name = lower.tooltip_text; row.add_child(lower)
	var raise := _settings_transparent_button("SettingsRaise" + key, "+", main._m3_adjust_setting.bind(key, 1), true); _settings_rect(raise, Rect2(0.72, 0.54, 0.22, 0.40)); raise.custom_minimum_size = Vector2(48, 48); raise.add_theme_font_size_override("font_size", 20); raise.add_theme_color_override("font_color", Color("f3d995") if key == "master_bps" else Color("47331f")); raise.tooltip_text = "Raise %s" % title.to_lower(); raise.accessibility_name = raise.tooltip_text; row.add_child(raise)

func _settings_toggle_row(main: Control, host: Control, key: String, title: String, rect: Rect2, draft: Dictionary) -> void:
	var suffix := "HighContrast" if key == "high_contrast" else "ReducedMotion"
	var row := Control.new(); row.name = "SettingsToggle" + suffix; _settings_rect(row, rect); host.add_child(row)
	var title_label: Label = main.label(title, 12, Color("47331f")); title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _settings_rect(title_label, Rect2(0.03, 0.18, 0.48, 0.64)); row.add_child(title_label)
	var toggle := _settings_transparent_button("Settings" + suffix, "ON" if bool(draft.get(key, false)) else "OFF", main._m3_set_setting.bind(key, not bool(draft.get(key, false))), bool(draft.get(key, false)))
	_settings_rect(toggle, Rect2(0.59, 0.15, 0.34, 0.70)); toggle.custom_minimum_size = Vector2(56, 48)
	if not bool(draft.get(key, false)): toggle.add_theme_color_override("font_color", Color("47331f"))
	toggle.tooltip_text = "%s %s" % [title.capitalize(), "on" if bool(draft.get(key, false)) else "off"]; toggle.accessibility_name = toggle.tooltip_text; row.add_child(toggle)

func _settings_preview_audio(main: Control, preview: Control, key: String, title: String, rect: Rect2, draft: Dictionary) -> void:
	var row := Control.new(); row.name = "SettingsPreviewMusic" if key == "music_bps" else "SettingsPreviewSfx"; _settings_rect(row, rect); preview.add_child(row)
	var value: Label = main.label("%s  %d%%" % [title, int(draft.get(key, 5000)) / 100], 11, Color("47331f")); value.name = "SettingsPreview" + title.capitalize() + "Value"; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _settings_rect(value, Rect2(0.22, 0.08, 0.56, 0.84)); row.add_child(value)
	var lower := _settings_transparent_button("SettingsLower" + key, "−", main._m3_adjust_setting.bind(key, -1)); _settings_rect(lower, Rect2(0.02, 0.07, 0.18, 0.86)); lower.custom_minimum_size = Vector2(48, 48); lower.add_theme_font_size_override("font_size", 20); lower.add_theme_color_override("font_color", Color("47331f")); lower.tooltip_text = "Lower %s volume" % title.to_lower(); lower.accessibility_name = lower.tooltip_text; row.add_child(lower)
	var raise := _settings_transparent_button("SettingsRaise" + key, "+", main._m3_adjust_setting.bind(key, 1), true); _settings_rect(raise, Rect2(0.80, 0.07, 0.18, 0.86)); raise.custom_minimum_size = Vector2(48, 48); raise.add_theme_font_size_override("font_size", 20); raise.add_theme_color_override("font_color", Color("47331f")); raise.tooltip_text = "Raise %s volume" % title.to_lower(); raise.accessibility_name = raise.tooltip_text; row.add_child(raise)

func _settings_plate(main: Control, node_name: String, rect: Rect2) -> PanelContainer:
	var plate := PanelContainer.new(); plate.name = node_name; _settings_rect(plate, rect); plate.add_theme_stylebox_override("panel", _settings_style(Color("ead9b7"), Color("79582f"), 2)); return plate

func _settings_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 12); button.add_theme_color_override("font_color", Color("f4e6c8")); button.add_theme_color_override("font_disabled_color", Color("b9ad95")); button.add_theme_stylebox_override("normal", _settings_style(Color("1e2b35"), Color("9f7540"), 2)); button.add_theme_stylebox_override("hover", _settings_style(Color("30414a"), Color("d5ad67"), 2)); button.add_theme_stylebox_override("pressed", _settings_style(Color("493d2d"), Color("f0ca7a"), 2)); button.add_theme_stylebox_override("focus", _settings_style(Color("1e2b35"), Color("75d8dd"), 3)); if active: button.add_theme_stylebox_override("normal", _settings_style(Color("5a482f"), Color("e0b45f"), 3))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _settings_transparent_button(node_name: String, value: String, action: Callable, active := false) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_font_size_override("font_size", 12); button.add_theme_color_override("font_color", Color("f3d995") if active else Color("f4e6c8")); button.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); button.add_theme_stylebox_override("hover", StyleBoxEmpty.new()); button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); button.add_theme_stylebox_override("focus", _settings_style(Color(0, 0, 0, 0), Color("75d8dd"), 3)); button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	if action.is_valid(): button.pressed.connect(action)
	return button

func _settings_style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 7; style.corner_radius_top_right = 7; style.corner_radius_bottom_left = 7; style.corner_radius_bottom_right = 7; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 2; style.content_margin_bottom = 2; return style

func _settings_rect(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x; node.anchor_top = rect.position.y; node.anchor_right = rect.end.x; node.anchor_bottom = rect.end.y

func render_recovery(main: Control, surface: Control, margin: Callable, heading: Callable) -> void:
	# SY-02 deliberately uses calm player-facing language.  Internal recovery
	# identifiers remain diagnostic implementation data and never become copy.
	var host := Control.new(); host.name = "M3RecoveryLedger"; host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(host)
	var state := str(GameManager.save_compatibility.get("state", SaveService.recovery_status))
	_recovery_hud(main, host)
	var top := Control.new(); top.name = "RecoveryTopPlate"; top.clip_contents = true; _settings_rect(top, Rect2(0.068, 0.156, 0.864, 0.206)); host.add_child(top)
	var title: Label = main.label(_recovery_title(state), 18, Color("49311f")); title.name = "RecoveryPlayerTitle"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_OFF; title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _settings_rect(title, Rect2(0.05, 0.08, 0.90, 0.20)); top.add_child(title)
	var copy: Label = main.label(_recovery_copy(state), 12, Color("513c25")); copy.name = "RecoveryPlayerExplanation"; copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _settings_rect(copy, Rect2(0.10, 0.33, 0.80, 0.54)); top.add_child(copy)
	_recovery_ledger_rows(main, host, state)
	_recovery_preservation_receipt(main, host, state)
	_recovery_actions(main, host, state)

func _recovery_hud(main: Control, host: Control) -> void:
	var rail := Control.new(); rail.name = "RecoveryCompactHud"; rail.anchor_left = 0.105; rail.anchor_top = 0.018; rail.anchor_right = 0.895; rail.anchor_bottom = 0.082; host.add_child(rail)
	# Recovery has one deliberate safe exit in the bottom plate.  This top rail is
	# informational only, so it cannot offer a duplicate Back action.
	for entry in [["RecoveryHudLevel", "Level %d" % int(GameManager.profile.get("level", 1)), Rect2(0.02, 0.08, 0.25, 0.84)], ["RecoveryHudXp", "XP %d" % int(GameManager.profile.get("spool_xp", 0)), Rect2(0.37, 0.08, 0.25, 0.84)], ["RecoveryHudCoins", "Coin %d" % int(GameManager.profile.get("forge_coins", 0)), Rect2(0.70, 0.08, 0.28, 0.84)]]:
		var label: Label = main.label(str(entry[1]), 12, Color("f3e5c9")); label.name = str(entry[0]); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.custom_minimum_size = Vector2(112, 48) if str(entry[0]) == "RecoveryHudCoins" else Vector2(64, 48); _settings_rect(label, entry[2]); rail.add_child(label)

func _recovery_ledger_rows(main: Control, host: Control, state: String) -> void:
	var compatibility: Dictionary = GameManager.save_compatibility if GameManager.save_compatibility is Dictionary else {}
	var saved_schema := str(compatibility.get("schema_version", GameManager.profile.get("schema_version", "—")))
	var supported_schema := str(compatibility.get("supported_schema", "—"))
	# The narrow stamped rows keep only compact schema/protection facts.  The full
	# preservation consequence is deliberately placed on the receipt below.
	var facts := [["Saved schema", saved_schema], ["Current schema", supported_schema], ["Protection", "Read-only"]]
	var row_rects := [Rect2(0.168, 0.537, 0.542, 0.058), Rect2(0.168, 0.604, 0.542, 0.060), Rect2(0.168, 0.670, 0.542, 0.055)]
	for index in 3:
		var row := Control.new(); row.name = "RecoveryLedgerRow%d" % (index + 1); _settings_rect(row, row_rects[index]); host.add_child(row)
		var key: Label = main.label(str((facts[index] as Array)[0]), 11, Color("47331f")); key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; key.autowrap_mode = TextServer.AUTOWRAP_OFF; _settings_rect(key, Rect2(0.05, 0.10, 0.48, 0.78)); row.add_child(key)
		var value: Label = main.label(str((facts[index] as Array)[1]), 11, Color("47331f")); value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; value.autowrap_mode = TextServer.AUTOWRAP_OFF; value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; _settings_rect(value, Rect2(0.55, 0.10, 0.40, 0.78)); row.add_child(value)
	var upper := _recovery_side_indicator(main, "RecoveryStateIndicator", _recovery_indicator(state)); _settings_rect(upper, Rect2(0.745, 0.507, 0.155, 0.088)); host.add_child(upper)
	var lower := _recovery_side_indicator(main, "RecoveryProtectionIndicator", "CURRENT %s\nREAD-ONLY" % supported_schema); _settings_rect(lower, Rect2(0.745, 0.612, 0.155, 0.088)); host.add_child(lower)

func _recovery_preservation_receipt(main: Control, host: Control, state: String) -> void:
	var receipt := Control.new(); receipt.name = "RecoveryPreservationReceipt"; receipt.clip_contents = true; _settings_rect(receipt, Rect2(0.252, 0.410, 0.243, 0.098)); host.add_child(receipt)
	var text := "Saved record preserved · No changes made"
	if state == "backup_recovered": text = "Validated backup preserved · Awaiting acknowledgement"
	elif state == "storage_unavailable": text = "No changes made · Storage remains read-only"
	var label: Label = main.label(text, 11, Color("47331f")); label.name = "RecoveryPreservationCopy"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _settings_rect(label, Rect2(0.04, 0.08, 0.92, 0.84)); receipt.add_child(label)

func _recovery_actions(main: Control, host: Control, state: String) -> void:
	var back := _settings_transparent_button("RecoveryBack", "BACK TO TITLE", func(): main.screen = "title"; main.render()); _settings_rect(back, Rect2(0.163, 0.762, 0.305, 0.096)); back.custom_minimum_size = Vector2(56, 56)
	# The physical button rests on parchment: every interactive text state stays
	# dark while the separate focus StyleBox keeps its complete cyan ring.
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		back.add_theme_color_override(color_name, Color("47331f"))
	back.tooltip_text = "Return safely to Title"; back.accessibility_name = back.tooltip_text; host.add_child(back)
	if state == "backup_recovered":
		var acknowledge := _settings_transparent_button("RecoveryAcknowledgeBackup", "ACKNOWLEDGE", main._m3_acknowledge_backup_recovery, true); _settings_rect(acknowledge, Rect2(0.500, 0.830, 0.245, 0.125)); acknowledge.custom_minimum_size = Vector2(56, 56); acknowledge.tooltip_text = "Acknowledge recovered backup and safely resume"; acknowledge.accessibility_name = acknowledge.tooltip_text; host.add_child(acknowledge)
	elif state in ["corrupt_primary", "corrupt_backup"]:
		var text := "CONFIRM NEW MAKER" if main.m3_recovery_new_maker_confirm else "PRESERVE + NEW MAKER"
		var action: Callable = main._m3_confirm_new_maker_recovery if main.m3_recovery_new_maker_confirm else main._m3_request_new_maker_recovery
		var new_maker := _settings_transparent_button("RecoveryNewMaker", text, action, true); _settings_rect(new_maker, Rect2(0.500, 0.830, 0.245, 0.125)); new_maker.custom_minimum_size = Vector2(56, 56); new_maker.tooltip_text = "Preserve recoverable files before starting New Maker"; new_maker.accessibility_name = new_maker.tooltip_text; host.add_child(new_maker)

func _recovery_side_indicator(main: Control, node_name: String, value: String) -> Label:
	var indicator: Label = main.label(value, 10, Color("47331f")); indicator.name = node_name; indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; indicator.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; return indicator

func _recovery_title(state: String) -> String:
	match state:
		"backup_recovered": return "RECOVERED WORKSHOP"
		"future_schema": return "NEWER WORKSHOP RECORD"
		"corrupt_primary", "corrupt_backup": return "WORKSHOP RECORD NEEDS CARE"
		_: return "SAVE STORAGE NEEDS CARE"

func _recovery_copy(state: String) -> String:
	match state:
		"backup_recovered": return "A validated backup is ready. Acknowledge it before PrintForge writes a new primary record."
		"future_schema": return "This workshop was made by a newer PrintForge version. Update the game before changing it."
		"corrupt_primary", "corrupt_backup": return "The saved record cannot be read. It remains preserved until you separately confirm a New Maker."
		_: return "Storage is temporarily unavailable. Return to Title and try again when the device is ready."

func _recovery_indicator(state: String) -> String:
	match state:
		"backup_recovered": return "BACKUP READY"
		"future_schema": return "UPDATE NEEDED"
		"corrupt_primary", "corrupt_backup": return "RECORD HELD"
		_: return "WAITING"
