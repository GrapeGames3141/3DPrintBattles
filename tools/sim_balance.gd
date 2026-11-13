extends SceneTree
## Balance probe: plays three stand-in players against every campaign rival.
##   godot --headless --path . -s tools/sim_balance.gd

const GAMES := 30

const MID_DECK := {"mossmunk": 2, "voltwig": 2, "cinderpaw": 2, "aquafin": 2, "sparkotter": 1, "frostling": 2,
	"stoneback": 2, "galehopper": 2, "heat_gun": 2, "glassdrake": 1, "runestag": 1, "bed_scraper": 1}
const LATE_DECK := {"mossmunk": 2, "voltwig": 1, "cinderpaw": 2, "aquafin": 2, "frostling": 2, "stoneback": 2,
	"galehopper": 1, "heat_gun": 2, "glassdrake": 1, "runestag": 1, "bed_scraper": 1, "printed_wrench": 1,
	"coalgriffin": 1, "ironmaw": 1}


func _initialize() -> void:
	var pilots := [
		{"name": "starter/Craftsman", "deck": GameData.STARTER_DECK, "level": 1, "up": {}},
		{"name": "starter/Master", "deck": GameData.STARTER_DECK, "level": 2, "up": {}},
		{"name": "mid/Master", "deck": MID_DECK, "level": 2, "up": {"frame": 1, "bed": 1}},
		{"name": "late/Master", "deck": LATE_DECK, "level": 2, "up": {"frame": 2, "bed": 2}},
	]
	for pl in pilots:
		assert(GameData.deck_error(GameData.expand(pl["deck"])) == "")
	var header := "%-20s" % "rival"
	for pl in pilots:
		header += "%20s" % pl["name"]
	print(header)
	for r in GameData.RIVALS:
		var line := "%-20s" % r["name"]
		for pl in pilots:
			var wins := 0
			for i in GAMES:
				var st := BattleEngine.new_game({"seed": 900 + i * 53, "players": [
					{"printer": "ember_forge", "deck": GameData.expand(pl["deck"]), "mods": pl["up"]},
					{"printer": r["printer"], "deck": GameData.expand(r["deck"]), "hp_bonus": r["hp_bonus"]}]})
				var steps := 0
				while not st["over"] and steps < 4000:
					steps += 1
					var seat: int = int(st["active"])
					BattleEngine.apply(st, seat, BattleAI.choose(st, seat, int(pl["level"]) if seat == 0 else int(r["level"])))
				if int(st["winner"]) == 0:
					wins += 1
			line += "%17d%%  " % (wins * 100 / GAMES)
		print(line)
	quit()
