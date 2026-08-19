extends Node

## Shipped-entry responsive contract. The compact unified_main harness is not
## instantiated here: every assertion exercises scenes/main.tscn/main.gd.
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _has_scroll(node: Node) -> bool:
	if node is ScrollContainer: return true
	for child in node.get_children():
		if _has_scroll(child): return true
	return false

func _legal_profile() -> Dictionary:
	var p := RULES.ensure(ProfileRules.new_profile())
	p.coins = 720
	p = RULES.choose_starter(p, "cinderpaw").profile
	p = RULES.print_starter(p).profile
	p.settings = {"text_scale_bps":12500,"high_contrast":false,"reduced_motion":true}
	return p

func _pager_labels(node: Node) -> Array:
	var found: Array = []
	if node is Label and node.get_parent() != null and "Pager" in node.get_parent().name:
		found.append(node)
	for child in node.get_children(): found.append_array(_pager_labels(child))
	return found

func _bottom_in_bounds(node: Control, viewport: Vector2) -> bool:
	var rect := node.get_global_rect()
	return node.is_visible_in_tree() and rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= viewport.x + 1.0 and rect.end.y <= viewport.y + 1.0

func _rect_text(node: Control) -> String:
	return str(node.get_global_rect())

func _button_named(node: Node, fragment: String) -> Button:
	if node is Button and fragment.to_lower() in (node as Button).text.to_lower(): return node as Button
	for child in node.get_children():
		var found := _button_named(child, fragment)
		if found != null: return found
	return null

func _ready() -> void:
	for viewport in [Vector2(1280, 720), Vector2(576, 1024)]:
		for surface in ["onboarding", "unified_market", "unified_library", "unified_deck", "unified_upgrades", "unified_forgedex", "unified_battle"]:
			GameManager.profile = ProfileRules.new_profile() if surface == "onboarding" else _legal_profile()
			if surface == "unified_market": GameManager.buy_card_pack("pack_3")
			var subviewport := SubViewport.new()
			subviewport.size = Vector2i(viewport)
			subviewport.size_2d_override = Vector2i(viewport)
			subviewport.size_2d_override_stretch = true
			subviewport.disable_3d = true
			add_child(subviewport)
			var canvas := Control.new()
			# A SubViewport has no Control parent. Full-rect anchors therefore resolve
			# against the test window instead of this requested viewport. Keep this
			# harness root explicitly in the SubViewport's local coordinate space.
			canvas.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			canvas.position = Vector2.ZERO
			canvas.size = viewport
			subviewport.add_child(canvas)
			var main := MAIN.instantiate()
			if surface == "onboarding": main.pending_starter_id = "cinderpaw"
			if surface == "unified_battle":
				var deck: Array = GameManager.active_deck_cards()
				main.battle = STATE.create(deck, deck, 81)
				main.battle_mode = "local"
				main.unified_local_handoff = false
				main.screen = surface
			else:
				main.screen = surface
			canvas.add_child(main)
			main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			await get_tree().process_frame
			await get_tree().process_frame
			require(main.get_script().resource_path == "res://scripts/ui/main.gd", "%s ships main.gd" % surface)
			require(not _has_scroll(main), "%s has no ScrollContainer at %s" % [surface, viewport])
			var pager_nodes := _pager_labels(main)
			if surface in ["onboarding", "unified_market", "unified_library", "unified_deck", "unified_upgrades", "unified_forgedex", "unified_battle"]:
				for pager in pager_nodes:
					var label := pager as Label
					require(label.autowrap_mode == TextServer.AUTOWRAP_OFF and _bottom_in_bounds(label, viewport), "%s pager is no-wrap/in bounds at %s rect=%s" % [surface, viewport, _rect_text(label)])
			var required: Array[String] = []
			match surface:
				"onboarding": required = ["Blueprint"]
				"unified_market": required = ["Back to Workshop"]
				"unified_library": required = ["Deck Blueprint Rack", "Back to Workshop"]
				"unified_deck": required = ["Save battle deck", "Back to Workshop"]
				"unified_upgrades": required = ["Apply staged upgrades", "Back to Workshop"]
				"unified_forgedex": required = ["Open Equipment Workbench", "Back to Workshop"]
				"unified_battle": required = ["Advance phase", "Return to Workshop"]
			for text in required:
				var required_button := _button_named(main, text)
				var rect := _rect_text(required_button) if required_button != null else "missing"
				require(required_button != null and _bottom_in_bounds(required_button, viewport), "%s action %s is in bounds at %s rect=%s" % [surface, text, viewport, rect])
			require(main.get_combined_minimum_size().x <= viewport.x + 1.0 and main.get_combined_minimum_size().y <= viewport.y + 1.0, "%s root minimum fits %s" % [surface, viewport])
			if surface == "onboarding":
				var confirm := main.find_child("StarterPager", true, false) as Control
				if viewport.y > viewport.x: require(confirm != null and _bottom_in_bounds(confirm, viewport), "portrait onboarding pager fits")
			if surface == "unified_library":
				main.unified_inspector_id = "cinderpaw"
				main.render()
				await get_tree().process_frame
				var modal := main.find_child("UnifiedCardInspector", true, false) as Control
				require(modal != null and modal.get_global_rect().position.is_equal_approx(Vector2.ZERO) and modal.get_global_rect().size.is_equal_approx(viewport), "library inspector covers viewport at %s" % viewport)
			if surface == "unified_market":
				var reveal := main.find_child("UnifiedPackReveal", true, false) as Control
				require(reveal != null and not _has_scroll(reveal) and reveal.get_global_rect().position.is_equal_approx(Vector2.ZERO) and reveal.get_global_rect().size.is_equal_approx(viewport), "market pack reveal covers viewport without scrolling at %s" % viewport)
			main.queue_free()
			await get_tree().process_frame
			subviewport.queue_free()
			await get_tree().process_frame
	if failures.is_empty(): print("PASS: shipped unified 125% layout matrix")
	get_tree().quit(0 if failures.is_empty() else 1)
