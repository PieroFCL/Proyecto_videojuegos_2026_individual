extends Control

signal item_used(item_id: String)
signal closed

@onready var slot_vida: Button = $Panel/GridContainer/SlotVida
@onready var slot_ataque: Button = $Panel/GridContainer/SlotAtaque
@onready var slot_defensa: Button = $Panel/GridContainer/SlotDefensa
@onready var slot_velocidad: Button = $Panel/GridContainer/SlotVelocidad

var combat_scene: Node = null
var current_index: int = -1
var slots: Array[Button] = []
var _just_opened: bool = false

const CONSUMABLE_IDS = {
	"vida": "consumables/elixir_vigor",
	"ataque": "consumables/tonico_furia",
	"defensa": "consumables/brebaje_escamas",
	"velocidad": "consumables/jarabe_sombra_ligera"
}

func _ready():
	print("BAG _ready: Inicializando submenú de bolsa")
	process_mode = PROCESS_MODE_ALWAYS
	# Permitir que el propio nodo raíz reciba foco
	focus_mode = Control.FOCUS_ALL
	
	slots = [slot_vida, slot_ataque, slot_defensa, slot_velocidad]
	for i in range(slots.size()):
		var item_id = _get_item_id_for_slot(i)
		slots[i].pressed.connect(_on_item_pressed.bind(item_id))
		slots[i].focus_mode = Control.FOCUS_ALL
		slots[i].focus_neighbor_left = NodePath()
		slots[i].focus_neighbor_right = NodePath()
		slots[i].focus_neighbor_top = NodePath()
		slots[i].focus_neighbor_bottom = NodePath()
		slots[i].focus_entered.connect(_on_focus_entered.bind(i))
	_set_mouse_filter_ignore(self)
	set_process_unhandled_input(true)
	print("BAG _ready: process_unhandled_input activado, focus_mode establecido")

func _get_item_id_for_slot(idx: int) -> String:
	match idx:
		0: return CONSUMABLE_IDS["vida"]
		1: return CONSUMABLE_IDS["ataque"]
		2: return CONSUMABLE_IDS["defensa"]
		3: return CONSUMABLE_IDS["velocidad"]
	return ""

func _on_focus_entered(idx: int):
	current_index = idx
	print("BAG: focus_entered en slot ", idx)

func initialize(combat_node: Node) -> void:
	print("BAG initialize: Recibido combat_node=", combat_node)
	combat_scene = combat_node
	_refresh_items()

	# Asegurar que el submenú recibe eventos no manejados
	set_process_unhandled_input(true)
	set_process_input(true)

	# Liberar foco de cualquier otro nodo
	var viewport = get_viewport()
	if viewport:
		viewport.gui_release_focus()

	# Pequeña pausa para que la UI se estabilice
	await get_tree().process_frame

	# Si no se enfocó ningún botón (todos deshabilitados), el propio submenú toma el foco
	# (esto ya se hace en _refresh_items, pero lo aseguramos)
	var found = false
	for btn in slots:
		if not btn.disabled and btn.has_focus():
			found = true
			break
	if not found:
		grab_focus()

	_just_opened = true
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		_just_opened = false
		print("BAG: protección _just_opened desactivada")
	else:
		print("BAG: nodo inválido después del timer, cancelando")
		
func _refresh_items() -> void:
	print("BAG _refresh_items: actualizando slots")
	var all_items = InventoryManager.get_all_items()
	print("BAG: Inventario completo: ", all_items)
	var vida_qty = all_items.get(CONSUMABLE_IDS["vida"], 0)
	var ataque_qty = all_items.get(CONSUMABLE_IDS["ataque"], 0)
	var defensa_qty = all_items.get(CONSUMABLE_IDS["defensa"], 0)
	var velocidad_qty = all_items.get(CONSUMABLE_IDS["velocidad"], 0)
	print("BAG: cantidades - vida:", vida_qty, " ataque:", ataque_qty, " defensa:", defensa_qty, " velocidad:", velocidad_qty)
	_update_slot(slot_vida, CONSUMABLE_IDS["vida"], vida_qty)
	_update_slot(slot_ataque, CONSUMABLE_IDS["ataque"], ataque_qty)
	_update_slot(slot_defensa, CONSUMABLE_IDS["defensa"], defensa_qty)
	_update_slot(slot_velocidad, CONSUMABLE_IDS["velocidad"], velocidad_qty)

	var found = false
	for i in range(slots.size()):
		if not slots[i].disabled:
			current_index = i
			slots[i].grab_focus()
			print("BAG: enfocando slot ", i, " con texto: ", slots[i].text)
			found = true
			break

	if not found:
		print("BAG: todos los slots deshabilitados, intentando dar foco al propio Control")
		var viewport = get_viewport()
		if viewport:
			viewport.gui_release_focus()
		grab_focus()
		print("BAG: grab_focus() ejecutado, focus_owner=", get_viewport().gui_get_focus_owner())
	else:
		# Si se enfocó un botón, esperar un frame para asegurar la propagación del foco
		await get_tree().process_frame
		# Volver a enfocar el mismo botón (por si se perdió)
		if current_index >= 0 and current_index < slots.size() and not slots[current_index].disabled:
			slots[current_index].grab_focus()

func _update_slot(button: Button, item_id: String, quantity: int) -> void:
	print("BAG: actualizando slot ", button.name, " item_id=", item_id, " cantidad=", quantity)
	if quantity > 0:
		var item_res = InventoryManager.get_item_resource(item_id)
		if item_res:
			var line1 = "%s x%d" % [item_res.display_name, quantity]
			var line2 = ""
			if item_res.has_method("get_hp_restore") and item_res.get_hp_restore() > 0:
				line2 = "Restaura %d HP" % item_res.get_hp_restore()
			elif item_res.has_method("get_effect_stat") and item_res.effect_stat != "":
				var stat_name = ""
				match item_res.effect_stat:
					"attack": stat_name = "Ataque"
					"defense": stat_name = "Defensa"
					"speed": stat_name = "Velocidad"
					_: stat_name = item_res.effect_stat.capitalize()
				line2 = "%s +%d (%d turno)" % [stat_name, item_res.effect_value, item_res.effect_duration]
			else:
				line2 = "Efecto especial"
			button.text = line1 + "\n" + line2
			button.disabled = false
			if button.pressed.is_connected(_on_item_pressed):
				button.pressed.disconnect(_on_item_pressed)
			button.pressed.connect(_on_item_pressed.bind(item_id))
			print("  Slot habilitado, texto: ", button.text)
		else:
			button.text = "Error\n---"
			button.disabled = true
	else:
		print("  Slot deshabilitado (sin cantidad)")
		button.text = "---\n---"
		button.disabled = true

func _on_item_pressed(item_id: String) -> void:
	print("BAG: item presionado, item_id=", item_id)
	item_used.emit(item_id)
	closed.emit()

# -----------------------------------------------------------------------------
# Navegación y captura de eventos
# -----------------------------------------------------------------------------
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	# Mostrar todos los eventos que llegan al submenú (solo para depuración)
	print("BAG_SUBMENU _unhandled_input: event=", event.as_text(), " visible=", visible)
	if not visible:
		print("  -> Submenú no visible, ignorando")
		return

	if event.is_action_pressed("menu_up"):
		print("  -> menu_up detectado")
		_move_focus_vertical(-2)
		_consume_event()
	elif event.is_action_pressed("menu_down"):
		print("  -> menu_down detectado")
		_move_focus_vertical(2)
		_consume_event()
	elif event.is_action_pressed("menu_left"):
		print("  -> menu_left detectado")
		_move_focus_horizontal()
		_consume_event()
	elif event.is_action_pressed("menu_right"):
		print("  -> menu_right detectado")
		_move_focus_horizontal()
		_consume_event()
	elif event.is_action_pressed("menu_accept"):
		print("  -> menu_accept detectado, _just_opened=", _just_opened)
		if _just_opened:
			print("     Ignorando porque recién abierto")
			_consume_event()
			return
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in slots and not focused.disabled:
			print("     Emitiendo pressed del botón: ", focused.text)
			focused.emit_signal("pressed")
		else:
			print("     No hay botón enfocado o está deshabilitado")
		_consume_event()
	# --- DETECCIONES PARA CERRAR CON Q ---
	elif event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		print("BAG: menu_cancel (Q) - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		print("BAG: Tecla Q directa - Emitiendo closed")
		closed.emit()
		_consume_event()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	if not visible:
		return
	if event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		print("BAG _input: menu_cancel (Q) - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		print("BAG _input: Tecla Q directa - Emitiendo closed")
		closed.emit()
		_consume_event()
	elif event.is_action_pressed("menu_accept"):
		if _just_opened:
			_consume_event()
			return
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button and focused in slots and not focused.disabled:
			focused.emit_signal("pressed")
		_consume_event()

func _get_focusable_button_count() -> int:
	var count = 0
	for btn in slots:
		if not btn.disabled:
			count += 1
	return count

func _focus_first_button() -> void:
	for i in range(slots.size()):
		if not slots[i].disabled:
			slots[i].grab_focus()
			current_index = i
			break

func _move_focus(_delta: int) -> void:
	pass

func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

func _consume_event() -> void:
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()
		print("BAG: evento consumido vía set_input_as_handled")
	else:
		print("BAG: no se pudo consumir evento, viewport nulo")

func _exit_tree() -> void:
	pass

func reset_state() -> void:
	current_index = -1
	_just_opened = false
	set_process_unhandled_input(true)
	if has_focus():
		release_focus()
