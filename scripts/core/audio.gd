extends Node
## Autoload `Audio`: music and sound effects. Volumes come from the profile.

const SFX := {
	"card": "res://assets/audio/sfx_card.wav",
	"print": "res://assets/audio/sfx_summon.wav",
	"hit": "res://assets/audio/sfx_hit.wav",
	"tool": "res://assets/audio/sfx_ability.wav",
	"coin": "res://assets/audio/sfx_coin.wav",
	"buy": "res://assets/audio/sfx_buy.wav",
	"error": "res://assets/audio/sfx_error.wav",
	"win": "res://assets/audio/sfx_victory.wav",
	"lose": "res://assets/audio/sfx_defeat.wav",
	"reveal": "res://assets/audio/sfx_levelup.wav",
}
const MUSIC := {
	"workshop": "res://assets/audio/music_workshop.wav",
	"battle": "res://assets/audio/music_battle.wav",
}

var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _track := ""


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.finished.connect(func(): _music.play())
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	apply_volume()


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


func apply_volume() -> void:
	var music := float(Profile.setting("music"))
	_music.volume_db = linear_to_db(maxf(music * 0.5, 0.0001))
	_music.stream_paused = music <= 0.001


func sfx(name: String, pitch: float = 1.0) -> void:
	var vol := float(Profile.setting("sfx"))
	if vol <= 0.001 or not SFX.has(name):
		return
	var stream := _stream(SFX[name])
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = linear_to_db(vol * 0.8)
			p.play()
			return


func music(track: String) -> void:
	if track == _track:
		return
	_track = track
	_music.stop()
	var stream := _stream(MUSIC.get(track, ""))
	if stream == null:
		return
	_music.stream = stream
	_music.play()
	apply_volume()
