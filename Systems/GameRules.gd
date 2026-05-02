class_name GameRules

## Single source for MVP economy / limits so gameplay and unit tests stay aligned.

const SHOP_OFFER_COUNT := 6
## Roster entries 001…N participate in shop draws and enemy summons (`UnitDatabase` pads missing ids to this cap).
const ACTIVE_ROSTER_CAP := 256
const SHOP_REFRESH_SECONDS := 86400
const QUEST_MATH_ADD_COINS := 15
const QUEST_MATH_SUB_COINS := 12
const QUEST_GEOMETRY_COINS := 18
const TEAM_MAX_UNITS := 3
const NEW_SAVE_STARTING_COINS := 25
const DEFAULT_FILAMENT_CAP := 3
const FILAMENT_CAP_MAX := 10
const SLICER_UPGRADE_COST_COINS := 25
const BATTLE_WIN_COINS := 40
const BATTLE_LOSS_COINS := 15


static func blueprint_shop_price(tier_level: int, unit_cost: int) -> int:
	return 8 + tier_level * 4 + unit_cost


## Tier 1 common → tier 8 rare (~few percent vs tier 1) for weighted shop picks.
static func shop_tier_weight(tier_level: int) -> float:
	var tl: int = clampi(tier_level, 1, 8)
	var base: float = 120.0
	var decay: float = 0.62
	return base * pow(decay, float(tl - 1))


static func _weighted_random_unit(rng: RandomNumberGenerator, roster: Array[Dictionary]) -> Dictionary:
	if roster.is_empty():
		return {}
	var total_w: float = 0.0
	var weights: Array[float] = []
	for u in roster:
		var tl: int = int(u.get("tier_level", 1))
		var w: float = shop_tier_weight(tl)
		weights.append(w)
		total_w += w
	var roll: float = rng.randf() * total_w
	var acc: float = 0.0
	for i in roster.size():
		acc += weights[i]
		if roll <= acc:
			return roster[i]
	return roster[roster.size() - 1]


## Returns up to [param max_offers] distinct blueprint ids. Higher [member tier_level] rolls less often.
static func pick_shop_offer_unit_ids(rng: RandomNumberGenerator, roster: Array[Dictionary], max_offers: int) -> Array[String]:
	var ids: Array[String] = []
	if roster.is_empty() or max_offers <= 0:
		return ids
	var attempts := 0
	const MAX_ATTEMPTS := 2000
	while ids.size() < max_offers and attempts < MAX_ATTEMPTS:
		attempts += 1
		var pick: Dictionary = _weighted_random_unit(rng, roster)
		var id: String = str(pick.get("id", ""))
		if id != "" and not ids.has(id):
			ids.append(id)
	return ids


static func can_add_team_member(team_size: int) -> bool:
	return team_size >= 0 and team_size < TEAM_MAX_UNITS


static func can_enter_battle(starter_chosen: bool, active_team_count: int) -> bool:
	return starter_chosen and active_team_count > 0


static func shop_refresh_due(last_refresh_unix: int, now_unix: int) -> bool:
	if last_refresh_unix <= 0:
		return true
	return (now_unix - last_refresh_unix) >= SHOP_REFRESH_SECONDS
