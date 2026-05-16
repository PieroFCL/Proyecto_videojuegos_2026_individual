extends Camera2D

# Registra la cámara en el CameraManager y la hace activa al iniciar
func _ready() -> void:
	make_current()
	CameraManager.register_camera(self)

# Elimina la cámara del registro al salir de la escena
func _exit_tree() -> void:
	CameraManager.clear_camera(self)
