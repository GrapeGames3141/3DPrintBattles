class_name ArcaneForgeScreenComponent
extends RefCounted
## Keeps the Forge compositor and imported textures alive across shell refreshes.

var stage: ArcaneForgeStage
var _asset_signature := ""

func enter(_context: Dictionary = {}) -> void:
	if stage == null or not is_instance_valid(stage):
		stage = ArcaneForgeStage.new()
		stage.name = "ArcaneForgeStage"

func refresh(creature_id: String, reduced_motion: bool, high_contrast: bool, phase: String, progress_bps: int, phase_bps: int, presentation_seconds: float, minimum_height: float, armor_id: String = "", core_id: String = "", continuity_station := false) -> ArcaneForgeStage:
	enter()
	var signature := "%s:%s:%s:%s:%s" % [creature_id, armor_id, core_id, reduced_motion, high_contrast]
	if signature != _asset_signature:
		_asset_signature = signature
		stage.configure(creature_id, reduced_motion, high_contrast, armor_id, core_id)
	stage.set_preview_phase(phase, progress_bps, phase_bps)
	stage.set_continuity_station(continuity_station)
	stage.set_presentation_time(presentation_seconds)
	stage.custom_minimum_size = Vector2(0, minimum_height)
	return stage

func attach(host: Node) -> void:
	if stage == null: return
	detach()
	host.add_child(stage)

func detach() -> void:
	if stage != null and is_instance_valid(stage) and stage.get_parent() != null:
		stage.get_parent().remove_child(stage)

func leave() -> void:
	detach()

func dispose() -> void:
	# Detach is deliberately non-destructive: Back/refresh must preserve the
	# accepted Forge presentation.  Owner teardown is the only lifecycle that
	# frees this detached compositor and its five stage children.
	if stage != null and is_instance_valid(stage):
		detach()
		stage.free()
	stage = null
	_asset_signature = ""
