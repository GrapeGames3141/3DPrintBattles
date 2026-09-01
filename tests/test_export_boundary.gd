extends Node

const FALLBACK_WORKSHOP_TEXTURE_PATH := "res://assets/ui/workshop/workshop-theme-reference-fallback.jpg"
const STARTUP_RESOURCES := [
	"res://scenes/main.tscn",
	"res://scripts/ui/main.gd",
	"res://scripts/ui/creature_art_gallery.gd",
	FALLBACK_WORKSHOP_TEXTURE_PATH
]

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _runtime_scripts(directory_path: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		require(false, "runtime script directory is available: " + directory_path)
		return paths
	for file_name in directory.get_files():
		if file_name.ends_with(".gd"):
			paths.append(directory_path.path_join(file_name))
	for folder_name in directory.get_directories():
		paths.append_array(_runtime_scripts(directory_path.path_join(folder_name)))
	return paths

func _ready() -> void:
	# Android excludes docs/*, so every executable runtime script must point only
	# at exportable resources. This catches eager preload failures before export.
	var docs_dependencies: Array[String] = []
	for script_path in _runtime_scripts("res://scripts"):
		if FileAccess.get_file_as_string(script_path).contains("res://docs/"):
			docs_dependencies.append(script_path)
	require(docs_dependencies.is_empty(), "runtime scripts must not depend on excluded docs resources: " + ", ".join(docs_dependencies))
	for path in STARTUP_RESOURCES:
		require(ResourceLoader.exists(path), "startup resource exists: " + path)
		require(ResourceLoader.load(path) != null, "startup resource loads: " + path)
	var fallback_texture := ResourceLoader.load(FALLBACK_WORKSHOP_TEXTURE_PATH) as Texture2D
	require(fallback_texture != null and fallback_texture.get_width() > 0 and fallback_texture.get_height() > 0, "runtime workshop fallback texture is a loadable image")
	var runtime_manifest := "res://assets/creatures/2d/blueprints/v2/manifest-v2.json"
	require(FileAccess.file_exists(runtime_manifest), "M7 runtime blueprint manifest is exportable")
	var legacy_dir := "res://assets/creatures/2d/blueprints/"
	var legacy_directory := DirAccess.open(legacy_dir)
	require(legacy_directory != null, "blueprint runtime root is available for legacy-package exclusion scan")
	if legacy_directory != null:
		for file_name in legacy_directory.get_files():
			var retired := file_name.ends_with("_blueprint_card_v1.png") or file_name.ends_with("_blueprint_card_v1.png.import") or file_name == "unknown_blueprint_card_v1.png" or file_name == "unknown_blueprint_card_v1.png.import" or file_name == "provenance-v1.json"
			require(not retired, "retired top-level v1 blueprint package input is absent: " + legacy_dir + file_name)
	if failures.is_empty(): print("PASS: Android export boundary has no docs runtime dependencies and startup resources load")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
