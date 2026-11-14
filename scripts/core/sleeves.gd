class_name Sleeves
extends RefCounted
## Card sleeves: a cosmetic look for each deck (its colours and emblem). The
## first few are free; the rest unlock as your Maker Rank climbs.

const LIST := [
	{"id": "forge", "name": "Forge Orange", "color": "#ff9a3a", "deep": "#6b2a08", "emblem": "flame", "rank": 1},
	{"id": "tide", "name": "Tide Blue", "color": "#4aa8ff", "deep": "#10307a", "emblem": "drop", "rank": 1},
	{"id": "spark", "name": "Spark Yellow", "color": "#ffd84a", "deep": "#6b4a08", "emblem": "star", "rank": 1},
	{"id": "moss", "name": "Moss Green", "color": "#6fd66a", "deep": "#1f5a28", "emblem": "cube", "rank": 2},
	{"id": "frost", "name": "Frost White", "color": "#dff3ff", "deep": "#3f6a8a", "emblem": "snow", "rank": 4},
	{"id": "granite", "name": "Granite", "color": "#b59a7a", "deep": "#3a3026", "emblem": "hex", "rank": 6},
	{"id": "gale", "name": "Gale Teal", "color": "#5fe0b4", "deep": "#1f4a40", "emblem": "burst", "rank": 8},
	{"id": "rune", "name": "Rune Violet", "color": "#b98cff", "deep": "#2e1d52", "emblem": "gear", "rank": 10},
	{"id": "carbon", "name": "Carbon Black", "color": "#8a94a3", "deep": "#14181e", "emblem": "shield", "rank": 14},
	{"id": "rose", "name": "Rose Gold", "color": "#ff9ec0", "deep": "#7a2a48", "emblem": "star", "rank": 18},
	{"id": "gold", "name": "Master Gold", "color": "#ffcf4d", "deep": "#8a4a08", "emblem": "coin", "rank": 24},
]


static func get_sleeve(id: String) -> Dictionary:
	for s in LIST:
		if s["id"] == id:
			return s
	return LIST[0]


static func valid(id: String) -> bool:
	for s in LIST:
		if s["id"] == id:
			return true
	return false


static func unlocked(id: String, rank: int) -> bool:
	return valid(id) and rank >= int(get_sleeve(id)["rank"])


## The next sleeve you can use after `id`, wrapping round.
static func next_unlocked(id: String, rank: int, step := 1) -> String:
	var idx := 0
	for i in LIST.size():
		if LIST[i]["id"] == id:
			idx = i
	for k in range(1, LIST.size() + 1):
		var cand: Dictionary = LIST[posmod(idx + step * k, LIST.size())]
		if rank >= int(cand["rank"]):
			return str(cand["id"])
	return id
