class_name StateWalk extends State

# Velocidad de movimiento del jugador mientras camina normalmente.
@export var move_speed: float = 70.0

# Referencia estado Idle para transicionar cuando jugador detiene movimiento.
@onready var idle: State = $"../Idle"

# Al entrar estado, actualiza animación caminar y registra cambio en consola.
func enter() -> void:
	print("Walk: enter")
	player.update_animation("walk")

# No realiza ninguna acción específica al salir del estado.
func exit() -> void: 
	pass

# Evalúa las condiciones para cambiar a otros estados en cada frame.
func process(_delta: float) -> State:
	# Si no hay dirección de movimiento, transiciona al estado Idle.
	if player.direction == Vector2.ZERO:
		return idle
	# Si se mantiene presionado sprint, transiciona al estado WalkFast.
	if Input.is_action_pressed("sprint"):
		return $"../WalkFast"
	# Actualiza la animación por si la dirección ha cambiado.
	player.update_animation("walk")
	return null

# Aplica la velocidad de movimiento al jugador usando dirección actual.
func physics_process(_delta: float) -> State: 
	player.velocity = player.direction * move_speed 
	return null

# No procesa eventos de entrada específicos en este estado.
func handle_input(_event: InputEvent) -> State:
	return null
