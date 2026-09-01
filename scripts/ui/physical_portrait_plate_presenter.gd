class_name PhysicalPortraitPlatePresenter
extends Control
## Fits a composition master without crop and exposes the exact rect that owns
## all native controls. Edge bleed remains native navy/wood, never duplicated art.

var plate_rect := Rect2()
var plate_texture: Texture2D
var _content_layer: Control

func configure(texture: Texture2D) -> void:
	plate_texture = texture
	queue_redraw()

func content_layer() -> Control:
	if _content_layer == null:
		_content_layer = Control.new()
		_content_layer.name = "PhysicalPlateContentLayer"
		_content_layer.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(_content_layer)
	_sync_content_layer()
	return _content_layer

func _sync_content_layer() -> void:
	if _content_layer != null:
		var fitted := fit_rect()
		_content_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_content_layer.position = fitted.position
		_content_layer.size = fitted.size

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_content_layer()
		queue_redraw()

func fit_rect() -> Rect2:
	var texture_size := Vector2(plate_texture.get_width(), plate_texture.get_height()) if plate_texture != null else Vector2.ZERO
	var result := composition_rect(size, texture_size)
	plate_rect = result
	return result

static func composition_rect(container_size: Vector2, master_size: Vector2) -> Rect2:
	## Normal portrait retains the authored contain composition.  The named M6 very
	## tall fixture instead maps one physical composition across the whole usable
	## surface: there is no second bottom reserve or letterbox ownership.
	if container_size.x <= 0.0 or container_size.y <= 0.0 or master_size.x <= 0.0 or master_size.y <= 0.0:
		return Rect2(Vector2.ZERO, container_size)
	if container_size.y / maxf(container_size.x, 1.0) > 2.05:
		return Rect2(Vector2.ZERO, container_size)
	var ratio := master_size.x / master_size.y
	var width := minf(container_size.x, container_size.y * ratio)
	return Rect2((container_size - Vector2(width, width / ratio)) * 0.5, Vector2(width, width / ratio))

func design_rect(rect: Rect2, design_size := Vector2(576, 928)) -> Rect2:
	var fitted := fit_rect()
	return Rect2(fitted.position + rect.position * fitted.size / design_size, rect.size * fitted.size / design_size)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111b"))
	var fitted := fit_rect()
	if plate_texture != null:
		draw_texture_rect(plate_texture, fitted, false)
	var top := Rect2(0, 0, size.x, fitted.position.y)
	var bottom := Rect2(0, fitted.end.y, size.x, size.y - fitted.end.y)
	draw_rect(top, Color("2c1c14"), true)
