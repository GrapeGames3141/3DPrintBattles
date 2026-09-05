extends Node

const CATALOG := preload("res://scripts/core/v3_catalog.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _file_snapshot() -> Dictionary:
	var snapshot := {}
	for path in [SaveService.profile_path, SaveService.profile_temp_path, SaveService.profile_backup_path, SaveService.profile_backup_temp_path, SaveService.journal_path, SaveService.pack_ui_session_path, SaveService.pack_ui_session_temp_path, SaveService.pack_ui_session_backup_path]:
		snapshot[path] = {"exists":FileAccess.file_exists(path), "bytes":FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()}
	return snapshot

func _requested_viewport() -> Vector2i:
	var width := 576
	var height := 1024
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-width="):
			width = maxi(1, int(argument.trim_prefix("--qa-width=")))
		elif argument.begins_with("--qa-height="):
			height = maxi(1, int(argument.trim_prefix("--qa-height=")))
	require(height > width, "Catalog package guard capture requires a portrait viewport, got %dx%d." % [width, height])
	return Vector2i(width, height)

func _capture_package_error() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var size := Vector2i(get_window().size)
	var path := SaveService.profile_path.get_base_dir().path_join("catalog-package-unavailable-%dx%d.png" % [size.x, size.y])
	require(image != null and image.get_size() == size and image.save_png(path) == OK, "Catalog package error writes its rendered native recovery capture at %s." % size)
	print("CATALOG_PACKAGE_GUARD_CAPTURE path=%s renderer=%s display=%s dimensions=%s" % [path, RenderingServer.get_current_rendering_method(), DisplayServer.get_name(), size])

func _ready() -> void:
	# Autoload storage is already redirected by --qa-save-root. Seed a known valid
	# record, then prove the injected package fault itself cannot normalize or write it.
	var allowed_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var configured_parent := SaveService.profile_path.get_base_dir().replace("\\", "/")
	require(configured_parent.begins_with(allowed_root + "/"), "Package guard only writes its fixture below the pre-autoload evidence root.")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	var requested_viewport := _requested_viewport()
	if not failures.is_empty():
		get_tree().quit(1)
		return
	get_window().content_scale_size = requested_viewport
	get_window().size = requested_viewport
	await get_tree().process_frame
	var selected: Dictionary = RULES.choose_starter(GameManager.default_profile(), "cinderpaw").profile
	var printed: Dictionary = RULES.print_starter(selected).profile
	var preserved: Dictionary = RULES.claim_next_starter_pack(printed, PackedByteArray(), "workshop").profile
	var receipt := str(preserved.get("pending_pack_reveal", {}).get("receipt", ""))
	require(str(preserved.get("onboarding", {}).get("founder_version", "")) == RULES.FOUNDER_VERSION and str(preserved.get("onboarding", {}).get("state", "")) == "complete" and int(preserved.get("starter_pack_rewards", {}).get("opened", 0)) == 1 and not receipt.is_empty(), "Guard fixture is a canonical partial Founder profile from rule transitions.")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	require(SaveService.commit_snapshot(preserved), "Guard fixture seeds a valid isolated profile.")
	require(SaveService.append_event("catalog_guard_fixture", {"receipt":receipt}, int(preserved.get("revision", 0))), "Guard fixture creates an isolated journal entry.")
	require(SaveService.save_pack_ui_session(receipt, {"page":1, "inspector_id":"mossmunk"}), "Guard fixture creates an isolated receipt sidecar.")
	var before_files := _file_snapshot()
	var before_events := SaveService.session_events.duplicate(true)
	var original_document := CATALOG.document()
	var broken_document := original_document.duplicate(true)
	for raw in broken_document.get("cards", []):
		if raw is Dictionary and str(raw.get("id", "")) == "filament_ring":
			raw["art"] = {"path":"res://assets/cards/v3/package-fault-fixture.png"}
	CATALOG._document_cache = broken_document
	CATALOG._cards_cache = []
	CATALOG._index_cache = {}
	GameManager._initialize_loaded_profile(preserved)
	require(GameManager.is_save_read_only(), "Invalid package mapping enters a read-only catalog state.")
	require(str(GameManager.save_compatibility.get("state", "")) == "catalog_unavailable", "Invalid package mapping identifies catalog_unavailable.")
	require(GameManager.profile == preserved, "Catalog failure preserves the loaded profile in memory without normalization.")
	require(_file_snapshot() == before_files and SaveService.session_events == before_events, "Catalog failure writes no profile, backup, journal, or receipt sidecar.")
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var exit := main.find_child("RecoveryExitCatalogUnavailable", true, false) as Button
	var recovery_host := main.find_child("M3RecoveryLedger", true, false) as Control
	require(exit != null and exit.tooltip_text == "Exit PrintForge without changing your saved workshop", "Catalog recovery offers the one native safe Exit action.")
	require(recovery_host != null and exit != null and exit.get_global_rect().position.is_equal_approx(recovery_host.global_position + recovery_host.size * Vector2(0.235, 0.767)) and exit.get_global_rect().size.is_equal_approx(recovery_host.size * Vector2(0.225, 0.069)) and exit.get_global_rect().size.x >= 56.0 and exit.get_global_rect().size.y >= 56.0 and recovery_host.get_global_rect().encloses(exit.get_global_rect()), "Catalog Exit is seated inside the lower-left cream action plate with a native 56px target.")
	require(main.find_child("RecoveryNewMaker", true, false) == null, "Catalog recovery never offers New Maker.")
	require(_file_snapshot() == before_files and SaveService.session_events == before_events, "Read-only recovery rendering performs no persistence writes.")
	await _capture_package_error()
	if not failures.is_empty():
		get_tree().quit(1)
		return
	print("CATALOG_PACKAGE_GUARD ready_to_exit=true input=touch state=catalog_unavailable writes_unchanged=true")
	# Exercise the actual native recovery control through parsed touch input. Its
	# callback reaches the same catalog-only Back exit used by Android/Escape.
	var point := exit.get_global_rect().get_center()
	var down := InputEventScreenTouch.new(); down.position = point; down.window_id = get_window().get_window_id(); down.index = 0; down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := InputEventScreenTouch.new(); up.position = point; up.window_id = get_window().get_window_id(); up.index = 0; up.pressed = false
	Input.parse_input_event(up)
