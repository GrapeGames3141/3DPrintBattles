class_name Matchmaker
extends RefCounted
## Pairs waiting players for a ranked game. Pure and deterministic: give it the
## queue and the clock, get pairs back. Close ratings match first; the longer
## someone waits the wider the rating gap they will accept, and you are not
## matched with someone you just played. Mirrored in backend/src/matchmaking.ts.

const BASE_WINDOW := 100
const GROWTH_PER_SECOND := 15
const MAX_WINDOW := 700
## After this long with no pair the player is offered a computer opponent.
const GHOST_AFTER := 20


## The rating gap a player who has waited `seconds` will accept.
static func window(seconds: int) -> int:
	return mini(BASE_WINDOW + GROWTH_PER_SECOND * maxi(seconds, 0), MAX_WINDOW)


## entry: {"id": String, "rating": int, "joined": int (seconds), "recent": Array of ids}
## Returns the best pair for `entry`, or [] if nobody fits yet.
static func partner_for(entry: Dictionary, queue: Array, now: int) -> Array:
	var best: Dictionary = {}
	var best_gap := 1 << 30
	var my_window := window(now - int(entry["joined"]))
	for other in queue:
		if str(other["id"]) == str(entry["id"]):
			continue
		if (entry["recent"] as Array).has(str(other["id"])) or (other["recent"] as Array).has(str(entry["id"])):
			continue
		var gap := absi(int(other["rating"]) - int(entry["rating"]))
		var reach := maxi(my_window, window(now - int(other["joined"])))
		if gap > reach:
			continue
		if gap < best_gap or (gap == best_gap and str(other["id"]) < str(best.get("id", "~"))):
			best = other
			best_gap = gap
	return [] if best.is_empty() else [str(entry["id"]), str(best["id"])]


## Every pair that can be made right now. Longest waiters choose first.
static func pairs(queue: Array, now: int) -> Array:
	var waiting: Array = queue.duplicate()
	waiting.sort_custom(func(a, b): return int(a["joined"]) < int(b["joined"]) or (int(a["joined"]) == int(b["joined"]) and str(a["id"]) < str(b["id"])))
	var out: Array = []
	var i := 0
	while i < waiting.size():
		var found := partner_for(waiting[i], waiting, now)
		if found.is_empty():
			i += 1
			continue
		out.append(found)
		var gone := [found[0], found[1]]
		waiting = waiting.filter(func(e): return not gone.has(str(e["id"])))
		i = 0
	return out


static func should_offer_ghost(waited_seconds: int) -> bool:
	return waited_seconds >= GHOST_AFTER
