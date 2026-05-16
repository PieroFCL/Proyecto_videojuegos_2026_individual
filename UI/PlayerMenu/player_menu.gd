extends CanvasLayer
## Menú del personaje con inventario, equipo y estadísticas.

# Nodos de la UI 
@onready var background: ColorRect = $Background
@onready var menu_container: Panel = $MenuContainer
@onready var inventory_grid: GridContainer = $MenuContainer/InventoryPanel/InventoryGrid

@onready var weapon_icon: TextureRect = $MenuContainer/EquipmentPanel/WeaponSlot/WeaponIcon
@onready var weapon_label: Label = $MenuContainer/EquipmentPanel/WeaponSlot/WeaponLabel

@onready var armor_icon: TextureRect = $MenuContainer/EquipmentPanel/ArmorSlot/ArmorIcon
@onready var armor_label: Label = $MenuContainer/EquipmentPanel/ArmorSlot/ArmorLabel

@onready var seal_icon: TextureRect = $MenuContainer/EquipmentPanel/MagicSlot/MagicIcon
@onready var seal_label: Label = $MenuContainer/EquipmentPanel/MagicSlot/MagicLabel

@onready var hp_value: Label = $MenuContainer/StatsPanel/HPValue
@onready var attack_value: Label = $MenuContainer/StatsPanel/AttackValue
@onready var defense_value: Label = $MenuContainer/StatsPanel/DefenseValue
@onready var speed_value: Label = $MenuContainer/StatsPanel/SpeedValue

@onready var empty_inventory_panel: Panel = $MenuContainer/InventoryPanel/EmptyInventoryPanel

# Panel de Descripción
@onready var description_panel: Panel = $DescriptionPanel
@onready var description_title: RichTextLabel = $DescriptionPanel/TitleItemLabel
@onready var description_text: RichTextLabel = $DescriptionPanel/DescriptionItemLabel
@onready var description_stats: RichTextLabel = $DescriptionPanel/StatsItemLabel

const COLLECTABLE_SCENE = preload("res://WorldObjects/CollectableItem/collectable_item.tscn")

# Variables internas
var is_open: bool = false                           # Menú visible o no
var _current_inventory_items: Array = []            # IDs de objetos en orden
var _selected_index: int = 0                       # Índice del objeto seleccionado
var _action_popup: PopupMenu = null                # Menú de acciones (Usar, Equipar...)
var _custom_font: Font = null                      # Fuente personalizada para cantidades
var _is_description_open: bool = false            # Evita aperturas múltiples

# Carga la fuente y configura el menú al iniciar
func _ready() -> void:
	_custom_font = load("res://UI/PlayerMenu/Fonts/Minecraft.ttf")
	process_mode = PROCESS_MODE_ALWAYS
	
	# Conectar señales
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	PlayerStats.stats_changed.connect(_update_stats_display)
	EquipmentManager.equipment_changed.connect(_update_equipment_display)
	
	_update_inventory_display()
	_update_equipment_display()
	_update_stats_display()
	
	# Popup de acciones
	_action_popup = PopupMenu.new()
	add_child(_action_popup)
	_action_popup.add_item("Usar")
	_action_popup.add_item("Equipar")
	_action_popup.add_item("Desequipar")
	_action_popup.add_item("Soltar")
	_action_popup.id_pressed.connect(_on_action_selected)
	
	# Fuente personalizada
	var minecraft_font = load("res://UI/PlayerMenu/Fonts/Minecraft.ttf")
	if minecraft_font:
		_action_popup.add_theme_font_override("font", minecraft_font)
		_action_popup.add_theme_font_size_override("font_size", 8)
	
	# Estilos
	_action_popup.add_theme_font_size_override("font_size", 8)
	_action_popup.add_theme_color_override("font_color", Color.WHITE)
	_action_popup.add_theme_color_override("font_hover_color", Color("FFD7A8")) 
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color("#935053")
	popup_style.set_corner_radius_all(1)
	_action_popup.add_theme_stylebox_override("panel", popup_style)
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#BC676C")
	hover_style.set_corner_radius_all(1)
	_action_popup.add_theme_stylebox_override("hover", hover_style)

	_set_mouse_filter_ignore(self)
	
	description_panel.visible = false
	
	visible = false
	is_open = false

# Desactiva el ratón recursivamente en todos los controles del menú
func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

# Abre el menú, pausa el juego y enfoca el primer objeto
func open_menu() -> void:
	if is_open: return
	is_open = true
	visible = true
	get_tree().paused = true
	_update_inventory_display()
	_update_equipment_display()
	_update_stats_display()
	await get_tree().process_frame
	_focus_inventory_item(0)

# Cierra el menú y reanuda el juego
func close_menu() -> void:
	if not is_open: return
	is_open = false
	visible = false
	get_tree().paused = false

# Procesa entrada del teclado (abrir/cerrar, navegación, acciones)
func _input(event: InputEvent) -> void:
	# Si hay combate activo, ignora la tecla de menú
	if event.is_action_pressed("toggle_menu") and CombatManager.combat_scene_instance != null:
		return
		
	if event.is_action_pressed("toggle_menu"):
		if is_open:
			close_menu()
		else:
			open_menu()
		return

	if not is_open:
		return

	# Cerrar descripción con Q (menu_cancel) si está abierta
	if _is_description_open and event.is_action_pressed("menu_cancel"):
		_close_description()
		return

	# Si la descripción está abierta y se presiona E, actualizar descripción con el objeto seleccionado
	if _is_description_open and event.is_action_pressed("menu_accept"):
		var container = inventory_grid.get_child(_selected_index) if _selected_index < inventory_grid.get_child_count() else null
		if container and container is MarginContainer:
			var btn = container.get_child(0)
			if btn is Button:
				var item_id = btn.get_meta("item_id", "")
				var item_res = InventoryManager.get_item_resource(item_id)
				if item_res:
					_show_item_description(item_id, item_res)
		return

	# Si hay un popup de acciones visible, no procesar navegación del inventario
	if _action_popup.visible:
		return

	# Cancelar (Q) si no hay descripción abierta: cierra popup o menú
	if event.is_action_pressed("menu_cancel"):
		if _action_popup.visible:
			_action_popup.hide()
		else:
			close_menu()
		return

	# Abrir popup de acciones con E, solo si la descripción NO está abierta
	if event.is_action_pressed("menu_accept") and not _is_description_open:
		_on_item_action()
		return

	# Navegación del inventario (solo si no hay popup abierto)
	var moved = false
	var new_index = _selected_index
	var grid_size = inventory_grid.columns
	var total_items = _current_inventory_items.size()
	if total_items == 0:
		return

	if event.is_action_pressed("menu_left"):
		new_index -= 1
		moved = true
	elif event.is_action_pressed("menu_right"):
		new_index += 1
		moved = true
	elif event.is_action_pressed("menu_up"):
		new_index -= grid_size
		moved = true
	elif event.is_action_pressed("menu_down"):
		new_index += grid_size
		moved = true

	if moved:
		new_index = clamp(new_index, 0, total_items - 1)
		if new_index != _selected_index:
			_focus_inventory_item(new_index)

# Actualiza la UI del inventario (botones dinámicos)
func _update_inventory_display() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
		
	var all_items = InventoryManager.get_all_items()
	var item_ids = all_items.keys()
	_current_inventory_items = item_ids
	
	var has_items = item_ids.size() > 0
	inventory_grid.visible = has_items
	empty_inventory_panel.visible = not has_items
	
	if has_items:
		for i in range(item_ids.size()):
			var item_id = item_ids[i]
			var item_resource = InventoryManager.get_item_resource(item_id)
			if not item_resource:
				continue
			
			var quantity = InventoryManager.get_quantity(item_id)
			var container = MarginContainer.new()
			container.custom_minimum_size = Vector2(36, 36)
			container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			
			var btn = Button.new()
			btn.text = ""
			btn.expand_icon = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.focus_mode = Control.FOCUS_ALL
			
			if item_resource.icon:
				btn.icon = item_resource.icon
			else:
				btn.text = item_resource.display_name
			
			btn.tooltip_text = item_resource.display_name
			btn.set_meta("item_id", item_id)
			btn.set_meta("index", i)
			
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color.TRANSPARENT
			normal_style.border_color = Color("8E5E58") 
			normal_style.set_border_width_all(2)
			normal_style.set_corner_radius_all(0)
			btn.add_theme_stylebox_override("normal", normal_style)
			
			var focus_style = StyleBoxFlat.new()
			focus_style.bg_color = Color.TRANSPARENT
			focus_style.border_color = Color("#6D403B")
			focus_style.set_border_width_all(2)
			focus_style.set_corner_radius_all(0)
			btn.add_theme_stylebox_override("focus", focus_style)
			
			container.add_child(btn)
			
			if quantity > 1:
				var qty_label = Label.new()
				qty_label.text = str(quantity)
				qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				
				if _custom_font:
					qty_label.add_theme_font_override("font", _custom_font)
				qty_label.add_theme_font_size_override("font_size", 8)
				qty_label.add_theme_color_override("font_color", Color.GREEN_YELLOW)
				
				# Sombra
				qty_label.add_theme_constant_override("shadow_offset_x", 1)
				qty_label.add_theme_constant_override("shadow_offset_y", 1)
				qty_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
				
				btn.add_child(qty_label)
				qty_label.position = Vector2(3, 3)
			
			inventory_grid.add_child(container)
	
	_selected_index = 0
	if has_items:
		_focus_inventory_item(0)

# Enfoca el botón del inventario en el índice dado
func _focus_inventory_item(index: int) -> void:
	var prev_container = inventory_grid.get_child(_selected_index) if _selected_index >= 0 and _selected_index < inventory_grid.get_child_count() else null
	if prev_container and prev_container is MarginContainer:
		var prev_btn = prev_container.get_child(0)
		if prev_btn is Button and prev_btn.has_focus():
			prev_btn.release_focus()
	
	_selected_index = index
	if index >= inventory_grid.get_child_count():
		return
	var container = inventory_grid.get_child(index)
	if container is MarginContainer:
		var target_btn = container.get_child(0)
		if target_btn is Button:
			target_btn.call_deferred("grab_focus")

# Actualiza los iconos y nombres del equipo (arma y armadura)
func _update_equipment_display(_slot = "", _item_id = "") -> void:
	var weapon_id = PlayerStats.equipped_weapon_id
	if weapon_id.is_empty():
		weapon_icon.texture = null
		weapon_label.text = "Arma"
	else:
		var weapon_res = InventoryManager.get_item_resource(weapon_id)
		if weapon_res:
			weapon_icon.texture = weapon_res.icon
			weapon_label.text = weapon_res.display_name
		else:
			weapon_icon.texture = null
			weapon_label.text = "Desconocida"
	
	var armor_id = PlayerStats.equipped_armor_id
	if armor_id.is_empty():
		armor_icon.texture = null
		armor_label.text = "Armadura"
	else:
		var armor_res = InventoryManager.get_item_resource(armor_id)
		if armor_res:
			armor_icon.texture = armor_res.icon
			armor_label.text = armor_res.display_name
		else:
			armor_icon.texture = null
			armor_label.text = "Desconocida"

	# Sello
	var seal_id = PlayerStats.equipped_seal_id
	if seal_id.is_empty():
		seal_icon.texture = null
		seal_label.text = "Sello"
	else:
		var seal_res = InventoryManager.get_item_resource(seal_id)
		if seal_res:
			seal_icon.texture = seal_res.icon
			seal_label.text = seal_res.display_name
		else:
			seal_icon.texture = null
			seal_label.text = "Desconocido"

# Actualiza las etiquetas de estadísticas
func _update_stats_display() -> void:
	var stats = PlayerStats.get_stats_dictionary()
	hp_value.text = str(stats["hp"]) + " / " + str(stats["max_hp"])
	attack_value.text = str(stats["attack"])
	defense_value.text = str(stats["defense"])
	speed_value.text = str(stats["speed"])

# Abre el popup de acciones para el objeto seleccionado
func _on_item_action() -> void:
	if _selected_index >= inventory_grid.get_child_count():
		return
	var container = inventory_grid.get_child(_selected_index)
	if not container is MarginContainer:
		return
	var btn = container.get_child(0)
	if not btn is Button:
		return
	
	var item_id = btn.get_meta("item_id", "")
	if item_id.is_empty():
		return
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res:
		return
	
	_action_popup.clear()
	
	_action_popup.add_item("Descripción")
	
	if item_res.category == "consumable":
		_action_popup.add_item("Usar")
		_action_popup.add_item("Soltar")
		
	elif item_res.category == "weapon" or item_res.category == "armor":
		var is_equipped = false
		if item_res.category == "weapon" and PlayerStats.equipped_weapon_id == item_id:
			is_equipped = true
		elif item_res.category == "armor" and PlayerStats.equipped_armor_id == item_id:
			is_equipped = true
		if is_equipped:
			_action_popup.add_item("Desequipar")
		else:
			_action_popup.add_item("Equipar")
		_action_popup.add_item("Soltar")
	
	# Dentro del match o if de categorías
	elif item_res.category == "seal":
		var is_equipped = (PlayerStats.equipped_seal_id == item_id)
		if is_equipped:
			_action_popup.add_item("Desequipar")
		else:
			_action_popup.add_item("Equipar")
		_action_popup.add_item("Soltar")
	else:
		_action_popup.add_item("Soltar")
	
	var popup_pos = btn.global_position + Vector2(btn.size.x / 2, btn.size.y)
	_action_popup.position = popup_pos
	_action_popup.popup()

# Ejecuta la acción seleccionada del popup
func _on_action_selected(id: int) -> void:
	_action_popup.hide()
	if _selected_index >= inventory_grid.get_child_count():
		return
	var container = inventory_grid.get_child(_selected_index)
	if not container is MarginContainer:
		return
	var btn = container.get_child(0)
	if not btn is Button:
		return
	var item_id = btn.get_meta("item_id", "")
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res:
		return
	
	var action_text = _action_popup.get_item_text(id)
	match action_text:
		"Usar":
			_use_item(item_id, item_res)
		"Equipar":
			_equip_item(item_id, item_res)
		"Desequipar":
			_unequip_item(item_id, item_res)
		"Soltar":
			_discard_item(item_id)
		"Descripción":
			_show_item_description(item_id, item_res)

# Usa un objeto consumible (ej. poción)
func _use_item(item_id: String, item_res: ItemResource) -> void:
	if item_res.category == "consumable" and item_res.has_method("get_hp_restore"):
		var heal_amount = item_res.get_hp_restore()
		PlayerStats.heal(heal_amount)
		InventoryManager.remove_item(item_id, 1)
		_update_inventory_display()
		_update_stats_display()
		_focus_inventory_item(0)

# Equipa un arma o armadura
func _equip_item(item_id: String, item_res: ItemResource) -> void:
	match item_res.category:
		"weapon":
			EquipmentManager.equip_weapon(item_id)
		"armor":
			EquipmentManager.equip_armor(item_id)
		"seal":
			EquipmentManager.equip_seal(item_id)
	_update_equipment_display()
	_update_stats_display()

# Desequipa un arma o armadura
func _unequip_item(_item_id: String, item_res: ItemResource) -> void:
	match item_res.category:
		"weapon":
			EquipmentManager.unequip_weapon()
		"armor":
			EquipmentManager.unequip_armor()
		"seal":
			EquipmentManager.unequip_seal()
	_update_equipment_display()
	_update_stats_display()

# Descarta un objeto del inventario
func _discard_item(item_id: String) -> void:
	# Obtener el recurso completo del objeto
	var item_res = InventoryManager.get_item_resource(item_id)
	if not item_res:
		return
	
	# Verifica si el objeto está equipado
	if item_res.category == "weapon" and PlayerStats.equipped_weapon_id == item_id:
		EquipmentManager.unequip_weapon()
	elif item_res.category == "armor" and PlayerStats.equipped_armor_id == item_id:
		EquipmentManager.unequip_armor()
	elif item_res.category == "seal" and PlayerStats.equipped_seal_id == item_id:
		EquipmentManager.unequip_seal()
		
	# Buscar al jugador, usando el grupo "player"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var drop_position = player.global_position
		# Añadir un pequeño offset aleatorio para que no quede dentro del jugador
		var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		drop_position += random_offset
		
		# Instanciar el objeto recolectable
		var dropped_item = COLLECTABLE_SCENE.instantiate() as CollectableItem
		if dropped_item:
			dropped_item.item_resource = item_res
			dropped_item.global_position = drop_position
			# Añadir al nivel actual (la escena principal o el nivel cargado)
			get_tree().current_scene.add_child(dropped_item)
			dropped_item.apply_scale_from_texture()  # Aplicalado
	
	# Eliminar el objeto del inventario (como se hacía originalmente)
	InventoryManager.remove_item(item_id, 1)
	
	# Actualizar la UI del inventario y equipo
	_update_inventory_display()
	_update_equipment_display()
	_update_stats_display()
	_focus_inventory_item(0)

# Responde a cambios en el inventario actualizando la UI si el menú está abierto
func _on_inventory_changed(_item_id: String, _new_quantity: int) -> void:
	if is_open:
		_update_inventory_display()
		_update_equipment_display()

# Muestra o actualiza la descripción del objeto en el panel flotante
func _show_item_description(item_id: String, item_res: ItemResource) -> void:
	# Título: nombre del objeto
	description_title.text = item_res.display_name

	# Descripción narrativa (flavor_text)
	var flavor = item_res.flavor_text if "flavor_text" in item_res else ""
	description_text.text = flavor if not flavor.is_empty() else "Sin descripción adicional."

	# Estadísticas (beneficios numéricos)
	var stats_text = ""
	match item_res.category:
		"consumable":
			if item_res.has_method("get_hp_restore"):
				stats_text = "▸ Restaura %d HP" % item_res.get_hp_restore()
		"weapon":
			if item_res.has_method("get_attack_bonus"):
				stats_text = "▸ Ataque +%d" % item_res.get_attack_bonus()
		"armor":
			if item_res.has_method("get_defense_bonus"):
				stats_text = "▸ Defensa +%d" % item_res.get_defense_bonus()
		"seal":
			stats_text = "▸ Otorga habilidades especiales"
		_:
			stats_text = ""
	description_stats.text = stats_text

	# Asegurar que el panel esté visible y marcado como abierto
	description_panel.visible = true
	_is_description_open = true

# Cierra la ventana de descripción
func _close_description() -> void:
	description_panel.visible = false
	_is_description_open = false
