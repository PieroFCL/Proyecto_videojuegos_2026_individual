extends Node
var current_bounds: Rect2i = Rect2i()
var current_camera: Camera2D = null

func set_bounds(bounds: Rect2i) -> void:
	current_bounds = bounds
	_apply_bounds_if_possible()

func register_camera(camera: Camera2D) -> void:
	current_camera = camera
	_apply_bounds_if_possible()

func clear_camera(camera: Camera2D) -> void:
	if current_camera == camera:
		current_camera = null

func clear_bounds() -> void:
	current_bounds = Rect2i()

func _apply_bounds_if_possible() -> void:
	if current_camera == null:
		return
	if current_bounds.size == Vector2i.ZERO:
		return

	current_camera.limit_left = current_bounds.position.x
	current_camera.limit_top = current_bounds.position.y
	current_camera.limit_right = current_bounds.end.x
	current_camera.limit_bottom = current_bounds.end.y

	# Evita que el smoothing deje la cámara visualmente fuera del área
	current_camera.reset_smoothing()
