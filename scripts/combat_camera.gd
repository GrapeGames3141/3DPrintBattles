class_name CombatCameraController
extends RefCounted

const MIN_PITCH := 24.0
const MAX_PITCH := 72.0
const TOUCH_PAN_SPEED := 0.035
const MOUSE_PAN_SPEED := 0.028
const ORBIT_SPEED := 0.18
const TOUCH_DRAG_THRESHOLD := 12.0

var camera_rig: Node3D
var camera: Camera3D
var world_root: Node3D
var map_width := 0
var map_height := 0
var cell_size := 1.0
var default_focus := Vector3.ZERO
var default_distance := 55.0
var minimum_distance := 8.0
var maximum_distance := 72.0
var default_offset := Vector3(0.0, 44.0, 51.0)
var default_pitch := 40.78

var focus := Vector3.ZERO
var distance := 55.0
var yaw_degrees := 0.0
var pitch_degrees := 40.78
var camera_dragging := false
var camera_rotation_dragging := false
var active_touches := {}
var touch_start_positions := {}
var touch_dragged := {}
var pinch_distance := -1.0
var pinch_active := false
var two_finger_angle := 0.0
var two_finger_centroid := Vector2.ZERO


func configure(
	rig: Node3D,
	view_camera: Camera3D,
	world: Node3D,
	grid_width: int,
	grid_height: int,
	grid_cell_size: float,
	initial_focus: Vector3,
	initial_distance: float,
	min_distance: float,
	max_distance: float,
	initial_offset: Vector3,
	initial_pitch: float
) -> void:
	camera_rig = rig
	camera = view_camera
	world_root = world
	map_width = grid_width
	map_height = grid_height
	cell_size = grid_cell_size
	default_focus = initial_focus
	default_distance = initial_distance
	minimum_distance = min_distance
	maximum_distance = max_distance
	default_offset = initial_offset
	default_pitch = initial_pitch
	reset_view()


func handle_input(event: InputEvent, cell_clicked: Callable) -> bool:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event, cell_clicked)
		return true
	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return true
	if event is InputEventMouseButton:
		if OS.has_feature("mobile") and event.button_index == MOUSE_BUTTON_LEFT:
			return true
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_dragging = event.pressed
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT:
			camera_rotation_dragging = event.pressed
			return true
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_distance(distance - 2.0)
			return true
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_distance(distance + 2.0)
			return true
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_emit_cell_click(event.position, cell_clicked)
			return true
	if event is InputEventMouseMotion and camera_dragging:
		_pan(event.relative, MOUSE_PAN_SPEED)
		return true
	if event is InputEventMouseMotion and camera_rotation_dragging:
		_orbit(event.relative)
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			yaw_degrees -= 45.0
			_update_transform()
			return true
		if event.keycode == KEY_E:
			yaw_degrees += 45.0
			_update_transform()
			return true
		if event.keycode == KEY_HOME:
			reset_view()
			return true
	return false


func reset_view() -> void:
	focus = default_focus
	distance = default_distance
	yaw_degrees = 0.0
	pitch_degrees = default_pitch
	_update_transform()


func screen_to_cell(screen_position: Vector2) -> Vector2i:
	if camera == null or world_root == null:
		return Vector2i(-1, -1)
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit == null:
		return Vector2i(-1, -1)
	var local_hit: Vector3 = world_root.to_local(hit)
	var x := roundi(local_hit.x / cell_size + float(map_width - 1) * 0.5)
	var y := roundi(local_hit.z / cell_size + float(map_height - 1) * 0.5)
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func set_distance(value: float) -> void:
	distance = clampf(value, minimum_distance, maximum_distance)
	_update_transform()


func _emit_cell_click(position: Vector2, callback: Callable) -> void:
	var cell := screen_to_cell(position)
	if cell.x >= 0 and callback.is_valid():
		callback.call(cell)


func _handle_screen_touch(event: InputEventScreenTouch, cell_clicked: Callable) -> void:
	if event.pressed:
		active_touches[event.index] = event.position
		touch_start_positions[event.index] = event.position
		touch_dragged[event.index] = false
		if active_touches.size() >= 2:
			pinch_active = true
			pinch_distance = _current_pinch_distance()
			two_finger_angle = _current_two_finger_angle()
			two_finger_centroid = _current_touch_centroid()
			for touch_index in touch_dragged.keys():
				touch_dragged[touch_index] = true
		return
	var was_gesture := pinch_active or bool(touch_dragged.get(event.index, false)) or active_touches.size() > 1
	active_touches.erase(event.index)
	touch_start_positions.erase(event.index)
	touch_dragged.erase(event.index)
	if active_touches.size() < 2:
		pinch_distance = -1.0
		two_finger_angle = 0.0
		two_finger_centroid = Vector2.ZERO
	if active_touches.is_empty():
		pinch_active = false
	if not was_gesture:
		_emit_cell_click(event.position, cell_clicked)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	active_touches[event.index] = event.position
	var start_position: Vector2 = touch_start_positions.get(event.index, event.position)
	if start_position.distance_to(event.position) >= TOUCH_DRAG_THRESHOLD:
		touch_dragged[event.index] = true
	if active_touches.size() >= 2:
		pinch_active = true
		for touch_index in touch_dragged.keys():
			touch_dragged[touch_index] = true
		var next_distance := _current_pinch_distance()
		var next_angle := _current_two_finger_angle()
		var next_centroid := _current_touch_centroid()
		if pinch_distance > 0.0 and next_distance > 0.0:
			set_distance(distance - (next_distance - pinch_distance) * 0.15)
		var angle_delta := wrapf(next_angle - two_finger_angle, -PI, PI)
		yaw_degrees -= rad_to_deg(angle_delta)
		pitch_degrees = clampf(
			pitch_degrees - (next_centroid.y - two_finger_centroid.y) * ORBIT_SPEED,
			MIN_PITCH,
			MAX_PITCH
		)
		pinch_distance = next_distance
		two_finger_angle = next_angle
		two_finger_centroid = next_centroid
		_update_transform()
		return
	if not pinch_active and bool(touch_dragged.get(event.index, false)):
		_pan(event.relative, TOUCH_PAN_SPEED)


func _pan(screen_delta: Vector2, speed: float) -> void:
	var right := camera.global_transform.basis.x
	var forward := -camera.global_transform.basis.z
	right.y = 0.0
	forward.y = 0.0
	if right.length_squared() < 0.0001 or forward.length_squared() < 0.0001:
		return
	var zoom_scale := clampf(distance / default_distance, 0.35, 1.35)
	focus += (-right.normalized() * screen_delta.x - forward.normalized() * screen_delta.y) * speed * zoom_scale
	var x_limit := float(map_width - 1) * cell_size * 0.55
	var z_limit := float(map_height - 1) * cell_size * 0.55
	focus.x = clampf(focus.x, -x_limit, x_limit)
	focus.z = clampf(focus.z, -z_limit, z_limit)
	_update_transform()


func _orbit(screen_delta: Vector2) -> void:
	yaw_degrees -= screen_delta.x * ORBIT_SPEED
	pitch_degrees = clampf(pitch_degrees - screen_delta.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
	_update_transform()


func _update_transform() -> void:
	if camera == null or camera_rig == null:
		return
	camera_rig.position = focus
	camera_rig.rotation_degrees.y = yaw_degrees
	var orbit_length := default_offset.length() * distance / default_distance
	var pitch_radians := deg_to_rad(pitch_degrees)
	camera.position = Vector3(0.0, sin(pitch_radians) * orbit_length, cos(pitch_radians) * orbit_length)
	camera.look_at(focus, Vector3.UP)


func _current_pinch_distance() -> float:
	if active_touches.size() < 2:
		return -1.0
	var positions: Array = active_touches.values()
	return (positions[0] as Vector2).distance_to(positions[1] as Vector2)


func _current_two_finger_angle() -> float:
	if active_touches.size() < 2:
		return 0.0
	var positions: Array = active_touches.values()
	var first: Vector2 = positions[0]
	var second: Vector2 = positions[1]
	return (second - first).angle()


func _current_touch_centroid() -> Vector2:
	if active_touches.is_empty():
		return Vector2.ZERO
	var result := Vector2.ZERO
	for position in active_touches.values():
		result += position as Vector2
	return result / float(active_touches.size())
