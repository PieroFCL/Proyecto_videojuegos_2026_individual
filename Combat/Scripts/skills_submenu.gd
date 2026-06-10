extends Control

# Señal emitida al seleccionar una habilidad.
signal skill_selected(skill: SkillResource)
# Señal emitida al cerrar el submenú.
signal closed

# Referencia al primer botón de habilidad.
@onready var slot1: Button = $Panel/GridContainer/SkillSlot1
# Referencia al segundo botón de habilidad.
@onready var slot2: Button = $Panel/GridContainer/SkillSlot2
# Referencia al tercer botón de habilidad.
@onready var slot3: Button = $Panel/GridContainer/SkillSlot3
# Referencia al cuarto botón de habilidad.
@onready var slot4: Button = $Panel/GridContainer/SkillSlot4

# Lista de botones de habilidades.
var slots: Array[Button] = []
# Lista de habilidades actualmente disponibles.
var current_skills: Array = []
# Índice del slot actualmente enfocado.
var current_index: int = -1
# Bandera para ignorar el primer menu_accept tras abrir.
var _just_opened: bool = false

# Configura el submenú al iniciar.
func _ready():
	# Asegura que recibe eventos incluso con juego pausado.
	process_mode = PROCESS_MODE_ALWAYS
	# Permite que el nodo raíz reciba foco si no hay botones.
	focus_mode = Control.FOCUS_ALL
	slots = [slot1, slot2, slot3, slot4]
	for i in range(slots.size()):
		# Conecta señal pressed de cada botón.
		slots[i].pressed.connect(_on_slot_pressed.bind(i))
		slots[i].focus_mode = Control.FOCUS_ALL
		# Desactiva navegación automática por vecinos.
		slots[i].focus_neighbor_left = NodePath()
		slots[i].focus_neighbor_right = NodePath()
		slots[i].focus_neighbor_top = NodePath()
		slots[i].focus_neighbor_bottom = NodePath()
		# Actualiza índice al enfocar.
		slots[i].focus_entered.connect(_on_focus_entered.bind(i))
	_set_mouse_filter_ignore(self)
	# Activa captura de eventos no manejados.
	set_process_unhandled_input(true)

# Actualiza el índice cuando un botón recibe foco.
func _on_focus_entered(idx: int):
	current_index = idx

# Inicializa el submenú con la lista de habilidades.
func initialize(skills_list: Array) -> void:
	print("SkillsSubmenu: initialize recibido, habilidades: ", skills_list.size())
	current_skills = skills_list
	for i in range(slots.size()):
		if i < current_skills.size():
			var skill = current_skills[i]
			slots[i].text = _format_skill_text(skill)
			slots[i].disabled = false
		else:
			slots[i].text = "---\n---"
			slots[i].disabled = true

	# Activa _input y _unhandled_input.
	set_process_input(true)
	set_process_unhandled_input(true)

	# Enfoca el primer slot habilitado.
	var found = false
	for i in range(slots.size()):
		if not slots[i].disabled:
			current_index = i
			slots[i].grab_focus()
			found = true
			break
	if not found:
		print("SkillsSubmenu: no hay botones habilitados, enfocando el propio control")
		grab_focus()
	else:
		# Da tiempo para estabilizar el foco.
		await get_tree().process_frame
		# Libera foco residual de otros nodos.
		var viewport = get_viewport()
		if viewport:
			viewport.gui_release_focus()
		# Re-enfoca el botón por seguridad.
		if current_index >= 0 and current_index < slots.size() and not slots[current_index].disabled:
			slots[current_index].grab_focus()

	# Activa protección contra primer accept.
	_just_opened = true
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		_just_opened = false

	# Refuerza el foco si no lo tiene y no hay botones.
	if not has_focus() and found == false:
		grab_focus()
		print("SkillsSubmenu: refuerzo de foco aplicado")

# Enfoca el primer botón habilitado.
func _focus_first_button() -> void:
	for i in range(slots.size()):
		if not slots[i].disabled:
			slots[i].grab_focus()
			current_index = i
			break

# Formatea el texto de una habilidad para mostrarlo en el botón.
func _format_skill_text(skill) -> String:
	if skill is SkillResource:
		return skill.get_formatted_text()
	else:
		return str(skill) + "\n" + "?"

# Emite señales al presionar un botón de habilidad.
func _on_slot_pressed(index: int) -> void:
	if index < current_skills.size():
		skill_selected.emit(current_skills[index])
	closed.emit()

# Navegación vertical entre filas de la cuadrícula (salta 2).
func _move_focus_vertical(delta: int) -> void:
	if current_index == -1:
		return
	var new_index = current_index + delta
	if new_index < 0 or new_index >= slots.size():
		return
	if not slots[new_index].disabled:
		slots[new_index].grab_focus()

# Navegación horizontal entre columnas (alterna entre 0-1 y 2-3).
func _move_focus_horizontal() -> void:
	if current_index == -1:
		return
	var new_index = current_index
	if current_index % 2 == 0:
		new_index += 1
	else:
		new_index -= 1
	if new_index >= 0 and new_index < slots.size() and not slots[new_index].disabled:
		slots[new_index].grab_focus()

# Captura eventos no manejados (navegación y cierre).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return

	print("SKILLS_SUBMENU _unhandled_input: event=", event.as_text(), " visible=", visible)
	if not visible:
		return

	# Navegación con teclas personalizadas.
	if event.is_action_pressed("menu_up"):
		_move_focus_vertical(-2)
		_consume_event()
	elif event.is_action_pressed("menu_down"):
		_move_focus_vertical(2)
		_consume_event()
	elif event.is_action_pressed("menu_left"):
		_move_focus_horizontal()
		_consume_event()
	elif event.is_action_pressed("menu_right"):
		_move_focus_horizontal()
		_consume_event()
	# Selección con E, ignorando si recién abierto.
	elif event.is_action_pressed("menu_accept"):
		if _just_opened:
			_consume_event()
			return
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in slots and not focused.disabled:
			focused.emit_signal("pressed")
		_consume_event()
	# Cierre con Q (acción personalizada o tecla directa).
	elif event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		print("SkillsSubmenu: menu_cancel (Q) - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		print("SkillsSubmenu: Tecla Q directa - Emitiendo closed")
		closed.emit()
		_consume_event()

# Captura eventos normales como respaldo para cierre con Q.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	
	print("SKILLS_SUBMENU _input EJECUTADO: ", event.as_text())
	if not visible:
		return
	# Cierre con Q en caso de que _unhandled_input no lo capture.
	if event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		print("SkillsSubmenu _input: menu_cancel (Q) - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		print("SkillsSubmenu _input: Tecla Q directa - Emitiendo closed")
		closed.emit()
		_consume_event()
	# Selección con E como alternativa si el botón no captura.
	elif event.is_action_pressed("menu_accept"):
		print("SkillsSubmenu _input: menu_accept detectado")
		if _just_opened:
			_consume_event()
			return
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in slots and not focused.disabled:
			focused.emit_signal("pressed")
		_consume_event()

# Desactiva el ratón recursivamente en todos los controles hijos.
func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

# Marca el evento como manejado para evitar propagación.
func _consume_event() -> void:
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()
