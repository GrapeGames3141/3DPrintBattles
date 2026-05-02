extends Control

## COPPA-safe offline trade stub (no chat, no accounts).

signal back

func _ready() -> void:
	name = "TradeScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var hdr := Label.new()
	hdr.text = "Offline Trade"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 26)
	root.add_child(hdr)

	var body := Label.new()
	body.text = "NPC paper trades (no chat, parent-friendly) will appear here in a future update. Collect blueprints in the shop for now."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 520
	root.add_child(body)

	var btn := Button.new()
	btn.text = "Back"
	btn.custom_minimum_size.x = 200
	btn.pressed.connect(func(): back.emit())
	root.add_child(btn)
