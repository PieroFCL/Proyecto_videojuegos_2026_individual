class_name PlayerStateMachine extends Node

var player: Player # Referencia al jugador
var states: Array[State] = [] # Lista de estados detectados
var current_state: State = null # Estado activo ejecutándose
var previous_state: State = null # Estado anterior

# Inicializa la máquina de estados y asigna el jugador a cada estado
func initialize(_player: Player) -> void:
	player = _player # Asigna referencia del jugador
	states.clear() # Limpia estados previos

	for child in get_children(): # Recorre nodos hijos 
		if child is State: # Filtra nodos tipo State
			var state := child as State # Convierte nodo a State
			state.player = player
			state.state_machine = self
			states.append(state) # Agrega estado a lista 

	if states.size() > 0: # Verifica estados disponibles
		change_state(states[0]) # Inicia con el primer estado

# Ejecuta lógica de estado en cada frame
func _process(delta: float) -> void:
	if current_state == null: # Evita ejecución sin estado activo
		return

	var next_state := current_state.process(delta) # Ejecuta lógica del estado actual
	if next_state != null: # Si el estado solicita transición
		change_state(next_state) # Cambia al nuevo estado

# Ejecuta lógica física del estado
func _physics_process(delta: float) -> void:
	if current_state == null: # Evita ejecución sin estado activo
		return

	var next_state := current_state.physics_process(delta) # Ejecuta lógica física del estado
	if next_state != null: # Si el estado solicita cambio
		change_state(next_state) # Aplica transición

# Maneja input no consumido por otros nodos
func _unhandled_input(event: InputEvent) -> void:
	if current_state == null: # Evita procesamiento sin estado activo
		return

	var next_state := current_state.handle_input(event) # Input al estado actual
	if next_state != null:
		change_state(next_state) # Ejecuta transición

# Realiza el cambio de estado de forma controlada
func change_state(new_state: State) -> void:
	if new_state == null or new_state == current_state: # Evita cambios inválidos
		return

	if current_state != null:
		current_state.exit() # Ejecuta salida del estado actual

	previous_state = current_state # Guarda estado anterior
	current_state = new_state # Asigna nuevo estado activo
	current_state.enter() # Ejecuta entrada del nuevo estado
