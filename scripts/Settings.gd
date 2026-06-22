# Settings.gd
# Settings screen — volume, fullscreen, reset save option.
# Scene file: res://scenes/Settings.tscn
# Accessed via Workshop → Settings button (add to Workshop scene)
#
# SCENE TREE:
# Settings (Node2D)
# ├── Background (ColorRect) — #1A1A2E full screen
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer) — top full width height 60 bg #0D0D1A
# │   │   ├── TitleLabel (Label) — "⚙ Settings" size 24
# │   │   └── BackBtn (Button) — "← Workshop" min 120x44
# │   └── SettingsPanel (VBoxContainer)
# │       center screen, width 500px, separation 24
# │       ├── MusicRow (HBoxContainer)
# │       │   ├── Label — "🎵 Music Volume" size 20 EXPAND_FILL
# │       │   ├── MusicSlider (HSlider) — min 0 max 1 step 0.05 width 200
# │       │   └── MusicToggle (CheckButton) — "On/Off"
# │       ├── SFXRow (HBoxContainer)
# │       │   ├── Label — "🔊 Sound Effects" size 20 EXPAND_FILL
# │       │   ├── SFXSlider (HSlider) — min 0 max 1 step 0.05 width 200
# │       │   └── SFXToggle (CheckButton) — "On/Off"
# │       ├── FullscreenRow (HBoxContainer)
# │       │   ├── Label — "🖥 Fullscreen" size 20 EXPAND_FILL
# │       │   └── FullscreenToggle (CheckButton)
# │       ├── HSeparator
# │       ├── VersionLabel (Label) — "PrintForge Legends v0.1.0" size 16
# │       │   color #555555 center
# │       └── ResetRow (VBoxContainer)
# │           ├── ResetLabel (Label) — "⚠ Reset All Progress" size 18
# │           │   color #884444
# │           ├── ResetWarning (Label) — "This deletes everything permanently."
# │           │   size 14 color #666666
# │           └── ResetBtn (Button) — "Reset Save Data"
# │               color #662222 min 200x44

extends Node2D

@onready var music_slider: HSlider      = $UI/SettingsPanel/MusicRow/MusicSlider
@onready var music_toggle: CheckButton  = $UI/SettingsPanel/MusicRow/MusicToggle
@onready var sfx_slider: HSlider        = $UI/SettingsPanel/SFXRow/SFXSlider
@onready var sfx_toggle: CheckButton    = $UI/SettingsPanel/SFXRow/SFXToggle
@onready var fullscreen_toggle: CheckButton = $UI/SettingsPanel/FullscreenRow/FullscreenToggle

func _ready() -> void:
	_load_current_settings()

func _load_current_settings() -> void:
	music_slider.value   = AudioManager._music_volume
	sfx_slider.value     = AudioManager._sfx_volume
	music_toggle.button_pressed  = AudioManager._music_enabled
	sfx_toggle.button_pressed    = AudioManager._sfx_enabled
	fullscreen_toggle.button_pressed = \
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

# ─────────────────────────────────────────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────────────────────────────────────────
func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_music_toggle_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_music(toggled_on)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

func _on_sfx_toggle_toggled(toggled_on: bool) -> void:
	AudioManager.toggle_sfx(toggled_on)

func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Save fullscreen pref
	if SaveManager.data.has("settings"):
		SaveManager.data["settings"]["fullscreen"] = toggled_on
		SaveManager.save_game()

func _on_reset_btn_pressed() -> void:
	# Show confirmation dialog before wiping save
	var dialog := AcceptDialog.new()
	dialog.title = "Reset Save Data"
	dialog.dialog_text = "This will permanently delete ALL progress.\nYour prints, coins, XP, and blueprints will be lost.\n\nAre you absolutely sure?"
	dialog.add_button("Cancel", true, "cancel")
	dialog.confirmed.connect(_confirm_reset)
	add_child(dialog)
	dialog.popup_centered()

func _confirm_reset() -> void:
	# Delete save file and reload from scratch
	DirAccess.remove_absolute(
		ProjectSettings.globalize_path("user://save_data.json")
	)
	get_tree().quit()
	# On next launch, save file won't exist → fresh start

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")
