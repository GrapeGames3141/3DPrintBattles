extends Control

## Full roster browser; unowned rows render darker (“silhouette” MVP).

signal back

func _ready() -> void:
	name = "ArchiveScreen"
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
	hdr.text = "Archive — full roster (%d)" % UnitDatabase.units_array.size()
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for defn in UnitDatabase.units_array:
		var row: Dictionary = defn
		var id: String = str(row.get("id", ""))
		var owned: bool = GameState.owned_blueprints.has(id)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "%s · %s · %s · C%d" % [
			id,
			str(row.get("name", "?")),
			str(row.get("element", "?")),
			int(row.get("cost", 1))
		]
		if owned:
			lbl.modulate = Color(1, 1, 1)
		else:
			lbl.modulate = Color(0.28, 0.28, 0.32)
		list.add_child(lbl)
