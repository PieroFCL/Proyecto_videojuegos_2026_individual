extends Marker2D
class_name EntrancePoint

# Dirección hacia la que mirará el jugador al aparecer (Vector2.UP, DOWN, LEFT, RIGHT)
@export var facing_direction: Vector2 = Vector2.DOWN

# Guarda la dirección como metadato para que LevelManager la pueda leer
func _ready():
	set_meta("facing_direction", facing_direction)
