extends Camera2D

func _ready() -> void:
	make_current()
	CameraManager.register_camera(self)

func _exit_tree() -> void:
	CameraManager.clear_camera(self)
