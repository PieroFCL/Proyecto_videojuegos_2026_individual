extends Area2D
# Actualiza orden de dibujo según posición vertical.

# Se ejecuta cada frame para mantener profundidad.
func _process(float) -> void:
	# Calcula z_index base más offset para orden correcto.
	z_index = int(global_position.y) + 500
