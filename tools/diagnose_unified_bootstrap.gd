extends SceneTree
func _init() -> void:
	print("DIAG 1")
	var profile: Dictionary = ProfileRules.new_profile()
	print("DIAG 2 %d" % int(profile.get("coins", 0)))
	quit()
