extends Control

signal skill_selected(skill: SkillResource)
signal closed

@onready var slot1: Button = $Panel/GridContainer/SkillSlot1
@onready var slot2: Button = $Panel/GridContainer/SkillSlot2
@onready var slot3: Button = $Panel/GridContainer/SkillSlot3
@onready var slot4: Button = $Panel/GridContainer/SkillSlot4

var slots: Array[Button] = []
var current_skills: Array = []
var current_index: int = -1
var _just_opened: bool = false

func _ready():
	process_mode = PROCESS_MODE_ALWAYS   # Asegurar que recibe eventos incluso con pausa
	focus_mode = Control.FOCUS_ALL
	slots = [slot1, slot2, slot3, slot4]
	for i in range(slots.size()):
		slots[i].pressed.connect(_on_slot_pressed.bind(i))
		slots[i].focus_mode = Control.FOCUS_ALL
		slots[i].focus_neighbor_left = NodePath()
		slots[i].focus_neighbor_right = NodePath()
		slots[i].focus_neighbor_top = NodePath()
		slots[i].focus_neighbor_bottom = NodePath()
		slots[i].focus_entered.connect(_on_focus_entered.bind(i))
	_set_mouse_filter_ignore(self)
	set_process_unhandled_input(true)

func _on_focus_entered(idx: int):
	current_index = idx

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

	set_process_input(true)
	set_process_unhandled_input(true)

	# Enfocar primer slot habilitado
	var found = false
	for i in range(slots.size()):
		if not slots[i].disabled:
			current_index = i
			slots[i].grab_focus()
			found = true
			break
	if not found:
		# No hay botones, enfocar el propio submenú
		print("SkillsSubmenu: no hay botones habilitados, enfocando el propio control")
		grab_focus()
	else:
		# Dar tiempo para que el foco se establezca y luego forzar que el submenú raíz también capture eventos
		await get_tree().process_frame
		# Liberar foco de cualquier otro nodo
		var viewport = get_viewport()
		if viewport:
			viewport.gui_release_focus()
		# Volver a enfocar el botón
		if current_index >= 0 and current_index < slots.size() and not slots[current_index].disabled:
			slots[current_index].grab_focus()

	_just_opened = true
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		_just_opened = false

	# Refuerzo: si después del timer el submenú no tiene foco y no hay botones, volver a enfocar
	if not has_focus() and found == false:
		grab_focus()
		print("SkillsSubmenu: refuerzo de foco aplicado")

func _focus_first_button() -> void:
	for i in range(slots.size()):
		if not slots[i].disabled:
			slots[i].grab_focus()
			current_index = i
			break

func _format_skill_text(skill) -> String:
	if skill is SkillResource:
		return skill.get_formatted_text()
	else:
		return str(skill) + "\n" + "?"

func _on_slot_pressed(index: int) -> void:
	if index < current_skills.size():
		skill_selected.emit(current_skills[index])
	closed.emit()

# ------------------------------------------------------------
# Navegación en cuadrícula 2x2
# ------------------------------------------------------------
func _move_focus_vertical(delta: int) -> void:
	if current_index == -1:
		return
	var new_index = current_index + delta
	if new_index < 0 or new_index >= slots.size():
		return
	if not slots[new_index].disabled:
		slots[new_index].grab_focus()

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

# ------------------------------------------------------------
# Captura de eventos (usando _unhandled_input)
# ------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return

	print("SKILLS_SUBMENU _unhandled_input: event=", event.as_text(), " visible=", visible)
	if not visible:
		return

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
	elif event.is_action_pressed("menu_accept"):
		if _just_opened:
			_consume_event()
			return
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in slots and not focused.disabled:
			focused.emit_signal("pressed")
		_consume_event()
	# DETECCIÓN DE Q (menu_cancel) - SIMPLIFICADA
	elif event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		print("SkillsSubmenu: menu_cancel (Q) - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		print("SkillsSubmenu: Tecla Q directa - Emitiendo closed")
		closed.emit()
		_consume_event()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	
	print("SKILLS_SUBMENU _input EJECUTADO: ", event.as_text())
	if not visible:
		return
	# Detectar cierre con Q (menu_cancel) – esto funciona incluso si un botón tiene foco
	if event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		print("SkillsSubmenu _input: menu_cancel (Q) - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		print("SkillsSubmenu _input: Tecla Q directa - Emitiendo closed")
		closed.emit()
		_consume_event()
	# Detectar selección con E (menu_accept) – pero la ejecución ya se hace mediante pressed del botón.
	# Esta es solo por si el botón no captura el evento.
	elif event.is_action_pressed("menu_accept"):
		print("SkillsSubmenu _input: menu_accept detectado")
		if _just_opened:
			_consume_event()
			return
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in slots and not focused.disabled:
			focused.emit_signal("pressed")
		_consume_event()

func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

func _consume_event() -> void:
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()
