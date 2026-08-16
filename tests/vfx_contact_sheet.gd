class_name VFXContactSheet
extends Control
## Capture-only labeled proof that every optional elemental and status cell is
## shipped and addressable. It does not participate in gameplay or save state.

const MOVE_VFX := preload("res://scripts/ui/battle_move_vfx.gd")
var elemental_atlas: Texture2D
var status_atlas: Texture2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	elemental_atlas = _source_texture(MOVE_VFX.ELEMENT_ATLAS_PATH)
	var status_image := Image.load_from_file(ProjectSettings.globalize_path(MOVE_VFX.STATUS_ATLAS_PATH))
	status_atlas = ImageTexture.create_from_image(status_image) if status_image != null and not status_image.is_empty() else null
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("091522"), true)
	var font := ThemeDB.fallback_font
	var heading_size := clampi(int(size.y * 0.045), 22, 34)
	var label_size := clampi(int(size.y * 0.025), 14, 20)
	draw_string(font, Vector2(28, heading_size + 20), "PRINTFORGE LEGENDS — OPTIONAL VFX ATLAS CONTACT SHEET", HORIZONTAL_ALIGNMENT_LEFT, -1.0, heading_size, Color("f7d991"))
	_draw_group("ELEMENTAL PROJECTILES", ["Fire", "Water", "Lightning", "Nature", "Ice", "Stone", "Wind", "Arcane"], elemental_atlas, true, Rect2(24, size.y * 0.12, size.x - 48, size.y * 0.38), font, label_size)
	_draw_group("STATUS ACCENTS", ["heal", "shield", "filament", "attack_buff", "debuff", "cleanse", "switch_discount", "ability_lock"], status_atlas, false, Rect2(24, size.y * 0.56, size.x - 48, size.y * 0.38), font, label_size)

func _source_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null

func _draw_group(title: String, labels: Array, texture: Texture2D, element: bool, area: Rect2, font: Font, label_size: int) -> void:
	draw_rect(area, Color("10243a"), true)
	draw_rect(area, Color("65d8ee"), false, 2.0)
	draw_string(font, area.position + Vector2(12, label_size + 10), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size, Color("e8f7ff"))
	if not element:
		var column_width := (area.size.x - 32.0) / 4.0
		var status_label_size := 13
		for index in labels.size():
			var row := index / 4
			var cell_position := area.position + Vector2(16.0 + (index % 4) * column_width, 40.0 + row * 112.0)
			var icon_rect := Rect2(cell_position + Vector2((column_width - 88.0) * 0.5, 0), Vector2(88, 88))
			if texture != null:
				var source := Rect2(Vector2((index % 4) * 443, row * 443), Vector2(443, 443))
				draw_texture_rect_region(texture, icon_rect, source)
			draw_string(font, Vector2(cell_position.x, cell_position.y + 106.0), str(labels[index]).replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_CENTER, column_width, status_label_size, Color("ffffff"))
		return
	var top := area.position.y + label_size + 18.0
	var column_width := (area.size.x - 24.0) / 8.0
	var cell_size := minf(column_width - 8.0, area.size.y - label_size - 34.0)
	for index in labels.size():
		var cell_rect := Rect2(area.position + Vector2(12.0 + index * column_width, top), Vector2(column_width - 8.0, cell_size))
		var icon_size := minf(cell_size * 0.58, cell_rect.size.x * 0.78)
		var icon_rect := Rect2(cell_rect.position + Vector2((cell_rect.size.x - icon_size) * 0.5, 2.0), Vector2.ONE * icon_size)
		if texture != null:
			var source := MOVE_VFX.element_atlas_region(texture, str(labels[index]))
			draw_texture_rect_region(texture, icon_rect, source)
		draw_string(font, Vector2(cell_rect.position.x, cell_rect.end.y - 4.0), str(labels[index]).replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_CENTER, cell_rect.size.x, label_size, Color("ffffff"))
