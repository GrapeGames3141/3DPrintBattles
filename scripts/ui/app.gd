extends Control
## Root of the game: owns the background, the stage every screen is laid out
## on, and screen-to-screen navigation.
##
## The stage is 1280x720 in landscape and 720x1280 in portrait. When the
## window (or phone) changes shape, the stage flips and the current screen is
## laid out again on the spot.

const STAGE_L := Vector2(1280, 720)
const STAGE_P := Vector2(720, 1280)
const SCREENS := {
	"starter": "res://scripts/ui/screens/starter_screen.gd",
	"menu": "res://scripts/ui/screens/menu_screen.gd",
	"play": "res://scripts/ui/screens/play_screen.gd",
	"collection": "res://scripts/ui/screens/collection_screen.gd",
	"shop": "res://scripts/ui/screens/shop_screen.gd",
	"blueprints": "res://scripts/ui/screens/blueprint_screen.gd",
	"workshop": "res://scripts/ui/screens/workshop_screen.gd",
	"profile": "res://scripts/ui/screens/profile_screen.gd",
	"battle": "res://scripts/ui/screens/battle_screen.gd",
}

## Which music plays on each screen (the battle picks its own).
const MUSIC := {"starter": "menu", "menu": "menu", "play": "menu", "collection": "bench", "workshop": "bench", "blueprints": "bench", "shop": "shop", "profile": "menu"}

var bg: TextureRect
var shade: ColorRect
var stage: Control
var current: GameScreen
var net: NetLink
var portrait := false
var stage_size := STAGE_L
var _switching := false
var _fitted := false


func _ready() -> void:
	theme = UI.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bg = TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	shade = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	net = NetLink.new()
	net.name = "Net"
	add_child(net)
	get_tree().node_added.connect(_juice)
	apply_fullscreen()
	_fit()
	get_tree().root.size_changed.connect(_fit)
	go("menu" if Profile.started() else "starter")


## Every button in the game gets the same feel: it swells under the pointer and
## squashes when pressed.
func _juice(n: Node) -> void:
	if not (n is Button) or n.has_meta("still"):
		return
	var b := n as Button
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)
	b.pivot_offset = b.size * 0.5
	var to := func(target: float, t: float):
		if not is_instance_valid(b) or not b.is_inside_tree():
			return
		var key := "_juice_tw"
		if b.has_meta(key):
			var old = b.get_meta(key)
			if old is Tween and (old as Tween).is_valid():
				(old as Tween).kill()
		var tw := b.create_tween()
		b.set_meta(key, tw)
		tw.tween_property(b, "scale", Vector2(target, target), t).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	b.mouse_entered.connect(func(): if not b.disabled: to.call(1.04, 0.12))
	b.mouse_exited.connect(func(): to.call(1.0, 0.12))
	b.button_down.connect(func(): to.call(0.95, 0.06))
	b.button_up.connect(func(): to.call(1.04 if b.is_hovered() else 1.0, 0.12))


## Picks the landscape or portrait stage from the window's shape.
func _fit() -> void:
	var win := Vector2(get_window().size)
	var want := win.y > win.x * 1.02
	if _fitted and want == portrait:
		return
	_fitted = true
	portrait = want
	stage_size = STAGE_P if portrait else STAGE_L
	get_window().content_scale_size = Vector2i(stage_size)
	stage.offset_left = -stage_size.x * 0.5
	stage.offset_right = stage_size.x * 0.5
	stage.offset_top = -stage_size.y * 0.5
	stage.offset_bottom = stage_size.y * 0.5
	if current != null and not _switching:
		current.size = stage_size
		current.relayout()


func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		return
	var want := bool(Profile.setting("fullscreen"))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if want else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		Profile.set_setting("fullscreen", not bool(Profile.setting("fullscreen")))
		apply_fullscreen()


func set_background(path: String, dim: float = 0.35) -> void:
	bg.texture = UI.tex(path)
	shade.color.a = dim


## Switches screens with a short fade.
func go(screen: String, args: Dictionary = {}) -> void:
	if _switching or not SCREENS.has(screen):
		return
	_switching = true
	if current != null:
		var old := current
		var out := old.create_tween()
		out.tween_property(old, "modulate:a", 0.0, 0.12)
		await out.finished
		old.queue_free()
	var s: GameScreen = (load(SCREENS[screen]) as GDScript).new()
	s.app = self
	s.args = args
	s.size = stage_size
	s.modulate.a = 0.0
	stage.add_child(s)
	current = s
	if MUSIC.has(screen):
		Audio.music(MUSIC[screen])
	s.build()
	var enter := s.create_tween().set_parallel(true)
	enter.tween_property(s, "modulate:a", 1.0, 0.2)
	s.position.y = 14.0
	enter.tween_property(s, "position:y", 0.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_switching = false
	# The window may have turned while the old screen was fading out.
	if s.size != stage_size:
		s.size = stage_size
		s.relayout()


func toast(text: String, color: Color = UI.CREAM) -> void:
	UI.floater(stage, text, Vector2(stage_size.x * 0.5, 120), color, 22 if portrait else 28, 30.0, 1.8)
