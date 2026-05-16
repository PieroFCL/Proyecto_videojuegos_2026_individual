extends Node

# Límites actuales del mapa (en coordenadas globales de píxeles)
var current_bounds: Rect2i = Rect2i()
# Referencia a la cámara activa del jugador
var current_camera: Camera2D = null

# Actualiza los límites y los aplica si la cámara está disponible
func set_bounds(bounds: Rect2i) -> void:
	current_bounds = bounds
	_apply_bounds_if_possible()

# Registra la cámara activa y aplica los límites actuales
func register_camera(camera: Camera2D) -> void:
	current_camera = camera
	_apply_bounds_if_possible()

# Elimina la cámara registrada si coincide con la pasada
func clear_camera(camera: Camera2D) -> void:
	if current_camera == camera:
		current_camera = null

# Restablece los límites a vacío (sin restricciones)
func clear_bounds() -> void:
	current_bounds = Rect2i()

# Aplica los límites a la cámara registrada si ambos existen
func _apply_bounds_if_possible() -> void:
	if current_camera == null:
		return
	if current_bounds.size == Vector2i.ZERO:
		return

	# Configura los límites de desplazamiento de la cámara
	current_camera.limit_left = current_bounds.position.x
	current_camera.limit_top = current_bounds.position.y
	current_camera.limit_right = current_bounds.end.x
	current_camera.limit_bottom = current_bounds.end.y

	# Evita que el suavizado (smoothing) muestre áreas fuera del límite
	current_camera.reset_smoothing()
