class_name StateWalk extends State

# Velocidad de movimiento del jugador en este estado
@export var move_speed: float = 70.0

# Referencia al estado Idle para transición cuando no hay dirección
@onready var idle: State = $"../Idle"

# Al entrar, actualiza la animación de caminar
func enter() -> void:
	print("Walk: enter")
	player.update_animation("walk")

# Sin acciones específicas al salir
func exit() -> void: 
	pass

# Evalúa transiciones en cada frame
func process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	if Input.is_action_pressed("sprint"):
		return $"../WalkFast"
	player.update_animation("walk")
	return null

# Aplica velocidad según la dirección y la velocidad de movimiento
func physics_process(_delta: float) -> State: 
	player.velocity = player.direction * move_speed 
	return null

# No maneja entrada específica en este estado
func handle_input(_event: InputEvent) -> State:
	return null
