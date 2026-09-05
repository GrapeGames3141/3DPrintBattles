class_name WorkshopScreenComponent
extends RefCounted
## Persistent non-authoritative station presentation. It never owns profile data.

var live_layer: WorkshopStationLiveLayer
var _config_signature := ""

func enter(_context: Dictionary = {}) -> void:
	if live_layer == null or not is_instance_valid(live_layer):
		live_layer = WorkshopStationLiveLayer.new()
		live_layer.name = "WorkshopStationLiveLayer"

func refresh(profile: Dictionary, station: String, portrait: bool, reduced_motion: bool, high_contrast: bool, seed: int, frozen: bool, capture_progress: int) -> WorkshopStationLiveLayer:
	enter()
	var team_signature: Array[String] = []
	for entry in ProfileRules.team_loadout(profile):
		team_signature.append(str(entry.get("creature_id", "")))
	var signature := "%s:%s:%s:%s:%s:%s:%s:%s" % [int(profile.get("revision", 0)), station, portrait, reduced_motion, high_contrast, seed, frozen, ",".join(team_signature)]
	if signature != _config_signature:
		_config_signature = signature
		live_layer.configure(profile, station, portrait, reduced_motion, high_contrast, seed, frozen)
	else:
		live_layer.resume()
	if capture_progress >= 0:
		live_layer.set_capture_progress(capture_progress)
	return live_layer

func attach(host: Node) -> void:
	if live_layer == null: return
	detach()
	host.add_child(live_layer)
	live_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	live_layer.resume()

func detach() -> void:
	if live_layer != null and is_instance_valid(live_layer):
		live_layer.suspend()
		if live_layer.get_parent() != null: live_layer.get_parent().remove_child(live_layer)

func leave() -> void:
	detach()

func dispose() -> void:
	# `detach()` is deliberately persistent across responsive Workshop rebuilds.
	# Main's final teardown owns the matching destructive release.
	if live_layer != null and is_instance_valid(live_layer):
		detach()
		live_layer.free()
	live_layer = null
	_config_signature = ""
