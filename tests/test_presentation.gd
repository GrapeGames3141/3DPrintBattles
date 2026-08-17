extends Node

const MAIN := preload("res://scenes/main.tscn")
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
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 500
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	var header := main.find_child("WorkshopHeader", true, false) as PanelContainer
	var header_style := header.get_theme_stylebox("panel") as StyleBoxTexture if header != null else null
	var shared_keycap: Button = main.make_button("Style probe", func(): pass)
	var normal_keycap := shared_keycap.get_theme_stylebox("normal") as StyleBoxTexture
	var hover_keycap := shared_keycap.get_theme_stylebox("hover") as StyleBoxTexture
	var pressed_keycap := shared_keycap.get_theme_stylebox("pressed") as StyleBoxTexture
	var focus_keycap := shared_keycap.get_theme_stylebox("focus") as StyleBoxTexture
	var disabled_keycap := shared_keycap.get_theme_stylebox("disabled") as StyleBoxTexture
	require(header_style != null and header_style.texture_margin_left > 0 and header_style.expand_margin_left >= 0, "shared runtime header uses a scalable Arcane Foundry panel texture")
	require(normal_keycap != null and hover_keycap != null and pressed_keycap != null and focus_keycap != null and disabled_keycap != null and normal_keycap.texture != hover_keycap.texture and normal_keycap.texture != pressed_keycap.texture and normal_keycap.texture != disabled_keycap.texture, "shared runtime controls use distinct textured keycap normal, hover, pressed, focus, and disabled styles")
	GameManager.profile.settings.high_contrast = true
	var contrast_panel: StyleBoxFlat = main.panel_style(Color("294d57"), Color("c39450"))
	var contrast_keycap: StyleBoxFlat = main.button_style(Color("294d57"), "normal")
	GameManager.profile.settings.high_contrast = false
	require(contrast_panel.border_width_left >= 3 and contrast_panel.border_color.is_equal_approx(Color.WHITE) and contrast_panel.bg_color.get_luminance() < 0.05 and contrast_keycap.border_width_left >= 3 and contrast_keycap.border_color.is_equal_approx(Color.WHITE), "high contrast preserves strongly outlined black and white plates and keycaps")
	main.start_battle()
	await get_tree().process_frame
	# The battle opening may belong to either seat; force a player-view state for the presentation seam.
	main.battle.active_player = 0
	main.battle_last_event = "defend"
	main.battle_secondary_open = true
	main.battle_secondary_tab = "hand"
	main.render()
	await get_tree().process_frame
	var banner := main.find_child("BattleImpactBanner", true, false) as Label
	var hand := main.find_child("BattleHandGrid", true, false) as GridContainer
	var first_card := hand.get_child(0) as Button if hand != null and hand.get_child_count() > 0 else null
	require(banner != null and banner.text.contains("Outcome:") and banner.text.contains("Cue:") and first_card != null and first_card.text.is_empty() and first_card.tooltip_text.contains("Filament") and first_card.accessibility_name.contains("Target:"), "battle impact banner, caption, and accessible support-card cost/effect/target detail are explicit")
	main.queue_free()
	if failures.is_empty(): print("PASS: presentation audio settings, captions, battle feedback, and card detail")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
