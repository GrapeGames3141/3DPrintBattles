class_name OpponentRules
extends RefCounted
## Offline contract generation. Every decision is driven by catalog data and a
## stable day hash so saved daily snapshots are reproducible and inspectable.

const CONTRACTS := [
	{"id":"apprentice_spar","name":"Apprentice Spar","difficulty":"Apprentice","ratio":92,"reward":{"coins":15,"xp":20},"deck":"balanced","tag":"Measured","score":{"reuse":18,"coverage":0,"synergy":0,"advantage":18,"offense":190,"rating":90}},
	{"id":"element_circuit","name":"Element Circuit","difficulty":"Craftsman","ratio":100,"reward":{"coins":20,"xp":30},"deck":"control","tag":"Elemental","score":{"reuse":18,"coverage":250,"synergy":0,"advantage":900,"offense":200,"rating":90}},
	{"id":"masterwork_challenge","name":"Masterwork Challenge","difficulty":"Master","ratio":108,"reward":{"coins":30,"xp":40},"deck":"pressure","tag":"Masterwork","score":{"reuse":18,"coverage":90,"synergy":160,"advantage":1500,"offense":75,"rating":40}}
]
const DECKS := {
	"balanced":["raw_filament","raw_filament","heated_spool","quick_patch","quick_patch","reinforced_layer","reinforced_layer","arcane_spark","arcane_spark","windup","coolant","calibration","switchback","spark_guard","print_preview"],
	"guard":["raw_filament","heated_spool","quick_patch","quick_patch","coolant","coolant","reinforced_layer","reinforced_layer","dense_infill","safety_brace","repair_drone","spark_guard","resin_wash","calibration","anchor_bolt"],
	"control":["raw_filament","heated_spool","calibration","forge_map","overclock","arcane_spark","switchback","filament_snare","filament_snare","layer_lock","tempered_edge","spool_siphon","windup","final_pass","coolant"],
	"pressure":["raw_filament","heated_spool","overclock","overclock","arcane_spark","arcane_spark","windup","windup","tempered_edge","tempered_edge","final_pass","filament_snare","print_accelerant","calibration","spark_guard"]
}
const BANDS := [["common"],["common","uncommon"],["uncommon","rare","epic"],["rare","epic","legendary","mythic","prismatic"],["epic","legendary","mythic","prismatic","primordial"]]

## Each daily contract reads the same explicit tuning vocabulary.  This keeps
## difficulty decisions inspectable and prevents a collection of one-off
## conditionals from quietly drifting apart as the roster grows.
## counter: none, periodic_one, max_one, at_least_one.
## rating_edge: lower, nearest, upper (inside the published +/-5% window).
## cores: none, first, all.  fallback_suit is only used when the primary
## equipment tier cannot produce a rating-eligible team; metadata still calls
## that a closest legal fallback so the UI never claims a false target hit.
const BAND_POLICIES := {
	"apprentice_spar": [
		{"suit":"", "cores":"none", "counter":"max_one", "rating_edge":"lower", "candidate_mode":"lowest_rating_legal", "offense":-2, "rival_spool_bonus":0, "rival_starting_filament":3},
		{"suit":"standard", "cores":"none", "counter":"periodic_one", "counter_period":4, "rating_edge":"lower", "offense":-1, "rival_spool_bonus":0, "rival_starting_filament":4},
		{"suit":"reinforced", "cores":"first", "counter":"max_one", "rating_edge":"upper", "offense":1, "rival_spool_bonus":1, "rival_starting_filament":5},
		{"suit":"arcane", "cores":"first", "counter":"max_one", "rating_edge":"upper", "offense":1, "rival_spool_bonus":2, "rival_starting_filament":6},
		{"suit":"legendary", "alternate_suit":"masterwork", "alternate_period":5, "alternate_count":2, "cores":"all", "counter":"periodic_one", "counter_period":1, "rating_edge":"upper", "offense":2, "deck":"pressure", "rival_spool_bonus":7, "rival_starting_filament":10}
	],
	"element_circuit": [
		{"suit":"", "cores":"none", "counter":"none", "rating_edge":"lower", "offense":0, "deck":"pressure", "rival_spool_bonus":1, "rival_starting_filament":4},
		{"suit":"standard", "cores":"none", "counter":"max_one", "alternate_counter":"at_least_one", "alternate_counter_day_index":true, "alternate_period":5, "alternate_count":1, "rating_edge":"nearest", "offense":1, "deck":"pressure", "rival_spool_bonus":5, "rival_starting_filament":10},
		{"suit":"masterwork", "cores":"all", "counter":"max_one", "alternate_counter":"at_least_one", "alternate_counter_day_index":true, "alternate_period":5, "alternate_count":1, "rating_edge":"lower", "offense":0, "deck":"pressure", "rival_spool_bonus":4, "rival_starting_filament":10},
		{"suit":"arcane", "cores":"all", "counter":"at_least_one", "rating_edge":"upper", "offense":1, "rival_spool_bonus":4, "rival_starting_filament":10},
		{"suit":"legendary", "alternate_suit":"masterwork", "alternate_period":5, "alternate_count":1, "cores":"all", "counter":"max_counters", "rating_edge":"upper", "offense":3, "deck":"pressure", "diversity":"distinct", "opening_order":"offense", "rival_spool_bonus":5, "rival_starting_filament":10}
	],
	"masterwork_challenge": [
		{"suit":"standard", "cores":"none", "counter":"at_least_one", "alternate_counter":"max_one", "alternate_period":5, "alternate_count":2, "rating_edge":"nearest", "offense":1, "rival_spool_bonus":6, "rival_starting_filament":10},
		{"suit":"masterwork", "cores":"all", "counter":"max_one", "rating_edge":"nearest", "offense":1, "rival_spool_bonus":3, "rival_starting_filament":8},
		{"suit":"reinforced", "cores":"all", "counter":"at_least_one", "rating_edge":"upper", "offense":1, "rival_spool_bonus":2, "rival_starting_filament":7},
		{"suit":"legendary", "cores":"all", "counter":"at_least_one", "rating_edge":"upper", "offense":3, "diversity":"distinct", "rival_spool_bonus":5, "rival_starting_filament":10},
		{"suit":"legendary", "cores":"all", "counter":"at_least_one", "rating_edge":"upper", "offense":2, "deck":"pressure", "diversity":"distinct", "opening_order":"offense", "tactics":"overdrive", "rival_spool_bonus":2, "rival_starting_filament":10}
	]
}

static func ensure_fields(source: Dictionary) -> Dictionary:
	var p := source.duplicate(true)
	if not p.has("daily_training") or not (p.get("daily_training") is Dictionary): p["daily_training"] = {}
	var daily: Dictionary = p["daily_training"]
	if not (daily.get("contracts", []) is Array): daily["contracts"] = []
	if not (daily.get("claimed_ids", []) is Array): daily["claimed_ids"] = []
	if not daily.has("day_key"): daily["day_key"] = ""
	p["daily_training"] = daily
	return p

static func prepare_daily(source: Dictionary, day_key: String, player_loadout: Array, player_deck: Array = []) -> Dictionary:
	var p := ensure_fields(source)
	if not _valid_day(day_key): return {"ok":false,"profile":p,"error":"Daily Training needs a valid calendar day."}
	var daily: Dictionary = p["daily_training"]
	if str(daily.get("day_key", "")) == day_key and not daily.get("contracts", []).is_empty(): return {"ok":true,"profile":p,"contracts":daily["contracts"],"frozen":true}
	var band := progression_band(p)
	var size := clampi(player_loadout.size(), 1, 3)
	var player_rating := rating_for_team(player_loadout, player_deck)
	var elements := _elements(player_loadout)
	var used := {}
	var prior_lineups: Array = []
	var built: Array = []
	for index in CONTRACTS.size():
		var definition: Dictionary = CONTRACTS[index]
		var contract_id := str(definition.id)
		var policy := policy_for_day(contract_id, band, day_key)
		var target: int = maxi(1, (player_rating * int(definition.ratio)) / 100)
		# Circuit stays close to its published 100% rating; its favorable element
		# coverage and focused Craftsman policy supply the challenge, not an
		# inflated hidden ratio.
		var selection_target: int = target
		var deck_id := str(policy.get("deck", definition.deck))
		var build := _best_team(day_key, contract_id, index, band, size, selection_target, elements, used, prior_lineups, deck_id, policy)
		var team: Array = build.get("team", [])
		for entry in team: used[_creature_id(entry)] = true
		prior_lineups.append(_ids_key(team))
		var actual := rating_for_team(team, deck(deck_id))
		var within_target: bool = absi(actual - target) * 100 <= target * 5
		var spool := clampi(2 + band + index, 3, 10)
		# Policy resources are visible frozen rival loadout properties, not hidden
		# combat multipliers. The launch factory applies starting filament exactly.
		var rival_spool := mini(10, spool + int(policy.get("rival_spool_bonus", 0)))
		var rival_starting_filament := clampi(int(policy.get("rival_starting_filament", 3)), 3, rival_spool)
		var equipment_reason := str(build.get("equipment_reason", "policy_primary"))
		built.append({"id":contract_id,"day_key":day_key,"name":str(definition.name),"difficulty":str(definition.difficulty),"team":team,"deck":deck(deck_id),"deck_role":deck_id,"tactics":str(policy.get("tactics", "")),"spool":spool,"rival_spool":rival_spool,"rival_starting_filament":rival_starting_filament,"rating":actual,"target_rating":target,"within_target":within_target,"rating_fallback":"within_5_percent" if within_target else "closest_legal","equipment_reason":equipment_reason,"policy":policy,"reward":definition.reward.duplicate(true),"tag":str(definition.tag),"band":band,"player_rating":player_rating,"team_size":size,"elements":elements})
	p["daily_training"] = {"day_key":day_key,"band":band,"player_rating":player_rating,"team_size":size,"elements":elements,"contracts":built,"claimed_ids":[]}
	return {"ok":true,"profile":p,"contracts":built,"frozen":false}

static func contracts(source: Dictionary) -> Array:
	return ensure_fields(source).get("daily_training", {}).get("contracts", []).duplicate(true)

static func claim_victory(source: Dictionary, contract_id: String, day_key: String) -> Dictionary:
	var p := ensure_fields(source); var daily: Dictionary = p["daily_training"]
	if str(daily.get("day_key", "")) != day_key: return {"ok":false,"profile":p,"error":"That training contract is from another day."}
	var contract: Dictionary = {}
	for raw in daily.get("contracts", []):
		if str(raw.get("id", "")) == contract_id: contract = raw; break
	if contract.is_empty(): return {"ok":false,"profile":p,"error":"That training contract is unavailable."}
	if contract_id in daily["claimed_ids"]: return {"ok":true,"profile":p,"payload":{"contract_id":contract_id,"reward":{"coins":0,"xp":0},"first_clear":false}}
	var reward: Dictionary = contract.get("reward", {})
	p["coins"] = int(p.get("coins", 0)) + int(reward.get("coins", 0))
	var xp_result: Dictionary = ProgressionRules.grant_xp(p, int(reward.get("xp", 0)))
	p = xp_result["profile"]; daily = p["daily_training"]; daily["claimed_ids"].append(contract_id); p["daily_training"] = daily
	return {"ok":true,"profile":p,"payload":{"contract_id":contract_id,"reward":reward,"first_clear":true,"spool_gained":int(xp_result.get("payload", {}).get("spool_gained", 0))}}

static func progression_band(profile: Dictionary) -> int:
	var campaign: Dictionary = profile.get("solo_campaign", {}) if profile.get("solo_campaign", {}) is Dictionary else {}
	return clampi(maxi(int(campaign.get("unlocked_tier", 1)), ceili(float(int(profile.get("spool_level", 3))) / 2.0)), 1, 5)

static func deck(id: String) -> Array: return Array(DECKS.get(id, DECKS["balanced"])).duplicate()

## Exact rating contract: HP + 3*ATK + 2*SPD + 8*guard + suit bonuses,
## signature damage/effects, Core effect, and floor(deck utility / 3).
static func rating_for_team(team: Array, loadout_deck: Array = []) -> int:
	var total: int = 0
	for raw in team:
		var def: Dictionary = Catalog.creature(_creature_id(raw)); if def.is_empty(): continue
		var suit: Dictionary = ArmorCoreDefinitions.suit_definition(str(raw.get("suit_id", ""))) if raw is Dictionary else {}
		var core := str(raw.get("core_id", "")) if raw is Dictionary else ""
		var signature: Dictionary = Catalog.signature_for_creature(str(def.get("id", "")))
		total += int(def.get("hp", 0)) + int(def.get("attack", 0)) * 3 + int(def.get("speed", 0)) * 2
		total += int(suit.get("hp", 0)) + int(suit.get("armor", 0)) * 8 + int(suit.get("speed", 0)) * 2
		total += int(signature.get("damage_bonus", 0)) * 2 + _effect_value(signature.get("effects", []))
		total += {"ember":8,"tide":7,"verdant":7,"storm":3,"arcane":6}.get(core, 0)
	return maxi(1, total + deck_rating(loadout_deck))

static func deck_rating(cards: Array) -> int:
	var total := 0
	for card_id in cards:
		var card := Catalog.support_card(str(card_id)); if card.is_empty(): continue
		total += _effect_value(card.get("effects", [])) + int(card.get("cost", 0))
	# A 15-card deck is tactical support, not fifteen extra combatants. Divide
	# standardized utility so creature/loadout strength remains the rating anchor.
	return total / 3

static func _best_team(day_key: String, contract_id: String, contract_index: int, band: int, size: int, target: int, player_elements: Array, used: Dictionary, prior_lineups: Array, deck_id: String, policy: Dictionary) -> Dictionary:
	var pool := _pool(band); var seed := _hash(day_key + "|" + contract_id)
	var candidates := _all_candidates(pool, size, policy)
	var equipment_reason := "policy_primary"
	var in_range: Array = []
	for candidate in candidates:
		var actual := rating_for_team(candidate, deck(deck_id))
		if absi(actual - target) * 100 <= target * 5: in_range.append(candidate)
	if in_range.is_empty() and policy.has("fallback_suit"):
		var fallback_policy := policy.duplicate(true)
		fallback_policy["suit"] = str(policy.fallback_suit)
		candidates = _all_candidates(pool, size, fallback_policy)
		for candidate in candidates:
			var actual := rating_for_team(candidate, deck(deck_id))
			if absi(actual - target) * 100 <= target * 5: in_range.append(candidate)
		equipment_reason = "fallback_suit_rating_eligible" if not in_range.is_empty() else "fallback_suit_closest_legal"
	# Rating eligibility is a hard first pass. Contract traits are primary;
	# cross-contract reuse is a small diversity tie-breaker, never a veto.
	var candidate_mode := str(policy.get("candidate_mode", "rating_eligible"))
	var choices: Array = in_range if not in_range.is_empty() else candidates
	var forced_lowest_legal := false
	if candidate_mode == "lowest_rating_legal":
		# B1 Apprentice may deliberately choose an under-target legal print. This
		# explicit policy keeps the novice recover-first AI approachable when its
		# lowest catalog options fall outside the normal +/-5% rating window.
		var below_target: Array = []
		var lower_window := (target * 95) / 100
		for candidate in candidates:
			if rating_for_team(candidate, deck(deck_id)) < lower_window: below_target.append(candidate)
		if not below_target.is_empty():
			choices = below_target
			forced_lowest_legal = true
	choices = _filter_counter_policy(choices, policy, seed, player_elements)
	# Daily contracts should present distinct rival squads, not three versions of
	# the same print roster. Rating/counter policy remains the first pass; among
	# those legal candidates, reject an exact repeat and prefer no more than one
	# shared creature with every already-frozen three-unit lineup. If the rating
	# window has no diverse legal option, broaden only to policy-legal candidates;
	# the caller records that honest closest-legal rating result on the contract.
	var diversity_mode := str(policy.get("diversity", "low_overlap"))
	var diverse: Array = _diverse_candidates(choices, prior_lineups, size, diversity_mode)
	if diverse.is_empty() and not choices.is_empty():
		diverse = choices
	if diverse.is_empty() or _contains_lineup_key(diverse, prior_lineups):
		var broader := _filter_counter_policy(candidates, policy, seed, player_elements)
		var broader_diverse := _diverse_candidates(broader, prior_lineups, size, diversity_mode)
		if not broader_diverse.is_empty():
			diverse = broader_diverse
			forced_lowest_legal = false
	choices = diverse
	var ranked: Array = []
	for candidate in choices:
		var actual := rating_for_team(candidate, deck(deck_id))
		var weights: Dictionary = CONTRACTS[contract_index].get("score", {})
		var score := _reuse_count(candidate, used) * int(weights.get("reuse", 18))
		score += _lineup_diversity_penalty(candidate, prior_lineups, size)
		if in_range.is_empty() and candidate_mode != "lowest_rating_legal": score += absi(actual - target) * 10000
		if forced_lowest_legal: score += actual * 1000 + _offense_score(candidate) * 100
		# Per-band offense is an explicit candidate-policy lever, not a dead
		# annotation: positive values favor punchier squads; negative values favor
		# lower-pressure training rivals.
		score -= _offense_score(candidate) * int(policy.get("offense", 0))
		score += _rating_edge_penalty(actual, target, str(policy.get("rating_edge", "nearest")), int(weights.get("rating", 90)))
		var counter_count := _advantaged_unit_count(candidate, player_elements)
		var counter_mode := str(policy.get("counter", "max_one"))
		if counter_mode in ["none", "max_one"]: score += counter_count * int(weights.get("advantage", 0))
		elif counter_mode in ["at_least_one", "max_counters"]: score -= counter_count * int(weights.get("advantage", 0))
		score -= _coverage_score(candidate) * int(weights.get("coverage", 0))
		score -= _synergy_score(candidate) * int(weights.get("synergy", 0))
		score -= _offense_score(candidate) * int(weights.get("offense", 0))
		ranked.append({"team":candidate,"score":score,"key":_ids_key(candidate)})
	ranked.sort_custom(func(a, b): return int(a.score) < int(b.score) or (int(a.score) == int(b.score) and str(a.key) < str(b.key)))
	if ranked.is_empty(): return {"team":[], "equipment_reason":equipment_reason}
	# Rotate through a compact, equivalent-quality cohort. This makes each
	# contract feel daily while retaining rating and contract-trait guarantees.
	if str(policy.get("selection", "rotate")) == "best":
		var best_team: Array = ranked[0].team
		return {"team":_ordered_team(best_team, contract_index, player_elements, policy), "equipment_reason":equipment_reason}
	var cutoff := int(ranked[0].score) + 240
	var cohort: Array = []
	for entry in ranked:
		if cohort.size() >= (20 if contract_index == 0 else 8) or int(entry.score) > cutoff: break
		cohort.append(entry)
	if cohort.is_empty(): cohort.append(ranked[0])
	var selected: Array = cohort[posmod(seed, cohort.size())].team
	return {"team":_ordered_team(selected, contract_index, player_elements, policy), "equipment_reason":equipment_reason}

static func _ordered_team(team: Array, contract_index: int, player_elements: Array, policy: Dictionary) -> Array:
	if contract_index == 0: return _order_apprentice_team(team, player_elements)
	if str(policy.get("opening_order", "")) != "offense": return team
	var ordered := team.duplicate(true)
	ordered.sort_custom(func(a, b):
		var a_def: Dictionary = Catalog.creature(_creature_id(a)); var b_def: Dictionary = Catalog.creature(_creature_id(b))
		var a_score := int(a_def.get("attack", 0)) * 10 + int(Catalog.signature_for_creature(_creature_id(a)).get("damage_bonus", 0))
		var b_score := int(b_def.get("attack", 0)) * 10 + int(Catalog.signature_for_creature(_creature_id(b)).get("damage_bonus", 0))
		return a_score > b_score or (a_score == b_score and _creature_id(a) < _creature_id(b))
	)
	return ordered

static func _diverse_candidates(source: Array, prior_lineups: Array, size: int, diversity_mode := "low_overlap") -> Array:
	if prior_lineups.is_empty(): return source.duplicate()
	var distinct: Array = []
	for candidate in source:
		if not (_ids_key(candidate) in prior_lineups): distinct.append(candidate)
	if distinct.is_empty(): return []
	if size < 3 or diversity_mode == "distinct": return distinct
	var low_overlap: Array = []
	for candidate in distinct:
		var acceptable := true
		for prior_key in prior_lineups:
			if _lineup_overlap(candidate, str(prior_key)) > 1:
				acceptable = false
				break
		if acceptable: low_overlap.append(candidate)
	return low_overlap if not low_overlap.is_empty() else distinct

static func _contains_lineup_key(source: Array, prior_lineups: Array) -> bool:
	for candidate in source:
		if _ids_key(candidate) in prior_lineups: return true
	return false

static func _lineup_overlap(candidate: Array, prior_key: String) -> int:
	var prior: Dictionary = {}
	for creature_id in prior_key.split(","):
		prior[str(creature_id)] = true
	var overlap := 0
	for entry in candidate:
		if prior.has(_creature_id(entry)): overlap += 1
	return overlap

static func _lineup_diversity_penalty(candidate: Array, prior_lineups: Array, size: int) -> int:
	var penalty := 0
	for prior_key in prior_lineups:
		var overlap := _lineup_overlap(candidate, str(prior_key))
		# An exact duplicate was filtered above. For three-unit teams, two shared
		# prints remain expensive when no <=1-overlap candidate is legal.
		if size >= 3: penalty += maxi(0, overlap - 1) * 1400
		else: penalty += overlap * 160
	return penalty

static func policy_for(contract_id: String, band: int) -> Dictionary:
	var entries: Array = BAND_POLICIES.get(contract_id, BAND_POLICIES["apprentice_spar"])
	return Dictionary(entries[clampi(band, 1, 5) - 1]).duplicate(true)

static func policy_for_day(contract_id: String, band: int, day_key: String) -> Dictionary:
	var result := policy_for(contract_id, band)
	var suit_alternate := posmod(_hash(day_key + "|" + contract_id + "|equipment"), maxi(1, int(result.get("alternate_period", 5)))) < int(result.get("alternate_count", 0))
	var counter_alternate := posmod(int(day_key.substr(8, 2)), maxi(1, int(result.get("alternate_period", 5)))) < int(result.get("alternate_count", 0)) if bool(result.get("alternate_counter_day_index", false)) else posmod(_hash(day_key + "|" + contract_id + "|counter"), maxi(1, int(result.get("alternate_period", 5)))) < int(result.get("alternate_count", 0))
	if result.has("alternate_suit") and suit_alternate:
		result["suit"] = str(result.get("alternate_suit", result.get("suit", "")))
		result["equipment_cycle"] = "alternate_suit"
	else:
		result["equipment_cycle"] = "primary_suit"
	if result.has("alternate_counter") and counter_alternate:
		result["counter"] = str(result.get("alternate_counter", result.get("counter", "max_one")))
		result["counter_cycle"] = "alternate_counter"
	else:
		result["counter_cycle"] = "primary_counter"
	var deck_alternate := posmod(_hash(day_key + "|" + contract_id + "|deck"), maxi(1, int(result.get("deck_alternate_period", 5)))) < int(result.get("deck_alternate_count", 0))
	if result.has("alternate_deck") and deck_alternate:
		result["deck"] = str(result.get("alternate_deck", result.get("deck", "balanced")))
		result["deck_cycle"] = "alternate_deck"
	else:
		result["deck_cycle"] = "primary_deck"
	return result

static func _filter_counter_policy(source: Array, policy: Dictionary, seed: int, player_elements: Array) -> Array:
	if source.is_empty(): return source
	var mode := str(policy.get("counter", "max_one"))
	var wanted := mode
	if mode == "periodic_one": wanted = "exact_one" if posmod(seed, maxi(1, int(policy.get("counter_period", 2)))) == 0 else "none"
	var filtered: Array = []
	for candidate in source:
		var count := _advantaged_unit_count(candidate, player_elements)
		if (wanted == "none" and count == 0) or (wanted == "exact_one" and count == 1) or (wanted == "max_one" and count <= 1) or (wanted == "at_least_one" and count >= 1): filtered.append(candidate)
	if wanted == "max_counters":
		var maximum := -1
		for candidate in source: maximum = maxi(maximum, _advantaged_unit_count(candidate, player_elements))
		for candidate in source:
			if _advantaged_unit_count(candidate, player_elements) == maximum: filtered.append(candidate)
	if not filtered.is_empty(): return filtered
	# Small catalog bands can lack a requested element.  Preserve legal/rating
	# requirements and choose the closest available counter count deterministically.
	var best_distance := 999
	for candidate in source:
		var count := _advantaged_unit_count(candidate, player_elements)
		var ideal := 1 if wanted in ["exact_one", "at_least_one", "max_counters"] else 0
		best_distance = mini(best_distance, absi(count - ideal))
	for candidate in source:
		var count := _advantaged_unit_count(candidate, player_elements)
		var ideal := 1 if wanted in ["exact_one", "at_least_one", "max_counters"] else 0
		if absi(count - ideal) == best_distance: filtered.append(candidate)
	return filtered

static func _rating_edge_penalty(actual: int, target: int, edge: String, weight: int) -> int:
	match edge:
		"lower": return (actual - target) * weight
		"upper": return (target - actual) * weight
		_: return absi(actual - target) * weight

static func _order_apprentice_team(team: Array, player_elements: Array) -> Array:
	var ordered: Array = team.duplicate(true)
	if ordered.size() < 2: return ordered
	var best_index := 0; var best_score := -999999
	var first_element := str(player_elements[0]) if not player_elements.is_empty() else ""
	for index in ordered.size():
		var def := Catalog.creature(_creature_id(ordered[index]))
		var signature := Catalog.signature_for_creature(str(def.get("id", "")))
		var score := int(def.get("attack", 0)) * 10 + int(signature.get("damage_bonus", 0)) * 10
		if not first_element.is_empty() and Catalog.element_multiplier(str(def.get("element", "")), first_element) >= 150: score += 10000
		if score > best_score: best_score = score; best_index = index
	if best_index > 0:
		var opener = ordered.pop_at(best_index); ordered.push_front(opener)
	return ordered

static func _pool(band: int) -> Array:
	var pool: Array = []
	for def in Catalog.CREATURES:
		if str(def.get("rarity", "")) in BANDS[band - 1]: pool.append(def.duplicate(true))
	pool.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	return pool
static func _candidate(pool: Array, start: int, stride: int, size: int, policy: Dictionary) -> Array:
	var result: Array = []
	for step in pool.size():
		var def: Dictionary = pool[(start + step * stride) % pool.size()]
		if _contains_id(result, str(def.get("id", ""))): continue
		result.append(_loadout_entry(str(def.get("id", "")), policy, result.size()))
		if result.size() == size: break
	return result
static func _all_candidates(pool: Array, size: int, policy: Dictionary) -> Array:
	var result: Array = []
	for first in pool.size():
		if size == 1:
			result.append([_loadout_entry(str(pool[first].get("id", "")), policy, 0)])
			continue
		for second in range(first + 1, pool.size()):
			if size == 2:
				result.append([_loadout_entry(str(pool[first].get("id", "")), policy, 0), _loadout_entry(str(pool[second].get("id", "")), policy, 1)])
				continue
			for third in range(second + 1, pool.size()):
				result.append([_loadout_entry(str(pool[first].get("id", "")), policy, 0), _loadout_entry(str(pool[second].get("id", "")), policy, 1), _loadout_entry(str(pool[third].get("id", "")), policy, 2)])
	return result
static func _ids_key(team: Array) -> String:
	var ids: Array[String] = []; for entry in team: ids.append(_creature_id(entry))
	ids.sort()
	return ",".join(ids)
static func _loadout_entry(creature_id: String, policy: Dictionary, index: int) -> Dictionary:
	var suit := str(policy.get("suit", ""))
	var core := ""
	var core_coverage := str(policy.get("cores", "none"))
	if core_coverage == "all" or (core_coverage == "first" and index == 0): core = core_for(str(Catalog.creature(creature_id).get("element", "")))
	return {"creature_id":creature_id,"suit_id":suit,"core_id":core}

static func core_for(element: String) -> String:
	return {"Fire":"ember","Water":"tide","Ice":"tide","Nature":"verdant","Stone":"verdant","Lightning":"storm","Wind":"storm","Arcane":"arcane"}.get(element, "arcane")
static func _elements(team: Array) -> Array:
	var result: Array = []; for entry in team:
		var def := Catalog.creature(_creature_id(entry)); if not def.is_empty(): result.append(str(def.get("element", "")))
	return result
static func _effect_value(effects: Array) -> int:
	var total := 0
	for raw in effects:
		if raw is Dictionary: total += maxi(1, int(raw.get("amount", 0)))
	return total
static func _reuse_count(team: Array, used: Dictionary) -> int:
	var count := 0; for entry in team: if used.has(_creature_id(entry)): count += 1
	return count
static func _advantage_count(team: Array, elements: Array) -> int:
	var count := 0; for entry in team: for element in elements: if Catalog.element_multiplier(str(Catalog.creature(_creature_id(entry)).get("element", "")), str(element)) >= 150: count += 1
	return count
static func _advantaged_unit_count(team: Array, elements: Array) -> int:
	var count := 0
	for entry in team:
		for element in elements:
			if Catalog.element_multiplier(str(Catalog.creature(_creature_id(entry)).get("element", "")), str(element)) >= 150:
				count += 1
				break
	return count
static func _favorable_count(team: Array, elements: Array) -> int: return _advantage_count(team, elements)
static func _coverage_score(team: Array) -> int:
	var values: Dictionary = {}
	for entry in team: values[str(Catalog.creature(_creature_id(entry)).get("element", ""))] = true
	return values.size()
static func _synergy_score(team: Array) -> int:
	var score := 0
	var elements: Dictionary = {}
	for entry in team:
		elements[str(Catalog.creature(_creature_id(entry)).get("element", ""))] = true
		if not str(entry.get("core_id", "")).is_empty(): score += 2
		if str(entry.get("core_id", "")) == core_for(str(Catalog.creature(_creature_id(entry)).get("element", ""))): score += 3
	return score + elements.size() * 2
static func _offense_score(team: Array) -> int:
	var score := 0
	for entry in team:
		var def := Catalog.creature(_creature_id(entry))
		score += int(def.get("attack", 0)) + int(Catalog.signature_for_creature(str(def.get("id", ""))).get("damage_bonus", 0))
	return score
static func _sustain_score(team: Array) -> int:
	var score := 0
	for entry in team:
		var def := Catalog.creature(_creature_id(entry)); score += int(def.get("hp", 0)) / 8
		for effect in Catalog.signature_for_creature(str(def.get("id", ""))).get("effects", []):
			if effect is Dictionary and str(effect.get("effect", "")) in ["heal", "shield"]: score += int(effect.get("amount", 0))
	return score
static func _creature_id(raw) -> String: return str(raw.get("creature_id", raw.get("id", ""))) if raw is Dictionary else str(raw)
static func _contains_id(team: Array, id: String) -> bool:
	for entry in team:
		if _creature_id(entry) == id: return true
	return false
static func _hash(text: String) -> int:
	var value := 17
	for byte in text.to_utf8_buffer(): value = int((value * 31 + int(byte)) % 2147483647)
	return value
static func _valid_day(day_key: String) -> bool:
	if day_key.length() != 10 or day_key[4] != "-" or day_key[7] != "-": return false
	var year := int(day_key.substr(0, 4)); var month := int(day_key.substr(5, 2)); var day := int(day_key.substr(8, 2))
	if year < 2020 or month < 1 or month > 12 or day < 1: return false
	var limits := [31, 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return day <= int(limits[month - 1])
