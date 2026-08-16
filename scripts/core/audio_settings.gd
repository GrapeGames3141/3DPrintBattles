class_name AudioSettings
extends RefCounted
## Pure fixed-step mix policy. Values are basis points so settings remain save-safe.

# 35% is the deliberately quieter default music step; all persisted values are
# still explicit fixed points rather than arbitrary slider values.
const LEVELS: Array[int] = [0, 2500, 3500, 5000, 7500, 10000]

static func defaults() -> Dictionary:
	return {"master_bps":5000,"music_bps":3500,"sfx_bps":5000}

static func ensure(values: Dictionary) -> Dictionary:
	var result := defaults()
	for key in result:
		var candidate := int(values.get(key, result[key]))
		result[key] = candidate if candidate in LEVELS else int(result[key])
	return result

static func save(source: Dictionary, updates: Dictionary) -> Dictionary:
	var candidate := ensure(source)
	for key in updates:
		if not candidate.has(key) or not int(updates[key]) in LEVELS:
			return {"ok":false,"error":"Choose one of the fixed audio levels."}
		candidate[key] = int(updates[key])
	return {"ok":true,"settings":candidate}

static func label_for(bps: int) -> String:
	return "%d%%" % (clampi(bps, 0, 10000) / 100)
