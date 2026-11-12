class_name PackView
extends Control
## A sealed foil card pack, laid out at 336x520. Scale the node to show it at
## other sizes. One shader draws the pouch and tears its top strip off; pass a
## `margin` to leave room around the pack for the strip to lift and fly away.

const W := 336.0
const H := 520.0
## Where the pack rips, measured down from its top edge.
const TEAR_Y := 46.0

var kind := ""
var tear := 0.0
var tear_dir := 1
var _mat: ShaderMaterial


static func make(pack_kind: String, pack_scale: float = 1.0, margin: float = 0.0) -> PackView:
	var v := PackView.new()
	v.kind = pack_kind
	v.size = Vector2(W, H)
	v.custom_minimum_size = Vector2(W, H) * minf(pack_scale, 1.0)
	v.scale = Vector2(pack_scale, pack_scale)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	v._build(margin)
	return v


func _build(margin: float) -> void:
	var def: Dictionary = GameData.PACKS[kind]
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://assets/shaders/foil_pack.gdshader")
	var foil := ColorRect.new()
	foil.material = _mat
	foil.position = Vector2(-margin, -margin)
	foil.size = Vector2(W, H) + Vector2(margin, margin) * 2.0
	foil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foil)
	_mat.set_shader_parameter("rect_size", foil.size)
	_mat.set_shader_parameter("origin", Vector2(margin, margin))
	_mat.set_shader_parameter("pack_size", Vector2(W, H))
	_mat.set_shader_parameter("tint", Color(def["foil"]))
	_mat.set_shader_parameter("tint_deep", Color(def["foil_deep"]))
	_mat.set_shader_parameter("holo", float(def["holo"]))
	_mat.set_shader_parameter("tear_y", TEAR_Y)
	var path: String = (GameData.RAW if def["art_raw"] else GameData.SPRITE) % def["art"]
	var tex := UI.tex(path)
	if tex != null:
		var region := Vector4(0, 0, 1, 1) if def["art_raw"] else UI.sprite_region(path, 0)
		_mat.set_shader_parameter("art", tex)
		_mat.set_shader_parameter("art_region", region)
		_mat.set_shader_parameter("art_aspect", (tex.get_width() * region.z) / (tex.get_height() * region.w))

	var ink := Color(def["foil_deep"]).darkened(0.55)
	var brand := UI.label("PRINTFORGE LEGENDS", 15, Color(1, 1, 1, 0.92), true, 4)
	brand.add_theme_color_override("font_outline_color", Color(ink, 0.85))
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, brand, Vector2(0, 62), Vector2(W, 22))
	var title: String = def["name"]
	var nm := UI.label(title, 33 if title.length() <= 14 else 28, Color.WHITE, true, 9)
	nm.add_theme_color_override("font_outline_color", ink)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.place(self, nm, Vector2(0, 360), Vector2(W, 50))
	var promise := "%d CARDS  -  %s OR BETTER INSIDE" % [int(def["size"]), str(GameData.RARITIES[def["guarantee"]]["name"]).to_upper()]
	var sub := UI.label(promise, 14, Color(1, 1, 1, 0.95), true, 4)
	sub.add_theme_color_override("font_outline_color", Color(ink, 0.85))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, sub, Vector2(0, 418), Vector2(W, 22))
	var gem := IconView.make("star" if kind == "premium" else "hex", 30, GameData.rarity_color(def["guarantee"]))
	gem.position = Vector2(W * 0.5 - 15, 446)
	add_child(gem)


## How far the top strip is ripped, 0 to 1, starting from the left edge when
## `dir` is 1 and from the right edge when it is -1.
func set_tear(amount: float, dir: int = 0) -> void:
	tear = clampf(amount, 0.0, 1.0)
	if dir != 0:
		tear_dir = dir
	_mat.set_shader_parameter("tear", tear)
	_mat.set_shader_parameter("tear_dir", float(tear_dir))


## The loose end of the strip: how far it has swung up, drifted and faded.
func set_strip(angle: float, offset := Vector2.ZERO, alpha: float = 1.0) -> void:
	_mat.set_shader_parameter("strip_angle", angle)
	_mat.set_shader_parameter("strip_offset", offset)
	_mat.set_shader_parameter("strip_alpha", alpha)


## Moves the light across the foil, -1 to 1.
func set_tilt(amount: float) -> void:
	_mat.set_shader_parameter("tilt", clampf(amount, -1.0, 1.0))
