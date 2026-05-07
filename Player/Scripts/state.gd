class_name State extends Node

var player: Player # Referencia al jugador
var state_machine: PlayerStateMachine # Referencia a la maquina de estados

# Se ejecuta al entrar a este estado
func enter() -> void:
	pass

# Se ejecuta al salir de este estado
func exit() -> void:
	pass

# Logica por frame, puede devolver un nuevo estado
func process(_delta: float) -> State:
	return null

# Logica fisica, usada para movimiento o fuerzas
func physics_process(_delta: float) -> State:
	return null

# Manejo de input, permite cambiar de estado segun acciones
func handle_input(_event: InputEvent) -> State:
	return null
