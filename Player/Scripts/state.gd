class_name State extends Node

# Referencia al jugador para acceder a sus propiedades.
var player: Player
# Referencia a la máquina de estados para cambiar de estado.
var state_machine: PlayerStateMachine

# Configura el estado al entrar.
func enter() -> void:
	pass

# Limpia el estado al salir.
func exit() -> void:
	pass

# Lógica por frame; puede devolver un nuevo estado.
func process(_delta: float) -> State:
	return null

# Lógica física para movimiento o fuerzas.
func physics_process(_delta: float) -> State:
	return null

# Maneja entrada para cambiar de estado según acciones.
func handle_input(_event: InputEvent) -> State:
	return null
