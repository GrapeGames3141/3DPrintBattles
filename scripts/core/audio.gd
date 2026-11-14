extends Node
## Autoload `Audio`: music and sound effects. Volumes come from the profile.
##
## Music is made of layered loops that all start together and stay in sync:
## the first layer always plays, the others fade in with `set_intensity`.
## Changing track crossfades. Sound effects are short one-shots with a little
## random pitch so repeats do not sound mechanical.

const SFX_PATH := "res://assets/audio/sfx_%s.wav"

## name -> [volume, pitch jitter]. Anything not listed plays at 0.8 with 0.03 jitter.
const TUNE := {
	"click": [0.55, 0.05], "back": [0.55, 0.04], "open": [0.5, 0.0], "close": [0.45, 0.0], "deny": [0.6, 0.0],
	"draw": [0.5, 0.08], "pick": [0.5, 0.06], "drop": [0.7, 0.06], "hop": [0.55, 0.06],
	"hit": [0.85, 0.1], "hit_heavy": [0.95, 0.06], "hit_printer": [0.9, 0.05], "swing": [0.6, 0.08],
	"print": [0.7, 0.04], "job_start": [0.75, 0.0], "print_done": [0.8, 0.0], "deploy": [0.8, 0.03],
	"shatter": [0.8, 0.07], "scrap": [0.55, 0.1], "spool_low": [0.7, 0.0],
	"turn_mine": [0.7, 0.0], "turn_foe": [0.6, 0.0], "win": [0.95, 0.0], "lose": [0.9, 0.0],
	"reveal": [0.8, 0.0], "reveal_epic": [0.9, 0.0], "heartbeat": [0.8, 0.02],
}
## Old names still used here and there, mapped to the effect that replaced them.
const ALIAS := {"card": "pick", "error": "deny"}
## Don't start the same effect again within this many seconds (a flurry of events would otherwise stack up).
const MIN_GAP := 0.045

const TRACKS := {
	"menu": ["res://assets/audio/music_menu.ogg"],
	"shop": ["res://assets/audio/music_shop.ogg"],
	"bench": ["res://assets/audio/music_bench.ogg"],
	"battle1": ["res://assets/audio/music_battle1_base.ogg", "res://assets/audio/music_battle1_drive.ogg", "res://assets/audio/music_battle1_danger.ogg"],
	"battle2": ["res://assets/audio/music_battle2_base.ogg", "res://assets/audio/music_battle2_drive.ogg", "res://assets/audio/music_battle2_danger.ogg"],
}
const FADE_IN := 1.4
const FADE_OUT := 1.0
const LAYER_RATE := 0.5          # layer fades take about two seconds

var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _last_played: Dictionary = {}
var _decks: Array = []           # newest last: {track, players, level, goal, layers, layer_goal}
var _track := ""
var _intensity := 0.0
var _duck := 1.0
var _duck_goal := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		_streams[path] = s
	return _streams[path]


## Kept for the settings screen: the new volume is picked up every frame.
func apply_volume() -> void:
	pass


func _music_volume() -> float:
	return float(Profile.setting("music"))


# ------------------------------------------------------------------- effects

func sfx(name: String, pitch: float = 1.0, volume: float = 1.0) -> void:
	var master := float(Profile.setting("sfx"))
	name = ALIAS.get(name, name)
	if master <= 0.001:
		return
	var path := SFX_PATH % name
	var stream := _stream(path)
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(name, -1.0)) < MIN_GAP:
		return
	_last_played[name] = now
	var tune: Array = TUNE.get(name, [0.8, 0.03])
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch * (1.0 + randf_range(-1.0, 1.0) * float(tune[1]))
			p.volume_db = linear_to_db(maxf(master * float(tune[0]) * volume, 0.0001))
			p.play()
			return


## A jingle: the music ducks underneath it while it plays.
func stinger(name: String, music_level: float = 0.25) -> void:
	sfx(name)
	var s := _stream(SFX_PATH % name)
	if s != null:
		duck(music_level, s.get_length())


func duck(level: float, seconds: float) -> void:
	_duck_goal = level
	await get_tree().create_timer(seconds).timeout
	_duck_goal = 1.0


# --------------------------------------------------------------------- music

## Starts (or crossfades to) a track. Unknown names stop the music.
func music(track: String) -> void:
	if track == _track:
		return
	_track = track
	for deck in _decks:
		deck["goal"] = 0.0
	if not TRACKS.has(track):
		return
	var deck := {"track": track, "players": [], "level": 0.0, "goal": 1.0, "layers": [], "layer_goal": []}
	var paths: Array = TRACKS[track]
	for i in paths.size():
		var stream := _stream(paths[i])
		if stream == null:
			continue
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = -80.0
		add_child(p)
		(deck["players"] as Array).append(p)
		(deck["layers"] as Array).append(1.0 if i == 0 else 0.0)
		(deck["layer_goal"] as Array).append(1.0 if i == 0 else 0.0)
	if (deck["players"] as Array).is_empty():
		return
	_decks.append(deck)
	_apply_intensity(deck)
	for p in deck["players"]:
		(p as AudioStreamPlayer).play()


## 0 plays only the first layer, 1 adds the second, 2 adds the third.
func set_intensity(value: float) -> void:
	_intensity = value
	for deck in _decks:
		if deck["goal"] > 0.0:
			_apply_intensity(deck)


func _apply_intensity(deck: Dictionary) -> void:
	var goals: Array = deck["layer_goal"]
	for i in goals.size():
		goals[i] = 1.0 if i == 0 else clampf(_intensity - (i - 1), 0.0, 1.0)


func _process(delta: float) -> void:
	_duck = move_toward(_duck, _duck_goal, delta * 2.5)
	var vol := _music_volume()
	for deck in _decks.duplicate():
		deck["level"] = move_toward(deck["level"], deck["goal"], delta / (FADE_IN if deck["goal"] > 0.0 else FADE_OUT))
		var players: Array = deck["players"]
		for i in players.size():
			deck["layers"][i] = move_toward(deck["layers"][i], deck["layer_goal"][i], delta * LAYER_RATE)
			var gain: float = float(deck["level"]) * float(deck["layers"][i]) * vol * 0.55 * _duck
			(players[i] as AudioStreamPlayer).volume_db = linear_to_db(maxf(gain, 0.00001))
		if deck["goal"] <= 0.0 and deck["level"] <= 0.0:
			for p in players:
				(p as AudioStreamPlayer).queue_free()
			_decks.erase(deck)
