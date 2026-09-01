extends Node

const ADAPTER := preload("res://scripts/android/review_admob_banner_adapter.gd")

const REVIEW_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const REVIEW_UNIT_ID := "ca-app-pub-3940256099942544/9214589741"
const ICONS := [
	["branding-app-icon-v1.png", 2399131, "91C67524D124506EE74333957F9D6CD1A37654315032C1417248A085B681034F"],
	["branding-adaptive-icon-background-v1.png", 2484293, "397ED26029D9BF6D1F1657546CDC5081A3111278402CD6B3A78A9607880A9935"],
	["branding-adaptive-icon-foreground-v2.png", 1231795, "22D433B4EFDD4DE827A591B5C70B9C82C8A3B36BDA3F9D3E87600C3CE68CAE3B"]
]

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func sha256(path: String) -> String:
	return FileAccess.get_sha256(path).to_upper()

func _ready() -> void:
	var adapter = ADAPTER.new()
	require(adapter.game_content_reserve_height() == 0.0, "M4 adapter must reserve zero Godot content height.")
	require(adapter.is_inert(), "Headless test adapter must be inert.")
	require(not adapter.start_review_banner(), "Headless adapter must not request an ad.")
	require(adapter.diagnostic_native_banner_height() == 0, "Inert adapter must report zero diagnostics.")

	var project := read_text("res://project.godot")
	var export_config := read_text("res://export_presets.cfg")
	var adapter_source := read_text("res://scripts/android/review_admob_banner_adapter.gd")
	var java_source := read_text("res://android-plugins/admob-banner/admob-banner/src/main/java/com/tak/printforge/legends/admob/PrintForgeAdMobBannerPlugin.java")
	var manifest := read_text("res://android-plugins/admob-banner/admob-banner/src/main/AndroidManifest.xml")
	# The singleton key deliberately differs from class_name ReviewAdMobBannerAdapter;
	# matching names hides the class in Godot's script registry.  It remains inert
	# until an Android review build finds the native plugin.
	require(project.contains('ReviewAdMobBanner="*res://scripts/android/review_admob_banner_adapter.gd"') and not project.contains('ReviewAdMobBannerAdapter="*res://scripts/android/review_admob_banner_adapter.gd"'), "Review banner adapter must use the distinct inert ReviewAdMobBanner autoload key.")
	require(project.contains('review_app_id="%s"' % REVIEW_APP_ID) and project.contains('review_banner_unit_id="%s"' % REVIEW_UNIT_ID), "Only locked review identifiers are configured.")
	require(project.contains('production_app_id=""') and project.contains('production_banner_unit_id=""'), "Production identifiers must be empty.")
	require(export_config.contains('version/name="0.8.4-physical-ui-review"') and export_config.contains("version/code=100"), "Android review version/code must be locked.")
	require(export_config.contains('package/unique_name="com.tak.printforge.legends.playtest"') and export_config.contains("gradle_build/use_gradle_build=true"), "Android review package and Gradle export must be configured.")
	require(export_config.contains("architectures/arm64-v8a=true") and not export_config.contains("architectures/x86=true"), "Review APK must be arm64 only.")
	require(export_config.contains("branding-adaptive-icon-foreground-v2.png") and export_config.contains("branding-adaptive-icon-background-v1.png"), "Adaptive icon layers must use approved sources.")
	require(adapter_source.contains("call_deferred(\"start_review_banner\")") and adapter_source.contains("_is_review_configuration_valid"), "Autoload must deferred-start only with the locked review configuration.")
	require(not adapter_source.contains("native_banner_height_changed"), "Godot adapter must not consume or re-emit native diagnostics.")
	require(not read_text("res://scripts/ui/main.gd").contains("ReviewAdMobBannerAdapter"), "Gameplay UI must not consume banner diagnostics.")
	require(java_source.contains("AtomicLong generation") and java_source.contains("token != generation.get()") and java_source.contains("pendingBanner") and java_source.contains("removeBannerAndRestore(true)"), "Native host must use atomic generation, pending cleanup, and supersede restore ordering.")
	require(java_source.contains("bottomMargin = originalSurfaceMargins.bottom + creativeHeight + systemBottomInset"), "Only loaded native host may add creative plus system inset.")
	require(java_source.contains("No native attachment or surface mutation occurs before this async callback") and java_source.contains("if (creativeHeight <= 0)"), "Loading must preserve the Godot surface and reject zero creative measurements.")
	require(java_source.count("native_banner_height_changed") == 3, "Native host must declare/emit only one diagnostics signal.")
	require(java_source.contains("surfaceLayout.bottomMargin = originalSurfaceMargins.bottom;") and java_source.contains("pendingBanner.destroy();") and java_source.contains("bannerView.destroy();"), "Failure, hide, supersede, and teardown must destroy pending/visible views and restore exact original Godot margins.")
	require(not java_source.contains("Rewarded") and not java_source.contains("Interstitial") and not java_source.contains("AppOpen") and not java_source.contains("NativeAd"), "Forbidden AdMob formats must not exist.")
	require(manifest.contains(REVIEW_APP_ID) and not manifest.contains("production"), "AAR manifest must contain only the review sample app id.")
	for item in ICONS:
		var source := "res://docs/art/printforge-physical-ui-spike-20260830/%s" % item[0]
		var runtime := "res://assets/ui/branding/android/%s" % item[0]
		require(FileAccess.file_exists(source) and FileAccess.file_exists(runtime), "Approved icon source/runtime pair must exist: %s" % item[0])
		require(FileAccess.get_file_as_bytes(source).size() == item[1] and FileAccess.get_file_as_bytes(runtime).size() == item[1], "Icon bytes must remain identity-preserving: %s" % item[0])
		require(sha256(source) == item[2] and sha256(runtime) == item[2], "Icon source/runtime hash mismatch: %s" % item[0])
	require(export_config.contains("docs/*") and export_config.contains("tests/*") and export_config.contains("build/*") and export_config.contains("android-plugins/*") and export_config.contains(".agents/*"), "Android export must exclude source, tests, generated output, Android build sources, and agent metadata.")
	var plugin_ignore := read_text("res://android-plugins/admob-banner/.gitignore")
	require(plugin_ignore.contains(".gradle/") and plugin_ignore.contains("build/") and plugin_ignore.contains("godot-lib.template_debug.aar") and not plugin_ignore.contains("gradlew"), "Android plugin ignores only transient Gradle/template outputs while retaining source and wrapper inputs.")
	var build_script := read_text("res://android-plugins/admob-banner/build_plugin.ps1")
	require(build_script.contains("ANDROID_USER_HOME") and build_script.contains("JAVA_TOOL_OPTIONS") and build_script.contains("user.home"), "M4 plugin builds keep Android preference/cache writes in ignored E:-workspace paths.")
	adapter.free()
	if failures.is_empty():
		print("PASS: M4 Android review boundary")
	get_tree().quit(0 if failures.is_empty() else 1)
