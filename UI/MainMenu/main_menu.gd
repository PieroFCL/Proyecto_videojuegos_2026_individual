extends CanvasLayer

@onready var new_game_btn = $Panel/VBoxContainer/NewGameButton
@onready var load_game_btn = $Panel/VBoxContainer/LoadGameButton
@onready var exit_btn = $Panel/VBoxContainer/ExitButton
@onready var cursor = $Panel.get_node_or_null("TextureCursor")
@onready var load_slot_panel = $LoadSlotPanel
@onready var slot_container = $LoadSlotPanel/ScrollContainer/VBoxContainer
@onready var close_slot_btn = $LoadSlotPanel.get_node_or_null("CloseButton")

@onready var auto_slot_btn = $LoadSlotPanel/ScrollContainer/VBoxContainer/AutoSlotButton
@onready var manual1_slot_btn = $LoadSlotPanel/ScrollContainer/VBoxContainer/Manual1SlotButton
@onready var manual2_slot_btn = $LoadSlotPanel/ScrollContainer/VBoxContainer/Manual2SlotButton
@onready var manual3_slot_btn = $LoadSlotPanel/ScrollContainer/VBoxContainer/Manual3SlotButton

# Botones del menú principal
var buttons: Array[Button]
# Índice del botón enfocado actualmente
var current_index: int = 0
# Lista de botones de carga
var slot_buttons: Array[Button]
# Evita que un accept residual active un slot al abrir el panel
var ignore_next_accept: bool = false

# Configuración inicial: desactiva ratón, conecta señales, pausa el juego
func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	_set_mouse_filter_ignore(self)
	
	buttons = [new_game_btn, load_game_btn, exit_btn]
	for i in range(buttons.size()):
		buttons[i].focus_entered.connect(_on_button_focused.bind(i))
		buttons[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	new_game_btn.pressed.connect(_on_new_game_pressed)
	load_game_btn.pressed.connect(_on_load_game_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	if close_slot_btn:
		close_slot_btn.pressed.connect(_close_load_panel)
	
	slot_buttons = [auto_slot_btn, manual1_slot_btn, manual2_slot_btn, manual3_slot_btn]
	for btn in slot_buttons:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.focus_mode = Control.FOCUS_ALL
	
	buttons[0].grab_focus()
	_update_cursor_position(buttons[0])
	
	get_tree().paused = true
	
	var hp_bar = get_tree().root.get_node_or_null("Playground/PlayerHPBarUI")
	if hp_bar:
		hp_bar.visible = false
	AudioManager.play_menu_music()

# Aplica recursivamente mouse_filter = IGNORE a todos los controles hijo
func _set_mouse_filter_ignore(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)

# Coloca el cursor a la izquierda del botón enfocado
func _update_cursor_position(button: Button):
	if not cursor:
		return
	var cursor_offset = Vector2(-9, button.size.y / 2 - cursor.size.y / 2)
	cursor.global_position = button.global_position + cursor_offset

# Actualiza índice y posición del cursor cuando cambia el foco
func _on_button_focused(idx: int):
	current_index = idx
	_update_cursor_position(buttons[idx])

# Marca el evento actual como manejado para que no se propague
func _consume_event() -> void:
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()

# Procesa entrada de teclado, navega y selecciona en menú principal y panel de slots
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print("MAIN_MENU _input: event=", event.as_text(), " visible=", visible)
	if not load_slot_panel.visible:
		if event.is_action_pressed("menu_up"):
			current_index = (current_index - 1 + buttons.size()) % buttons.size()
			buttons[current_index].grab_focus()
			_consume_event()
		elif event.is_action_pressed("menu_down"):
			current_index = (current_index + 1) % buttons.size()
			buttons[current_index].grab_focus()
			_consume_event()
		elif event.is_action_pressed("menu_accept"):
			buttons[current_index].emit_signal("pressed")
			_consume_event()
		elif event.is_action_pressed("menu_cancel"):
			_on_exit_pressed()
			_consume_event()
	else:
		if event.is_action_pressed("menu_cancel"):
			_close_load_panel()
			_consume_event()
		elif event.is_action_pressed("menu_up") or event.is_action_pressed("menu_down"):
			var focused = get_viewport().gui_get_focus_owner()
			var idx = slot_buttons.find(focused)
			if idx == -1:
				for i in range(slot_buttons.size()):
					if not slot_buttons[i].disabled:
						slot_buttons[i].grab_focus()
						break
				_consume_event()
				return
			var new_idx = idx
			if event.is_action_pressed("menu_up"):
				new_idx = (idx - 1 + slot_buttons.size()) % slot_buttons.size()
			else:
				new_idx = (idx + 1) % slot_buttons.size()
			while new_idx != idx and slot_buttons[new_idx].disabled:
				if event.is_action_pressed("menu_up"):
					new_idx = (new_idx - 1 + slot_buttons.size()) % slot_buttons.size()
				else:
					new_idx = (new_idx + 1) % slot_buttons.size()
			if not slot_buttons[new_idx].disabled:
				slot_buttons[new_idx].grab_focus()
			_consume_event()
		elif event.is_action_pressed("menu_accept"):
			var focused = get_viewport().gui_get_focus_owner()
			if focused is Button and focused in slot_buttons and not focused.disabled:
				var slot_id = -1
				match focused:
					auto_slot_btn:
						slot_id = AutosaveManager.AUTO_SLOT_ID
					manual1_slot_btn:
						slot_id = 1
					manual2_slot_btn:
						slot_id = 2
					manual3_slot_btn:
						slot_id = 3
				if slot_id != -1:
					_on_slot_selected(slot_id)
			_consume_event()

# Nueva partida, borra todos los datos y carga playground
func _on_new_game_pressed():
	AutosaveManager.pending_load_slot = -1
	print("DEBUG: _on_new_game_pressed ejecutado")
	AutosaveManager.reset_all_saves()
	WorldStateManager.reset()
	InventoryManager.clear()
	DocumentManager.clear()
	PlayerStats.reset_to_default()
	EquipmentManager.unequip_weapon()
	EquipmentManager.unequip_armor()
	EquipmentManager.unequip_seal()
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://playground.tscn")

# Abre el panel de carga de slots y enfoca el primer slot disponible
func _on_load_game_pressed():
	print("DEBUG: _on_load_game_pressed ejecutado")
	_update_slot_buttons_state()
	load_slot_panel.visible = true
	for btn in slot_buttons:
		if not btn.disabled:
			btn.grab_focus()
			break

# Sale del juego
func _on_exit_pressed():
	print("DEBUG: _on_exit_pressed ejecutado")
	get_tree().quit()

# Actualiza textos y estado disabled de los botones según los archivos de guardado
func _update_slot_buttons_state():
	var manual_saves = AutosaveManager.get_manual_saves()
	auto_slot_btn.text = "Ultimo Punto Guardado Automático"
	auto_slot_btn.disabled = false
	var manual_btns = [manual1_slot_btn, manual2_slot_btn, manual3_slot_btn]
	for i in range(manual_btns.size()):
		var slot_id = i + 1
		var has_save = slot_id in manual_saves
		manual_btns[i].text = "Manual %d %s" % [slot_id, "(guardado)" if has_save else "(vacío)"]
		manual_btns[i].disabled = not has_save
	print("=== Actualizando estado de botones: manual_saves = ", manual_saves)

# Almacena el slot seleccionado, reanuda y cambia a playground
func _on_slot_selected(slot_id: int):
	print("DEBUG: Slot seleccionado: ", slot_id)
	AutosaveManager.pending_load_slot = slot_id
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://playground.tscn")

# Cierra el panel de carga y vuelve a enfocar el botón Cargar partida
func _close_load_panel():
	load_slot_panel.visible = false
	buttons[1].grab_focus()
