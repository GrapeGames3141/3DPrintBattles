class_name PhysicalResultReceiptComponent
extends RefCounted
## Native BA-05 receipt seating. This component only presents returned settlement facts.

const RULES := preload("res://scripts/core/unified_rules.gd")
const UNIFIED_CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const BAYS := [Rect2(0.105, 0.502, 0.255, 0.110), Rect2(0.380, 0.502, 0.245, 0.110), Rect2(0.645, 0.502, 0.245, 0.110), Rect2(0.222, 0.630, 0.250, 0.110), Rect2(0.530, 0.630, 0.250, 0.110)]

func render(main: Control, surface: Control, margin: Callable, heading: Callable) -> void:
	var receipt: Dictionary = main.m3_result_receipt if main.m3_result_receipt is Dictionary else {}
	var state := str(main.m3_result_state)
	_render_hud(main, surface, state)
	var status := _label(_outcome_copy(receipt) + " · " + _status_copy(receipt, state), 16, Color("49311f")); status.name = "M3ResultSettlementStatus"; status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status.anchor_left = 0.175; status.anchor_top = 0.180; status.anchor_right = 0.825; status.anchor_bottom = 0.225; surface.add_child(status)
	var mode := _label(_mode_copy(receipt, state), 11, Color("65472b")); mode.name = "M3ResultReceiptMode"; mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; mode.anchor_left = 0.175; mode.anchor_top = 0.230; mode.anchor_right = 0.825; mode.anchor_bottom = 0.265; surface.add_child(mode)
	var host := Control.new(); host.name = "M3ResultAuthoritativeValues"; host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); surface.add_child(host)
	var facts := _receipt_facts(receipt)
	for index in BAYS.size():
		var fact: Dictionary = facts[index] if index < facts.size() else {"label":"OPTIONAL", "value":"—", "tooltip":"No additional reward"}
		var bay := Control.new(); bay.name = "M3ResultBay%02d" % (index + 1); bay.clip_contents = true; _set_rect(bay, BAYS[index]); host.add_child(bay); _render_fact(bay, fact)
	# Native text is seated over the upper face of the left dial; the button itself
	# stays transparent so the approved brass hardware remains visible.
	var continue_label := _label("CONTINUE", 14, Color("47331f"), true); continue_label.name = "ResultContinueLabel"; continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; continue_label.anchor_left = 0.161; continue_label.anchor_top = 0.812; continue_label.anchor_right = 0.491; continue_label.anchor_bottom = 0.887; surface.add_child(continue_label)
	var continue_button := _physical_button("ResultContinue", main.dispatch_back); continue_button.anchor_left = 0.080; continue_button.anchor_top = 0.785; continue_button.anchor_right = 0.575; continue_button.anchor_bottom = 0.950; continue_button.custom_minimum_size = Vector2(56, 56); continue_button.tooltip_text = "Continue to Workshop"; continue_button.accessibility_name = continue_button.tooltip_text; continue_button.disabled = state not in ["committed", "duplicate"] or main.battle_mode == "local"; surface.add_child(continue_button)
	if state == "error":
		var retry_label := _label("RETRY", 13, Color("f3d995")); retry_label.name = "ResultRetryLabel"; retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; retry_label.anchor_left = 0.675; retry_label.anchor_top = 0.770; retry_label.anchor_right = 0.875; retry_label.anchor_bottom = 0.805; surface.add_child(retry_label)
		var retry := _physical_button("ResultRetry", main._m3_retry_result); retry.anchor_left = 0.675; retry.anchor_top = 0.805; retry.anchor_right = 0.875; retry.anchor_bottom = 0.935; retry.custom_minimum_size = Vector2(56, 56); retry.tooltip_text = "Retry settlement persistence"; retry.accessibility_name = retry.tooltip_text; surface.add_child(retry)

func _render_hud(main: Control, surface: Control, state: String) -> void:
	var hud := Control.new(); hud.name = "ResultCompactHud"; hud.anchor_left = 0.120; hud.anchor_top = 0.010; hud.anchor_right = 0.880; hud.anchor_bottom = 0.055; surface.add_child(hud)
	# Continue is the sole physical exit owner; no competing generic HUD Back.
	var level := _label("Level %d" % int(GameManager.profile.get("level", 1)), 12, Color("f3e5c9")); level.name = "ResultHudLevel"; _set_rect(level, Rect2(0.180, 0.0, 0.220, 1.0)); hud.add_child(level)
	var xp := _label("XP %d" % int(GameManager.profile.get("spool_xp", 0)), 12, Color("f3e5c9")); xp.name = "ResultHudXp"; _set_rect(xp, Rect2(0.410, 0.0, 0.220, 1.0)); hud.add_child(xp)
	var coins := _label("Coin %d" % int(GameManager.profile.get("forge_coins", 0)), 12, Color("f3e5c9")); coins.name = "ResultHudCoins"; _set_rect(coins, Rect2(0.690, 0.0, 0.290, 1.0)); hud.add_child(coins)

func _outcome_copy(receipt: Dictionary) -> String:
	var raw := str(receipt.get("result", receipt.get("outcome", ""))).to_lower()
	if raw == "victory" or bool(receipt.get("victory", false)): return "VICTORY"
	if raw == "defeat" or bool(receipt.get("defeat", false)): return "DEFEAT"
	return "BATTLE RESULT"

func _status_copy(receipt: Dictionary, state: String) -> String:
	if state == "error": return "SETTLEMENT NEEDS RETRY"
	if state == "duplicate" or bool(receipt.get("duplicate", false)): return "RECEIPT ALREADY RECORDED"
	if state == "committed": return "SETTLEMENT RECORDED"
	return "SETTLEMENT PENDING"

func _mode_copy(receipt: Dictionary, state: String) -> String:
	return "%s · %s" % [str(receipt.get("mode", "battle")).replace("_", " ").to_upper(), "AUTHORITATIVE" if state in ["committed", "duplicate"] else "NO RE-ROLL"]

func _receipt_facts(receipt: Dictionary) -> Array:
	var values: Dictionary = {}
	for source in [receipt, receipt.get("reward", {}), _claim_reward(receipt)]:
		if source is Dictionary:
			for field in ["coins", "xp", "spool_gained", "drop", "first_clear", "quest", "quest_progress", "level"]:
				if (source as Dictionary).has(field) and not values.has(field): values[field] = (source as Dictionary).get(field)
	var facts: Array = []
	if values.has("coins"): facts.append({"label":"COINS", "value":_whole(values["coins"])})
	if values.has("xp"): facts.append({"label":"XP", "value":_whole(values["xp"])})
	var spool: Dictionary = receipt.get("spool", {}) if receipt.get("spool", {}) is Dictionary else {}
	var spool_value := ""
	if values.has("spool_gained"): spool_value = "+%s" % _whole(values["spool_gained"])
	if spool.has("levels"): spool_value = "%s · Lv %s" % [spool_value, _whole(spool.get("levels"))] if not spool_value.is_empty() else "Lv %s" % _whole(spool.get("levels"))
	if not spool_value.is_empty(): facts.append({"label":"SPOOL", "value":spool_value})
	var drop: Variant = values.get("drop", receipt.get("drop", null))
	if drop != null: facts.append(_drop_fact(drop))
	if values.has("first_clear"): facts.append({"label":"FIRST CLEAR", "value":"YES" if bool(values["first_clear"]) else "—"})
	elif values.has("quest_progress"): facts.append({"label":"QUEST", "value":_simple_value(values["quest_progress"])})
	elif values.has("quest"): facts.append({"label":"QUEST", "value":_simple_value(values["quest"])})
	elif values.has("level"): facts.append({"label":"LEVEL", "value":_whole(values["level"])})
	return facts

func _claim_reward(receipt: Dictionary) -> Dictionary:
	var claim: Dictionary = receipt.get("reward_claim", {}) if receipt.get("reward_claim", {}) is Dictionary else {}
	return claim.get("reward", {}) if claim.get("reward", {}) is Dictionary else {}

func _drop_fact(drop: Variant) -> Dictionary:
	if drop is Dictionary:
		var data: Dictionary = drop; var id := str(data.get("id", data.get("card_id", ""))); return _drop_fact_for_id(str(data.get("name", id if not id.is_empty() else "—")), id)
	return _drop_fact_for_id(str(drop), str(drop))

func _drop_fact_for_id(value: String, id: String) -> Dictionary:
	var fact := {"label":"DROP", "value":value, "drop_id":id}
	var card := RULES.card(id)
	if str(card.get("type", "")) == "creature":
		fact["owned_copies"] = int(GameManager.profile.get("owned_cards", {}).get(id, 0))
		fact["blueprint_license"] = RULES.has_printable_blueprint(GameManager.profile, id)
		fact["printed_models"] = _printed_model_count(id)
	return fact

func _printed_model_count(creature_id: String) -> int:
	var count := 0
	for raw_model in GameManager.profile.get("printed_models", {}).values():
		if raw_model is Dictionary and str((raw_model as Dictionary).get("blueprint_id", "")) == creature_id: count += 1
	return count

func _simple_value(value: Variant) -> String:
	if value is Dictionary:
		var source: Dictionary = value
		if source.has("name"): return str(source.get("name"))
		if source.has("id"): return str(source.get("id"))
		return "—"
	return str(value)

func _whole(value: Variant) -> String:
	if value is int or value is float: return str(int(value))
	return str(value)

func _render_fact(bay: Control, fact: Dictionary) -> void:
	var label := _label(str(fact.get("label", "REWARD")), 10, Color("65472b")); label.name = "M3ResultBayLabel"; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.tooltip_text = str(fact.get("tooltip", "")); label.accessibility_name = label.tooltip_text if not label.tooltip_text.is_empty() else label.text; _set_rect(label, Rect2(0.06, 0.08, 0.88, 0.22)); bay.add_child(label)
	var drop_id := str(fact.get("drop_id", ""))
	if not drop_id.is_empty() and not RULES.card(drop_id).is_empty():
		var card := RULES.card(drop_id)
		if str(card.get("type", "")) == "creature":
			IMPRINT.add_blueprint_card(bay, "M3ResultDropBlueprintCard", IMPRINT.blueprint_texture(card), Rect2(0.26, 0.30, 0.48, 0.40))
		else:
			var art := TextureRect.new(); art.name = "M3ResultDropArt"; art.texture = UNIFIED_CARD_VIEW.art_for_definition(card); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; _set_rect(art, Rect2(0.26, 0.30, 0.48, 0.46)); bay.add_child(art)
		if fact.has("owned_copies"):
			var ownership := _label("Copies %d · License %s · Models %d" % [int(fact.get("owned_copies", 0)), "permanent" if bool(fact.get("blueprint_license", false)) else "none", int(fact.get("printed_models", 0))], 8, Color("3b2b1c")); ownership.name = "M3ResultDropOwnershipFacts"; ownership.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ownership.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _set_rect(ownership, Rect2(0.04, 0.69, 0.92, 0.28)); bay.add_child(ownership)
	# Numeric rewards and optional em dashes share the same scale and tall value
	# seat, keeping their baseline aligned at 150% instead of making absence look
	# lower than Coins/XP.
	var plain_value := drop_id.is_empty()
	var value := _label(str(fact.get("value", "—")), 16 if plain_value else 11, Color("3b2b1c"), plain_value); value.name = "M3ResultBayValue"; value.tooltip_text = str(fact.get("tooltip", "")); value.accessibility_name = value.tooltip_text if not value.tooltip_text.is_empty() else value.text; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _set_rect(value, Rect2(0.06, 0.34, 0.88, 0.40) if plain_value else Rect2(0.06, 0.68, 0.88, 0.16)); bay.add_child(value)

func _set_rect(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x; node.anchor_top = rect.position.y; node.anchor_right = rect.end.x; node.anchor_bottom = rect.end.y

func _label(value: String, size: int, color: Color, scale_with_accessibility := false) -> Label:
	var label := Label.new(); label.text = value; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_OFF; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var settings: Dictionary = GameManager.profile.get("settings", {}) if GameManager.profile.get("settings", {}) is Dictionary else {}
	var scale_bps := int(settings.get("text_scale_bps", 10000))
	label.add_theme_font_size_override("font_size", maxi(12, (size * scale_bps) / 10000) if scale_with_accessibility else size); label.add_theme_color_override("font_color", color); label.mouse_filter = Control.MOUSE_FILTER_IGNORE; return label

func _button(node_name: String, value: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = value; button.focus_mode = Control.FOCUS_ALL; button.add_theme_font_size_override("font_size", 14); button.add_theme_color_override("font_color", Color("f5e1b0")); button.add_theme_color_override("font_disabled_color", Color("a99578")); button.add_theme_stylebox_override("normal", _style(Color("26333b"), Color("b98b46"), 3)); button.add_theme_stylebox_override("hover", _style(Color("3c4c4d"), Color("f0c76c"), 3)); button.add_theme_stylebox_override("pressed", _style(Color("5a462e"), Color("f7d77b"), 3)); button.add_theme_stylebox_override("focus", _style(Color("26333b"), Color("74d8df"), 4)); button.add_theme_stylebox_override("disabled", _style(Color("1d2930"), Color("66553b"), 2))
	if action.is_valid(): button.pressed.connect(action)
	return button

func _physical_button(node_name: String, action: Callable) -> Button:
	var button := Button.new(); button.name = node_name; button.text = ""; button.focus_mode = Control.FOCUS_ALL; button.flat = true; button.add_theme_stylebox_override("normal", StyleBoxEmpty.new()); button.add_theme_stylebox_override("hover", StyleBoxEmpty.new()); button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new()); button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color("74d8df"), 4)); button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	if action.is_valid(): button.pressed.connect(action)
	return button

func _style(fill: Color, edge: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = fill; style.border_color = edge; style.set_border_width_all(width); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8; style.content_margin_left = 4; style.content_margin_right = 4; style.content_margin_top = 2; style.content_margin_bottom = 2; return style
