class_name ItemActionMenu extends Panel

# Señal emitida al seleccionar una acción.
signal action_selected(action_name: String)

# Contenedor vertical de los botones.
@onready var button_container: VBoxContainer = $ButtonContainer
# Botón para mostrar descripción del objeto.
@onready var desc_btn: Button = $ButtonContainer/DescripcionButton
# Botón para usar consumibles.
@onready var usar_btn: Button = $ButtonContainer/UsarButton
# Botón para equipar armas/armaduras.
@onready var equipar_btn: Button = $ButtonContainer/EquiparButton
# Botón para desequipar objetos.
@onready var desequipar_btn: Button = $ButtonContainer/DesequiparButton
# Botón para soltar objetos al mundo.
@onready var soltar_btn: Button = $ButtonContainer/SoltarButton

# Lista de botones actualmente visibles.
var _buttons: Array[Button] = []
# Índice del botón enfocado actualmente.
var _current_index: int = 0

# Inicialización (sin configuraciones especiales).
func _ready() -> void:
	pass

# Muestra solo las acciones indicadas en el array.
func setup(actions: Array[String]) -> void:
	# Oculta y desconecta todos los botones.
	for btn in [desc_btn, usar_btn, equipar_btn, desequipar_btn, soltar_btn]:
		btn.visible = false
		if btn.pressed.is_connected(_on_button_pressed):
			btn.pressed.disconnect(_on_button_pressed)
	_buttons.clear()
	
	# Activa botones según las acciones solicitadas.
	for action in actions:
		var btn = _get_button_for_action(action)
		if btn:
			btn.visible = true
			btn.pressed.connect(_on_button_pressed.bind(btn.text))
			_buttons.append(btn)
	
	# Enfoca el primer botón visible.
	if _buttons.size() > 0:
		_current_index = 0
		await get_tree().process_frame
		_buttons[0].grab_focus()
	
	visible = true

# Devuelve el botón correspondiente a una acción.
func _get_button_for_action(action: String) -> Button:
	match action:
		"Descripción": return desc_btn
		"Usar": return usar_btn
		"Equipar": return equipar_btn
		"Desequipar": return desequipar_btn
		"Soltar": return soltar_btn
	return null

# Emite la acción y cierra el menú al presionar botón.
func _on_button_pressed(action: String) -> void:
	action_selected.emit(action)
	queue_free()

# Maneja navegación y selección por teclado.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print("ITEM_ACTION_MENU _input: event=", event.as_text(), " visible=", visible)
	if not visible: return
	if _buttons.is_empty(): return
	
	if event.is_action_pressed("menu_up"):
		_current_index = (_current_index - 1 + _buttons.size()) % _buttons.size()
		_buttons[_current_index].grab_focus()
		_consume_event()
	elif event.is_action_pressed("menu_down"):
		_current_index = (_current_index + 1) % _buttons.size()
		_buttons[_current_index].grab_focus()
		_consume_event()
	elif event.is_action_pressed("menu_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in _buttons:
			focused.emit_signal("pressed")
		_consume_event()
	elif event.is_action_pressed("menu_cancel"):
		action_selected.emit("cancel")
		queue_free()
		_consume_event()

# Marca evento como manejado para evitar propagación.
func _consume_event() -> void:
	var vp = get_viewport()
	if vp: vp.set_input_as_handled()
