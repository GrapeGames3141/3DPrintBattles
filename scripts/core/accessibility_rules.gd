class_name AccessibilityRules
extends RefCounted
## Pure persisted accessibility/settings validation.

const TEXT_SCALES := [10000, 12500, 15000]
const DIFFICULTIES := ["Apprentice", "Craftsman", "Master"]

static func defaults() -> Dictionary:
	var result := {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false,"ai_difficulty":"Craftsman"}
	for key in AudioSettings.defaults(): result[key] = AudioSettings.defaults()[key]
	return result

static func ensure_fields(profile: Dictionary) -> Dictionary:
	var p := profile.duplicate(true)
	var settings: Dictionary = defaults()
	for key in p.get("settings", {}): settings[key] = p.settings[key]
	if not int(settings.get("text_scale_bps", 0)) in TEXT_SCALES: settings.text_scale_bps = 10000
	if not str(settings.get("ai_difficulty", "")) in DIFFICULTIES: settings.ai_difficulty = "Craftsman"
	settings.high_contrast = bool(settings.get("high_contrast", false))
	settings.reduced_motion = bool(settings.get("reduced_motion", false))
	var audio := AudioSettings.ensure(settings)
	for key in audio: settings[key] = audio[key]
	p.settings = settings
	return p

static func save(source: Dictionary, values: Dictionary) -> Dictionary:
	var p := ensure_fields(source)
	var candidate: Dictionary = p.settings.duplicate(true)
	for key in values: candidate[key] = values[key]
	if not int(candidate.get("text_scale_bps", 0)) in TEXT_SCALES: return {"ok":false,"profile":p,"error":"Choose a supported text size."}
	if not str(candidate.get("ai_difficulty", "")) in DIFFICULTIES: return {"ok":false,"profile":p,"error":"Choose a supported training difficulty."}
	var audio_updates := {}
	for key in AudioSettings.defaults(): audio_updates[key] = candidate.get(key, p.settings.get(key, AudioSettings.defaults()[key]))
	var audio_result := AudioSettings.save(p.settings, audio_updates)
	if not bool(audio_result.get("ok", false)): return {"ok":false,"profile":p,"error":str(audio_result.get("error", "Choose a supported audio level."))}
	p.settings = {"text_scale_bps":int(candidate.text_scale_bps),"high_contrast":bool(candidate.high_contrast),"reduced_motion":bool(candidate.reduced_motion),"ai_difficulty":str(candidate.ai_difficulty)}
	for key in audio_result.settings: p.settings[key] = audio_result.settings[key]
	return {"ok":true,"profile":p,"payload":{"settings":p.settings.duplicate(true)}}
