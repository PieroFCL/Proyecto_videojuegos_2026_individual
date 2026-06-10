extends Panel
# Panel de documentos con lista y visor de texto.

# Contenedor de la lista de documentos (VBoxContainer).
@onready var documents_list: VBoxContainer = $HSplitContainer/ListContainer/ScrollContainer/DocumentsList
# Visor de texto enriquecido para mostrar contenido.
@onready var doc_viewer: RichTextLabel = $HSplitContainer/ViewerContainer/DocViewer
# Panel mostrado cuando no hay documentos.
@onready var empty_label: Panel = $HSplitContainer/ListContainer/EmptyLabelContainer
# Textura decorativa del visor.
@onready var viewer_texture: TextureRect = $HSplitContainer/ViewerContainer/ViewerTexture

# Indicador visual de desplazamiento disponible.
@onready var scroll_indicator: TextureRect = $HSplitContainer/ViewerContainer/ScrollIndicator

# Margen superior de las cabeceras de colección.
const HEADER_TOP_MARGIN: int = 3
# Margen inferior de las cabeceras de colección.
const HEADER_BOTTOM_MARGIN: int = 1

# Altura del separador entre botones.
const SEPARATOR_HEIGHT: int = 1
# Ancho del separador entre botones.
const SEPARATOR_WIDTH: int = 125
# Color del separador.
const SEPARATOR_COLOR: Color = Color("51413090")

# Velocidad de desplazamiento vertical del texto (píxeles/segundo).
var scroll_speed: float = 200.0
# Fuente personalizada para la interfaz.
var custom_font: Font = preload("res://UI/PlayerMenu/Fonts/W95F.otf")

# Configura visor y barra de scroll al iniciar.
func _ready() -> void:
	visible = false
	doc_viewer.bbcode_enabled = true
	
	var v_scroll = doc_viewer.get_v_scroll_bar()
	if v_scroll:
		# Oculta visualmente la barra de scroll.
		v_scroll.modulate = Color(0, 0, 0, 0)
		v_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Elimina el estilo visual de la barra.
		var style = StyleBoxEmpty.new()
		v_scroll.add_theme_stylebox_override("scroll", style)
		v_scroll.add_theme_stylebox_override("grabber", style)
		v_scroll.add_theme_stylebox_override("grabber_highlight", style)

# Desplaza el texto con teclas A/D.
func _process(delta: float) -> void:
	if not visible:
		return
	var v_scroll = doc_viewer.get_v_scroll_bar()
	if not v_scroll:
		return
	# Ignora si el documento no requiere scroll.
	if v_scroll.max_value <= 0:
		return
	var left_pressed = Input.is_action_pressed("menu_left")
	var right_pressed = Input.is_action_pressed("menu_right")
	var scroll_delta = 0.0
	if left_pressed and v_scroll.value > 0:
		scroll_delta = -scroll_speed * delta
	elif right_pressed and v_scroll.value < v_scroll.max_value:
		scroll_delta = scroll_speed * delta
	if scroll_delta != 0.0:
		var new_value = v_scroll.value + scroll_delta
		v_scroll.value = clamp(new_value, 0.0, v_scroll.max_value)
		_update_scroll_indicator()

# Maneja navegación vertical en la lista de documentos.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	# Ignora si hay combate activo.
	if CombatManager.combat_scene_instance != null:
		return
	if not visible:
		return
	# Ignora si se presiona A/D (desplazamiento).
	var left_right_pressed = Input.is_action_pressed("menu_left") or Input.is_action_pressed("menu_right")
	if left_right_pressed:
		return

	if event.is_action_pressed("menu_up") or event.is_action_pressed("menu_down"):
		var focused = get_viewport().gui_get_focus_owner()
		# Si no hay botón enfocado, enfoca el primero.
		if not focused is Button:
			var first_button = _get_first_focusable_button()
			if first_button:
				first_button.grab_focus()
			return
		# Recolecta todos los botones de la lista.
		var buttons = []
		for child in documents_list.get_children():
			if child is Button:
				buttons.append(child)
			elif child is CenterContainer and child.get_child_count() > 0:
				var inner_btn = child.get_child(0)
				if inner_btn is Button:
					buttons.append(inner_btn)
		if buttons.is_empty():
			return
		var current_index = buttons.find(focused)
		if current_index == -1:
			return
		var new_index = current_index
		if event.is_action_pressed("menu_up"):
			new_index -= 1
		else:
			new_index += 1
		if new_index >= 0 and new_index < buttons.size():
			buttons[new_index].grab_focus()
			# Ajusta scroll para mostrar el botón.
			var btn_rect = buttons[new_index].get_global_rect()
			var scroll_rect = documents_list.get_global_rect()
			if btn_rect.position.y < scroll_rect.position.y or btn_rect.position.y + btn_rect.size.y > scroll_rect.position.y + scroll_rect.size.y:
				var scroll_container = documents_list.get_parent().get_parent()
				if scroll_container is ScrollContainer:
					var target_scroll = btn_rect.position.y - scroll_rect.position.y
					scroll_container.scroll_vertical = target_scroll
		# Consume el evento para evitar propagación.
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()

# Muestra el panel y carga la lista de documentos.
func open() -> void:
	visible = true
	_populate_list()
	await get_tree().process_frame
	var first_button = _get_first_focusable_button()
	if first_button:
		first_button.grab_focus()

# Oculta el panel.
func close() -> void:
	visible = false

# Actualiza la visibilidad del indicador de scroll.
func _update_scroll_indicator() -> void:
	if not scroll_indicator:
		return
	var v_scroll = doc_viewer.get_v_scroll_bar()
	if v_scroll:
		var needs_scroll = v_scroll.max_value > v_scroll.page
		scroll_indicator.visible = needs_scroll

# Construye la lista de documentos y encabezados por colección.
func _populate_list() -> void:
	# Limpia la lista antes de reconstruirla.
	for child in documents_list.get_children():
		child.queue_free()
	
	# Muestra panel vacío si no hay documentos.
	if DocumentManager.is_empty():
		empty_label.visible = true
		documents_list.visible = false
		viewer_texture.visible = false
		return
	else:
		empty_label.visible = false
		documents_list.visible = true
		viewer_texture.visible = true
	
	# Orden fijo de colecciones.
	var collections_order = ["aldren", "ricardo", "doroti", "otros"]
	for col_id in collections_order:
		var docs = DocumentManager.get_documents(col_id)
		if docs.is_empty():
			continue
		
		# Crea encabezado de la colección.
		var header_label = Label.new()
		header_label.text = _get_collection_display_name(col_id)
		header_label.add_theme_font_size_override("font_size", 10)
		header_label.add_theme_font_override("font", custom_font)
		header_label.add_theme_color_override("font_color", Color("#472228"))
		# Agrega sombra al texto del encabezado.
		header_label.add_theme_color_override("font_shadow_color", Color("47222862")) 
		header_label.add_theme_constant_override("shadow_offset_x", 0)
		header_label.add_theme_constant_override("shadow_offset_y", 0)
		header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Contenedor con márgenes para el encabezado.
		var header_container = MarginContainer.new()
		header_container.add_child(header_label)
		header_container.add_theme_constant_override("margin_top", HEADER_TOP_MARGIN)
		header_container.add_theme_constant_override("margin_bottom", HEADER_BOTTOM_MARGIN)
		documents_list.add_child(header_container)

		# Ordena páginas numéricamente.
		var pages = docs.keys()
		pages.sort()
		var btn_list = []
		for page in pages:
			var doc = docs[page]
			var btn_container = _create_document_button(doc)
			documents_list.add_child(btn_container)
			btn_list.append(btn_container)
		
		# Agrega separadores entre botones si hay varios.
		if btn_list.size() > 1:
			for i in range(btn_list.size() - 1):
				var separator = _create_separator()
				var btn_index = btn_list[i].get_index()
				documents_list.add_child(separator)
				documents_list.move_child(separator, btn_index + 1)

# Crea un separador visual entre botones.
func _create_separator() -> Control:
	var center_container = CenterContainer.new()
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var separator_rect = ColorRect.new()
	separator_rect.color = SEPARATOR_COLOR
	separator_rect.custom_minimum_size = Vector2(SEPARATOR_WIDTH, SEPARATOR_HEIGHT)
	separator_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	center_container.add_child(separator_rect)
	return center_container

# Crea un botón para un documento con formato según colección.
func _create_document_button(doc: DocumentItem) -> Button:
	var btn = Button.new()
	
	# Texto personalizado según tipo de colección.
	match doc.collection_id:
		"aldren":
			btn.text = "Página %d. %s" % [doc.page_number, doc.title]
		"doroti":
			btn.text = "Nota %d. %s" % [doc.page_number, doc.title]
		"ricardo":
			btn.text = "Bitácora %d. %s" % [doc.page_number, doc.title]
		_:  # "otros" o cualquier otro
			btn.text = doc.title
	
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_meta("document", doc)
	
	# Configura colores de texto.
	var text_color = Color("#514130")
	var focus_text_color = Color("b07b00ff")
	
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_pressed_color", focus_text_color)
	btn.add_theme_color_override("font_focus_color", focus_text_color)
	btn.add_theme_color_override("font_hover_color", focus_text_color)
	
	# Estilos base para los botones.
	var base_style = func() -> StyleBoxFlat:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("ffffff00")
		style.border_color = Color("ffffff00")
		style.border_width_top = 0
		style.border_width_bottom = 0
		style.border_width_left = 0
		style.border_width_right = 0
		style.set_corner_radius_all(0)
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		style.content_margin_left = 5
		style.content_margin_right = 5
		return style
	
	# Aplica estilos normal, presionado, foco y hover.
	var normal_style = base_style.call()
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var pressed_style = base_style.call()
	pressed_style.bg_color = Color("ffffff00")
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	var focus_style = base_style.call()
	focus_style.bg_color = Color("ffffff00")
	btn.add_theme_stylebox_override("focus", focus_style)
	
	var hover_style = base_style.call()
	hover_style.bg_color = Color("ffffff00")
	btn.add_theme_stylebox_override("hover", hover_style)
	
	# Asigna fuente personalizada.
	if custom_font:
		btn.add_theme_font_override("font", custom_font)
	btn.add_theme_font_size_override("font_size", 8)
	
	# Configura alineación y tamaño mínimo.
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(0, 14)
	
	# Conecta señal para mostrar documento al enfocar.
	btn.focus_entered.connect(_on_document_focused.bind(doc))
	return btn

# Obtiene el primer botón enfocable de la lista.
func _get_first_focusable_button() -> Button:
	for child in documents_list.get_children():
		if child is Button:
			return child
	return null

# Muestra el contenido del documento al enfocar su botón.
func _on_document_focused(doc: DocumentItem) -> void:
	var text = "[center][font_size=11]%s[/font_size][/center]\n\n[font_size=8]%s[/font_size]" % [doc.title, doc.text_content]
	doc_viewer.bbcode_text = text
	await get_tree().process_frame
	await get_tree().process_frame
	doc_viewer.scroll_to_line(0)
	await get_tree().process_frame
	_update_scroll_indicator()

# Devuelve nombre legible de la colección según su ID.
func _get_collection_display_name(collection_id: String) -> String:
	match collection_id:
		"aldren": return "Diario de Aldren Valen"
		"ricardo": return "Bitácoras de Ricardo Santos"
		"doroti": return "Apuntes de la Devota Doroti"
		"otros": return "Otros documentos"
		_: return collection_id.capitalize()
