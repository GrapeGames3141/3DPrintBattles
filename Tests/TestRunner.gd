extends Node

## Headless entry: autoloads exist when this scene runs (unlike `--script` as the main entry point).


func _ready() -> void:
	print("== 3D Print Battles: unit tests ==")
	var suite := UnitTests.new()
	var failures: int = suite.run_all()
	if failures > 0:
		push_error("TESTS FAILED: %d" % failures)
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)
