extends Node

## Reusable source/export resource probe. The tracked script is copied by the
## runner into an extracted compiled package; it never supplies game content.
const CATALOG := preload("res://scripts/core/v3_catalog.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const CATALOG_IMPRINT := preload("res://scripts/ui/physical_catalog_imprint.gd")
const SUPPORT_CARD_VIEW := preload("res://scripts/ui/support_card_view.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	var errors: Array[String] = CATALOG.validation_errors()
	require(errors.is_empty(), "Catalog validation is clean: %s" % JSON.stringify(errors))
	var cards: Array = CATALOG.cards()
	require(cards.size() == 57, "Catalog exposes exactly 57 cards, got %d." % cards.size())
	var counts := {"creature":0, "equipment":0, "filament":0, "spell":0, "trap":0, "upgrade":0}
	var ids := {}
	var card_back := SUPPORT_CARD_VIEW.card_back_for_test()
	for card_variant in cards:
		var card: Dictionary = card_variant if card_variant is Dictionary else {}
		var id := str(card.get("id", ""))
		var kind := str(card.get("type", ""))
		require(not id.is_empty() and not ids.has(id), "Catalog ID is stable and unique: %s." % id)
		ids[id] = true
		if counts.has(kind):
			counts[kind] = int(counts[kind]) + 1
		else:
			require(false, "Catalog has only supported type keys, got %s for %s." % [kind, id])
		var front: Texture2D = CARD_VIEW.art_for_definition(card)
		require(front != null and front != card_back, "%s resolves a face-up front instead of the concealed card back." % id)
		if kind == "creature":
			require(not CATALOG_IMPRINT.is_neutral_placeholder(front), "%s resolves its approved non-neutral creature blueprint." % id)
		else:
			var art: Dictionary = card.get("art", {}) if card.get("art", {}) is Dictionary else {}
			var direct_path := str(art.get("path", ""))
			if not direct_path.is_empty():
				require(ResourceLoader.exists(direct_path) and ResourceLoader.load(direct_path) != null, "%s direct front is loadable by exported-resource semantics." % id)
	require(counts == {"creature":24, "equipment":11, "filament":4, "spell":6, "trap":4, "upgrade":8}, "Catalog type ledger is 24/11/4/6/4/8, got %s." % JSON.stringify(counts))
	require(ids.has("filament_ring"), "Catalog contains Filament Ring.")
	if failures.is_empty():
		print("PASS: catalog export probe exposes 57 face-up cards with the 24/11/4/6/4/8 type ledger")
	get_tree().quit(0 if failures.is_empty() else 1)
