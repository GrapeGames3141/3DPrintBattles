extends Control
## Root of the game: owns the background, the 1280x720 stage every screen is
## laid out on, and screen-to-screen navigation.

const STAGE := Vector2(1280, 720)
const SCREENS := {
	"starter": "res://scripts/ui/screens/starter_screen.gd",
	"menu": "res://scripts/ui/screens/menu_screen.gd",
	"play": "res://scripts/ui/screens/play_screen.gd",
	"collection": "res://scripts/ui/screens/collection_screen.gd",
	"shop": "res://scripts/ui/screens/shop_screen.gd",
	"workshop": "res://scripts/ui/screens/workshop_screen.gd",
	"battle": "res://scripts/ui/screens/battle_screen.gd",
}

var bg: TextureRect
var shade: ColorRect
var stage: Control
var current: GameScreen
var net: NetLink
var _switching := false


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
	stage.offset_left = -STAGE.x * 0.5
	stage.offset_right = STAGE.x * 0.5
	stage.offset_top = -STAGE.y * 0.5
	stage.offset_bottom = STAGE.y * 0.5
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	net = NetLink.new()
	net.name = "Net"
	add_child(net)
	apply_fullscreen()
	go("menu" if Profile.started() else "starter")


func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
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
	s.size = STAGE
	s.modulate.a = 0.0
	stage.add_child(s)
	current = s
	s.build()
	s.create_tween().tween_property(s, "modulate:a", 1.0, 0.16)
	_switching = false


func toast(text: String, color: Color = UI.CREAM) -> void:
	UI.floater(stage, text, Vector2(STAGE.x * 0.5, 120), color, 28, 30.0, 1.8)
