# Main.gd
# Entry point for PrintForge Legends.
# Attached to scenes/Main.tscn (Node2D root named "Main")
# This is the first scene that runs (set in project.godot run/main_scene).
# It simply routes to the correct starting screen based on save state.

extends Node2D

func _ready() -> void:
	# Small delay so SceneTransition overlay can initialize
	await get_tree().process_frame
	if SaveManager.has_chosen_starter():
		SceneTransition.go_to("res://scenes/Workshop.tscn")
	else:
		SceneTransition.go_to("res://scenes/StarterSelection.tscn")
