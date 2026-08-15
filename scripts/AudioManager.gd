# AudioManager.gd
# Autoload singleton — add to Project Settings > Autoload as "AudioManager"
# Handles all music and SFX. Music persists between scene changes.
# Usage:
#   AudioManager.play_music("workshop")
#   AudioManager.play_sfx("hit")
#   AudioManager.set_music_volume(0.8)

extends Node

const MUSIC_TRACKS = {
	"workshop": preload("res://assets/audio/music_workshop.wav"),
	"battle":   preload("res://assets/audio/music_battle.wav"),
	"academy":  preload("res://assets/audio/music_academy.wav"),
}

const SFX_TRACKS = {
	"hit":     preload("res://assets/audio/sfx_hit.wav"),
	"summon":  preload("res://assets/audio/sfx_summon.wav"),
	"victory": preload("res://assets/audio/sfx_victory.wav"),
	"defeat":  preload("res://assets/audio/sfx_defeat.wav"),
	"coin":    preload("res://assets/audio/sfx_coin.wav"),
	"levelup": preload("res://assets/audio/sfx_levelup.wav"),
	"card":    preload("res://assets/audio/sfx_card.wav"),
	"ability": preload("res://assets/audio/sfx_ability.wav"),
	"buy":     preload("res://assets/audio/sfx_buy.wav"),
	"error":   preload("res://assets/audio/sfx_error.wav"),
}

const SFX_POOL_SIZE = 6
const MIN_VOLUME_DB = -40.0

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []

var _current_music_key = ""
var _music_volume = 0.8
var _sfx_volume = 1.0
var _music_enabled = true
var _sfx_enabled = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.bus = "Master"
	add_child(_music_player)

	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)

	_load_settings_from_save()

	var tree = get_tree()
	if tree:
		tree.scene_changed.connect(_on_scene_changed)
		call_deferred("_sync_scene_music")

func _on_scene_changed() -> void:
	call_deferred("_sync_scene_music")

func _sync_scene_music() -> void:
	var scene = get_tree().current_scene
	if scene:
		play_for_scene(scene.name)

func play_music(key: String) -> void:
	if not _music_enabled:
		return
	if not key in MUSIC_TRACKS:
		push_warning("[AudioManager] Unknown music key: %s" % key)
		return

	if key == _current_music_key and _music_player.playing:
		return

	_current_music_key = key
	var stream := _make_looping_stream(MUSIC_TRACKS[key])
	_music_player.stream = stream
	_music_player.volume_db = _volume_to_db(_music_volume)
	_music_player.play()

func stop_music(fade_seconds: float = 1.0) -> void:
	if not _music_player.playing:
		_current_music_key = ""
		return
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", MIN_VOLUME_DB, fade_seconds)
	tween.tween_callback(_finish_stop_music)

func _finish_stop_music() -> void:
	_music_player.stop()
	_current_music_key = ""

func set_music_volume(vol: float) -> void:
	_music_volume = clamp(vol, 0.0, 1.0)
	_music_player.volume_db = _volume_to_db(_music_volume)
	_save_settings()

func toggle_music(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		stop_music()
	else:
		_sync_scene_music()
	_save_settings()

func play_sfx(key: String) -> void:
	if not _sfx_enabled:
		return
	if not key in SFX_TRACKS:
		push_warning("[AudioManager] Unknown SFX key: %s" % key)
		return

	var player = _get_free_sfx_player()
	if player == null:
		return

	player.stream = SFX_TRACKS[key]
	player.volume_db = _volume_to_db(_sfx_volume)
	player.play()

func play_test_sound() -> void:
	play_sfx("coin")
	if _music_enabled and not _music_player.playing:
		_sync_scene_music()

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
	return _sfx_pool[0]

func play_for_scene(scene_name: String) -> void:
	match scene_name:
		"Workshop", "StarterSelection", "PrintYard", "GearLocker", "Settings":
			play_music("workshop")
		"Battle":
			play_music("battle")
		"Academy":
			play_music("academy")
		"Shop", "Forgedex", "TrainerSelect":
			play_music("workshop")

func _make_looping_stream(source: AudioStream) -> AudioStream:
	var stream = source.duplicate()
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream

func _volume_to_db(vol: float) -> float:
	if vol <= 0.0:
		return MIN_VOLUME_DB
	return linear_to_db(vol)

func _load_settings_from_save() -> void:
	if SaveManager.data.has("settings"):
		var s = SaveManager.data["settings"]
		_music_volume = s.get("music_volume", 0.8)
		_sfx_volume   = s.get("sfx_volume", 1.0)
		_music_enabled = s.get("music_enabled", true)
		_sfx_enabled   = s.get("sfx_enabled", true)
	if _music_player:
		_music_player.volume_db = _volume_to_db(_music_volume)

func _ensure_audio_buses() -> void:
	# Keep Music/SFX buses available for future mixer UI; playback uses Master.
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func _save_settings() -> void:
	if SaveManager.data.has("settings"):
		SaveManager.data["settings"]["music_volume"]  = _music_volume
		SaveManager.data["settings"]["sfx_volume"]    = _sfx_volume
		SaveManager.data["settings"]["music_enabled"] = _music_enabled
		SaveManager.data["settings"]["sfx_enabled"]   = _sfx_enabled
		SaveManager.save_game()
