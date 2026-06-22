# PrintYard.gd
# The Print Yard — a diorama where all owned prints wander and interact.
# Scene file: res://scenes/PrintYard.tscn
#
# SCENE TREE:
# PrintYard (Node2D)
# ├── Background (ColorRect) — #1A1A2E full screen
# ├── YardArea (ColorRect) — #0D1A0D (dark green floor), centered 1100x500
# ├── UI (CanvasLayer)
# │   ├── TopBar (HBoxContainer) — top full width height 60 bg #0D0D1A
# │   │   ├── TitleLabel (Label) — "🐾 Print Yard" size 24
# │   │   ├── CountLabel (Label) — "3 Prints roaming" size 18 color #AAAAAA
# │   │   └── BackBtn (Button) — "← Workshop" min 120x44
# │   └── StatPopup (Panel) — stat_popup, hidden, 280x320
# │       ├── PopupSprite (ColorRect) — 80x80
# │       ├── PopupName (Label) — size 22 bold
# │       ├── PopupElement (Label) — size 16
# │       ├── PopupBend (Label) — size 16
# │       ├── PopupHP (Label) — size 16
# │       ├── PopupAbility (Label) — size 14 autowrap
# │       ├── PopupBattles (Label) — size 14 color #AAAAAA
# │       └── ClosePopupBtn (Button) — "×" min 32x32

extends Node2D

const YARD_BOUNDS = Rect2(90, 100, 1100, 500)  # Where prints can roam
const WANDER_SPEED = 40.0                        # Pixels per second
const BEHAVIOR_CHANGE_MIN = 2.0                  # Seconds before new behavior
const BEHAVIOR_CHANGE_MAX = 5.0

# Behaviors a print can have in the yard
enum YardBehavior { WANDER, IDLE, SLEEP, INTERACT }

# Runtime data for each print in the yard
class YardPrint:
	var instance_id: String
	var creature_id: String
	var node: Control          # The visual node (ColorRect or TextureRect)
	var behavior: int = YardBehavior.WANDER
	var velocity: Vector2 = Vector2.ZERO
	var behavior_timer: float = 0.0
	var interact_target_id: String = ""  # instance_id of partner print

var yard_prints: Array[YardPrint] = []

@onready var yard_area: ColorRect = $YardArea
@onready var count_label: Label   = $UI/TopBar/CountLabel
@onready var stat_popup: Panel    = $UI/StatPopup
@onready var popup_sprite: ColorRect  = $UI/StatPopup/PopupSprite
@onready var popup_name: Label    = $UI/StatPopup/PopupName
@onready var popup_element: Label = $UI/StatPopup/PopupElement
@onready var popup_bend: Label    = $UI/StatPopup/PopupBend
@onready var popup_hp: Label      = $UI/StatPopup/PopupHP
@onready var popup_ability: Label = $UI/StatPopup/PopupAbility
@onready var popup_battles: Label = $UI/StatPopup/PopupBattles

func _ready() -> void:
	stat_popup.visible = false
	_spawn_prints()
	_update_count_label()

# ─────────────────────────────────────────────────────────────────────────────
# SPAWN ALL OWNED PRINTS
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_prints() -> void:
	var prints = SaveManager.get_prints()
	for inst in prints:
		if inst["hp_current"] <= 0:
			continue  # Don't show defeated prints
		_spawn_single_print(inst)

func _spawn_single_print(inst: Dictionary) -> void:
	var creature = GameData.CREATURES[inst["creature_id"]]

	var yp = YardPrint.new()
	yp.instance_id = inst["instance_id"]
	yp.creature_id = inst["creature_id"]

	# Try real sprite first, fall back to colored rect
	var sprite_path = "res://assets/sprites/%s" % creature["sprite"]
	if ResourceLoader.exists(sprite_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(sprite_path)
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		tex_rect.gui_input.connect(_on_print_clicked.bind(inst["instance_id"]))
		add_child(tex_rect)
		yp.node = tex_rect
	else:
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(56, 56)
		rect.color = creature["placeholder_color"]
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		rect.gui_input.connect(_on_print_clicked.bind(inst["instance_id"]))
		add_child(rect)
		yp.node = rect

	# Random starting position within yard bounds
	yp.node.position = Vector2(
		randf_range(YARD_BOUNDS.position.x, YARD_BOUNDS.end.x - 64),
		randf_range(YARD_BOUNDS.position.y, YARD_BOUNDS.end.y - 64)
	)

	# Random starting behavior timer
	yp.behavior_timer = randf_range(BEHAVIOR_CHANGE_MIN, BEHAVIOR_CHANGE_MAX)
	_pick_new_behavior(yp)

	yard_prints.append(yp)

# ─────────────────────────────────────────────────────────────────────────────
# UPDATE LOOP — moves prints around
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	for yp in yard_prints:
		yp.behavior_timer -= delta
		if yp.behavior_timer <= 0.0:
			_pick_new_behavior(yp)

		_update_print_movement(yp, delta)
		_clamp_to_yard(yp)

func _update_print_movement(yp: YardPrint, delta: float) -> void:
	match yp.behavior:
		YardBehavior.WANDER:
			yp.node.position += yp.velocity * delta
			# Slight wobble on idle
			yp.node.rotation = sin(Time.get_unix_time_from_system() * 2.0 + float(yp.instance_id.hash())) * 0.04
		YardBehavior.IDLE:
			# Gentle breathing scale
			var scale_pulse = 1.0 + sin(Time.get_unix_time_from_system() * 1.5) * 0.03
			yp.node.scale = Vector2(scale_pulse, scale_pulse)
		YardBehavior.SLEEP:
			# Nearly still, slight bob
			yp.node.position.y += sin(Time.get_unix_time_from_system() * 0.5) * 0.2
		YardBehavior.INTERACT:
			# Move toward interact target
			var target = _find_yard_print(yp.interact_target_id)
			if target != null:
				var dir = (target.node.position - yp.node.position).normalized()
				var dist = yp.node.position.distance_to(target.node.position)
				if dist > 80:
					yp.node.position += dir * WANDER_SPEED * 0.5 * delta
			else:
				_pick_new_behavior(yp)  # Target gone, pick something else

func _clamp_to_yard(yp: YardPrint) -> void:
	yp.node.position.x = clamp(yp.node.position.x,
		YARD_BOUNDS.position.x, YARD_BOUNDS.end.x - 64)
	yp.node.position.y = clamp(yp.node.position.y,
		YARD_BOUNDS.position.y, YARD_BOUNDS.end.y - 64)
	# Bounce off walls while wandering
	if yp.behavior == YardBehavior.WANDER:
		if yp.node.position.x <= YARD_BOUNDS.position.x or \
		   yp.node.position.x >= YARD_BOUNDS.end.x - 64:
			yp.velocity.x *= -1
		if yp.node.position.y <= YARD_BOUNDS.position.y or \
		   yp.node.position.y >= YARD_BOUNDS.end.y - 64:
			yp.velocity.y *= -1

# ─────────────────────────────────────────────────────────────────────────────
# BEHAVIOR SELECTION
# ─────────────────────────────────────────────────────────────────────────────
func _pick_new_behavior(yp: YardPrint) -> void:
	yp.behavior_timer = randf_range(BEHAVIOR_CHANGE_MIN, BEHAVIOR_CHANGE_MAX)

	# Weight: 50% wander, 20% idle, 15% sleep, 15% interact
	var roll = randf()
	if roll < 0.50:
		yp.behavior = YardBehavior.WANDER
		var angle = randf() * TAU
		yp.velocity = Vector2(cos(angle), sin(angle)) * WANDER_SPEED
	elif roll < 0.70:
		yp.behavior = YardBehavior.IDLE
		yp.velocity = Vector2.ZERO
	elif roll < 0.85:
		yp.behavior = YardBehavior.SLEEP
		yp.velocity = Vector2.ZERO
		yp.behavior_timer = randf_range(4.0, 8.0)  # Sleep longer
	else:
		# Try to interact with another print
		var others = yard_prints.filter(func(p): return p.instance_id != yp.instance_id)
		if others.size() > 0:
			var partner: YardPrint = others[randi() % others.size()]
			yp.behavior = YardBehavior.INTERACT
			yp.interact_target_id = partner.instance_id
			yp.velocity = Vector2.ZERO
		else:
			yp.behavior = YardBehavior.WANDER
			var angle = randf() * TAU
			yp.velocity = Vector2(cos(angle), sin(angle)) * WANDER_SPEED

# ─────────────────────────────────────────────────────────────────────────────
# CLICK TO SHOW STATS
# ─────────────────────────────────────────────────────────────────────────────
func _on_print_clicked(event: InputEvent, instance_id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var inst = SaveManager.get_print_by_instance_id(instance_id)
	if inst.is_empty():
		return
	_show_stat_popup(inst)

func _show_stat_popup(inst: Dictionary) -> void:
	var creature = GameData.CREATURES[inst["creature_id"]]
	var ability = GameData.ABILITIES[creature["ability"]]

	popup_sprite.color = creature["placeholder_color"]
	popup_name.text = creature["name"]
	popup_element.text = "Element: %s" % creature["element"].capitalize()
	popup_bend.text = "Bend Score: %d" % creature["bend_score"]
	popup_hp.text = "HP: %d / %d" % [inst["hp_current"], creature["hp_base"]]
	popup_ability.text = "Ability: %s\n%s" % [ability["name"], ability["description"]]
	popup_battles.text = "Battles: %d  |  Wins: %d" % [
		inst["times_battled"], inst["times_won"]
	]

	# Position popup near center-right, avoid going off-screen
	stat_popup.position = Vector2(900, 200)
	stat_popup.visible = true

func _on_close_popup_btn_pressed() -> void:
	stat_popup.visible = false

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _find_yard_print(instance_id: String) -> YardPrint:
	for yp in yard_prints:
		if yp.instance_id == instance_id:
			return yp
	return null

func _update_count_label() -> void:
	count_label.text = "%d Prints roaming" % yard_prints.size()

func _on_back_btn_pressed() -> void:
	SceneTransition.go_to("res://scenes/Workshop.tscn")
