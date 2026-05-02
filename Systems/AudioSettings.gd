extends Object
class_name AudioSettings

## Ensures Music/SFX buses exist (default Godot project may only ship Master), then applies mutes from settings.


static func ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") < 0:
		var idx: int = AudioServer.get_bus_count()
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		var idx2: int = AudioServer.get_bus_count()
		AudioServer.add_bus(idx2)
		AudioServer.set_bus_name(idx2, "SFX")
		AudioServer.set_bus_send(idx2, "Master")


static func apply_from_game_state() -> void:
	ensure_buses()
	var music_on: bool = bool(GameState.settings.get("music", true))
	var sfx_on: bool = bool(GameState.settings.get("sfx", true))
	_apply_bus_mutes(music_on, sfx_on)


static func apply_from_local_settings() -> void:
	ensure_buses()
	var ls: Dictionary = SaveSystem.load_local_settings()
	var music_on: bool = bool(ls.get("music", true))
	var sfx_on: bool = bool(ls.get("sfx", true))
	_apply_bus_mutes(music_on, sfx_on)


static func _apply_bus_mutes(music_on: bool, sfx_on: bool) -> void:
	var im: int = AudioServer.get_bus_index("Music")
	var isfx: int = AudioServer.get_bus_index("SFX")
	if im >= 0:
		AudioServer.set_bus_mute(im, not music_on)
	if isfx >= 0:
		AudioServer.set_bus_mute(isfx, not sfx_on)
