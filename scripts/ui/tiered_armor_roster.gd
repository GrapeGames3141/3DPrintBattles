class_name TieredArmorRoster
extends RefCounted
## Immutable presentation contract for one armor master per catalog creature.
##
## Masters are authored blue-plate / signature-green-gem PNGs.  Tiers and
## Cores remain shader parameters; this registry never creates per-tier or
## per-Core image variants.  Cinderpaw keeps its approved v3 master exactly.

const TIERED_DIRECTORY := "res://assets/armor/tiered"
const ROSTER := {

	"cinderpaw": {"path":"res://assets/armor/tiered/cinderpaw_tiered_armor_signature_green_alpha_v3.png", "gem_anchor":Vector2(0.694, 0.241), "gem_radius":Vector2(0.045, 0.060)},
	"aquafin": {"path":"res://assets/armor/tiered/aquafin_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.827, 0.306), "gem_radius":Vector2(0.040, 0.055)},
	"voltwig": {"path":"res://assets/armor/tiered/voltwig_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.688, 0.369), "gem_radius":Vector2(0.045, 0.055)},
	"mossmunk": {"path":"res://assets/armor/tiered/mossmunk_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.732, 0.257), "gem_radius":Vector2(0.045, 0.060)},
	"frostling": {"path":"res://assets/armor/tiered/frostling_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.758, 0.302), "gem_radius":Vector2(0.045, 0.060)},
	"stoneback": {"path":"res://assets/armor/tiered/stoneback_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.788, 0.325), "gem_radius":Vector2(0.055, 0.070)},
	"galehopper": {"path":"res://assets/armor/tiered/galehopper_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.735, 0.348), "gem_radius":Vector2(0.050, 0.065)},
	"sparkotter": {"path":"res://assets/armor/tiered/sparkotter_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.740, 0.235), "gem_radius":Vector2(0.050, 0.060)},
	"glassdrake": {"path":"res://assets/armor/tiered/glassdrake_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.744, 0.249), "gem_radius":Vector2(0.045, 0.055)},
	"coralisk": {"path":"res://assets/armor/tiered/coralisk_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.789, 0.276), "gem_radius":Vector2(0.050, 0.065)},
	"runestag": {"path":"res://assets/armor/tiered/runestag_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.681, 0.282), "gem_radius":Vector2(0.035, 0.045)},
	"brambleowl": {"path":"res://assets/armor/tiered/brambleowl_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.678, 0.236), "gem_radius":Vector2(0.045, 0.070)},
	"ironmaw": {"path":"res://assets/armor/tiered/ironmaw_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.774, 0.281), "gem_radius":Vector2(0.050, 0.065)},
	"aurorawing": {"path":"res://assets/armor/tiered/aurorawing_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.700, 0.252), "gem_radius":Vector2(0.035, 0.055)},
	"thunderelk": {"path":"res://assets/armor/tiered/thunderelk_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.756, 0.271), "gem_radius":Vector2(0.035, 0.050)},
	"coalgriffin": {"path":"res://assets/armor/tiered/coalgriffin_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.785, 0.225), "gem_radius":Vector2(0.050, 0.065)},
	"tidewhale": {"path":"res://assets/armor/tiered/tidewhale_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.739, 0.317), "gem_radius":Vector2(0.060, 0.080)},
	"skyforge": {"path":"res://assets/armor/tiered/skyforge_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.770, 0.281), "gem_radius":Vector2(0.035, 0.045)},
	"pyraxis": {"path":"res://assets/armor/tiered/pyraxis_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.702, 0.228), "gem_radius":Vector2(0.050, 0.065)},
	"verdantitan": {"path":"res://assets/armor/tiered/verdantitan_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.751, 0.255), "gem_radius":Vector2(0.045, 0.060)},
	"miragefox": {"path":"res://assets/armor/tiered/miragefox_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.772, 0.281), "gem_radius":Vector2(0.045, 0.060)},
	"voidmanta": {"path":"res://assets/armor/tiered/voidmanta_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.682, 0.453), "gem_radius":Vector2(0.045, 0.065)},
	"worldcoil": {"path":"res://assets/armor/tiered/worldcoil_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.650, 0.223), "gem_radius":Vector2(0.050, 0.065)},
	"starloom": {"path":"res://assets/armor/tiered/starloom_tiered_armor_signature_green_alpha_v1.png", "gem_anchor":Vector2(0.758, 0.306), "gem_radius":Vector2(0.045, 0.060)}
}

static func creature_ids() -> Array[String]:
	var ids: Array[String] = []
	for creature_id in ROSTER:
		ids.append(str(creature_id))
	return ids

static func definition(creature_id: String) -> Dictionary:
	return Dictionary(ROSTER.get(creature_id, {})).duplicate(true)

static func master_path_for(creature_id: String) -> String:
	return str(definition(creature_id).get("path", ""))

static func plate_mask_path_for(creature_id: String) -> String:
	if not ROSTER.has(creature_id):
		return ""
	return "%s/masks/%s_armor_plate_mask_v1.png" % [TIERED_DIRECTORY, creature_id]

static func gem_anchor_for(creature_id: String) -> Vector2:
	return definition(creature_id).get("gem_anchor", Vector2(0.5, 0.2)) as Vector2

static func gem_radius_for(creature_id: String) -> Vector2:
	return definition(creature_id).get("gem_radius", Vector2(0.05, 0.06)) as Vector2

static func has_master(creature_id: String) -> bool:
	var path := master_path_for(creature_id)
	var mask_path := plate_mask_path_for(creature_id)
	return not path.is_empty() and not mask_path.is_empty() and ResourceLoader.exists(path) and ResourceLoader.exists(mask_path)

static func expected_file_names() -> Array[String]:
	var names: Array[String] = []
	for creature_id in creature_ids():
		names.append(master_path_for(creature_id).get_file())
	return names
