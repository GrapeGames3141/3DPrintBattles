extends Node
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var sequence := ArcaneForgeSequence.create(false)
	require(sequence.phase == ArcaneForgeSequence.IDLE and not sequence.request_commit(), "idle cannot commit")
	require(sequence.begin() and sequence.advance(2100) and sequence.progress_bps == 2100 and sequence.layer_reveal_bps() == 3000, "print phase has monotonic integer layer mapping")
	require(sequence.advance(4900) and sequence.phase == ArcaneForgeSequence.RAW_COMPLETE and sequence.progress_bps == 7000, "raw completion has fixed threshold")
	require(ArcaneForgeSequence.presentation_interval_seconds(false) * ceil(float(ArcaneForgeSequence.PRINT_COMPLETE_BPS) / ArcaneForgeSequence.presentation_step_bps(false, ArcaneForgeSequence.PRINTING)) >= 10.0, "normal visible layer printing lasts at least ten seconds")
	require(sequence.request_commit() and not sequence.request_commit() and sequence.resolve_commit(true) and sequence.phase == ArcaneForgeSequence.RAW_HOLD, "commit request is a one-time latch before the raw hold")
	require(sequence.advance(ArcaneForgeSequence.RAW_HOLD_BPS) and sequence.phase == ArcaneForgeSequence.AWAKENING and sequence.advance(ArcaneForgeSequence.AWAKEN_BPS) and sequence.phase == ArcaneForgeSequence.DEPARTING and sequence.advance(ArcaneForgeSequence.DEPART_BPS) and sequence.phase == ArcaneForgeSequence.AWAKENED and not sequence.skip(), "committed raw hold, awakening, departure, and final state complete once")
	var reduced := ArcaneForgeSequence.create(true); reduced.begin(); reduced.skip()
	require(reduced.reduced_motion and reduced.phase == ArcaneForgeSequence.RAW_COMPLETE and reduced.request_commit() and reduced.resolve_commit(true) and reduced.skip() and reduced.phase == ArcaneForgeSequence.AWAKENED and ArcaneForgeSequence.presentation_interval_seconds(true) > ArcaneForgeSequence.presentation_interval_seconds(false), "reduced motion remains calm staged, safe, and skippable")
	var frame_stage := ArcaneForgeStage.new()
	frame_stage.configure("cinderpaw", false, false)
	frame_stage.set_presentation_time(0.0)
	var first_frame := frame_stage.printer_frame_index()
	frame_stage.set_preview_phase(ArcaneForgeSequence.PRINTING, 1200)
	frame_stage.set_presentation_time(1.0)
	require(first_frame == 0 and frame_stage.printer_frame_index() in [1, 2, 3] and frame_stage.is_processing() and ArcaneForgeStage.PRINTER_FRAME_PATHS.size() == 4, "printing maps four printer frames through a deterministic ping-pong")
	frame_stage.set_preview_phase(ArcaneForgeSequence.AWAKENED, 10000)
	require(not frame_stage.is_processing(), "idle or awakened Forge preview disables processing")
	frame_stage.set_preview_phase(ArcaneForgeSequence.AWAKENING, 8000, 5000)
	require(not frame_stage.is_processing(), "awakening is driven by deterministic phase progress rather than per-frame stage processing")
	frame_stage.set_preview_phase(ArcaneForgeSequence.DEPARTING, 9000, 5000)
	require(not frame_stage.is_processing(), "departure is driven by deterministic phase progress rather than per-frame stage processing")
	for path in ArcaneForgeStage.PRINTER_FRAME_PATHS:
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		require(source != null and not source.is_empty() and source.get_pixel(0, 0).a == 0.0 and source.get_pixel(source.get_width() - 1, source.get_height() - 1).a == 0.0, "%s has transparent keyed corners" % path)
	const WORKSHOP_BOOT_SPLASH_PATH := "res://assets/ui/workshop/workshop_overview_landscape_v4.png"
	for path in ["res://assets/ui/printforge_launcher_icon.png", WORKSHOP_BOOT_SPLASH_PATH]:
		require(ResourceLoader.exists(path) and ResourceLoader.load(path) != null, "%s runtime icon/splash path loads" % path)
	var workshop_boot_splash := Image.load_from_file(ProjectSettings.globalize_path(WORKSHOP_BOOT_SPLASH_PATH))
	require(workshop_boot_splash != null and not workshop_boot_splash.is_empty() and workshop_boot_splash.get_width() == 1672 and workshop_boot_splash.get_height() == 941, "boot splash uses the canonical 1672x941 Workshop overview plate")
	require(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 1, "portrait orientation is locked and configured")
	require(str(ProjectSettings.get_setting("application/boot_splash/image", "")) == WORKSHOP_BOOT_SPLASH_PATH, "boot splash setting uses the canonical Workshop overview plate")
	var fallback := Catalog.creature("future_unmapped_creature")
	require(fallback.is_empty() and BattleSpriteStage.sprite_path_for("future_unmapped_creature").ends_with("mossmunk_sprite_sheet.png"), "unknown future IDs retain the safe mascot visual fallback")
	for definition in Catalog.CREATURES:
		var creature_id: String = str(definition.id)
		var living_path: String = str(definition.get("sprite_sheet", ""))
		var raw_path: String = str(definition.get("raw_print", ""))
		var living_texture := ResourceLoader.load(living_path) as Texture2D
		var raw_texture := ResourceLoader.load(raw_path) as Texture2D
		# Headless Windows may not expose source PNG bytes, so validate the imported/export seam here.
		require(ResourceLoader.exists(living_path) and living_texture != null and living_texture.get_width() == 1536 and living_texture.get_height() == 1024, "%s living 4x2 sheet exists and loads at 1536x1024" % creature_id)
		require(ResourceLoader.exists(raw_path) and raw_texture != null and raw_texture.get_width() > 0 and raw_texture.get_height() > 0, "%s raw print exists and loads" % creature_id)
	for armor in Catalog.SUITS + Catalog.CORE_BLUEPRINTS:
		var armor_id: String = str(armor.get("id", ""))
		var armor_path: String = str(armor.get("raw_print", ""))
		var armor_image := Image.load_from_file(ProjectSettings.globalize_path(armor_path))
		var armor_texture := ResourceLoader.load(armor_path) as Texture2D
		var imported := armor_texture.get_image() if armor_texture != null else null
		require(ResourceLoader.exists(armor_path) and armor_image != null and not armor_image.is_empty() and armor_image.get_width() == 512 and armor_image.get_height() == 512 and _armor_import_alpha_contract(armor_image, imported), "%s source transparency survives import without a rectangular matte" % armor_id)
	var armor_sequence := ArcaneForgeSequence.create(false, true)
	armor_sequence.begin(); armor_sequence.advance(ArcaneForgeSequence.PRINT_COMPLETE_BPS); armor_sequence.request_commit(); armor_sequence.resolve_commit(true); armor_sequence.advance(ArcaneForgeSequence.RAW_HOLD_BPS)
	require(armor_sequence.phase == ArcaneForgeSequence.AWAKENED, "armor print exits its full completed-part hold directly to transfer completion without creature awakening or departure")
	if failures.is_empty(): print("PASS: checkpoint6 Arcane Forge sequence and asset mappings")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)

func _armor_import_alpha_contract(source: Image, imported: Image) -> bool:
	if imported == null or imported.is_empty() or source.get_size() != imported.get_size(): return false
	var samples: int = 0
	var transparent_samples: int = 0
	var opaque_samples: int = 0
	for y in range(8, source.get_height(), 16):
		for x in range(8, source.get_width(), 16):
			samples += 1
			var source_alpha: float = source.get_pixel(x, y).a
			var imported_alpha: float = imported.get_pixel(x, y).a
			if source_alpha <= 0.03:
				transparent_samples += 1
				if imported_alpha > 0.03: return false
			elif source_alpha >= 0.50:
				opaque_samples += 1
	# Each centered armor silhouette must retain meaningful transparent surround
	# and opaque material, but must not approximate a filled 512px rectangle.
	return samples > 0 and transparent_samples * 100 >= samples * 30 and opaque_samples * 100 >= samples * 2 and opaque_samples * 100 <= samples * 75
