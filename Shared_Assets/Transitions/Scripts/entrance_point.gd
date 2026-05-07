extends Marker2D
class_name EntrancePoint

## Dirección hacia la que mirará el jugador al aparecer en este punto.
## Debe ser un vector cardinal normalizado: Vector2.UP, DOWN, LEFT, RIGHT.
@export var facing_direction: Vector2 = Vector2.DOWN

func _ready():
	# Guardamos la dirección como metadata para que el LevelManager la pueda leer fácilmente.
	set_meta("facing_direction", facing_direction)
