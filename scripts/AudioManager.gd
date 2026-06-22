# AudioManager.gd
# Autoload singleton — add to Project Settings > Autoload as "AudioManager"
# Handles all music and SFX. Music persists between scene changes.
# Usage:
#   AudioManager.play_music("workshop")
#   AudioManager.play_sfx("hit")
#   AudioManager.set_music_volume(0.8)

extends Node

# ─────────────────────────────────────────────────────────────────────────────
# AUDIO TRACK DEFINITIONS
# Add file to assets/audio/ then reference the key here.
# ─────────────────────────────────────────────────────────────────────────────
const MUSIC_TRACKS := {
	"workshop":  "res://assets/audio/music_workshop.ogg",
	"battle":    "res://assets/audio/music_battle.ogg",
	"academy":   "res://assets/audio/music_academy.ogg",
}

const SFX_TRACKS := {
	"hit":       "res://assets/audio/sfx_hit.ogg",
	"summon":    "res://assets/audio/sfx_summon.ogg",
	"victory":   "res://assets/audio/sfx_victory.ogg",
	"defeat":    "res://assets/audio/sfx_defeat.ogg",
	"coin":      "res://assets/audio/sfx_coin.ogg",
	"levelup":   "res://assets/audio/sfx_levelup.ogg",
	"card":      "res://assets/audio/sfx_card.ogg",
	"ability":   "res://assets/audio/sfx_ability.ogg",
	"buy":       "res://assets/audio/sfx_buy.ogg",
	"error":     "res://assets/audio/sfx_error.ogg",
}

# ─────────────────────────────────────────────────────────────────────────────
# NODES
# ─────────────────────────────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer    # For short one-shot effects
var _sfx_pool: Array[AudioStreamPlayer] = []  # Pool of 6 for overlapping SFX
const SFX_POOL_SIZE := 6

var _current_music_key := ""
var _music_volume := 0.8
var _sfx_volume := 1.0
var _music_enabled := true
var _sfx_enabled := true

func _ready() -> void:
	# Music player — looping, persistent
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	# SFX pool — for overlapping sound effects
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_load_settings_from_save()

# ─────────────────────────────────────────────────────────────────────────────
# MUSIC
# ─────────────────────────────────────────────────────────────────────────────
func play_music(key: String) -> void:
	if key == _current_music_key and _music_player.playing:
		return  # Already playing this track
	if not _music_enabled:
		return
	if not key in MUSIC_TRACKS:
		push_warning("[AudioManager] Unknown music key: %s" % key)
		return

	var path := MUSIC_TRACKS[key]
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] Music file not found: %s" % path)
		return

	_current_music_key = key
	_music_player.stream = load(path)
	_music_player.volume_db = linear_to_db(_music_volume)

	# Fade in new track
	_music_player.play()
	var tween := create_tween()
	_music_player.volume_db = -60.0
	tween.tween_property(_music_player, "volume_db",
		linear_to_db(_music_volume), 1.0)

func stop_music(fade_seconds: float = 1.0) -> void:
	if not _music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -60.0, fade_seconds)
	tween.tween_callback(_music_player.stop)
	_current_music_key = ""

func set_music_volume(vol: float) -> void:
	_music_volume = clamp(vol, 0.0, 1.0)
	_music_player.volume_db = linear_to_db(_music_volume)
	_save_settings()

func toggle_music(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		stop_music()
	_save_settings()

# ─────────────────────────────────────────────────────────────────────────────
# SFX
# ─────────────────────────────────────────────────────────────────────────────
func play_sfx(key: String) -> void:
	if not _sfx_enabled:
		return
	if not key in SFX_TRACKS:
		push_warning("[AudioManager] Unknown SFX key: %s" % key)
		return

	var path := SFX_TRACKS[key]
	if not ResourceLoader.exists(path):
		# Silent fail — SFX files may not exist during development
		return

	# Find a free player from the pool
	var player := _get_free_sfx_player()
	if player == null:
		return

	player.stream = load(path)
	player.volume_db = linear_to_db(_sfx_volume)
	player.play()

func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clamp(vol, 0.0, 1.0)
	_save_settings()

func toggle_sfx(enabled: bool) -> void:
	_sfx_enabled = enabled
	_save_settings()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	# All busy — use the first one (interrupt least-recent)
	return _sfx_pool[0]

# ─────────────────────────────────────────────────────────────────────────────
# SCENE-BASED MUSIC ROUTING
# Call this from each scene's _ready() to auto-play the right music.
# ─────────────────────────────────────────────────────────────────────────────
func play_for_scene(scene_name: String) -> void:
	match scene_name:
		"Workshop", "StarterSelection", "PrintYard", "GearLocker":
			play_music("workshop")
		"Battle":
			play_music("battle")
		"Academy":
			play_music("academy")
		"Shop", "Forgedex", "TrainerSelect":
			play_music("workshop")  # Reuse workshop music for menus

# ─────────────────────────────────────────────────────────────────────────────
# SETTINGS PERSISTENCE
# ─────────────────────────────────────────────────────────────────────────────
func _load_settings_from_save() -> void:
	if SaveManager.data.has("settings"):
		var s := SaveManager.data["settings"]
		_music_volume = s.get("music_volume", 0.8)
		_sfx_volume   = s.get("sfx_volume", 1.0)
		_music_enabled = s.get("music_enabled", true)
		_sfx_enabled   = s.get("sfx_enabled", true)

func _save_settings() -> void:
	if SaveManager.data.has("settings"):
		SaveManager.data["settings"]["music_volume"]  = _music_volume
		SaveManager.data["settings"]["sfx_volume"]    = _sfx_volume
		SaveManager.data["settings"]["music_enabled"] = _music_enabled
		SaveManager.data["settings"]["sfx_enabled"]   = _sfx_enabled
		SaveManager.save_game()
