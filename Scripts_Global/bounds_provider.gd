extends Node2D

@onready var bounds_layer: TileMapLayer = $BoundsLayer

func _ready() -> void:
	_publish_bounds()

func _exit_tree() -> void:
	CameraManager.clear_bounds()

func _publish_bounds() -> void:
	if bounds_layer == null:
		push_error("BoundsLayer no encontrado en " + name)
		return

	if bounds_layer.tile_set == null:
		push_error("BoundsLayer sin TileSet en " + name)
		return

	var used: Rect2i = bounds_layer.get_used_rect()

	if used.size == Vector2i.ZERO:
		push_warning("BoundsLayer vacío en " + name)
		return

	var tile_size: Vector2i = bounds_layer.tile_set.tile_size

	# Conversión a mundo (IMPORTANTE)
	var world_position: Vector2i = Vector2i(bounds_layer.global_position) + used.position * tile_size
	var world_size: Vector2i = used.size * tile_size

	CameraManager.set_bounds(Rect2i(world_position, world_size))
