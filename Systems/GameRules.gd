class_name GameRules

## Single source for MVP economy / limits so gameplay and unit tests stay aligned.

const SHOP_OFFER_COUNT := 5
## Stage 1 MVP: only the first N entries in `units.json` participate in shop random offers and enemy pulls (expand in Stage 2).
const MVP_ACTIVE_UNIT_COUNT := 20
const TEAM_MAX_UNITS := 3
const NEW_SAVE_STARTING_COINS := 25
const DEFAULT_FILAMENT_CAP := 3
const FILAMENT_CAP_MAX := 10
const SLICER_UPGRADE_COST_COINS := 25
const BATTLE_WIN_COINS := 40
const BATTLE_LOSS_COINS := 15


static func blueprint_shop_price(tier_level: int, unit_cost: int) -> int:
	return 8 + tier_level * 4 + unit_cost


## Returns up to [param max_offers] distinct blueprint ids from [param roster]. Never duplicates an id.
static func pick_shop_offer_unit_ids(rng: RandomNumberGenerator, roster: Array[Dictionary], max_offers: int) -> Array[String]:
	var ids: Array[String] = []
	if roster.is_empty() or max_offers <= 0:
		return ids
	var attempts := 0
	const MAX_ATTEMPTS := 600
	while ids.size() < max_offers and attempts < MAX_ATTEMPTS:
		attempts += 1
		var pick: Dictionary = roster[rng.randi_range(0, roster.size() - 1)]
		var id: String = str(pick.get("id", ""))
		if id != "" and not ids.has(id):
			ids.append(id)
	return ids


static func can_add_team_member(team_size: int) -> bool:
	return team_size >= 0 and team_size < TEAM_MAX_UNITS


static func can_enter_battle(starter_chosen: bool, active_team_count: int) -> bool:
	return starter_chosen and active_team_count > 0
