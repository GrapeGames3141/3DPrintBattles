class_name PortraitPresentationBoundary
extends RefCounted
## Owns only presentation geometry. Native Android owns a bottom AdMob view and
## its navigation/gesture inset outside the Godot surface, so production Godot
## reserve is deliberately zero. A positive reserve is a labeled desktop/capture
## fixture only; it never represents the native production contract.

const SYNTHETIC_OVERLAY_STRESS_LABEL := "Synthetic overlay stress — not native AdMob geometry"
const TALL_SAFE_TOP_FIXTURE_LABEL := "Synthetic tall Android safe-top fixture"

var _native_banner_height := 0.0
var _synthetic_overlay_stress_enabled := false
var _top_safe_inset := 0.0

func native_banner_height() -> float:
	return _native_banner_height

func set_native_banner_height_for_diagnostics(height: float) -> void:
	_native_banner_height = maxf(0.0, height)

func game_content_reserve_height() -> float:
	# Native-bottom-outside-Godot contract: Godot receives the resized usable
	# surface, therefore it must not reserve creative, disclosure, or safe inset.
	return 0.0

func set_synthetic_overlay_stress(enabled: bool) -> void:
	_synthetic_overlay_stress_enabled = enabled

func set_top_safe_inset(inset: float) -> void:
	_top_safe_inset = maxf(0.0, inset)

func top_safe_inset() -> float:
	return _top_safe_inset

func synthetic_overlay_stress_height(logical_width: float) -> float:
	if logical_width <= 0.0:
		return 0.0
	if logical_width <= 576.0:
		return 96.0
	if logical_width <= 720.0:
		return 120.0
	return 180.0 * (logical_width / 1080.0)

func effective_visual_stress_reserve(logical_width: float) -> float:
	return synthetic_overlay_stress_height(logical_width) if _synthetic_overlay_stress_enabled else 0.0

func content_rect(available: Rect2) -> Rect2:
	# This intentionally ignores the synthetic fixture. Production layout is
	# driven by the Godot surface supplied by Android, not an assumed banner size.
	return Rect2(available.position + Vector2(0.0, _top_safe_inset), Vector2(available.size.x, maxf(0.0, available.size.y - _top_safe_inset)))

func visual_test_rect(available: Rect2) -> Rect2:
	var reserve := effective_visual_stress_reserve(available.size.x)
	return Rect2(available.position, Vector2(available.size.x, maxf(0.0, available.size.y - reserve)))

func is_synthetic_overlay_stress_enabled() -> bool:
	return _synthetic_overlay_stress_enabled

func synthetic_fixture_label() -> String:
	return SYNTHETIC_OVERLAY_STRESS_LABEL

func tall_safe_top_fixture_label() -> String:
	return TALL_SAFE_TOP_FIXTURE_LABEL
