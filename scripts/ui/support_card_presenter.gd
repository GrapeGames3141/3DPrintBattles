class_name SupportCardPresenter
extends RefCounted
## Catalog-only text adapter for deck and battle presentation.

static func target_text(definition: Dictionary) -> String:
	return "Foe active print" if str(definition.get("effect", "")) in ["debuff", "ability_lock"] else "Your active print"

static func effect_text(definition: Dictionary) -> String:
	var effect := str(definition.get("effect", ""))
	var amount := int(definition.get("amount", 0))
	match effect:
		"filament": return "Gain %d Filament" % amount
		"heal": return "Restore %d HP" % amount
		"shield": return "Gain %d shield" % amount
		"attack_buff": return "Gain +%d Attack" % amount
		"cooldown": return "Reduce signature cooldown by %d" % amount
		"draw": return "Draw %d support card%s" % [amount, "s" if amount != 1 else ""]
		"switch_discount": return "Next switch costs %d less" % amount
		"debuff": return "Foe loses %d Attack and signature locks 1 turn" % amount
		"cleanse": return "Cleanse debuffs"
	return "Catalog effect unavailable"
