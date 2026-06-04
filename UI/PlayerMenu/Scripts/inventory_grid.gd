class_name InventoryGrid extends GridContainer

# Señales
signal inventory_emptiness_changed(is_empty: bool)
signal item_selected(item_id: String)

var _items: Array = []            # IDs de los objetos en orden.
var _selected_index: int = 0      # Índice del objeto actualmente enfocado.
var _custom_font: Font = null     # Fuente para la etiqueta de cantidad.

func _ready() -> void:
	_custom_font = load("res://UI/PlayerMenu/Fonts/W95F.otf")
	InventoryManager.inventory_changed.connect(_refresh)
	_refresh()

# Reconstruye la cuadrícula cuando cambia el inventario.
func _refresh(_item_id = "", _new_quantity = 0) -> void:
	# Limpiar hijos anteriores
	for child in get_children():
		child.queue_free()

	var all_items = InventoryManager.get_all_items()
	_items = all_items.keys()
	var has_items = _items.size() > 0
	inventory_emptiness_changed.emit(not has_items)

	if not has_items:
		_selected_index = -1
		return

	# Crear botones
	for i in range(_items.size()):
		var item_id = _items[i]
		var res = InventoryManager.get_item_resource(item_id)
		if not res:
			continue
		var qty = InventoryManager.get_quantity(item_id)

		var container = MarginContainer.new()
		container.custom_minimum_size = Vector2(36, 36)

		var btn = Button.new()
		btn.expand_icon = true
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.focus_mode = Control.FOCUS_ALL
		btn.icon = res.icon if res.icon else null
		btn.tooltip_text = res.display_name
		btn.set_meta("item_id", item_id)
		btn.set_meta("index", i)

		# Estilos
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color.TRANSPARENT
		normal_style.border_color = Color("8E5E58")
		normal_style.set_border_width_all(2)
		btn.add_theme_stylebox_override("normal", normal_style)

		var focus_style = StyleBoxFlat.new()
		focus_style.bg_color = Color.TRANSPARENT
		focus_style.border_color = Color("6D403B")
		focus_style.set_border_width_all(2)
		btn.add_theme_stylebox_override("focus", focus_style)

		container.add_child(btn)

		# Etiqueta de cantidad si es > 1
		if qty > 1:
			var qty_label = Label.new()
			qty_label.text = str(qty)
			qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if _custom_font:
				qty_label.add_theme_font_override("font", _custom_font)
			qty_label.add_theme_font_size_override("font_size", 8)
			qty_label.add_theme_color_override("font_color", Color.GREEN_YELLOW)
			qty_label.add_theme_constant_override("shadow_offset_x", 1)
			qty_label.add_theme_constant_override("shadow_offset_y", 1)
			qty_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
			btn.add_child(qty_label)
			qty_label.position = Vector2(3, 3)

		add_child(container)

	# Enfocar primer objeto
	_selected_index = 0
	_focus_item(0)

# Enfoca el botón en el índice dado
func _focus_item(idx: int) -> void:
	if idx < 0 or idx >= get_child_count():
		return
	var container = get_child(idx) as MarginContainer
	if not container:
		return
	var btn = container.get_child(0) as Button
	if btn:
		btn.grab_focus.call_deferred()

# Libera foco del botón actual
func _unfocus_current() -> void:
	if _selected_index >= 0 and _selected_index < get_child_count():
		var container = get_child(_selected_index) as MarginContainer
		if container:
			var btn = container.get_child(0) as Button
			if btn and btn.has_focus():
				btn.release_focus()

# Consume el evento para evitar propagación
func _consume_event() -> void:
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

# Manejo de entrada de teclado
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print("InventoryGrid _input: ", event.as_text())
	# Eliminamos 'or get_tree().paused' para que funcione con el juego pausado
	if not visible:
		return
	var total = _items.size()
	if total == 0:
		return

	var moved = false
	var new_idx = _selected_index
	var cols = columns if columns > 0 else 1

	if event.is_action_pressed("menu_left"):
		new_idx -= 1
		moved = true
	elif event.is_action_pressed("menu_right"):
		new_idx += 1
		moved = true
	elif event.is_action_pressed("menu_up"):
		new_idx -= cols
		moved = true
	elif event.is_action_pressed("menu_down"):
		new_idx += cols
		moved = true
	# Usamos 'interact' como acción de selección (puedes cambiarlo a menu_accept si lo prefieres)
	elif event.is_action_pressed("interact"):
		print("DEBUG: interact detectado en InventoryGrid")
		if _selected_index >= 0 and _selected_index < _items.size():
			print("DEBUG: Emitiendo item_selected para: ", _items[_selected_index])
			item_selected.emit(_items[_selected_index])
		else:
			print("DEBUG: índice inválido: ", _selected_index)
		_consume_event()
		return

	if moved:
		new_idx = clampi(new_idx, 0, total - 1)
		if new_idx != _selected_index:
			_unfocus_current()
			_selected_index = new_idx
			_focus_item(_selected_index)
		_consume_event()
