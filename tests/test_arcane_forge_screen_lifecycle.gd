extends Node

## Detached Forge presentation is intentionally persistent across ordinary route
## changes.  The Main owner must nevertheless release it on final teardown.

const COMPONENT := preload("res://scripts/ui/arcane_forge_screen_component.gd")
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const BATTLE_STATE := preload("res://scripts/battle/unified_battle_state.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	await _component_detach_contract()
	await _main_owner_teardown_contract()
	await _main_battle_workshop_teardown_contract()
	if failures.is_empty():
		print("PASS: Arcane Forge detached-stage lifecycle")
	get_tree().quit(0 if failures.is_empty() else 1)

func _component_detach_contract() -> void:
	var host := Control.new()
	host.name = "ForgeLifecycleHost"
	add_child(host)
	var component = COMPONENT.new()
	var first = component.refresh("cinderpaw", false, false, ArcaneForgeSequence.PRINTING, 4200, 4200, 1.0, 480.0)
	component.attach(host)
	await get_tree().process_frame
	require(first.get_parent() == host, "Forge attach gives the compositor one live host parent.")
	component.detach()
	require(is_instance_valid(first) and first.get_parent() == null, "Forge Back-style detach preserves the compositor for resume.")
	var resumed = component.refresh("cinderpaw", false, false, ArcaneForgeSequence.PRINTING, 4200, 4200, 1.0, 480.0)
	require(resumed == first and resumed.progress_bps == 4200 and resumed.phase == ArcaneForgeSequence.PRINTING, "Forge refresh after detach keeps the same accepted stage and sequence facts.")
	component.attach(host)
	component.detach()
	component.attach(host)
	require(first.get_parent() == host, "Repeated attach/detach never duplicates the persistent Forge stage.")
	component.dispose()
	await get_tree().process_frame
	require(not is_instance_valid(first), "Forge final dispose frees the detached compositor.")
	component.dispose()
	var rebuilt = component.refresh("cinderpaw", true, false, ArcaneForgeSequence.IDLE, 0, 0, 0.0, 480.0)
	require(is_instance_valid(rebuilt) and rebuilt != first, "Repeated dispose is safe and a later entry builds a fresh compositor.")
	component.dispose()
	host.queue_free()

func _main_owner_teardown_contract() -> void:
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.screen = "onboarding"
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var component = main.get("_forge_screen_component")
	var stage = component.get("stage") if component != null else null
	require(is_instance_valid(stage), "Main owns a live Forge compositor while the First Print route is open.")
	main.get_parent().remove_child(main)
	main.free()
	await get_tree().process_frame
	require(not is_instance_valid(stage), "Main teardown disposes its detached Forge compositor exactly once.")

func _main_battle_workshop_teardown_contract() -> void:
	GameManager.profile = RULES.print_starter(RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile).profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.battle = BATTLE_STATE.create(["cinderpaw"], ["aquafin"], 61)
	main.battle_mode = "training"
	main.battle_settlement_context = {"mode":"training"}
	main.unified_battle_coordinator.configure(main.battle, 0)
	main.screen = "unified_battle"
	main.render()
	await get_tree().process_frame
	var battle_component = main.get("_unified_battle_screen_component")
	var battle_stage = battle_component.get("_stage") if battle_component != null else null
	require(is_instance_valid(battle_stage), "Battle route owns a physical stage before its ordinary detach.")
	main.screen = "workshop"
	main.render()
	await get_tree().process_frame
	require(is_instance_valid(battle_stage) and battle_stage.get_parent() == null, "Leaving Battle detaches rather than destroys its resumable stage.")
	var workshop_component = main.get("_workshop_screen_component")
	# The M9 portrait Workshop uses a static plate, but Main still owns this
	# reusable station layer for legacy/live close-ups. Exercise its normal
	# refresh/attach/detach path under the same final owner teardown.
	var workshop_host := Control.new()
	workshop_host.name = "LifecycleWorkshopLiveHost"
	main.add_child(workshop_host)
	if workshop_component != null:
		workshop_component.refresh(GameManager.profile, "printer", true, false, false, 17, true, 5000)
		workshop_component.attach(workshop_host)
		workshop_component.detach()
	var workshop_layer = workshop_component.get("live_layer") if workshop_component != null else null
	require(is_instance_valid(workshop_layer), "Workshop route owns a live presentation layer before final teardown.")
	main.get_parent().remove_child(main)
	main.free()
	await get_tree().process_frame
	require(not is_instance_valid(battle_stage) and not is_instance_valid(workshop_layer), "Main teardown frees detached Battle and Workshop presentation nodes.")
