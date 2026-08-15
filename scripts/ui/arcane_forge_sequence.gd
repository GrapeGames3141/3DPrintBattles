class_name ArcaneForgeSequence
extends RefCounted
## Deterministic presentation state only. The caller owns the single profile commit.

const IDLE := "idle"
const PRINTING := "printing"
const RAW_COMPLETE := "raw_complete"
const AWAKENING := "awakening"
const AWAKENED := "awakened"
const FAILED := "failed"
const CANCELLED := "cancelled"
const PRINT_COMPLETE_BPS := 7000
const FULL_BPS := 10000

static func presentation_interval_seconds(reduce_motion: bool) -> float:
	return 0.45 if reduce_motion else 0.12

static func presentation_step_bps(reduce_motion: bool) -> int:
	# Reduced motion intentionally lasts longer than the animated path: clear staged holds.
	return 1400 if reduce_motion else 900

var phase := IDLE
var progress_bps := 0
var reduced_motion := false
var commit_requested := false
var resolved := false

static func create(reduce_motion := false) -> ArcaneForgeSequence:
	var sequence := ArcaneForgeSequence.new()
	sequence.reduced_motion = reduce_motion
	return sequence

func begin() -> bool:
	if phase != IDLE: return false
	phase = PRINTING
	progress_bps = 0
	return true

func advance(step_bps: int) -> bool:
	if step_bps <= 0 or phase in [IDLE, AWAKENED, FAILED, CANCELLED]: return false
	if phase == PRINTING:
		progress_bps = mini(PRINT_COMPLETE_BPS, progress_bps + step_bps)
		if progress_bps >= PRINT_COMPLETE_BPS: phase = RAW_COMPLETE
		return true
	if phase == AWAKENING:
		progress_bps = mini(FULL_BPS, progress_bps + step_bps)
		if progress_bps >= FULL_BPS: phase = AWAKENED
		return true
	return false

func layer_reveal_bps() -> int:
	return clampi((progress_bps * FULL_BPS) / PRINT_COMPLETE_BPS, 0, FULL_BPS) if phase in [PRINTING, RAW_COMPLETE] else FULL_BPS

func request_commit() -> bool:
	if phase != RAW_COMPLETE or commit_requested: return false
	commit_requested = true
	return true

func resolve_commit(ok: bool) -> bool:
	if not commit_requested or resolved: return false
	resolved = true
	if ok:
		phase = AWAKENING
		progress_bps = PRINT_COMPLETE_BPS
	else:
		phase = FAILED
	return true

func skip() -> bool:
	if phase in [AWAKENED, FAILED, CANCELLED]: return false
	if phase == IDLE:
		phase = CANCELLED
		return true
	if phase == PRINTING:
		progress_bps = PRINT_COMPLETE_BPS
		phase = RAW_COMPLETE
		return true
	if phase == RAW_COMPLETE: return false
	if phase == AWAKENING:
		progress_bps = FULL_BPS
		phase = AWAKENED
		return true
	return false

func cancel() -> bool:
	if phase != IDLE: return false
	phase = CANCELLED
	return true
