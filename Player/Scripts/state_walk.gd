class_name StateWalk extends State

@export var move_speed: float = 70.0 # Velocidad de player
@onready var idle: State = $"../Idle" # Referencia a idle 

# Se ejecuta al entrar en el estado walk
func enter() -> void: 
	player.update_animation("walk") 

# Se ejecuta al salir del estado walk
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

# Aplica movimiento físico del estado
func physics_process(_delta: float) -> State: 
	player.velocity = player.direction * move_speed 
	return null

# Maneja input si se requiere cambiar de estado
func handle_input(_event: InputEvent) -> State:
	return null
