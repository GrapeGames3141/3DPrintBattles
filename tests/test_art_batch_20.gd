extends Node
## Deliberately fails until the primary art batch has been placed at every manifest path.

var failures: Array[String] = []

func _ready() -> void:
	var additions: Array = Catalog.CREATURES.slice(4)
	if additions.size() != 20:
		failures.append("Art batch must target exactly the twenty non-launch-sheet catalog creatures.")
	else:
		for definition in additions:
			if str(definition.get("sprite_sheet", "")).is_empty() or str(definition.get("raw_print", "")).is_empty():
				failures.append("%s is missing a catalog asset mapping." % str(definition.get("id", "unknown")))
	failures.append_array(CreatureAssetValidator.validate_catalog())
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: all 24 catalog creature living sheets and raw prints meet the source contract")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
