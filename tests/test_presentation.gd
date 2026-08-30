extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var migrated := AccessibilityRules.ensure_fields({"settings":{"text_scale_bps":12500,"high_contrast":true}})
	require(int(migrated.settings.master_bps) == 5000 and int(migrated.settings.music_bps) == 3500 and int(migrated.settings.sfx_bps) == 5000, "audio settings migrate idempotently with quiet fixed defaults")
	var saved := AccessibilityRules.save(migrated, {"master_bps":7500,"music_bps":0,"sfx_bps":2500})
	require(bool(saved.ok) and int(saved.profile.settings.master_bps) == 7500 and int(saved.profile.settings.music_bps) == 0, "fixed audio levels validate and persist")
	var director := AudioDirector.new()
	director.configure(saved.profile.settings, true)
	var silent_gain := AudioDirector.channel_gain_bps({"master_bps":0,"music_bps":10000,"sfx_bps":10000}, "music")
	var quarter_gain := AudioDirector.channel_gain_bps({"master_bps":10000,"music_bps":2500,"sfx_bps":10000}, "music")
	var full_gain := AudioDirector.channel_gain_bps({"master_bps":10000,"music_bps":10000,"sfx_bps":10000}, "music")
	var compounded_gain := AudioDirector.channel_gain_bps({"master_bps":2500,"music_bps":5000,"sfx_bps":10000}, "music")
	require(silent_gain == 0 and quarter_gain == 2500 and full_gain == 10000 and compounded_gain == 1250 and AudioDirector.sample_gain({"master_bps":10000,"music_bps":10000}, "music") <= 0.12, "audio gain uses bounded deterministic master-by-channel levels")
	require(director.route("forge").contains("Forge cue") and director.cue("press").contains("Button press") and director.cue("impact").contains("Impact") and director.route("forge").contains("Impact") and director.route("battle").contains("Battle cue") and not director.audible("impact"), "audio director routes deterministic captions, preserves unchanged cues, and capture mutes")
	var profile: Dictionary = RULES.new_profile()
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	profile.forge_coins = 500
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	var progress_instrument := main.find_child("WorkshopProgressInstrument", true, false) as PanelContainer
	var progress_bar := main.find_child("WorkshopHudProgress", true, false) as ProgressBar
	var shared_keycap: Button = main.make_button("Style probe", func(): pass)
	var normal_keycap := shared_keycap.get_theme_stylebox("normal") as StyleBoxFlat
	var hover_keycap := shared_keycap.get_theme_stylebox("hover") as StyleBoxFlat
	var pressed_keycap := shared_keycap.get_theme_stylebox("pressed") as StyleBoxFlat
	var focus_keycap := shared_keycap.get_theme_stylebox("focus") as StyleBoxFlat
	var disabled_keycap := shared_keycap.get_theme_stylebox("disabled") as StyleBoxFlat
	require(progress_instrument != null and progress_bar != null and progress_bar.max_value > 0, "visual Workshop uses the scalable physical spool XP instrument instead of the retired header texture")
	require(shared_keycap.get_theme_stylebox("normal") != null and shared_keycap.get_theme_stylebox("focus") != null and shared_keycap.custom_minimum_size.y >= 44.0, "shared runtime controls retain accessible native keycap styling and touch size")
	GameManager.profile.settings = GameManager.profile.get("settings", {}).duplicate(true)
	GameManager.profile.settings.high_contrast = true
	var contrast_panel: StyleBoxFlat = main.panel_style(Color("294d57"), Color("c39450"))
	var contrast_keycap: StyleBoxFlat = main.button_style(Color("294d57"), "normal")
	GameManager.profile.settings.high_contrast = false
	require(contrast_panel.border_width_left >= 3 and contrast_panel.border_color.is_equal_approx(Color.WHITE) and contrast_panel.bg_color.get_luminance() < 0.05 and contrast_keycap.border_width_left >= 3 and contrast_keycap.border_color.is_equal_approx(Color.WHITE), "high contrast preserves strongly outlined black and white plates and keycaps")
	main.start_mode("trial_first_layers")
	await get_tree().process_frame
	main.render()
	await get_tree().process_frame
	var battle_heading := main.find_child("UnifiedBattleHeading", true, false) as Label
	var phase_action := main.find_child("UnifiedBattlePrimaryAction", true, false) as Button
	require(main.battle != null and main.screen == "unified_battle" and battle_heading != null and phase_action != null and not phase_action.tooltip_text.is_empty() and not phase_action.accessibility_name.is_empty(), "supported v3 battle launch renders explicit accessible phase presentation")
	main.queue_free()
	if failures.is_empty(): print("PASS: presentation audio settings, captions, battle feedback, and card detail")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
