class_name PhysicalNavigationComponent
extends RefCounted
## Shared contract for physical Back hardware.  Presentation owners choose their
## own plate/position; native text stays readable above this shared binding.

const CONTROL_FAMILY := preload("res://scripts/ui/physical_control_family.gd")

static func configure_back(button: Button, destination: String, minimum := Vector2(56, 56), transparent_hit := false) -> Button:
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	# Several route helpers create transparent semantic controls first.  A real
	# Back must restore its shared physical base instead of inheriting `flat` and
	# rendering as bare text over the master artwork.
	button.flat = transparent_hit
	button.tooltip_text = "Back to %s" % destination
	button.accessibility_name = button.tooltip_text
	CONTROL_FAMILY.apply(button, "binding", false, transparent_hit)
	return button
