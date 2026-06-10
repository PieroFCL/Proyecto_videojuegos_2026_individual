extends Control
# Menú principal de combate (habilidades, bolsa, estado).

# Botón para abrir submenú de habilidades.
@onready var skills_button: Button = $Panel/VBoxContainer/SkillsButton
# Botón para abrir submenú de bolsa.
@onready var bag_button: Button = $Panel/VBoxContainer/BagButton
# Botón para abrir submenú de estado.
@onready var status_button: Button = $Panel/VBoxContainer/StatusButton
# Textura del cursor que sigue al botón enfocado.
@onready var cursor: TextureRect = $TextureCursor

# Lista de botones del menú principal.
var buttons: Array[Button] = []
# Índice del botón actualmente enfocado.
var current_index: int = 0

# Configura botones y cursor al iniciar.
func _ready() -> void:
	print("COMBAT_MENU_UI _ready: Inicializando")
	buttons = [skills_button, bag_button, status_button]
	# Valida que exista al menos un botón.
	if buttons.is_empty():
		print("ERROR: CombatMenuUI no tiene botones configurados.")
		return
	
	# Configura cada botón: conecta foco, desactiva ratón y permite foco.
	for i in range(buttons.size()):
		buttons[i].focus_entered.connect(_move_cursor.bind(buttons[i]))
		buttons[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
		buttons[i].focus_mode = Control.FOCUS_ALL
	
	# Enfoca el primer botón y posiciona cursor.
	buttons[0].grab_focus()
	_move_cursor(buttons[0])
	print("  Primer botón enfocado: ", buttons[0].name)

# Mueve el cursor al botón enfocado y actualiza índice.
func _move_cursor(button: Button) -> void:
	# Actualiza current_index con el índice del botón.
	var idx = buttons.find(button)
	if idx != -1:
		current_index = idx
	if not cursor:
		return
	# Calcula offset para posicionar cursor a la izquierda.
	var offset = Vector2(-9, button.size.y / 2 - cursor.size.y / 2)
	cursor.global_position = button.global_position + offset
	print("COMBAT_MENU_UI: cursor movido a ", cursor.global_position, " para botón ", button.name)

# Maneja entrada de teclado (navegación y selección).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	# Muestra eventos incluso si menú no visible (depuración).
	print("COMBAT_MENU_UI _input: event=", event.as_text(), " visible=", visible)
	if not visible:
		print("  -> Menú no visible, ignorando")
		return
	if buttons.is_empty():
		return
	
	# Navegación hacia arriba con W.
	if event.is_action_pressed("menu_up"):
		print("  -> menu_up detectado, current_index=", current_index)
		current_index = (current_index - 1 + buttons.size()) % buttons.size()
		buttons[current_index].grab_focus()
		_consume_event()
	# Navegación hacia abajo con S.
	elif event.is_action_pressed("menu_down"):
		print("  -> menu_down detectado, current_index=", current_index)
		current_index = (current_index + 1) % buttons.size()
		buttons[current_index].grab_focus()
		_consume_event()
	# Selección con E (abre submenú correspondiente).
	elif event.is_action_pressed("menu_accept"):
		print("  -> menu_accept detectado, emitiendo pressed del botón ", current_index, " (", buttons[current_index].name, ")")
		buttons[current_index].emit_signal("pressed")
		_consume_event()
	# Cancela con Q (solo consume, no cierra combate).
	elif event.is_action_pressed("menu_cancel"):
		print("  -> menu_cancel detectado (Q) - Consumiendo evento, NO se cierra combate aquí")
		_consume_event()

# Marca evento como manejado para evitar propagación.
func _consume_event() -> void:
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()
		print("COMBAT_MENU_UI: evento consumido vía set_input_as_handled")
	else:
		print("COMBAT_MENU_UI: no se pudo consumir evento, viewport nulo")

# Fuerza el foco en un botón específico (usado al restaurar menú).
func force_focus_on_button(idx: int) -> void:
	if idx < 0 or idx >= buttons.size(): 
		print("COMBAT_MENU_UI: force_focus_on_button índice inválido: ", idx)
		return
	current_index = idx
	buttons[idx].grab_focus()
	_move_cursor(buttons[idx])
	print("COMBAT_MENU_UI: foco forzado al botón ", idx, " (", buttons[idx].name, ")")
