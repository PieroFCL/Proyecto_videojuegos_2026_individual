extends Marker2D

# Punto de entrada donde aparecerá el jugador al cambiar de nivel.
class_name EntrancePoint

# Dirección que mirará el jugador al aparecer (UP, DOWN, LEFT, RIGHT).
@export var facing_direction: Vector2 = Vector2.DOWN

# Guarda dirección como metadato para que LevelManager lo lea.
func _ready():
	set_meta("facing_direction", facing_direction)
