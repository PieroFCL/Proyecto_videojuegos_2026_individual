extends Control

@onready var skills_button: Button = $Panel/VBoxContainer/SkillsButton
@onready var bag_button: Button = $Panel/VBoxContainer/BagButton
@onready var status_button: Button = $Panel/VBoxContainer/StatusButton
@onready var cursor: TextureRect = $TextureCursor

var buttons: Array[Button] = []
var current_index: int = 0

func _ready() -> void:
	print("COMBAT_MENU_UI _ready: Inicializando")
	# Configurar botones
	buttons = [skills_button, bag_button, status_button]
	# Verificar que haya al menos un botón
	if buttons.is_empty():
		print("ERROR: CombatMenuUI no tiene botones configurados.")
		return
	
	for i in range(buttons.size()):
		# Conectar señal de foco para mover el cursor
		buttons[i].focus_entered.connect(_move_cursor.bind(buttons[i]))
		buttons[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
		buttons[i].focus_mode = Control.FOCUS_ALL
	
	# Enfocar primer botón
	buttons[0].grab_focus()
	_move_cursor(buttons[0])
	print("  Primer botón enfocado: ", buttons[0].name)

func _move_cursor(button: Button) -> void:
	# Actualizar el índice actual con el botón enfocado
	var idx = buttons.find(button)
	if idx != -1:
		current_index = idx
	if not cursor:
		return
	var offset = Vector2(-9, button.size.y / 2 - cursor.size.y / 2)
	cursor.global_position = button.global_position + offset
	print("COMBAT_MENU_UI: cursor movido a ", cursor.global_position, " para botón ", button.name)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	# Mostrar todos los eventos que llegan al menú principal, incluso si no está visible (para depuración)
	print("COMBAT_MENU_UI _input: event=", event.as_text(), " visible=", visible)
	if not visible:
		print("  -> Menú no visible, ignorando")
		return
	if buttons.is_empty():
		return
	
	if event.is_action_pressed("menu_up"):
		print("  -> menu_up detectado, current_index=", current_index)
		current_index = (current_index - 1 + buttons.size()) % buttons.size()
		buttons[current_index].grab_focus()
		_consume_event()
	elif event.is_action_pressed("menu_down"):
		print("  -> menu_down detectado, current_index=", current_index)
		current_index = (current_index + 1) % buttons.size()
		buttons[current_index].grab_focus()
		_consume_event()
	elif event.is_action_pressed("menu_accept"):
		print("  -> menu_accept detectado, emitiendo pressed del botón ", current_index, " (", buttons[current_index].name, ")")
		buttons[current_index].emit_signal("pressed")
		_consume_event()
	elif event.is_action_pressed("menu_cancel"):
		print("  -> menu_cancel detectado (Q) - Consumiendo evento, NO se cierra combate aquí")
		_consume_event()

func _consume_event() -> void:
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()
		print("COMBAT_MENU_UI: evento consumido vía set_input_as_handled")
	else:
		print("COMBAT_MENU_UI: no se pudo consumir evento, viewport nulo")

func force_focus_on_button(idx: int) -> void:
	if idx < 0 or idx >= buttons.size(): 
		print("COMBAT_MENU_UI: force_focus_on_button índice inválido: ", idx)
		return
	current_index = idx
	buttons[idx].grab_focus()
	_move_cursor(buttons[idx])
	print("COMBAT_MENU_UI: foco forzado al botón ", idx, " (", buttons[idx].name, ")")
