class_name ArcaneForgeSequence
extends RefCounted
## Deterministic presentation state only. The caller owns the single profile commit.

const IDLE := "idle"
const PRINTING := "printing"
const RAW_COMPLETE := "raw_complete"
const RAW_HOLD := "raw_hold"
const AWAKENING := "awakening"
const DEPARTING := "departing"
const AWAKENED := "awakened"
const FAILED := "failed"
const CANCELLED := "cancelled"

const PRINT_COMPLETE_BPS := 7000
const RAW_HOLD_BPS := 3000
const AWAKEN_BPS := 2000
const DEPART_BPS := 1000
const FULL_BPS := 10000

var phase := IDLE
var progress_bps := 0
var phase_elapsed_bps := 0
var reduced_motion := false
var commit_requested := false
var resolved := false

static func create(reduce_motion := false) -> ArcaneForgeSequence:
	var sequence := ArcaneForgeSequence.new()
	sequence.reduced_motion = reduce_motion
	return sequence

static func presentation_interval_seconds(reduce_motion: bool) -> float:
	# Normal printing visibly lasts 100 * 0.12 = 12 seconds. Reduced motion
	# preserves the same calm duration without nozzle motion or sparks.
	return 0.60 if reduce_motion else 0.12

static func presentation_step_bps(reduce_motion: bool, active_phase := PRINTING) -> int:
	match active_phase:
		PRINTING: return 350 if reduce_motion else 70
		RAW_HOLD: return 600 if reduce_motion else 120
		AWAKENING: return 400 if reduce_motion else 100
		DEPARTING: return 500 if reduce_motion else 120
	return 350 if reduce_motion else 70

func begin() -> bool:
	if phase != IDLE: return false
	phase = PRINTING
	progress_bps = 0
	phase_elapsed_bps = 0
	return true

func advance(step_bps: int) -> bool:
	if step_bps <= 0 or phase in [IDLE, AWAKENED, FAILED, CANCELLED, RAW_COMPLETE]: return false
	if phase == PRINTING:
		progress_bps = mini(PRINT_COMPLETE_BPS, progress_bps + step_bps)
		if progress_bps >= PRINT_COMPLETE_BPS: phase = RAW_COMPLETE
		return true
	if phase == RAW_HOLD:
		phase_elapsed_bps = mini(RAW_HOLD_BPS, phase_elapsed_bps + step_bps)
		if phase_elapsed_bps >= RAW_HOLD_BPS:
			phase = AWAKENING
			phase_elapsed_bps = 0
		return true
	if phase == AWAKENING:
		phase_elapsed_bps = mini(AWAKEN_BPS, phase_elapsed_bps + step_bps)
		progress_bps = PRINT_COMPLETE_BPS + phase_elapsed_bps
		if phase_elapsed_bps >= AWAKEN_BPS:
			phase = DEPARTING
			phase_elapsed_bps = 0
			progress_bps = PRINT_COMPLETE_BPS + AWAKEN_BPS
		return true
	if phase == DEPARTING:
		phase_elapsed_bps = mini(DEPART_BPS, phase_elapsed_bps + step_bps)
		progress_bps = PRINT_COMPLETE_BPS + AWAKEN_BPS + phase_elapsed_bps
		if phase_elapsed_bps >= DEPART_BPS:
			phase = AWAKENED
			progress_bps = FULL_BPS
		return true
	return false

func layer_reveal_bps() -> int:
	return clampi((progress_bps * FULL_BPS) / PRINT_COMPLETE_BPS, 0, FULL_BPS) if phase == PRINTING else FULL_BPS

func phase_progress_bps() -> int:
	match phase:
		RAW_HOLD: return (phase_elapsed_bps * FULL_BPS) / RAW_HOLD_BPS
		AWAKENING: return (phase_elapsed_bps * FULL_BPS) / AWAKEN_BPS
		DEPARTING: return (phase_elapsed_bps * FULL_BPS) / DEPART_BPS
	return FULL_BPS if phase == AWAKENED else 0

func request_commit() -> bool:
	if phase != RAW_COMPLETE or commit_requested: return false
	commit_requested = true
	return true

func resolve_commit(ok: bool) -> bool:
	if not commit_requested or resolved: return false
	resolved = true
	if ok:
		phase = RAW_HOLD
		phase_elapsed_bps = 0
	else:
		phase = FAILED
	return true

func skip() -> bool:
	if phase in [AWAKENED, FAILED, CANCELLED, RAW_COMPLETE]: return false
	if phase == IDLE:
		phase = CANCELLED
		return true
	if phase == PRINTING:
		progress_bps = PRINT_COMPLETE_BPS
		phase = RAW_COMPLETE
		return true
	# Once the transaction is safely resolved, one skip may safely settle every
	# remaining visual-only phase without another profile mutation.
	if phase in [RAW_HOLD, AWAKENING, DEPARTING]:
		phase = AWAKENED
		progress_bps = FULL_BPS
		phase_elapsed_bps = DEPART_BPS
		return true
	return false

func cancel() -> bool:
	if phase != IDLE: return false
	phase = CANCELLED
	return true
