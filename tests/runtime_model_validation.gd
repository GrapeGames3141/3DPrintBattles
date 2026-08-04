extends SceneTree

const MODEL_EXPECTATIONS := {
	"res://assets/models/moonlit_elf_duelist_animated.glb": [
		"Dead", "Double_Blade_Spin", "Flirty_Strut", "Idle_6", "Running",
		"Stand_Dodge", "Thrust_Slash", "Walking", "Walking_Woman",
	],
	"res://assets/models/verdant_alchemist_animated.glb": [
		"Casual_Walk", "Dead", "mage_soell_cast_4", "Running", "Thrust_Slash", "Walking",
	],
}


func _initialize() -> void:
	var exercised := 0
	for path in MODEL_EXPECTATIONS:
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Unable to load runtime model: %s" % path)
			quit(1)
			return
		var instance := packed.instantiate()
		root.add_child(instance)
		var players := instance.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			push_error("No AnimationPlayer found in %s" % path)
			quit(1)
			return
		var player := players[0] as AnimationPlayer
		for animation_name in MODEL_EXPECTATIONS[path]:
			if not player.has_animation(animation_name):
				push_error("Missing %s in %s; found %s" % [animation_name, path, player.get_animation_list()])
				quit(1)
				return
			player.play(animation_name)
			player.advance(0.05)
			exercised += 1
		player.stop()
		instance.queue_free()
	print("RUNTIME_MODEL_VALIDATION_OK models=%d animations=%d" % [MODEL_EXPECTATIONS.size(), exercised])
	quit(0)
