class_name TeamPrototypeSystemPresenter
extends RefCounted
## Settings and recovery rendering only. The shell retains routing and persistence.

const SETTINGS := "res://assets/ui/physical_ui/m3/ST-01-settings-instrument-text-free-v3.png"
const RECOVERY := "res://assets/ui/physical_ui/m3/SY-02-recovery-ledger-text-free-v2.png"


func render_settings(shell: Variant) -> void:
	shell._background(SETTINGS)
	var enlarged := int(shell.settings_draft.get("text_scale_bps", 10000)) == 15000
	shell._back_at(Rect2(155, 1481, 202, 127), "Workshop")
	shell._label("TEXT SIZE", Rect2(209, 142, 268, 201), 27)
	var text_scale: Button = shell._button("%d%%" % (int(shell.settings_draft.get("text_scale_bps", 10000)) / 100), Rect2(513, 142, 301, 201), func(): shell.settings_draft["text_scale_bps"] = 15000 if int(shell.settings_draft.get("text_scale_bps", 10000)) == 10000 else 10000; shell._render(), false, "square")
	text_scale.name = "SettingsTextScale"
	text_scale.accessibility_name = "Text Size: %s. Activate to switch text size." % text_scale.text
	shell._label("CONTRAST", Rect2(209, 755, 282, 151), 27)
	var high_contrast: Button = shell._button("ON" if bool(shell.settings_draft.get("high_contrast", false)) else "OFF", Rect2(523, 755, 286, 151), func(): shell.settings_draft["high_contrast"] = not bool(shell.settings_draft.get("high_contrast", false)); shell._render(), false, "binding")
	high_contrast.name = "SettingsHighContrast"
	high_contrast.accessibility_name = "High Contrast: %s" % high_contrast.text
	_apply_switch_ink(high_contrast, bool(shell.settings_draft.get("high_contrast", false)))
	shell._label("REDUCED\nMOTION", Rect2(209, 921, 282, 151), 27)
	var reduced_motion: Button = shell._button("ON" if bool(shell.settings_draft.get("reduced_motion", false)) else "OFF", Rect2(523, 921, 286, 151), func(): shell.settings_draft["reduced_motion"] = not bool(shell.settings_draft.get("reduced_motion", false)); shell._render(), false, "binding")
	reduced_motion.name = "SettingsReducedMotion"
	reduced_motion.accessibility_name = "Reduced Motion: %s" % reduced_motion.text
	_apply_switch_ink(reduced_motion, bool(shell.settings_draft.get("high_contrast", false)))
	var save_label := "RETRY SAVE" if not shell.route_error.is_empty() else "APPLY"
	var preview := "Preview\nNative text stays readable."
	if not shell.route_error.is_empty():
		preview = "%s\nRetry keeps this Settings draft." % shell.route_error
	shell._label(preview, Rect2(151, 1120, 659, 309), 27)
	var apply: Button = shell._button("", Rect2(446, 1504, 363, 134), shell._apply_settings, false, "binding", true)
	apply.name = "SettingsApply"
	apply.accessibility_name = save_label
	apply.tooltip_text = save_label
	var apply_caption: Label = shell._label(save_label, Rect2(629, 1481, 196, 94), 27)
	apply_caption.name = "SettingsApplyCaption"
	apply_caption.add_theme_color_override("font_color", Color("fff0c8"))
	apply_caption.add_theme_color_override("font_outline_color", Color("1a0d04"))
	apply_caption.add_theme_constant_override("outline_size", 3 if enlarged else 2)


func render_recovery(shell: Variant) -> void:
	shell._background(RECOVERY)
	shell._back_at(Rect2(29.40, 32.68, 133.96, 78.50), "Workshop")
	if shell.leave_confirmation:
		render_leave_confirmation_content(shell)
		return
	var details := str(shell.recovery_reason())
	var summary := "Profile data is damaged." if details == "profile_corrupt" else "Your save opened read-only. Nothing was changed."
	var detail_copy := "Profile data is damaged. You can leave safely." if details == "profile_corrupt" and shell.recovery_details else ("This save cannot be used right now. You can leave safely." if shell.recovery_details else summary)
	shell._label("RECOVERY REQUIRED", Rect2(95, 290, 752, 80), 34)
	var recovery_copy: Label = shell._label(detail_copy, Rect2(95, 370, 752, 150), 24)
	recovery_copy.name = "RecoverySummary"
	recovery_copy.accessibility_name = "%s Diagnostic code: %s" % [detail_copy, details]
	var recovery_details: Button = shell._button("CLOSE" if shell.recovery_details else "VIEW DETAILS", Rect2(157, 1280, 288, 149), func(): shell.recovery_details = not shell.recovery_details; shell._render(), false)
	recovery_details.name = "RecoveryDetails"
	recovery_details.accessibility_name = "Close recovery details" if shell.recovery_details else "View recovery details. Diagnostic code: %s" % details


func render_root_leave_confirmation(shell: Variant) -> void:
	# An inert recovery-ledger sheet replaces Workshop entirely, preventing its
	# five hotspots and Back owner from remaining reachable behind the root modal.
	shell._background(RECOVERY)
	render_leave_confirmation_content(shell)


func render_leave_confirmation_content(shell: Variant) -> void:
	shell._label("LEAVE PRINTFORGE?\nYour last confirmed progress is saved.", Rect2(155, 390, 650, 130), 27)
	var stay: Button = shell._button("STAY", Rect2(193, 900, 555, 84), func(): shell.leave_confirmation = false; shell._render(), false, "wide")
	stay.name = "LeaveStay"
	var leave: Button = shell._button("LEAVE", Rect2(193, 1004, 555, 84), func(): shell.get_tree().quit(), false, "wide")
	leave.name = "LeaveConfirm"


func _apply_switch_ink(button: Button, high_contrast: bool) -> void:
	var ink := Color("ffffff") if high_contrast else Color("24160b")
	var outline := Color("06121c") if high_contrast else Color("f4e6c4")
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	button.add_theme_color_override("font_disabled_color", ink)
	button.add_theme_color_override("font_outline_color", outline)
	button.add_theme_constant_override("outline_size", 3 if high_contrast else 2)
