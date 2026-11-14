class_name PlayerIdentity
extends RefCounted
## Who you are in ranked play. There is no typed text anywhere: a name is an
## adjective and a noun picked from fixed lists plus a two-digit number, the
## picture is one of your own prints, and titles are earned.

const ADJECTIVES := ["Swift", "Brave", "Clever", "Calm", "Bold", "Bright", "Sneaky", "Mighty", "Lucky", "Quiet", "Fuzzy", "Steady", "Sunny", "Daring", "Gentle", "Jolly"]
const NOUNS := ["Maker", "Printer", "Nozzle", "Spool", "Gear", "Bolt", "Forge", "Tinker", "Builder", "Sprocket", "Widget", "Gadget", "Slicer", "Layer", "Filament", "Brim"]
const HISTORY_LIMIT := 20


static func make_id() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()


static func valid_id(id: String) -> bool:
	return id.length() == 16 and id.is_valid_hex_number()


static func name_of(adj: int, noun: int, num: int) -> String:
	return "%s %s %02d" % [ADJECTIVES[posmod(adj, ADJECTIVES.size())], NOUNS[posmod(noun, NOUNS.size())], posmod(num, 100)]


static func random_name(rng: RandomNumberGenerator) -> String:
	return name_of(rng.randi() % ADJECTIVES.size(), rng.randi() % NOUNS.size(), rng.randi() % 100)


static func fresh_player() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return {
		"id": make_id(), "adj": rng.randi() % ADJECTIVES.size(), "noun": rng.randi() % NOUNS.size(), "num": rng.randi() % 100,
		"avatar": "", "title": "rookie", "rating": Rating.START, "ranked_games": 0, "ranked_wins": 0,
		"best_rating": Rating.START, "streak": 0, "best_streak": 0, "history": [],
	}


## Cleans a loaded player record so a damaged or edited save cannot break the game.
static func sanitize(p: Dictionary) -> Dictionary:
	var base := fresh_player()
	var out: Dictionary = {}
	out["id"] = str(p.get("id", "")) if valid_id(str(p.get("id", ""))) else base["id"]
	out["adj"] = posmod(int(p.get("adj", base["adj"])), ADJECTIVES.size())
	out["noun"] = posmod(int(p.get("noun", base["noun"])), NOUNS.size())
	out["num"] = posmod(int(p.get("num", base["num"])), 100)
	out["avatar"] = str(p.get("avatar", ""))
	out["title"] = str(p.get("title", "rookie"))
	out["rating"] = maxi(Rating.FLOOR, int(p.get("rating", Rating.START)))
	out["ranked_games"] = maxi(0, int(p.get("ranked_games", 0)))
	out["ranked_wins"] = clampi(int(p.get("ranked_wins", 0)), 0, int(out["ranked_games"]))
	out["best_rating"] = maxi(int(out["rating"]), int(p.get("best_rating", out["rating"])))
	out["streak"] = int(p.get("streak", 0))
	out["best_streak"] = maxi(0, int(p.get("best_streak", 0)))
	var hist: Array = []
	for h in p.get("history", []):
		if h is Dictionary:
			hist.append({"opp": _clean_name(str(h.get("opp", ""))), "opp_rating": maxi(0, int(h.get("opp_rating", 0))),
				"won": bool(h.get("won", false)), "delta": int(h.get("delta", 0)), "mode": str(h.get("mode", "ranked")).substr(0, 10)})
	out["history"] = hist.slice(maxi(0, hist.size() - HISTORY_LIMIT))
	return out


static func _clean_name(s: String) -> String:
	var out := ""
	for ch in s.substr(0, 28):
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == " ":
			out += ch
	return out


## Titles earned so far, as {id, name}. `stats` carries what they depend on.
static func titles(best_rating: int, wins: int, best_streak: int, rivals_beaten: int, owned_cards: int) -> Array:
	var out: Array = [{"id": "rookie", "name": "Rookie Maker"}]
	if wins >= 10:
		out.append({"id": "seasoned", "name": "Seasoned Maker"})
	if wins >= 50:
		out.append({"id": "veteran", "name": "Veteran Maker"})
	if best_streak >= 5:
		out.append({"id": "streak", "name": "Hot Streak"})
	if rivals_beaten >= GameData.RIVALS.size():
		out.append({"id": "champion", "name": "Campaign Champion"})
	if owned_cards >= 100:
		out.append({"id": "archivist", "name": "Archivist"})
	var top: int = int(Rating.league(best_rating)["index"])
	for i in range(1, top + 1):
		out.append({"id": "league_%d" % i, "name": "%s Maker" % Rating.LEAGUES[i]["name"]})
	return out


## What you tell an opponent about yourself. Numbers only: the other side builds
## the name from its own word lists, so no text ever crosses the wire.
static func who_of(player: Dictionary, avatar: String) -> Dictionary:
	return {"adj": int(player["adj"]), "noun": int(player["noun"]), "num": int(player["num"]), "rating": int(player["rating"]), "avatar": avatar}


## Reads what an opponent sent, trusting none of it.
static func read_who(d: Variant) -> Dictionary:
	var src: Dictionary = d if d is Dictionary else {}
	var avatar := str(src.get("avatar", ""))
	if GameData.card(avatar).get("type", "") != "creature":
		avatar = ""
	return {"name": name_of(int(src.get("adj", 0)), int(src.get("noun", 0)), int(src.get("num", 0))),
		"rating": clampi(int(src.get("rating", Rating.START)), Rating.FLOOR, 5000), "avatar": avatar}
