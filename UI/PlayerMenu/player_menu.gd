extends CanvasLayer
## Menú del personaje con inventario, equipo y estadísticas.

# ---- Nodos de la UI ----
@onready var background: ColorRect = $Background
@onready var menu_container: Panel = $MenuContainer
@onready var inventory_grid: GridContainer = $MenuContainer/InventoryPanel/InventoryGrid
@onready var weapon_icon: TextureRect = $MenuContainer/EquipmentPanel/WeaponSlot/WeaponIcon
@onready var weapon_label: Label = $MenuContainer/EquipmentPanel/WeaponSlot/WeaponLabel
@onready var armor_icon: TextureRect = $MenuContainer/EquipmentPanel/ArmorSlot/ArmorIcon
@onready var armor_label: Label = $MenuContainer/EquipmentPanel/ArmorSlot/ArmorLabel
@onready var hp_value: Label = $MenuContainer/StatsPanel/HPValue
@onready var attack_value: Label = $MenuContainer/StatsPanel/AttackValue
@onready var defense_value: Label = $MenuContainer/StatsPanel/DefenseValue
@onready var speed_value: Label = $MenuContainer/StatsPanel/SpeedValue

@onready var empty_inventory_panel: Panel = $MenuContainer/InventoryPanel/EmptyInventoryPanel

# ---- Variables internas ----
var is_open: bool = false
var _current_inventory_items: Array = []        # IDs ordenados
var _selected_index: int = 0
var _action_popup: PopupMenu = null
var _custom_font: Font = null

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
	_action_popup.add_item("Descartar")
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
	
	visible = false
	is_open = false

func _set_mouse_filter_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_mouse_filter_ignore(child)

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

func close_menu() -> void:
	if not is_open: return
	is_open = false
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	# Abrir/cerrar menú
	if event.is_action_pressed("toggle_menu"):
		if is_open:
			close_menu()
		else:
			open_menu()
		return
	
	if not is_open:
		return
	
	# Cancelar / cerrar popup o menú (tecla Q)
	if event.is_action_pressed("menu_cancel"):
		if _action_popup.visible:
			_action_popup.hide()
		else:
			close_menu()
		return
	
	# Abrir popup (tecla E) - solo cuando el popup NO está visible
	if event.is_action_pressed("menu_accept") and not _action_popup.visible:
		_on_item_action()
		return
	
	# Navegación del inventario (solo si el popup no está visible)
	if not _action_popup.visible:
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

# ---- Actualización de la UI ----

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

func _update_stats_display() -> void:
	var stats = PlayerStats.get_stats_dictionary()
	hp_value.text = str(stats["hp"]) + " / " + str(stats["max_hp"])
	attack_value.text = str(stats["attack"])
	defense_value.text = str(stats["defense"])
	speed_value.text = str(stats["speed"])

# ---- Manejo de acciones ----
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
	
	if item_res.category == "consumable":
		_action_popup.add_item("Usar")
		_action_popup.add_item("Descartar")
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
		_action_popup.add_item("Descartar")
	else:
		_action_popup.add_item("Descartar")
	
	var popup_pos = btn.global_position + Vector2(btn.size.x / 2, btn.size.y)
	_action_popup.position = popup_pos
	_action_popup.popup()

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
		"Descartar":
			_discard_item(item_id)

func _use_item(item_id: String, item_res: ItemResource) -> void:
	if item_res.category == "consumable" and item_res.has_method("get_hp_restore"):
		var heal_amount = item_res.get_hp_restore()
		PlayerStats.heal(heal_amount)
		InventoryManager.remove_item(item_id, 1)
		_update_inventory_display()
		_update_stats_display()
		_focus_inventory_item(0)

func _equip_item(item_id: String, item_res: ItemResource) -> void:
	if item_res.category == "weapon":
		EquipmentManager.equip_weapon(item_id)
	elif item_res.category == "armor":
		EquipmentManager.equip_armor(item_id)
	else:
		return
	_update_equipment_display()
	_update_stats_display()

func _unequip_item(item_id: String, item_res: ItemResource) -> void:
	if item_res.category == "weapon":
		EquipmentManager.unequip_weapon()
	elif item_res.category == "armor":
		EquipmentManager.unequip_armor()
	_update_equipment_display()
	_update_stats_display()

func _discard_item(item_id: String) -> void:
	InventoryManager.remove_item(item_id, 1)
	_update_inventory_display()
	_update_equipment_display()
	_update_stats_display()
	_focus_inventory_item(0)

func _on_inventory_changed(item_id: String, new_quantity: int) -> void:
	if is_open:
		_update_inventory_display()
		_update_equipment_display()
