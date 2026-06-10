class_name PlayerStateMachine extends Node

# Señal emitida al cambiar de estado.
signal state_changed(state_name: String)

# Referencia al jugador controlado por esta máquina.
var player: Player

# Lista de todos los estados hijos (heredan de State).
var states: Array[State] = []

# Estado actualmente activo.
var current_state: State = null

# Estado anterior (para transiciones especiales).
var previous_state: State = null

# Configura la máquina y prepara todos los estados hijos.
func initialize(_player: Player) -> void:
	player = _player
	states.clear()

	for child in get_children():
		if child is State:
			var state := child as State
			state.player = player
			state.state_machine = self
			states.append(state)

	if states.size() > 0:
		change_state(states[0])

# Ejecuta la lógica por frame del estado actual.
func _process(delta: float) -> void:
	if current_state == null:
		return

	var next_state := current_state.process(delta)
	if next_state != null:
		change_state(next_state)

# Ejecuta la lógica física del estado actual.
func _physics_process(delta: float) -> void:
	if current_state == null:
		return

	var next_state := current_state.physics_process(delta)
	if next_state != null:
		change_state(next_state)

# Maneja eventos de entrada no consumidos para el estado actual.
func _unhandled_input(event: InputEvent) -> void:
	if current_state == null:
		return

	var next_state := current_state.handle_input(event)
	if next_state != null:
		change_state(next_state)

# Cambia al nuevo estado ejecutando salida y entrada correspondientes.
func change_state(new_state: State) -> void:
	var from_state = "null"
	if current_state:
		from_state = current_state.name
	print(" change_state: ", from_state, " -> ", new_state.name)
	if new_state == null or new_state == current_state:
		return
	if current_state != null:
		current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()
	state_changed.emit(current_state.name)
