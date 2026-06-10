extends Node

# Activa o desactiva los logs con F3.
var enabled: bool = true

# Configura el logger al iniciar.
func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	print("InputLogger activado. Presiona F3 para activar/desactivar logs.")

# Procesa eventos de teclado para sonido y logs.
func _input(event: InputEvent):
	# Ignora eventos si el logger está desactivado.
	if not enabled:
		return

	# Reproduce sonido UI para teclas válidas (sin movimiento).
	if event is InputEventKey and event.pressed and not event.echo:
		# Teclas que no deben reproducir sonido.
		var ignore_keys = [
			KEY_W, KEY_A, KEY_S, KEY_D,           # Movimiento WASD
			KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, # Flechas
			KEY_SHIFT, KEY_CTRL, KEY_ALT           # Modificadores
		]
		# Reproduce sonido si la tecla no está en la lista.
		if event.keycode not in ignore_keys:
			# Llama al AudioManager si existe.
			if AudioManager and AudioManager.has_method("play_ui_sfx"):
				AudioManager.play_ui_sfx()

	# Muestra logs para acciones personalizadas.
	if event is InputEventKey:
		# Lista de acciones personalizadas relevantes.
		var actions = [
			"menu_cancel", "menu_accept", "menu_up", "menu_down",
			"menu_left", "menu_right", "interact", "inventory", "toggle_inventory"
		]
		# Imprime presión o liberación de acciones.
		for action in actions:
			if event.is_action_pressed(action) or event.is_action_released(action):
				var estado = "presionada" if event.is_action_pressed(action) else "liberada"
				print("[INPUT] ", action, " (", estado, ") - tecla física: ", event.keycode, " ", event.as_text())
				break
		# Log directo de tecla Q por si falla acción.
		if event.keycode == KEY_Q:
			print("[INPUT] Tecla Q física - pressed: ", event.pressed)

	# Activa o desactiva logs con F3.
	if event.is_action_pressed("ui_debug") or (event is InputEventKey and event.keycode == KEY_F3):
		enabled = !enabled
		print("[INPUT] Logs de entrada ", "activados" if enabled else "desactivados")
