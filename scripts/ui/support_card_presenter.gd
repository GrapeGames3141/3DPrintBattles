class_name SupportCardPresenter
extends RefCounted
## Catalog-only text adapter for deck and battle presentation.
const RULES := preload("res://scripts/battle/support_card_rules.gd")

static func target_text(definition: Dictionary) -> String:
	return RULES.target_text(definition)

static func effect_text(definition: Dictionary) -> String:
	return RULES.rules_text(definition)
