class_name StateIdle extends State

@onready var walk: State = $"../Walk"   # Referencia al estado Walk

# Al entrar, actualiza animación y notifica
func enter() -> void:
	print("Idle enter")
	player.update_animation("idle")

# Al salir, no requiere acciones adicionales
func exit() -> void:
	pass

# Evalúa transición a Walk o WalkFast según input
func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		if Input.is_action_pressed("sprint"):
			return $"../WalkFast"
		else:
			return walk
	return null

# Detiene el movimiento físico del jugador
func physics_process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	return null

# No maneja input específico en este estado
func handle_input(_event: InputEvent) -> State:
	return null
