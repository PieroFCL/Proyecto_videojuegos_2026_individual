extends Node2D

# Referencia a la capa de tiles que define los límites del nivel
@onready var bounds_layer: TileMapLayer = $BoundsLayer

# Publica los límites del mapa al CameraManager cuando el nivel entra en escena
func _ready() -> void:
	_publish_bounds()

# Limpia los límites de la cámara al salir del nivel
func _exit_tree() -> void:
	CameraManager.clear_bounds()

# Calcula el rectángulo de límites basado en los tiles usados de BoundsLayer y lo envía al CameraManager
func _publish_bounds() -> void:
	if bounds_layer == null:
		push_error("BoundsLayer no encontrado en " + name)
		return

	if bounds_layer.tile_set == null:
		push_error("BoundsLayer sin TileSet en " + name)
		return
	
	# Área de celdas ocupadas en el mapa de límites
	var used: Rect2i = bounds_layer.get_used_rect()  

	if used.size == Vector2i.ZERO:
		push_warning("BoundsLayer vacío en " + name)
		return

	# Tamaño en píxeles de cada tile
	var tile_size: Vector2i = bounds_layer.tile_set.tile_size

	# Convierte la posición de tile a coordenadas globales del mundo
	var world_position: Vector2i = Vector2i(bounds_layer.global_position) + used.position * tile_size
	var world_size: Vector2i = used.size * tile_size

	# Aplica los límites calculados a la cámara del jugador
	CameraManager.set_bounds(Rect2i(world_position, world_size))
