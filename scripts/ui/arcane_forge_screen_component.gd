class_name ArcaneForgeScreenComponent
extends RefCounted
## Keeps the Forge compositor and imported textures alive across shell refreshes.

var stage: ArcaneForgeStage
var _asset_signature := ""

func enter(_context: Dictionary = {}) -> void:
	if stage == null or not is_instance_valid(stage):
		stage = ArcaneForgeStage.new()
		stage.name = "ArcaneForgeStage"

func refresh(creature_id: String, reduced_motion: bool, high_contrast: bool, phase: String, progress_bps: int, phase_bps: int, presentation_seconds: float, minimum_height: float) -> ArcaneForgeStage:
	enter()
	var signature := "%s:%s:%s" % [creature_id, reduced_motion, high_contrast]
	if signature != _asset_signature:
		_asset_signature = signature
		stage.configure(creature_id, reduced_motion, high_contrast)
	stage.set_preview_phase(phase, progress_bps, phase_bps)
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
