extends Node

## Descriptive deterministic F7 pacing evidence.  A harness limit is an explicit
## failure, never a synthetic battle outcome.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")

var failures: Array[String] = []
var require_count := 0
var completed_groups := 0
const REQUIRED_GROUPS := 1
const MATCH_LIMIT := 500


func require(value: bool, message: String) -> void:
	require_count += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	_test_all_starter_pairings()
	require(completed_groups == REQUIRED_GROUPS, "pacing test group reaches its end marker")
	print("TEAM_BATTLE_PACING groups=%d/%d requires=%d failures=%d" % [completed_groups, REQUIRED_GROUPS, require_count, failures.size()])
	if completed_groups == REQUIRED_GROUPS:
		print("TEAM_BATTLE_PACING failures=%d" % failures.size())
	get_tree().quit(0 if completed_groups == REQUIRED_GROUPS and failures.is_empty() else 1)


func _test_all_starter_pairings() -> void:
	var teams := [
		["cinderpaw", "aquafin", "mossmunk"],
		["aquafin", "voltwig", "mossmunk"],
		["voltwig", "cinderpaw", "mossmunk"],
	]
	var cycles := []
	var first_prints := []
	var first_contacts := []
	var replacements := []
	var first_replacements := []
	var supports := []
	var swaps := []
	var terminal_causes := {}
	var draws := 0
	var completed_matches := 0

	for player_index in range(3):
		for rival_index in range(3):
			for replicate_index in range(5):
				var seed := (player_index * 3 + rival_index) * 5 + replicate_index
				var created := State.create_production(
					teams[player_index],
					teams[rival_index],
					Data.recommended_kit(),
					Data.recommended_kit(),
					seed,
					false
				)
				require(bool(created.get("ok", false)), "pacing factory creates seed %d" % seed)
				if not bool(created.get("ok", false)):
					continue
				var state: Dictionary = created.state
				var steps := 0
				var first_print := -1
				var first_contact := -1
				var replacement_count := 0
				var first_replacement := -1
				var replacement_marks := []
				var support_count := 0
				var swap_count := 0
				var trace_ok := true
				while str(state.result).is_empty() and steps < MATCH_LIMIT:
					var player_view_result := Rules.view_for_seat(state, "player")
					var rival_view_result := Rules.view_for_seat(state, "rival")
					require(bool(player_view_result.get("ok", false)) and bool(rival_view_result.get("ok", false)), "pacing views are checked seed %d cycle %d" % [seed, steps + 1])
					if not bool(player_view_result.get("ok", false)) or not bool(rival_view_result.get("ok", false)):
						trace_ok = false
						break
					var player_choice := Bot.choose_plan(player_view_result.view)
					var rival_choice := Bot.choose_plan(rival_view_result.view)
					require(bool(player_choice.get("ok", false)) and bool(rival_choice.get("ok", false)), "pacing Bot plans are legal previews seed %d cycle %d" % [seed, steps + 1])
					if not bool(player_choice.get("ok", false)) or not bool(rival_choice.get("ok", false)):
						trace_ok = false
						break
					var resolved := Rules.run_cycle(state, player_choice.plan, rival_choice.plan)
					require(bool(resolved.get("ok", false)), "pacing Run resolves seed %d cycle %d" % [seed, steps + 1])
					if not bool(resolved.get("ok", false)):
						trace_ok = false
						break
					steps += 1
					var queue_stage := _stage(resolved.receipt, "Queue")
					var attack_stage := _stage(resolved.receipt, "AttackLock")
					var replace_stage := _stage(resolved.receipt, "Replace")
					var swap_stage := _stage(resolved.receipt, "Swap")
					for event_value in queue_stage.get("events", []):
						var event: Dictionary = event_value
						if str(event.type) == "fabrication_queued" and first_print < 0:
							first_print = steps
						if str(event.type) in ["printer_aid", "support_played", "equipment_queued"]:
							support_count += 1
					for event_value in attack_stage.get("events", []):
						var event: Dictionary = event_value
						if str(event.type) == "attack_locked" and first_contact < 0:
							first_contact = steps
					for event_value in replace_stage.get("events", []):
						var event: Dictionary = event_value
						if str(event.type) == "replacement":
							replacement_count += 1
							if first_replacement < 0:
								first_replacement = steps
							replacement_marks.append("%s:%d" % [str(event.seat), steps])
					swap_count += swap_stage.get("events", []).size()
					state = resolved.state
				require(not trace_ok or not str(state.result).is_empty() or steps < MATCH_LIMIT, "pacing trace remains below the 500-cycle hard failure bound seed %d" % seed)
				if trace_ok and not str(state.result).is_empty():
					completed_matches += 1
					cycles.append(steps)
					first_prints.append(first_print)
					first_contacts.append(first_contact)
					replacements.append(replacement_count)
					first_replacements.append(first_replacement)
					supports.append(support_count)
					swaps.append(swap_count)
					terminal_causes[state.result] = int(terminal_causes.get(state.result, 0)) + 1
					if str(state.result) == "Draw":
						draws += 1
				print("TEAM_BATTLE_PACING match seed=%d pairing=%d-%d cycles=%d result=%s first_print=%d first_contact=%d replacements=%d replacement_cycles=%s supports=%d swaps=%d complete=%s" % [seed, player_index, rival_index, steps, str(state.result), first_print, first_contact, replacement_count, JSON.stringify(replacement_marks), support_count, swap_count, trace_ok and not str(state.result).is_empty()])

	cycles.sort()
	first_prints.sort()
	first_contacts.sort()
	first_replacements.sort()
	require(completed_matches == 45, "all 45 bot matches terminate without harness timeout")
	var median := _nearest_rank(cycles, 0.50)
	var p95 := _nearest_rank(cycles, 0.95)
	var longest: int = int(cycles.back()) if not cycles.is_empty() else -1
	print("TEAM_BATTLE_PACING aggregate matches=%d median=%d p95=%d max=%d first_print_median=%d first_contact_median=%d first_replacement_median=%d replacements=%d supports=%d swaps=%d draws=%d terminal_causes=%s" % [completed_matches, median, p95, longest, _nearest_rank(first_prints, 0.50), _nearest_rank(first_contacts, 0.50), _nearest_rank(first_replacements, 0.50), _sum(replacements), _sum(supports), _sum(swaps), draws, JSON.stringify(terminal_causes)])
	completed_groups += 1


func _stage(receipt: Dictionary, name: String) -> Dictionary:
	for stage_value in receipt.stages:
		var stage: Dictionary = stage_value
		if str(stage.name) == name:
			return stage
	return {}


func _nearest_rank(values: Array, percentile: float) -> int:
	if values.is_empty():
		return -1
	var index := int(ceil(percentile * float(values.size()))) - 1
	return int(values[clamp(index, 0, values.size() - 1)])


func _sum(values: Array) -> int:
	var total := 0
	for value in values:
		total += int(value)
	return total
