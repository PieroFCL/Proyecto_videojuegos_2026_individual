class_name ItemActionMenu extends Panel

signal action_selected(action_name: String)

@onready var button_container: VBoxContainer = $ButtonContainer
@onready var desc_btn: Button = $ButtonContainer/DescripcionButton
@onready var usar_btn: Button = $ButtonContainer/UsarButton
@onready var equipar_btn: Button = $ButtonContainer/EquiparButton
@onready var desequipar_btn: Button = $ButtonContainer/DesequiparButton
@onready var soltar_btn: Button = $ButtonContainer/SoltarButton

var _buttons: Array[Button] = []
var _current_index: int = 0

func _ready() -> void:
	# Opcional: configurar estilos
	pass

# Configura qué acciones mostrar (ej. ["Descripción", "Usar", "Soltar"])
func setup(actions: Array[String]) -> void:
	# Ocultar todos los botones inicialmente
	for btn in [desc_btn, usar_btn, equipar_btn, desequipar_btn, soltar_btn]:
		btn.visible = false
		# Desconectar señales previas para evitar duplicados (opcional)
		if btn.pressed.is_connected(_on_button_pressed):
			btn.pressed.disconnect(_on_button_pressed)
	_buttons.clear()
	
	# Mostrar los botones según las acciones, en el orden dado
	for action in actions:
		var btn = _get_button_for_action(action)
		if btn:
			btn.visible = true
			btn.pressed.connect(_on_button_pressed.bind(btn.text))   # <-- LÍNEA CLAVE
			_buttons.append(btn)
	
	if _buttons.size() > 0:
		_current_index = 0
		await get_tree().process_frame
		_buttons[0].grab_focus()
	
	visible = true

func _get_button_for_action(action: String) -> Button:
	match action:
		"Descripción": return desc_btn
		"Usar": return usar_btn
		"Equipar": return equipar_btn
		"Desequipar": return desequipar_btn
		"Soltar": return soltar_btn
	return null

# Se ejecuta cuando el usuario presiona un botón (por tecla E, Enter, o clic)
func _on_button_pressed(action: String) -> void:
	action_selected.emit(action)
	queue_free()

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
			# Emitir la señal directamente, pues el botón ya tiene conectada su señal pressed
			# Pero también podemos simular clic:
			focused.emit_signal("pressed")
		_consume_event()
	elif event.is_action_pressed("menu_cancel"):
		action_selected.emit("cancel")
		queue_free()
		_consume_event()

func _consume_event() -> void:
	var vp = get_viewport()
	if vp: vp.set_input_as_handled()
