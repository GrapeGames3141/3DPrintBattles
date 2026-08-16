class_name BattleScreenComponent
extends RefCounted
## Owns the expensive animated stage while Main rebuilds only surrounding layout.

var stage: BattleSpriteStage
var _presentation_signature := ""

func enter(_context: Dictionary = {}) -> void:
	if stage == null or not is_instance_valid(stage):
		stage = BattleSpriteStage.new()
		stage.name = "BattleStage"

func refresh(player: Dictionary, rival: Dictionary, event_kind: String, actor: int, reduced_motion: bool, minimum_height: float, high_contrast := false, presentation_token := 0) -> BattleSpriteStage:
	enter()
	# Token is monotonic per accepted intent. It deliberately distinguishes two
	# consecutive attacks/cards after the persistent stage has been reattached.
	var signature := "%s:%s:%s:%s:%s:%s:%s" % [str(player.get("id", "")), str(rival.get("id", "")), event_kind, actor, reduced_motion, high_contrast, presentation_token]
	if signature != _presentation_signature:
		_presentation_signature = signature
		stage.configure(player, rival, event_kind, actor, reduced_motion, high_contrast, presentation_token)
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
