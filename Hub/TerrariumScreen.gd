extends Control

## Stage 2: display owned blueprints as a “collection” (text-only MVP).

signal back

func _ready() -> void:
	name = "TerrariumScreen"
	anchor_right = 1
	anchor_bottom = 1

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var btn := Button.new()
	btn.text = "Back"
	btn.pressed.connect(func(): back.emit())
	top.add_child(btn)
	var hdr := Label.new()
	hdr.text = "Terrarium — your collection"
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	if GameState.owned_blueprints.is_empty():
		var empty := Label.new()
		empty.text = "No blueprints owned yet. Visit the Shop Terminal."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty)
	else:
		for oid in GameState.owned_blueprints:
			var defn: Dictionary = UnitDatabase.get_unit(oid)
			var line := Label.new()
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if defn.is_empty():
				line.text = "· %s (unknown id)" % oid
			else:
				line.text = "· %s — %s · Tier %d" % [
					str(defn.get("name", oid)),
					str(defn.get("element", "?")),
					int(defn.get("tier_level", 1))
				]
			list.add_child(line)
