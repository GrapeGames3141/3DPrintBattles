class_name TieredArmorPalettePreview
extends Control
## One creature master + one shader material, parameterized into visual tiers.

const ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
# Legacy Cinderpaw constant retained for existing showcase/test callers.
const MASTER_PATH := "res://assets/armor/tiered/cinderpaw_tiered_armor_signature_green_alpha_v3.png"
const SHADER := preload("res://assets/armor/tiered/cinderpaw_tier_palette.gdshader")
const CORES := preload("res://scripts/core/armor_core_definitions.gd")
const GEM_CENTER_NORMALIZED := Vector2(0.694, 0.241)
const PALETTES := {
	"standard": {"name":"Standard", "subtitle":"Gunmetal field plate", "shadow":Color("111a24"), "primary":Color("3d5365"), "highlight":Color("98aab3")},
	"reinforced": {"name":"Reinforced", "subtitle":"Bronze forge plate", "shadow":Color("332016"), "primary":Color("8d5430"), "highlight":Color("e2ae68")},
	"arcane": {"name":"Arcane", "subtitle":"Blue sigil plate", "shadow":Color("071b43"), "primary":Color("155bb4"), "highlight":Color("71dcff")},
	"masterwork": {"name":"Masterwork", "subtitle":"Violet tuned plate", "shadow":Color("281143"), "primary":Color("7134a7"), "highlight":Color("e2a2ff")},
	"legendary": {"name":"Legendary", "subtitle":"Gold crown plate", "shadow":Color("493010"), "primary":Color("b67818"), "highlight":Color("ffe58d")}
}

var tier_id := "standard"
var core_id := ""
var creature_id := "cinderpaw"
var image: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	image = TextureRect.new()
	image.name = "TieredArmorMaster"
	image.texture = load(master_path()) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(image)
	_apply_palette()

func configure_tier(next_tier_id: String) -> void:
	tier_id = next_tier_id if PALETTES.has(next_tier_id) else "standard"
	_apply_palette()

func configure_core(next_core_id: String) -> void:
	core_id = next_core_id if CORES.CORES.has(next_core_id) else ""
	_apply_palette()

func configure_creature(next_creature_id: String) -> void:
	creature_id = next_creature_id if ROSTER.ROSTER.has(next_creature_id) else "cinderpaw"
	if image != null:
		image.texture = load(master_path()) as Texture2D
	_apply_palette()

func master_path() -> String:
	return ROSTER.master_path_for(creature_id)

func gem_anchor() -> Vector2:
	return ROSTER.gem_anchor_for(creature_id)

func gem_radius() -> Vector2:
	return ROSTER.gem_radius_for(creature_id)

func palette() -> Dictionary:
	return Dictionary(PALETTES.get(tier_id, PALETTES.standard)).duplicate(true)

static func source_path_for_tier(next_tier_id: String) -> String:
	return MASTER_PATH if PALETTES.has(next_tier_id) else ""

static func source_path_for_creature_tier(next_creature_id: String, next_tier_id: String) -> String:
	return ROSTER.master_path_for(next_creature_id) if PALETTES.has(next_tier_id) else ""

static func apply_core_tint_sample(source: Color, mask_alpha: float, core_color: Color, installed: bool) -> Color:
	if mask_alpha <= 0.0:
		return source
	var luminance := source.r * 0.2126 + source.g * 0.7152 + source.b * 0.0722
	var palette := core_palette_for_color(core_color) if installed else neutral_gem_palette()
	var colored := luminance_palette(luminance, Color(palette.shadow), Color(palette.primary), Color(palette.highlight))
	colored.a = source.a
	return source.lerp(colored, clampf(mask_alpha, 0.0, 1.0))

static func core_palette_for_color(core_color: Color) -> Dictionary:
	return {
		"shadow": Color("07101c").lerp(core_color, 0.29),
		"primary": Color("121a29").lerp(core_color, 0.80),
		"highlight": core_color.lerp(Color.WHITE, 0.68)
	}

static func neutral_gem_palette() -> Dictionary:
	return {"shadow":Color("1a1f26"), "primary":Color("575f69"), "highlight":Color("c7cfd6")}

static func tier_ids() -> Array[String]:
	return ["standard", "reinforced", "arcane", "masterwork", "legendary"]

static func armor_mask_for_color(color: Color) -> float:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	var saturation := brightest - darkest
	var blue_dominance := color.b - maxf(color.r, color.g)
	return _smoothstep(0.16, 0.32, saturation) * _smoothstep(0.075, 0.195, blue_dominance)

static func gem_mask_for_color(color: Color) -> float:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	var saturation := brightest - darkest
	var green_dominance := color.g - maxf(color.r, color.b)
	return _smoothstep(0.012, 0.040, saturation) * _smoothstep(0.006, 0.035, green_dominance)

static func gem_region_mask(normalized_position: Vector2, anchor: Vector2, radius: Vector2) -> float:
	var safe_radius := Vector2(maxf(radius.x, 0.001), maxf(radius.y, 0.001))
	var delta := (normalized_position - anchor) / safe_radius
	# Feather only inside the measured ellipse; nothing outside the declared
	# helmet-local bound may receive a Core tint.
	return 1.0 - _smoothstep(0.82, 1.0, delta.length_squared())

static func gem_mask_for_creature(color: Color, normalized_position: Vector2, next_creature_id: String) -> float:
	return gem_mask_for_color(color) * gem_region_mask(normalized_position, ROSTER.gem_anchor_for(next_creature_id), ROSTER.gem_radius_for(next_creature_id))

static func recolor_source_color(color: Color, selected_palette: Dictionary) -> Color:
	return recolor_masked_source_color(color, armor_mask_for_color(color), selected_palette)

static func recolor_masked_source_color(color: Color, mask_alpha: float, selected_palette: Dictionary) -> Color:
	var mask := clampf(mask_alpha, 0.0, 1.0)
	if mask <= 0.0:
		return color
	var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	var recolored := luminance_palette(luminance, Color(selected_palette.shadow), Color(selected_palette.primary), Color(selected_palette.highlight))
	recolored.a = color.a
	return color.lerp(recolored, mask)

static func luminance_palette(source_luminance: float, shadow: Color, primary: Color, highlight: Color) -> Color:
	var recolored := shadow.lerp(primary, _smoothstep(0.10, 0.72, source_luminance))
	recolored = recolored.lerp(highlight, _smoothstep(0.63, 0.95, source_luminance) * 0.56)
	return recolored

static func _smoothstep(edge0: float, edge1: float, value: float) -> float:
	var t := clampf((value - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _apply_palette() -> void:
	if image == null:
		return
	var palette_data := palette()
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("plate_shadow", palette_data.shadow)
	material.set_shader_parameter("plate_primary", palette_data.primary)
	material.set_shader_parameter("plate_highlight", palette_data.highlight)
	material.set_shader_parameter("plate_mask_texture", load(ROSTER.plate_mask_path_for(creature_id)) as Texture2D)
	var core_data: Dictionary = CORES.definition(core_id)
	material.set_shader_parameter("core_tint", core_data.get("color", Color.WHITE))
	material.set_shader_parameter("core_installed", 1.0 if not core_data.is_empty() else 0.0)
	material.set_shader_parameter("gem_mask_min_saturation", 0.012)
	material.set_shader_parameter("gem_mask_min_green_dominance", 0.006)
	material.set_shader_parameter("gem_anchor", gem_anchor())
	material.set_shader_parameter("gem_radius", gem_radius())
	image.material = material
