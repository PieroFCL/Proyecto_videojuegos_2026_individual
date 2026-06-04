extends Node

# Activar/desactivar logs con F3 (puedes cambiar la tecla)
var enabled: bool = true

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	print("InputLogger activado. Presiona F3 para activar/desactivar logs.")

func _input(event: InputEvent):
	if not enabled:
		return

	# reproducir sonido
	if event is InputEventKey and event.pressed and not event.echo:
		# Lista de teclas que NO deben reproducir sonido
		var ignore_keys = [
			KEY_W, KEY_A, KEY_S, KEY_D,           # Movimiento WASD
			KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, # Flechas
			KEY_SHIFT, KEY_CTRL, KEY_ALT           # Modificadores
		]
		if event.keycode not in ignore_keys:
			# Asegurar que AudioManager existe y tiene el método
			if AudioManager and AudioManager.has_method("play_ui_sfx"):
				AudioManager.play_ui_sfx()

	# mostrar log
	if event is InputEventKey:
		# Solo acciones personalizadas y teclas de control
		var actions = [
			"menu_cancel", "menu_accept", "menu_up", "menu_down",
			"menu_left", "menu_right", "interact", "inventory", "toggle_inventory"
		]
		for action in actions:
			if event.is_action_pressed(action) or event.is_action_released(action):
				var estado = "presionada" if event.is_action_pressed(action) else "liberada"
				print("[INPUT] ", action, " (", estado, ") - tecla física: ", event.keycode, " ", event.as_text())
				break
		# También mostrar tecla Q directamente (por si la acción falla)
		if event.keycode == KEY_Q:
			print("[INPUT] Tecla Q física - pressed: ", event.pressed)

	# activar o desasctivar con f3
	if event.is_action_pressed("ui_debug") or (event is InputEventKey and event.keycode == KEY_F3):
		enabled = !enabled
		print("[INPUT] Logs de entrada ", "activados" if enabled else "desactivados")
