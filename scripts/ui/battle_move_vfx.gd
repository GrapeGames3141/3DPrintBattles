class_name BattleMoveVFX
extends RefCounted
## Deterministic, non-authoritative combat presentation profiles.

## Profiles derive from immutable catalog ability/element/effect data. They never
## alter BattleState; optional raster atlas cells enhance a code-native fallback.

const BATTLE_CATALOG := preload("res://scripts/battle/battle_catalog.gd")
## Optional generated atlases. The stage keeps its code-native presentation as a
## reliable fallback until a review build includes the transparent atlas assets.
const ELEMENT_ATLAS_PATH := "res://assets/vfx/elemental_projectiles_v1.png"
const STATUS_ATLAS_PATH := "res://assets/vfx/status_accents_v1.png"
const ATLAS_COLUMNS := 4
const ATLAS_ROWS := 2
const ELEMENT_ATLAS_CELLS := {
	"Fire": 0, "Water": 1, "Lightning": 2, "Nature": 3,
	"Ice": 4, "Stone": 5, "Wind": 6, "Arcane": 7
}
const STATUS_ATLAS_CELLS := {
	"heal": 0, "shield": 1, "filament": 2, "attack_buff": 3,
	"debuff": 4, "cleanse": 5, "switch_discount": 6, "ability_lock": 7
}
static var _element_atlas: Texture2D
static var _status_atlas: Texture2D
static var _element_atlas_checked := false
static var _status_atlas_checked := false
const ELEMENT_VISUALS := {
	"Fire":{"travel":"ember","impact":"flare","color":"ff925d"},
	"Water":{"travel":"droplet","impact":"ripple","color":"68c9ff"},
	"Lightning":{"travel":"bolt","impact":"spark","color":"ffe36b"},
	"Nature":{"travel":"leaf","impact":"bloom","color":"8ce59a"},
	"Ice":{"travel":"shard","impact":"crystal","color":"b7f4ff"},
	"Stone":{"travel":"rock","impact":"dust","color":"d0b18b"},
	"Wind":{"travel":"ribbon","impact":"gust","color":"b9ead9"},
	"Arcane":{"travel":"rune","impact":"nova","color":"d7a7ff"}
}

static func event_duration(kind: String) -> float:
	match kind:
		"attack", "ability": return 0.62
		"print": return 0.78
		"defend": return 0.42
		"card": return 0.52
		"switch": return 0.48
	return 0.0

static func is_finite_event(kind: String) -> bool:
	return event_duration(kind) > 0.0

static func optional_element_atlas() -> Texture2D:
	if not _element_atlas_checked:
		_element_atlas_checked = true
		if ResourceLoader.exists(ELEMENT_ATLAS_PATH): _element_atlas = ResourceLoader.load(ELEMENT_ATLAS_PATH) as Texture2D
	return _element_atlas

static func optional_status_atlas() -> Texture2D:
	if not _status_atlas_checked:
		_status_atlas_checked = true
		if ResourceLoader.exists(STATUS_ATLAS_PATH): _status_atlas = ResourceLoader.load(STATUS_ATLAS_PATH) as Texture2D
	return _status_atlas

static func clear_optional_atlas_cache_for_test() -> void:
	_element_atlas = null
	_status_atlas = null
	_element_atlas_checked = false
	_status_atlas_checked = false

static func atlas_region(texture: Texture2D, cell_index: int) -> Rect2:
	if texture == null:
		return Rect2()
	var cell_size := Vector2(float(texture.get_width()) / ATLAS_COLUMNS, float(texture.get_height()) / ATLAS_ROWS)
	var clamped := clampi(cell_index, 0, ATLAS_COLUMNS * ATLAS_ROWS - 1)
	return Rect2(Vector2(float(clamped % ATLAS_COLUMNS) * cell_size.x, float(clamped / ATLAS_COLUMNS) * cell_size.y), cell_size)

static func element_atlas_region(texture: Texture2D, element: String) -> Rect2:
	return atlas_region(texture, int(ELEMENT_ATLAS_CELLS.get(element, ELEMENT_ATLAS_CELLS["Arcane"])))

static func status_atlas_region(texture: Texture2D, accent: String) -> Rect2:
	return atlas_region(texture, int(STATUS_ATLAS_CELLS.get(accent, STATUS_ATLAS_CELLS["ability_lock"])))

static func profile_for(creature_id: String, kind: String = "ability") -> Dictionary:
	var definition := BATTLE_CATALOG.creature(creature_id)
	if definition.is_empty(): definition = BATTLE_CATALOG.creature("mossmunk")
	var element := str(definition.get("element", "Arcane"))
	var base: Dictionary = ELEMENT_VISUALS.get(element, ELEMENT_VISUALS["Arcane"]).duplicate(true)
	var signature := BATTLE_CATALOG.signature_for_creature(str(definition.get("id", "mossmunk")))
	var accents: Array[String] = []
	for raw_effect in signature.get("effects", []):
		if raw_effect is Dictionary:
			var effect := str(raw_effect.get("effect", ""))
			if not effect.is_empty() and not effect in accents: accents.append(effect)
	if kind == "attack":
		base["travel"] = "streak"
		base["impact"] = "impact"
		accents = []
	elif kind == "defend":
		base["travel"] = "guard"
		base["impact"] = "shield"
	elif kind == "card":
		base["travel"] = "card"
		base["impact"] = "support"
	elif kind == "switch":
		base["travel"] = "swap"
		base["impact"] = "arrival"
	return {"creature_id":str(definition.get("id", "mossmunk")), "ability":str(definition.get("ability", "Signature")), "element":element, "travel":str(base.get("travel", "rune")), "impact":str(base.get("impact", "nova")), "color":Color(str(base.get("color", "d7a7ff"))), "accents":accents}

static func audit_profiles() -> Array:
	var result: Array = []
	for definition in BATTLE_CATALOG.DATA.CREATURES:
		var creature_id := str(definition.get("id", ""))
		var profile := profile_for(creature_id, "ability")
		result.append(profile)
	return result
