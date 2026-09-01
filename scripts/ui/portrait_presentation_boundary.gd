class_name PortraitPresentationBoundary
extends RefCounted
## Owns presentation geometry. Production always consumes the host's usable surface
## with no extra bottom reserve. A positive reserve is an explicit capture fixture.

const SYNTHETIC_HOST_INSET_STRESS_LABEL := "Synthetic host-inset stress — outside gameplay"
const TALL_SAFE_TOP_FIXTURE_LABEL := "Synthetic tall Android safe-top fixture"

var _synthetic_host_inset_stress_enabled := false
var _top_safe_inset := 0.0

func game_content_reserve_height() -> float:
	# Production never reserves a synthetic host inset.
	return 0.0

func set_synthetic_host_inset_stress(enabled: bool) -> void:
	_synthetic_host_inset_stress_enabled = enabled

func set_top_safe_inset(inset: float) -> void:
	_top_safe_inset = maxf(0.0, inset)

func top_safe_inset() -> float:
	return _top_safe_inset

func synthetic_host_inset_stress_height(logical_width: float) -> float:
	if logical_width <= 0.0:
		return 0.0
	if logical_width <= 576.0:
		return 96.0
	if logical_width <= 720.0:
		return 120.0
	return 180.0 * (logical_width / 1080.0)

func effective_visual_stress_reserve(logical_width: float) -> float:
	return synthetic_host_inset_stress_height(logical_width) if _synthetic_host_inset_stress_enabled else 0.0

func content_rect(available: Rect2) -> Rect2:
	# This intentionally ignores the synthetic fixture.
	return Rect2(available.position + Vector2(0.0, _top_safe_inset), Vector2(available.size.x, maxf(0.0, available.size.y - _top_safe_inset)))

func visual_test_rect(available: Rect2) -> Rect2:
	var reserve := effective_visual_stress_reserve(available.size.x)
	return Rect2(available.position, Vector2(available.size.x, maxf(0.0, available.size.y - reserve)))

func is_synthetic_host_inset_stress_enabled() -> bool:
	return _synthetic_host_inset_stress_enabled

func synthetic_fixture_label() -> String:
	return SYNTHETIC_HOST_INSET_STRESS_LABEL

func tall_safe_top_fixture_label() -> String:
	return TALL_SAFE_TOP_FIXTURE_LABEL
