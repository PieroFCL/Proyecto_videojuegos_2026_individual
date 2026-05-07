class_name StateIdle extends State

@onready var walk: State = $"../Walk" # Referencia a walk

# Se ejecuta al entrar en el estado idle
func enter() -> void:
	player.update_animation("idle") # Reproduce animacion idle

# Se ejecuta al salir del estado idle
func exit() -> void:
	pass

# Evalua transiciones en cada frame
func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		if Input.is_action_pressed("sprint"):
			return $"../WalkFast"
		else:
			return walk
	return null

# Mantiene al jugador sin movimiento
func physics_process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	return null

# Maneja input si se requiere cambiar de estado
func handle_input(_event: InputEvent) -> State:
	return null
