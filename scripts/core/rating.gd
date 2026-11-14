class_name Rating
extends RefCounted
## Maker Rating: an Elo-style number for ranked play. Everyone starts at 1000;
## the first games move it fast (calibration), later games move it less. The
## same maths runs in backend/src/rating.ts so a server can own the numbers,
## and backend/test/rating_vectors.json holds cases both sides must agree on.

const START := 1000
const FLOOR := 100
const CALIBRATION_GAMES := 10
const SETTLING_GAMES := 30

## League name and the rating where it starts. Three divisions (III up to I)
## split each league except the last.
const LEAGUES := [
	{"name": "Spool", "floor": 0}, {"name": "Filament", "floor": 900}, {"name": "Nozzle", "floor": 1050},
	{"name": "Hotend", "floor": 1200}, {"name": "Extruder", "floor": 1400}, {"name": "Gantry", "floor": 1600},
	{"name": "Print Master", "floor": 1850},
]


static func k_factor(games: int) -> int:
	if games < CALIBRATION_GAMES:
		return 40
	if games < SETTLING_GAMES:
		return 28
	return 20


## The chance (0..1) that rating `a` beats rating `b`.
static func expected(a: int, b: int) -> float:
	return 1.0 / (1.0 + pow(10.0, float(b - a) / 400.0))


## How many points `a` gains (or loses) from one game against `b`.
static func delta(a: int, b: int, won: bool, games: int) -> int:
	return roundi(float(k_factor(games)) * ((1.0 if won else 0.0) - expected(a, b)))


static func after(a: int, b: int, won: bool, games: int) -> int:
	return maxi(FLOOR, a + delta(a, b, won, games))


## {name, division (3 lowest, 1 highest; 0 for the top league), index, floor, next}
static func league(rating: int) -> Dictionary:
	var idx := 0
	for i in LEAGUES.size():
		if rating >= int(LEAGUES[i]["floor"]):
			idx = i
	var floor_r: int = int(LEAGUES[idx]["floor"])
	var last: bool = idx == LEAGUES.size() - 1
	var next_r: int = -1 if last else int(LEAGUES[idx + 1]["floor"])
	var division := 0
	if not last:
		var span := next_r - floor_r
		division = 3 - clampi(int(3.0 * float(rating - floor_r) / float(span)), 0, 2)
	return {"name": LEAGUES[idx]["name"], "division": division, "index": idx, "floor": floor_r, "next": next_r}


static func league_text(rating: int) -> String:
	var l := league(rating)
	if int(l["division"]) == 0:
		return str(l["name"])
	return "%s %s" % [l["name"], ["", "I", "II", "III"][int(l["division"])]]
