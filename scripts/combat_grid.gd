class_name CombatGridNavigation
extends RefCounted

var map_width := 0
var map_height := 0
var cell_size := 1.0
var terrain: Dictionary
var obstacles: Dictionary
var printer_cells: Dictionary
var units: Dictionary
var cell_occupants: Dictionary
var water_terrain_id := "water"


func configure(
	grid_width: int,
	grid_height: int,
	grid_cell_size: float,
	terrain_state: Dictionary,
	obstacle_state: Dictionary,
	printer_cell_state: Dictionary,
	unit_state: Dictionary,
	occupant_state: Dictionary,
	water_id: String
) -> void:
	map_width = grid_width
	map_height = grid_height
	cell_size = grid_cell_size
	terrain = terrain_state
	obstacles = obstacle_state
	printer_cells = printer_cell_state
	units = unit_state
	cell_occupants = occupant_state
	water_terrain_id = water_id


func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		(float(cell.x) - float(map_width - 1) * 0.5) * cell_size,
		0.0,
		(float(cell.y) - float(map_height - 1) * 0.5) * cell_size
	)


func cells_center(cells: Array) -> Vector3:
	var result := Vector3.ZERO
	for cell in cells:
		result += cell_to_world(cell)
	return result / float(cells.size())


func reachable_cells(id: String, allowance: int) -> Dictionary:
	var start: Vector2i = units[id]["cell"]
	var costs := {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return int(costs[a]) < int(costs[b]))
		var current: Vector2i = frontier.pop_front()
		for neighbor in neighbors(current):
			if not is_walkable(neighbor, id):
				continue
			var next_cost := int(costs[current]) + movement_cost(id, neighbor)
			if next_cost > allowance:
				continue
			if not costs.has(neighbor) or next_cost < int(costs[neighbor]):
				costs[neighbor] = next_cost
				if not frontier.has(neighbor):
					frontier.append(neighbor)
	return costs


func find_path(id: String, destination: Vector2i, allowance: int) -> Array[Vector2i]:
	var start: Vector2i = units[id]["cell"]
	if start == destination:
		return [start]
	var costs := {start: 0}
	var came_from := {}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return int(costs[a]) < int(costs[b]))
		var current: Vector2i = frontier.pop_front()
		if current == destination:
			break
		for neighbor in neighbors(current):
			if not is_walkable(neighbor, id):
				continue
			var next_cost := int(costs[current]) + movement_cost(id, neighbor)
			if next_cost > allowance:
				continue
			if not costs.has(neighbor) or next_cost < int(costs[neighbor]):
				costs[neighbor] = next_cost
				came_from[neighbor] = current
				if not frontier.has(neighbor):
					frontier.append(neighbor)
	if not costs.has(destination):
		return []
	var path: Array[Vector2i] = [destination]
	var cursor := destination
	while cursor != start:
		cursor = came_from[cursor]
		path.push_front(cursor)
	return path


func movement_cost(id: String, cell: Vector2i) -> int:
	if terrain.get(cell, "grass") == water_terrain_id and not units[id]["statuses"].has("riverstep"):
		return 3
	return 1


func is_walkable(cell: Vector2i, mover_id := "") -> bool:
	if cell.x < 0 or cell.x >= map_width or cell.y < 0 or cell.y >= map_height:
		return false
	if obstacles.has(cell) or printer_cells.has(cell):
		return false
	if cell_occupants.has(cell) and str(cell_occupants[cell]) != mover_id:
		return false
	return true


func neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN]


func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func has_line_of_sight(source: Vector2i, target: Vector2i) -> bool:
	var delta := target - source
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps <= 1:
		return true
	for index in range(1, steps):
		var sample := Vector2(
			float(source.x) + float(delta.x) * float(index) / float(steps),
			float(source.y) + float(delta.y) * float(index) / float(steps)
		)
		if obstacles.has(Vector2i(roundi(sample.x), roundi(sample.y))):
			return false
	return true
