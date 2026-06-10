class_name StateIdle extends State

# Referencia estado Walk para transicionar cuando jugador se mueve.
@onready var walk: State = $"../Walk"

# Al entrar estado, actualiza animación a reposo y muestra en consola.
func enter() -> void:
	print("Idle enter")
	player.update_animation("idle")

# No requiere ninguna acción específica al salir del estado.
func exit() -> void:
	pass

# Evalúa si debe transicionar a Walk o WalkFast según dirección y tecla sprint.
func process(_delta: float) -> State:
	# Si hay dirección de movimiento, verifica si debe correr o caminar.
	if player.direction != Vector2.ZERO:
		# Si mantiene presionado sprint, transiciona a WalkFast; si no Walk.
		if Input.is_action_pressed("sprint"):
			return $"../WalkFast"
		else:
			return walk
	return null

# Detiene completamente movimiento del jugador.
func physics_process(_delta: float) -> State:
	player.velocity = Vector2.ZERO
	return null

# No procesa eventos de entrada específicos en este estado.
func handle_input(_event: InputEvent) -> State:
	return null
