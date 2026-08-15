class_name WorkshopLiveSequence
extends RefCounted
## Integer-only, presentation-only loop for the empty v3 overview printer bench.

const PRINTING := "printing"
const RAW_HOLD := "raw_hold"
const AWAKENING := "awakening"
const DEPARTING := "departing"
const CYCLE_BPS := 16000
const PRINT_BPS := 10000 # ten seconds at 1,000 BPS per second
const RAW_HOLD_BPS := 3000
const AWAKEN_BPS := 2000
const DEPART_BPS := 1000

var cycle_bps := 0
var creature_index := 0
var seed := 1

static func create(initial_seed := 1) -> WorkshopLiveSequence:
	var value := WorkshopLiveSequence.new()
	value.seed = maxi(0, initial_seed)
	return value

func set_capture_progress(value_bps: int) -> void:
	cycle_bps = clampi(value_bps, 0, CYCLE_BPS - 1)

func advance(step_bps: int, creature_count: int) -> void:
	if step_bps <= 0 or creature_count <= 0:
		return
	cycle_bps += step_bps
	while cycle_bps >= CYCLE_BPS:
		cycle_bps -= CYCLE_BPS
		creature_index = (creature_index + 1) % creature_count

func phase() -> String:
	if cycle_bps < PRINT_BPS:
		return PRINTING
	if cycle_bps < PRINT_BPS + RAW_HOLD_BPS:
		return RAW_HOLD
	if cycle_bps < PRINT_BPS + RAW_HOLD_BPS + AWAKEN_BPS:
		return AWAKENING
	return DEPARTING

func phase_progress_bps() -> int:
	match phase():
		PRINTING: return int((cycle_bps * 10000) / PRINT_BPS)
		RAW_HOLD: return int(((cycle_bps - PRINT_BPS) * 10000) / RAW_HOLD_BPS)
		AWAKENING: return int(((cycle_bps - PRINT_BPS - RAW_HOLD_BPS) * 10000) / AWAKEN_BPS)
		DEPARTING: return int(((cycle_bps - PRINT_BPS - RAW_HOLD_BPS - AWAKEN_BPS) * 10000) / DEPART_BPS)
	return 0

func selected_index(creature_count: int) -> int:
	if creature_count <= 0:
		return -1
	return (seed + creature_index) % creature_count

func printer_frame_index(reduced_motion: bool) -> int:
	if reduced_motion or phase() != PRINTING:
		return 0
	var pattern := [0, 1, 2, 3, 2, 1]
	# 400 bps per still gives the head a readable left-to-right ping-pong.
	var pattern_index: int = int((cycle_bps / 400) % pattern.size())
	return int(pattern[pattern_index])
