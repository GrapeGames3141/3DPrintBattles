extends Node

const BOUNDARY := preload("res://scripts/ui/portrait_presentation_boundary.gd")

const ICONS := [
	["branding-app-icon-v1.png", "91C67524D124506EE74333957F9D6CD1A37654315032C1417248A085B681034F"],
	["branding-adaptive-icon-background-v1.png", "397ED26029D9BF6D1F1657546CDC5081A3111278402CD6B3A78A9607880A9935"],
	["branding-adaptive-icon-foreground-v2.png", "22D433B4EFDD4DE827A591B5C70B9C82C8A3B36BDA3F9D3E87600C3CE68CAE3B"]
]

# This forbidden-token ledger is test-only; it never ships because tests are exported out.
const FORBIDDEN_RUNTIME_TOKENS := [
	"admob", "mobileads", "com.google.android.gms.ads", "ca-app-pub-",
	"adview", "adrequest", "ad_id", "access_adservices", "rewarded",
	"interstitial", "app_open"
]
const RUNTIME_INPUTS := [
	"res://project.godot",
	"res://export_presets.cfg",
	"res://scripts/ui/main.gd",
	"res://scripts/ui/portrait_presentation_boundary.gd",
	"res://scripts/ui/unified_battle_screen_component.gd"
]
const REMOVED_PATHS := [
	"res://addons/admob_banner",
	"res://android-plugins/admob-banner",
	"res://scripts/android/review_admob_banner_adapter.gd",
	"res://scripts/android/review_admob_banner_adapter.gd.uid",
	"res://tests/test_m4_android_review.gd",
	"res://tests/test_m4_android_review.gd.uid",
	"res://tests/test_m4_android_review.tscn"
]

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func _ready() -> void:
	var project := _text("res://project.godot")
	var export_config := _text("res://export_presets.cfg")
	require(not project.contains("[admob_review]") and not project.contains("ReviewAdMobBanner") and not project.contains("[editor_plugins]"), "Project configuration has no advertising review singleton or plugin section.")
	require(export_config.contains('version/name="0.8.8-deck-export-fix"') and export_config.contains("version/code=104"), "Android no-ad version and code are locked.")
	require(export_config.contains('package/unique_name="com.tak.printforge.legends.playtest"') and export_config.contains('package/name="PrintForge Legends Physical UI No-Ad Review"'), "Android no-ad package identity is locked.")
	require(export_config.contains('custom_features="unified_playtest"') and not export_config.contains("android_review"), "Android export has no review-only custom feature.")
	require(export_config.contains("gradle_build/use_gradle_build=false"), "Android export uses the standard Godot template.")
	require(export_config.contains("package/signed=false"), "Android no-ad review preset makes no project signing request; APK signing is verified separately.")
	require(export_config.contains("architectures/arm64-v8a=true") and export_config.contains("architectures/armeabi-v7a=false") and export_config.contains("architectures/x86=false") and export_config.contains("architectures/x86_64=false"), "Android export remains arm64-only.")
	require(project.contains("window/handheld/orientation=1"), "Android gameplay remains portrait-only.")
	require(export_config.contains("launcher_icons/main_192x192") and export_config.contains("branding-adaptive-icon-background-v1.png") and export_config.contains("branding-adaptive-icon-foreground-v2.png"), "Approved launcher branding remains selected.")
	require(export_config.contains("addons/*") and export_config.contains("android-plugins/*") and export_config.contains("tests/*") and export_config.contains("docs/*") and export_config.contains("build/*"), "Android export excludes plugins, tests, source docs, and build output.")
	require(export_config.contains("m8_print_idle_576x1024_M8-R5-m8-print-idle-576x1024.png") and export_config.contains("onboarding_576x1024.png"), "Android export excludes the two retained root capture PNGs exactly.")

	for path in REMOVED_PATHS:
		require(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)), "Removed M4 path is absent: %s" % path)
	for path in RUNTIME_INPUTS:
		var source := _text(path).to_lower()
		for token in FORBIDDEN_RUNTIME_TOKENS:
			require(not source.contains(token), "Forbidden runtime/export token '%s' is absent from %s." % [token, path])

	for item in ICONS:
		var filename := str(item[0])
		var source_path := "res://docs/art/printforge-physical-ui-spike-20260830/%s" % filename
		var runtime_path := "res://assets/ui/branding/android/%s" % filename
		require(FileAccess.file_exists(source_path) and FileAccess.file_exists(runtime_path), "Approved icon source/runtime pair exists: %s" % filename)
		require(FileAccess.get_file_as_bytes(source_path) == FileAccess.get_file_as_bytes(runtime_path), "Approved icon runtime bytes are identical: %s" % filename)
		require(FileAccess.get_sha256(source_path).to_upper() == str(item[1]) and FileAccess.get_sha256(runtime_path).to_upper() == str(item[1]), "Approved icon hash remains locked: %s" % filename)

	var boundary := BOUNDARY.new()
	require(is_zero_approx(boundary.game_content_reserve_height()), "Production bottom reserve is exactly zero.")
	require(not boundary.is_synthetic_host_inset_stress_enabled(), "Capture-only host-inset stress is disabled by default.")
	require(not _text("res://scripts/ui/main.gd").contains("SyntheticAdMob") and not _text("res://scripts/ui/unified_battle_screen_component.gd").contains("SyntheticAdMob"), "Runtime nodes use generic host-inset fixture names only.")
	if failures.is_empty():
		print("PASS: M5 Android no-ad boundary")
	get_tree().quit(0 if failures.is_empty() else 1)
