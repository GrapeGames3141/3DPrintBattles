@tool
extends EditorPlugin

## Export-only wiring. The AAR manifest contains the locked review sample app id;
## this plugin never injects account-owned production identifiers.
const PLUGIN_AAR := "res://addons/admob_banner/bin/printforge-admob-banner.aar"
const REVIEW_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const REVIEW_BANNER_UNIT_ID := "ca-app-pub-3940256099942544/9214589741"
const PRODUCTION_APP_ID := ""
const PRODUCTION_BANNER_UNIT_ID := ""
const MOBILE_ADS_DEPENDENCY := "com.google.android.gms:play-services-ads:25.4.0"

var _android_export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_android_export_plugin = PrintForgeAdMobBannerExportPlugin.new()
	add_export_plugin(_android_export_plugin)

func _exit_tree() -> void:
	if _android_export_plugin != null:
		remove_export_plugin(_android_export_plugin)
		_android_export_plugin = null

class PrintForgeAdMobBannerExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "PrintForgeAdMobBannerExport"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([PLUGIN_AAR])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([MOBILE_ADS_DEPENDENCY])

	func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://maven.google.com"])
