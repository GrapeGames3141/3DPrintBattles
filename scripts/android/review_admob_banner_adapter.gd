class_name ReviewAdMobBannerAdapter
extends Node
## Desktop/headless and non-review builds are deliberately inert. Native Android
## owns the banner and resizes the surface, so this adapter exposes diagnostics only.

const REVIEW_FEATURE := "android_review"
const REVIEW_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const REVIEW_BANNER_UNIT_ID := "ca-app-pub-3940256099942544/9214589741"
const PRODUCTION_APP_ID := ""
const PRODUCTION_BANNER_UNIT_ID := ""
const PLUGIN_NAME := "PrintForgeAdMobBanner"

var _plugin: Object
var _requested := false

func _ready() -> void:
	if not _is_review_configuration_valid():
		return
	_plugin = Engine.get_singleton(PLUGIN_NAME) if _is_review_android() else null
	if _plugin != null:
		call_deferred("start_review_banner")

func is_inert() -> bool:
	return not _is_review_android() or _plugin == null

func game_content_reserve_height() -> float:
	return 0.0

func diagnostic_native_banner_height() -> int:
	# The native signal is intentionally not consumed by Godot. This adapter cannot
	# turn a diagnostic into a layout reserve or another observable gameplay signal.
	return 0

func start_review_banner() -> bool:
	if is_inert() or _requested or not _is_review_configuration_valid():
		return false
	_requested = true
	_plugin.call("startReviewBanner", REVIEW_BANNER_UNIT_ID)
	return true

func hide_review_banner() -> void:
	_requested = false
	if _plugin != null:
		_plugin.call("hideReviewBanner")

func _is_review_android() -> bool:
	return OS.get_name() == "Android" and OS.has_feature(REVIEW_FEATURE) and not OS.has_feature("headless")

func _is_review_configuration_valid() -> bool:
	return bool(ProjectSettings.get_setting("admob_review/enabled", false)) \
		and str(ProjectSettings.get_setting("admob_review/review_app_id", "")) == REVIEW_APP_ID \
		and str(ProjectSettings.get_setting("admob_review/review_banner_unit_id", "")) == REVIEW_BANNER_UNIT_ID \
		and str(ProjectSettings.get_setting("admob_review/production_app_id", "")) == PRODUCTION_APP_ID \
		and str(ProjectSettings.get_setting("admob_review/production_banner_unit_id", "")) == PRODUCTION_BANNER_UNIT_ID
