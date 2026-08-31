extends SceneTree

const BOUNDARY := preload("res://scripts/ui/portrait_presentation_boundary.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _init() -> void:
	var boundary = BOUNDARY.new()
	require(is_zero_approx(boundary.game_content_reserve_height()), "Native-bottom production reserve must remain zero.")
	boundary.set_native_banner_height_for_diagnostics(120.0)
	require(is_equal_approx(boundary.native_banner_height(), 120.0), "Native height is diagnostic only.")
	require(is_equal_approx(boundary.synthetic_overlay_stress_height(576.0), 96.0), "576 synthetic fixture is 96 logical pixels.")
	require(is_equal_approx(boundary.synthetic_overlay_stress_height(720.0), 120.0), "720 synthetic fixture is 120 logical pixels.")
	require(is_equal_approx(boundary.synthetic_overlay_stress_height(1080.0), 180.0), "1080 synthetic fixture is 180 logical pixels.")
	require(is_zero_approx(boundary.effective_visual_stress_reserve(720.0)), "Synthetic fixture is disabled by default.")
	boundary.set_synthetic_overlay_stress(true)
	require(is_equal_approx(boundary.effective_visual_stress_reserve(720.0), 120.0), "Synthetic fixture is explicit and positive only when enabled.")
	require(is_equal_approx(boundary.visual_test_rect(Rect2(0, 0, 576, 1024)).size.y, 928.0), "576 visual test content ends above the 96px band.")
	require(is_equal_approx(boundary.visual_test_rect(Rect2(0, 0, 720, 1280)).size.y, 1160.0), "720 visual test content ends above the 120px band.")
	require(is_equal_approx(boundary.visual_test_rect(Rect2(0, 0, 1080, 2400)).size.y, 2220.0), "1080 visual test content ends above the 180px band.")
	for bottom in [506.0, 442.0, 442.0, 692.0, 692.0, 900.0]:
		require(bottom <= 900.0, "Each Workshop station ends at or above the 928 logical content boundary minus 28.")
	boundary.set_synthetic_overlay_stress(false)
	require("Synthetic overlay stress" in boundary.synthetic_fixture_label(), "Synthetic fixture remains visibly labeled.")
	boundary.set_top_safe_inset(84.0)
	require(is_equal_approx(boundary.top_safe_inset(), 84.0) and is_equal_approx(boundary.content_rect(Rect2(0, 0, 576, 1024)).position.y, 84.0) and is_equal_approx(boundary.content_rect(Rect2(0, 0, 576, 1024)).size.y, 940.0), "Tall safe-top fixture produces an explicit usable presentation region without a production bottom reserve.")
	require("safe-top" in boundary.tall_safe_top_fixture_label(), "Tall safe-top fixture remains visibly labeled.")
	if failures.is_empty():
		print("PASS: portrait presentation boundary")
	quit(0 if failures.is_empty() else 1)
