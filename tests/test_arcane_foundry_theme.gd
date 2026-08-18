extends Node

const THEME := preload("res://scripts/ui/arcane_foundry_theme_kit.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	THEME.clear_cache_for_test()
	var panel := THEME.panel("surface", false)
	var inset := THEME.inset("surface", false)
	var primary := THEME.button("primary", "normal", false)
	var hover := THEME.button("primary", "hover", false)
	var pressed := THEME.button("primary", "pressed", false)
	var disabled := THEME.button("primary", "disabled", false)
	require(panel is StyleBoxTexture and primary is StyleBoxTexture, "normal Foundry chrome is raster nine-slice")
	require((primary as StyleBoxTexture).texture != (hover as StyleBoxTexture).texture and (hover as StyleBoxTexture).texture != (pressed as StyleBoxTexture).texture, "keycap states use distinct generated textures")
	require((primary as StyleBoxTexture).texture_margin_left > 0 and (panel as StyleBoxTexture).texture_margin_top > 0 and inset is StyleBoxTexture, "nine-slice patch margins and shallow inset well are configured")
	require((primary as StyleBoxTexture).texture_margin_top + (primary as StyleBoxTexture).texture_margin_bottom <= 28 and (panel as StyleBoxTexture).texture_margin_top + (panel as StyleBoxTexture).texture_margin_bottom <= 40 and (THEME.cartridge(false, false) as StyleBoxTexture).texture_margin_top + (THEME.cartridge(false, false) as StyleBoxTexture).texture_margin_bottom <= 48, "nine-slice opposing margins fit the smallest destination controls")
	require((inset as StyleBoxTexture).texture.resource_path.ends_with("foundry_inset_well_compact_v1.png") and (inset as StyleBoxTexture).texture.get_size().x < 1024, "only the compact inset derivative is referenced at runtime")
	require(disabled is StyleBoxTexture and THEME.cache_count_for_test() >= 7, "semantic style cache retains state resources")
	var contrast := THEME.button("primary", "normal", true)
	require(contrast is StyleBoxFlat and THEME.display_font() != null, "high contrast uses code-native fallback and Foundry font is bundled")
	if failures.is_empty(): print("PASS: Arcane Foundry theme texture/cache/high-contrast contract")
	get_tree().quit(0 if failures.is_empty() else 1)
