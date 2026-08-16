class_name BattleFeedbackPresenter
extends RefCounted
## Pure, accessibility-safe battle outcome copy. It has no game-state effects.

static func format(state: BattleState, last_event: String, audio_caption: String) -> String:
	var cue := audio_caption.replace("Battle cue: ", "").replace("Impact: ", "").replace("Support card: ", "")
	if last_event.is_empty(): return "Outcome: choose a move. Cue: " + cue
	var you := state.active_unit(0)
	var rival := state.active_unit(1)
	var action := last_event.replace("_", " ").capitalize()
	return "Outcome: %s. You %d/%d; Rival %d/%d HP; Shield %d/%d. Cue: %s" % [action, int(you.get("hp", 0)), int(you.get("max_hp", 0)), int(rival.get("hp", 0)), int(rival.get("max_hp", 0)), int(you.get("shield", 0)), int(rival.get("shield", 0)), cue]
