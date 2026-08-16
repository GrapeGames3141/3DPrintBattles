class_name SupportCardView
extends Button
## Cached renderer. Texture resources load only when a card is actually shown.
const CARD_RULES := preload("res://scripts/battle/support_card_rules.gd")
const ATLAS_PATHS := {"resources":"res://assets/cards/support_cards_resources_source_v1.png", "defense":"res://assets/cards/support_cards_defense_source_v1.png", "offense":"res://assets/cards/support_cards_offense_source_v1.png", "utility":"res://assets/cards/support_cards_utility_source_v1.png"}
const CARD_BACK_PATH := "res://assets/cards/support_card_back_source_v1.png"
static var _textures: Dictionary = {}
static var _regions: Dictionary = {}

func configure(definition: Dictionary, copies := 1, disabled_reason := "", hidden := false, compact := false, interactive := true) -> void:
	text = "" # Child labels own visible text; the native Button never overdraws it.
	custom_minimum_size = Vector2(132, 104) if compact else Vector2(148, 218)
	var semantic := "Hidden support card" if hidden else "%s - %s - Target: %s" % [str(definition.get("name", "Support Card")), CARD_RULES.rules_text(definition), CARD_RULES.target_text(definition)]
	tooltip_text = semantic
	accessibility_name = semantic
	focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	disabled = not disabled_reason.is_empty() or not interactive
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("263950") if disabled_reason.is_empty() else Color("28303b")
	frame.border_color = Color("ffd36c") if str(definition.get("rarity", "common")) in ["rare", "epic"] else Color("78cfe5")
	frame.set_border_width_all(3)
	frame.corner_radius_top_left = 10; frame.corner_radius_top_right = 10; frame.corner_radius_bottom_left = 10; frame.corner_radius_bottom_right = 10
	add_theme_stylebox_override("normal", frame)
	if compact:
		_configure_compact(definition, disabled_reason, hidden)
		return
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	add_child(content)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(128, 102); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = card_back_for_test() if hidden else atlas_region(definition)
	content.add_child(art)
	if hidden:
		content.add_child(_text("Private hand", 14, Color("dce8f4")))
		return
	content.add_child(_text(str(definition.get("name", "Support Card")), 15, Color("fff0a1")))
	content.add_child(_text("%d Filament / %s" % [int(definition.get("cost", 0)), str(definition.get("rarity", "common")).capitalize()], 12, Color("a9ecff")))
	content.add_child(_text(CARD_RULES.rules_text(definition), 12, Color("e1eef9")))
	content.add_child(_text("Target: " + CARD_RULES.target_text(definition), 11, Color("b9d3e8")))
	if copies > 1: content.add_child(_text("Owned / hand: x%d" % copies, 11, Color("a8e3a5")))
	if not disabled_reason.is_empty(): content.add_child(_text(disabled_reason, 11, Color("ffaaa1")))

func _configure_compact(definition: Dictionary, disabled_reason: String, hidden: bool) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(52, 52); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = card_back_for_test() if hidden else atlas_region(definition)
	row.add_child(art)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE; copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	if hidden:
		copy.add_child(_text("Private hand", 13, Color("dce8f4")))
		return
	copy.add_child(_text(str(definition.get("name", "Support Card")), 12, Color("fff0a1")))
	var compact_detail := "%d Filament / %s" % [int(definition.get("cost", 0)), str(definition.get("rarity", "common")).capitalize()]
	copy.add_child(_text(compact_detail, 10, Color("a9ecff")))
	copy.add_child(_text(CARD_RULES.rules_text(definition) + " | Target: " + CARD_RULES.target_text(definition), 9, Color("dce8f4")))
	if not disabled_reason.is_empty(): copy.add_child(_text(disabled_reason, 8, Color("ffaaa1")))

static func atlas_texture_for_test(atlas_id: String) -> Texture2D:
	if not ATLAS_PATHS.has(atlas_id): return null
	if not _textures.has(atlas_id): _textures[atlas_id] = ResourceLoader.load(str(ATLAS_PATHS[atlas_id])) as Texture2D
	return _textures.get(atlas_id) as Texture2D

static func card_back_for_test() -> Texture2D:
	if not _textures.has("back"): _textures["back"] = ResourceLoader.load(CARD_BACK_PATH) as Texture2D
	return _textures.get("back") as Texture2D

static func atlas_region(definition: Dictionary) -> Texture2D:
	var art = definition.get("art", {})
	var atlas_id := str(art.get("atlas", "")) if art is Dictionary else ""
	var cell := int(art.get("cell", -1)) if art is Dictionary else -1
	var key := "%s:%d" % [atlas_id, cell]
	if _regions.has(key): return _regions[key]
	var texture := atlas_texture_for_test(atlas_id)
	if texture == null or cell < 0 or cell >= 8: return card_back_for_test()
	var size := texture.get_size()
	var region := AtlasTexture.new()
	region.atlas = texture
	region.region = Rect2(float(cell % 4) * size.x / 4.0, float(cell / 4) * size.y / 2.0, size.x / 4.0, size.y / 2.0)
	_regions[key] = region
	return region

static func cache_count_for_test() -> int: return _textures.size() + _regions.size()
static func reset_cache_for_test() -> void: _textures.clear(); _regions.clear()

func _text(value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", size); result.add_theme_color_override("font_color", color)
	return result
