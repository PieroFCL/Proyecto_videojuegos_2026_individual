extends CanvasLayer

# Referencia al grid del inventario.
@onready var inventory_grid: InventoryGrid = $MenuContainer/InventoryPanel/InventoryGrid
# Referencia al panel de equipamiento.
@onready var equipment_panel: EquipmentPanel = $MenuContainer/EquipmentPanel
# Referencia al panel de estadísticas.
@onready var stats_panel: StatsPanel = $MenuContainer/StatsPanel
# Referencia al panel de descripción de objetos.
@onready var description_panel: DescriptionPanel = $DescriptionPanel
# Icono para cambiar a modo documentos.
@onready var doc_icon: TextureRect = $DocumentTexture_IcoR
# Referencia al panel de documentos.
@onready var documents_panel: Panel = $DocumentsPanel

# Contenedor principal del menú.
@onready var menu_container: Panel = $MenuContainer
# Fondo oscuro del menú.
@onready var background: ColorRect = $Background
# Panel de inventario vacío (se muestra si no hay objetos).
@onready var empty_inventory_panel: Panel = $MenuContainer/InventoryPanel/EmptyInventoryPanel

# Escena para instanciar objetos soltados en el mundo.
const COLLECTABLE_SCENE = preload("res://WorldObjects/CollectableItem/collectable_item.tscn")
# Escena del menú de acciones personalizado (ItemActionMenu).
const ITEM_ACTION_MENU = preload("res://UI/PlayerMenu/item_action_menu.tscn")

# Indica si el menú está abierto.
var is_open: bool = false
# Modo documentos activado (true) u objetos (false).
var documents_mode: bool = false
# Guarda el último modo al cerrar el menú.
var last_documents_mode: bool = false
# Indica si el panel de descripción está visible.
var _is_description_open: bool = false

# Instancia actual del menú de acciones.
var current_action_menu: ItemActionMenu = null

# Configuración inicial del menú.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_set_mouse_filter_ignore(self)

	# Conecta señal de selección de objeto del grid.
	inventory_grid.item_selected.connect(_on_item_selected)
	# Conecta señal de inventario vacío para mostrar panel.
	inventory_grid.inventory_emptiness_changed.connect(_on_inventory_emptiness_changed)

	description_panel.hide_description()
	documents_panel.visible = false
	visible = false
	# Oculta y desactiva grid al inicio.
	inventory_grid.visible = false
	inventory_grid.process_mode = PROCESS_MODE_DISABLED

	# Actualiza estado inicial del panel vacío.
	_on_inventory_emptiness_changed(inventory_grid._items.is_empty())
	
	_update_doc_icon_visibility()

# Muestra u oculta panel de inventario vacío según estado.
func _on_inventory_emptiness_changed(is_empty: bool) -> void:
	empty_inventory_panel.visible = is_empty

# Desactiva el ratón recursivamente en controles hijos.
func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

# Actualiza visibilidad del icono para cambiar a documentos.
func _update_doc_icon_visibility() -> void:
	if not is_open:
		doc_icon.visible = false
		return
	doc_icon.visible = (not documents_mode) and (not _is_description_open)

# Abre el menú en el último modo guardado.
func open_menu() -> void:
	if is_open: return
	is_open = true
	visible = true
	get_tree().paused = true

	# Desactiva interacción del jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(false)

	documents_mode = last_documents_mode
	if documents_mode:
		# Modo documentos: oculta grid y muestra panel.
		menu_container.visible = false
		inventory_grid.visible = false
		inventory_grid.process_mode = PROCESS_MODE_DISABLED
		documents_panel.open()
	else:
		# Modo objetos: muestra grid y cierra documentos.
		menu_container.visible = true
		documents_panel.close()
		inventory_grid.visible = true
		inventory_grid.process_mode = PROCESS_MODE_ALWAYS
		inventory_grid._refresh()
		await get_tree().process_frame
		inventory_grid._focus_item(0)

	_update_doc_icon_visibility()

# Cierra el menú y restaura el juego.
func close_menu() -> void:
	if not is_open: return

	# Libera menú de acciones si existe.
	if current_action_menu:
		current_action_menu.queue_free()
		current_action_menu = null

	last_documents_mode = documents_mode
	is_open = false
	documents_panel.close()
	# Oculta y desactiva el grid.
	menu_container.visible = false
	inventory_grid.visible = false
	inventory_grid.process_mode = PROCESS_MODE_DISABLED
	visible = false
	get_tree().paused = false

	# Reactiva la interacción del jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(true)

	doc_icon.visible = false

# Procesa entrada de teclado (WASD, E, Q, I, R).
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print("PLAYER_MENU _input: event=", event.as_text(), " is_open=", is_open, " combat_active=", CombatManager.combat_scene_instance != null)

	# Ignora todo si hay combate activo.
	if CombatManager.combat_scene_instance != null:
		print("  -> Combate activo, ignorando evento en inventario")
		return

	if event.is_action_pressed("inventory") and CombatManager.combat_scene_instance != null:
		print("  -> inventory presionado pero combate activo, consumiendo")
		_consume_event()
		return

	# Abre o cierra el menú con la tecla I.
	if event.is_action_pressed("inventory"):
		print("  -> inventory presionado, is_open=", is_open)
		if is_open: close_menu()
		else: open_menu()
		_consume_event()
		return

	if not is_open: return

	# Maneja cierre de descripción con Q.
	if _is_description_open and event.is_action_pressed("menu_cancel"):
		print("  -> Cerrando descripción por menu_cancel")
		_close_description()
		_consume_event()
		return

	# Actualiza descripción con E si está abierta.
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

	# Bloquea otras teclas si menú de acciones está visible.
	if current_action_menu and current_action_menu.visible:
		print("  -> Menú de acciones visible, ignorando otras teclas")
		return

	# Cierra el inventario o el menú de acciones con Q.
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

	# Alterna entre modo objetos y documentos con R.
	if event.is_action_pressed("toggle_inventory") and not _is_description_open:
		print("  -> toggle_inventory presionado, documents_mode=", documents_mode)
		
		# Cierra menú de acciones si está abierto.
		if current_action_menu:
			current_action_menu.queue_free()
			current_action_menu = null
		
		documents_mode = not documents_mode
		if documents_mode:
			# Modo documentos: desactiva grid y muestra panel.
			inventory_grid.visible = false
			inventory_grid.process_mode = PROCESS_MODE_DISABLED
			menu_container.visible = false
			documents_panel.visible = true
			if documents_panel.has_method("open"):
				documents_panel.open()
		else:
			# Modo objetos: reactiva grid y cierra documentos.
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

# Libera el menú de acciones si está instanciado.
func close_action_menu() -> void:
	if current_action_menu:
		current_action_menu.queue_free()
		current_action_menu = null

# Construye menú de acciones al seleccionar objeto.
func _on_item_selected(item_id: String) -> void:
	print("DEBUG: _on_item_selected recibido, item_id=", item_id)
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res: return

	# Lista de acciones según categoría del objeto.
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

	# Elimina menú anterior antes de crear otro.
	if current_action_menu:
		current_action_menu.queue_free()

	# Crea e instancia menú de acciones personalizado.
	current_action_menu = ITEM_ACTION_MENU.instantiate()
	print("DEBUG: ItemActionMenu instanciado: ", current_action_menu)
	add_child(current_action_menu)
	current_action_menu.move_to_front()
	current_action_menu.z_index = 4000
	current_action_menu.setup(actions)
	print("DEBUG: setup llamado, visible=", current_action_menu.visible)
	current_action_menu.action_selected.connect(_on_action_selected_from_menu)

	# Posiciona menú cerca del botón seleccionado.
	var btn_container = inventory_grid.get_child(inventory_grid._selected_index) as MarginContainer
	if btn_container:
		var btn = btn_container.get_child(0) as Button
		if btn:
			current_action_menu.global_position = btn.global_position + Vector2(btn.size.x / 2, btn.size.y)
		else:
			current_action_menu.global_position = get_viewport().size / 2
	else:
		current_action_menu.global_position = get_viewport().size / 2
		
# Ejecuta acción elegida desde menú personalizado.
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

# Usa consumible: cura o aplica buff temporal.
func _use_item(item_id: String, item_res: ItemResource) -> void:
	if item_res.category == "consumable" and item_res.has_method("get_hp_restore"):
		PlayerStats.heal(item_res.get_hp_restore())
		InventoryManager.remove_item(item_id, 1)

# Equipa arma, armadura o sello según categoría.
func _equip_item(item_id: String, item_res: ItemResource) -> void:
	match item_res.category:
		"weapon": EquipmentManager.equip_weapon(item_id)
		"armor": EquipmentManager.equip_armor(item_id)
		"seal": EquipmentManager.equip_seal(item_id)

# Desequipa arma, armadura o sello actual.
func _unequip_item(_item_id: String, item_res: ItemResource) -> void:
	match item_res.category:
		"weapon": EquipmentManager.unequip_weapon()
		"armor": EquipmentManager.unequip_armor()
		"seal": EquipmentManager.unequip_seal()

# Elimina objeto del inventario y lo instancia en el mundo.
func _discard_item(item_id: String) -> void:
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res: return

	# Desequipar si estaba equipado.
	if item_res.category == "weapon" and PlayerStats.equipped_weapon_id == item_id:
		EquipmentManager.unequip_weapon()
	elif item_res.category == "armor" and PlayerStats.equipped_armor_id == item_id:
		EquipmentManager.unequip_armor()
	elif item_res.category == "seal" and PlayerStats.equipped_seal_id == item_id:
		EquipmentManager.unequip_seal()

	# Crea objeto flotante cerca del jugador.
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

# Muestra panel descriptivo del objeto.
func _show_item_description(_item_id: String, item_res: ItemResource) -> void:
	description_panel.show_description(item_res)
	_is_description_open = true
	_update_doc_icon_visibility()

# Oculta panel de descripción.
func _close_description() -> void:
	description_panel.hide_description()
	_is_description_open = false
	_update_doc_icon_visibility()

# Marca evento como manejado para evitar propagación.
func _consume_event() -> void:
	var vp = get_viewport()
	if vp: vp.set_input_as_handled()
