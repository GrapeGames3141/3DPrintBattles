extends Node
## Reusable deterministic visual QA capture; output is deliberately outside the repository.
const OUTPUT_DIR := "E:/CodexCache/printforge-validation"
const MAIN_SCENE := preload("res://scenes/main.tscn")
var workshop: Control
var capture_size := ""
var capture_mode := "onboarding"
var capture_tag := ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	capture_mode = requested_mode()
	capture_tag = requested_tag()
	GameManager.profile = fixture_profile() if capture_mode != "onboarding" else ProfileRules.new_profile()
	if capture_mode == "high_contrast_battle": GameManager.profile.settings.high_contrast = true; GameManager.profile.settings.reduced_motion = true
	workshop = MAIN_SCENE.instantiate()
	workshop.shop_day_key = "2026-08-14"
	if capture_mode in ["battle", "high_contrast_battle"]:
		workshop.screen = "battle"
		workshop.battle = BattleState.create(GameManager.current_team_loadout(), ["mossmunk"], GameManager.filament_cap(), 3, 2, GameManager.active_deck_cards())
	elif capture_mode == "local_vs":
		workshop.screen = "local_vs"
		workshop.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
	elif capture_mode == "local_vs_ready":
		workshop.screen = "local_vs"
		workshop.local_authority = LocalBattleAuthority.create(GameManager.current_team_loadout(), ["mossmunk", "voltwig"], GameManager.active_deck_cards(), 20260814)
		workshop.local_ready_seat = workshop.local_authority.state.active_player
	elif capture_mode in ["trade", "trade_draft", "trade_settled"]:
		workshop.screen = "trade"
		workshop.local_trade = LocalTradeAuthority.create(GameManager.profile, workshop._guildmate_profile())
		var yours: Array = workshop.local_trade.eligible(workshop.local_trade.creator)
		var theirs: Array = workshop.local_trade.eligible(workshop.local_trade.partner)
		if not yours.is_empty() and not theirs.is_empty():
			workshop.trade_creator_choice = yours[0]; workshop.trade_partner_choice = theirs[0]
			workshop.local_trade.choose(yours[0], theirs[0])
			if capture_mode in ["trade_draft", "trade_settled"]: workshop.local_trade.confirm(0, workshop.local_trade.creator_revision, workshop.local_trade.partner_revision)
			if capture_mode == "trade_settled":
				var settled: Dictionary = workshop.local_trade.confirm(1, workshop.local_trade.creator_revision, workshop.local_trade.partner_revision)
				if bool(settled.get("settled", false)): GameManager.profile = settled.creator
	elif capture_mode != "onboarding": workshop.screen = capture_mode
	get_tree().root.call_deferred("add_child", workshop)
	call_deferred("capture")

func fixture_profile() -> Dictionary:
	var fixture: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	fixture.coins = 1000
	var blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(fixture, "mossmunk")
	var printed: Dictionary = ProgressionRules.print_creature(blueprint.profile, "mossmunk")
	var armor_blueprint: Dictionary = ProgressionRules.learn_armor_blueprint(printed.profile, "helm")
	var armor_print: Dictionary = ProgressionRules.print_armor(armor_blueprint.profile, "helm")
	fixture = ProgressionRules.equip_armor(armor_print.profile, str(armor_print.profile.onboarding.starter_instance_id), str(armor_print.payload.armor_instance_id)).profile
	fixture.team = [str(fixture.onboarding.starter_instance_id), str(printed.payload.instance_id)]
	# A spare print remains off-team so the trade capture demonstrates a legal offer.
	var spare: Dictionary = ProgressionRules.print_creature(fixture, "mossmunk")
	if bool(spare.ok): fixture = spare.profile
	fixture.support_cards.coolant = 1
	return fixture

func capture() -> void:
	await wait_for_stable_header()
	capture_size = requested_resolution()
	var suffix := "_%s" % capture_tag if not capture_tag.is_empty() else ""
	get_viewport().get_texture().get_image().save_png(OUTPUT_DIR.path_join("%s_%s%s.png" % [capture_mode, capture_size, suffix]))
	print("CAPTURED: %s (%s, %s%s)" % [OUTPUT_DIR, capture_mode, capture_size, suffix])
	get_tree().quit()

func wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame

func wait_for_stable_header() -> void:
	# Avoid capturing before a resized window has completed its first container pass.
	for _frame in 60:
		var header := workshop.find_child("WorkshopHeader", true, false) as Control
		if header and header.is_visible_in_tree() and header.get_global_rect().position.y >= 15.0 and header.get_global_rect().size.y >= 80.0:
			await wait_frames(3)
			return
		await get_tree().process_frame
	push_error("Capture header never reached a safe visible layout.")

func requested_resolution() -> String:
	var size := DisplayServer.window_get_size()
	if size.x <= 0 or size.y <= 0: size = get_viewport().get_texture().get_size()
	return "%dx%d" % [int(size.x), int(size.y)]

func requested_mode() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-mode="):
			var mode := arg.trim_prefix("--capture-mode=")
			if mode in ["workshop", "shop", "collection", "team", "armor", "deck", "settings", "battle", "high_contrast_battle", "local_vs", "local_vs_ready", "trade", "trade_draft", "trade_settled"]: return mode
	return "onboarding"

func requested_tag() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-tag="):
			return arg.trim_prefix("--capture-tag=").validate_filename()
	return ""
