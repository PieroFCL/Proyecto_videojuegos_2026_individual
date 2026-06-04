extends CanvasLayer

# Nodos de UI (submódulos)
@onready var inventory_grid: InventoryGrid = $MenuContainer/InventoryPanel/InventoryGrid
@onready var equipment_panel: EquipmentPanel = $MenuContainer/EquipmentPanel
@onready var stats_panel: StatsPanel = $MenuContainer/StatsPanel
@onready var description_panel: DescriptionPanel = $DescriptionPanel
@onready var doc_icon: TextureRect = $DocumentTexture_IcoR
@onready var documents_panel: Panel = $DocumentsPanel

# Contenedores auxiliares
@onready var menu_container: Panel = $MenuContainer
@onready var background: ColorRect = $Background
@onready var empty_inventory_panel: Panel = $MenuContainer/InventoryPanel/EmptyInventoryPanel

# Escena para soltar objetos en el mundo
const COLLECTABLE_SCENE = preload("res://WorldObjects/CollectableItem/collectable_item.tscn")
# Escena del menú de acciones personalizado
const ITEM_ACTION_MENU = preload("res://UI/PlayerMenu/ItemActionMenu.tscn")

# Estado del menú
var is_open: bool = false
var documents_mode: bool = false          # true = mostrando documentos
var last_documents_mode: bool = false     # recordar modo al cerrar
var _is_description_open: bool = false    # panel de descripción visible

# Menú de acciones actual (instancia)
var current_action_menu: ItemActionMenu = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_set_mouse_filter_ignore(self)

	# Conectar señales de submódulos
	inventory_grid.item_selected.connect(_on_item_selected)
	# Conectar señal de inventario vacío
	inventory_grid.inventory_emptiness_changed.connect(_on_inventory_emptiness_changed)

	description_panel.hide_description()
	documents_panel.visible = false
	visible = false
	# Asegurar que el grid de inventario esté oculto y desactivado al inicio
	inventory_grid.visible = false
	inventory_grid.process_mode = PROCESS_MODE_DISABLED

	# Forzar actualización inicial del panel vacío (por si la señal ya se emitió antes de conectar)
	_on_inventory_emptiness_changed(inventory_grid._items.is_empty())
	
	_update_doc_icon_visibility()

func _on_inventory_emptiness_changed(is_empty: bool) -> void:
	empty_inventory_panel.visible = is_empty

# Desactiva el ratón recursivamente en todos los controles
func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

# Actualiza la visibilidad del icono para cambiar a documentos
func _update_doc_icon_visibility() -> void:
	if not is_open:
		doc_icon.visible = false
		return
	doc_icon.visible = (not documents_mode) and (not _is_description_open)

func open_menu() -> void:
	if is_open: return
	is_open = true
	visible = true
	get_tree().paused = true

	# Desactivar interacción del jugador
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(false)

	documents_mode = last_documents_mode
	if documents_mode:
		# Modo documentos: desactivar grid y mostrar panel
		menu_container.visible = false
		inventory_grid.visible = false
		inventory_grid.process_mode = PROCESS_MODE_DISABLED
		documents_panel.open()
	else:
		# Modo objetos: activar grid y cerrar documentos
		menu_container.visible = true
		documents_panel.close()
		inventory_grid.visible = true
		inventory_grid.process_mode = PROCESS_MODE_ALWAYS
		inventory_grid._refresh()
		await get_tree().process_frame
		inventory_grid._focus_item(0)

	_update_doc_icon_visibility()

func close_menu() -> void:
	if not is_open: return

	# Cerrar menú de acciones si estaba abierto
	if current_action_menu:
		current_action_menu.queue_free()
		current_action_menu = null

	last_documents_mode = documents_mode
	is_open = false
	documents_panel.close()
	# Ocultar contenedor principal y el grid
	menu_container.visible = false
	inventory_grid.visible = false
	inventory_grid.process_mode = PROCESS_MODE_DISABLED
	visible = false
	get_tree().paused = false

	# Reactivar interacción del jugador
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(true)

	doc_icon.visible = false

# Manejo de entrada de teclado (WASD, E, Q, I, R) - CON PRINTS DE DEPURACIÓN
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print("PLAYER_MENU _input: event=", event.as_text(), " is_open=", is_open, " combat_active=", CombatManager.combat_scene_instance != null)

	# Si hay combate activo, el inventario no debe procesar ninguna tecla
	if CombatManager.combat_scene_instance != null:
		print("  -> Combate activo, ignorando evento en inventario")
		return

	if event.is_action_pressed("inventory") and CombatManager.combat_scene_instance != null:
		print("  -> inventory presionado pero combate activo, consumiendo")
		_consume_event()
		return

	if event.is_action_pressed("inventory"):
		print("  -> inventory presionado, is_open=", is_open)
		if is_open: close_menu()
		else: open_menu()
		_consume_event()
		return

	if not is_open: return

	# Panel de descripción abierto
	if _is_description_open and event.is_action_pressed("menu_cancel"):
		print("  -> Cerrando descripción por menu_cancel")
		_close_description()
		_consume_event()
		return

	if _is_description_open and event.is_action_pressed("menu_accept"):
		print("  -> Actualizando descripción con menu_accept")
		var items = inventory_grid._items
		var idx = inventory_grid._selected_index
		if idx >= 0 and idx < items.size():
			var item_id = items[idx]
			var res = InventoryManager.get_item_resource(item_id)
			if res:
				_show_item_description(item_id, res)
		_consume_event()
		return

	# Menú de acciones personalizado visible -> bloquear otras teclas
	if current_action_menu and current_action_menu.visible:
		print("  -> Menú de acciones visible, ignorando otras teclas")
		return

	# Cancelar (Q)
	if event.is_action_pressed("menu_cancel"):
		print("  -> menu_cancel detectado en inventario")
		if current_action_menu and current_action_menu.visible:
			print("     Cerrando menú de acciones")
			current_action_menu.action_selected.emit("cancel")
		else:
			print("     Cerrando inventario")
			close_menu()
		_consume_event()
		return

	# Alternar modo documentos (R) - VERSIÓN MODIFICADA
	if event.is_action_pressed("toggle_inventory") and not _is_description_open:
		print("  -> toggle_inventory presionado, documents_mode=", documents_mode)
		
		# Cerrar menú de acciones si estaba abierto
		if current_action_menu:
			current_action_menu.queue_free()
			current_action_menu = null
		
		documents_mode = not documents_mode
		if documents_mode:
			# Modo documentos: desactivar completamente el grid de inventario
			inventory_grid.visible = false
			inventory_grid.process_mode = PROCESS_MODE_DISABLED
			menu_container.visible = false
			documents_panel.visible = true
			if documents_panel.has_method("open"):
				documents_panel.open()
		else:
			# Modo objetos: cerrar documentos y restaurar grid
			if documents_panel.has_method("close"):
				documents_panel.close()
			documents_panel.visible = false
			menu_container.visible = true
			inventory_grid.visible = true
			inventory_grid.process_mode = PROCESS_MODE_ALWAYS
			inventory_grid._refresh()
			await get_tree().process_frame
			inventory_grid._focus_item(0)
		
		_update_doc_icon_visibility()
		_consume_event()
		return

func close_action_menu() -> void:
	if current_action_menu:
		current_action_menu.queue_free()
		current_action_menu = null

# Respuesta a la selección de un objeto en InventoryGrid
func _on_item_selected(item_id: String) -> void:
	print("DEBUG: _on_item_selected recibido, item_id=", item_id)
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res: return

	# Construir lista de acciones
	var actions: Array[String] = ["Descripción"]
	match item_res.category:
		"consumable":
			actions.append("Usar")
			actions.append("Soltar")
		"weapon", "armor", "seal":
			var is_equipped = false
			if item_res.category == "weapon" and PlayerStats.equipped_weapon_id == item_id:
				is_equipped = true
			elif item_res.category == "armor" and PlayerStats.equipped_armor_id == item_id:
				is_equipped = true
			elif item_res.category == "seal" and PlayerStats.equipped_seal_id == item_id:
				is_equipped = true
			if is_equipped:
				actions.append("Desequipar")
			else:
				actions.append("Equipar")
			actions.append("Soltar")
		_:
			actions.append("Soltar")

	# Limpiar menú anterior
	if current_action_menu:
		current_action_menu.queue_free()

	# Instanciar nuevo menú
	current_action_menu = ITEM_ACTION_MENU.instantiate()
	print("DEBUG: ItemActionMenu instanciado: ", current_action_menu)
	add_child(current_action_menu)
	current_action_menu.move_to_front()
	current_action_menu.z_index = 4000
	current_action_menu.setup(actions)
	print("DEBUG: setup llamado, visible=", current_action_menu.visible)
	current_action_menu.action_selected.connect(_on_action_selected_from_menu)

	# Posicionar cerca del botón seleccionado, o en el centro si falla
	var btn_container = inventory_grid.get_child(inventory_grid._selected_index) as MarginContainer
	if btn_container:
		var btn = btn_container.get_child(0) as Button
		if btn:
			current_action_menu.global_position = btn.global_position + Vector2(btn.size.x / 2, btn.size.y)
		else:
			current_action_menu.global_position = get_viewport().size / 2
	else:
		current_action_menu.global_position = get_viewport().size / 2
		
# Gestiona la acción elegida desde el menú personalizado
func _on_action_selected_from_menu(action: String) -> void:
	if action == "cancel":
		if current_action_menu:
			current_action_menu.queue_free()
			current_action_menu = null
		return

	var idx = inventory_grid._selected_index
	if idx < 0 or idx >= inventory_grid._items.size(): return
	var item_id = inventory_grid._items[idx]
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res: return

	match action:
		"Usar": _use_item(item_id, item_res)
		"Equipar": _equip_item(item_id, item_res)
		"Desequipar": _unequip_item(item_id, item_res)
		"Soltar": _discard_item(item_id)
		"Descripción": _show_item_description(item_id, item_res)

	if current_action_menu:
		current_action_menu.queue_free()
		current_action_menu = null

# Usa un consumible (cura)
func _use_item(item_id: String, item_res: ItemResource) -> void:
	if item_res.category == "consumable" and item_res.has_method("get_hp_restore"):
		PlayerStats.heal(item_res.get_hp_restore())
		InventoryManager.remove_item(item_id, 1)

# Equipa arma, armadura o sello
func _equip_item(item_id: String, item_res: ItemResource) -> void:
	match item_res.category:
		"weapon": EquipmentManager.equip_weapon(item_id)
		"armor": EquipmentManager.equip_armor(item_id)
		"seal": EquipmentManager.equip_seal(item_id)

# Desequipa arma, armadura o sello
func _unequip_item(_item_id: String, item_res: ItemResource) -> void:
	match item_res.category:
		"weapon": EquipmentManager.unequip_weapon()
		"armor": EquipmentManager.unequip_armor()
		"seal": EquipmentManager.unequip_seal()

# Descarta un objeto (lo elimina del inventario y lo instancia en el mundo)
func _discard_item(item_id: String) -> void:
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res: return

	# Desequipar si estaba equipado
	if item_res.category == "weapon" and PlayerStats.equipped_weapon_id == item_id:
		EquipmentManager.unequip_weapon()
	elif item_res.category == "armor" and PlayerStats.equipped_armor_id == item_id:
		EquipmentManager.unequip_armor()
	elif item_res.category == "seal" and PlayerStats.equipped_seal_id == item_id:
		EquipmentManager.unequip_seal()

	# Crear objeto en el mundo (posición aleatoria alrededor del jugador)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var drop_pos = player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var dropped = COLLECTABLE_SCENE.instantiate() as CollectableItem
		if dropped:
			dropped.item_resource = item_res
			dropped.global_position = drop_pos
			get_tree().current_scene.add_child(dropped)
			dropped.apply_scale_from_texture()

	InventoryManager.remove_item(item_id, 1)

# Descripción de objetos
func _show_item_description(_item_id: String, item_res: ItemResource) -> void:
	description_panel.show_description(item_res)
	_is_description_open = true
	_update_doc_icon_visibility()

func _close_description() -> void:
	description_panel.hide_description()
	_is_description_open = false
	_update_doc_icon_visibility()

# Consumo de eventos (para evitar propagación)
func _consume_event() -> void:
	var vp = get_viewport()
	if vp: vp.set_input_as_handled()
