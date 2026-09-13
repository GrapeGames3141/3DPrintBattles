class_name TeamPrototypeChassis
extends RefCounted
## Shared, data-free stage mechanics for the prototype's native route presenters.

const DESIGN := Vector2(941, 1672)


static func remove_route_children(content: Control) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()


static func fit_design(stage: Control, viewport: Vector2, insets: Rect2) -> void:
	var usable := viewport - Vector2(insets.position.x + insets.size.x, insets.position.y + insets.size.y)
	if usable.x <= 0.0 or usable.y <= 0.0:
		return
	var scale_factor := minf(usable.x / DESIGN.x, usable.y / DESIGN.y)
	stage.scale = Vector2.ONE * scale_factor
	stage.position = insets.position + (usable - DESIGN * scale_factor) * 0.5


static func mobile_safe_insets(viewport: Vector2) -> Rect2:
	# Desktop safe rectangles describe monitor work areas, not app-content notches.
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var safe_display := DisplayServer.get_display_safe_area()
	var client_origin := DisplayServer.window_get_position()
	var client_size := DisplayServer.window_get_size()
	return local_safe_insets(viewport, Vector2(client_origin), Vector2(client_size), Rect2(Vector2(safe_display.position), Vector2(safe_display.size)))


static func local_safe_insets(viewport: Vector2, client_origin: Vector2, client_size: Vector2, safe_display: Rect2) -> Rect2:
	if client_size.x <= 0.0 or client_size.y <= 0.0 or viewport.x <= 0.0 or viewport.y <= 0.0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var local_safe := safe_display.intersection(Rect2(client_origin, client_size))
	if local_safe.size.x <= 0 or local_safe.size.y <= 0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var scale := viewport / client_size
	var local_position := (local_safe.position - client_origin) * scale
	var local_end: Vector2 = local_position + local_safe.size * scale
	return Rect2(
		Vector2(maxf(local_position.x, 0.0), maxf(local_position.y, 0.0)),
		Vector2(maxf(0.0, viewport.x - local_end.x), maxf(0.0, viewport.y - local_end.y))
	)
