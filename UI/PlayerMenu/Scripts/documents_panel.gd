extends Panel

@onready var documents_list: VBoxContainer = $HSplitContainer/ListContainer/ScrollContainer/DocumentsList
@onready var doc_viewer: RichTextLabel = $HSplitContainer/ViewerContainer/DocViewer
@onready var empty_label: Panel = $HSplitContainer/ListContainer/EmptyLabelContainer
@onready var viewer_texture: TextureRect = $HSplitContainer/ViewerContainer/ViewerTexture

@onready var scroll_indicator: TextureRect = $HSplitContainer/ViewerContainer/ScrollIndicator

# Tamaños de separación de Cabeceras
const HEADER_TOP_MARGIN: int = 3
const HEADER_BOTTOM_MARGIN: int = 1

# Separador de Botones
const SEPARATOR_HEIGHT: int = 1
const SEPARATOR_WIDTH: int = 125   # Ajusta este valor para cambiar la longitud
const SEPARATOR_COLOR: Color = Color("51413090")

var scroll_speed: float = 200.0  # píxeles por segundo
var custom_font: Font = preload("res://UI/PlayerMenu/Fonts/W95F.otf")

func _ready() -> void:
	visible = false
	doc_viewer.bbcode_enabled = true
	
	# Obtener la barra de scroll vertical del RichTextLabel
	var v_scroll = doc_viewer.get_v_scroll_bar()
	if v_scroll:
		# Hacerla transparente e ignorar eventos de ratón
		v_scroll.modulate = Color(0, 0, 0, 0)
		v_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Opcional: también quitar el estilo visual
		var style = StyleBoxEmpty.new()
		v_scroll.add_theme_stylebox_override("scroll", style)
		v_scroll.add_theme_stylebox_override("grabber", style)
		v_scroll.add_theme_stylebox_override("grabber_highlight", style)

func _process(delta: float) -> void:
	if not visible:
		return
	
	var v_scroll = doc_viewer.get_v_scroll_bar()
	if not v_scroll:
		return
	
	var left_pressed = Input.is_action_pressed("menu_left")
	var right_pressed = Input.is_action_pressed("menu_right")
	
	# Solo permitir desplazamiento si el documento lo requiere
	if v_scroll.max_value <= 0:
		return
	
	var scroll_delta = 0.0
	
	# Calcular el desplazamiento pero respetando los límites
	if left_pressed:
		# Solo si no está ya en el inicio
		if v_scroll.value > 0:
			scroll_delta = -scroll_speed * delta
	elif right_pressed:
		# Solo si no está ya en el final
		if v_scroll.value < v_scroll.max_value:
			scroll_delta = scroll_speed * delta
	
	if scroll_delta != 0.0:
		var new_value = v_scroll.value + scroll_delta
		v_scroll.value = clamp(new_value, 0.0, v_scroll.max_value)
		_update_scroll_indicator()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	# Si hay combate activo, el panel de documentos no debe procesar teclas
	if CombatManager.combat_scene_instance != null:
		return

	# Solo procesar si el panel está visible
	if not visible:
		return

	# Solo manejar navegación vertical si NO se está desplazando el texto con A/D
	var left_right_pressed = Input.is_action_pressed("menu_left") or Input.is_action_pressed("menu_right")
	if left_right_pressed:
		return

	if event.is_action_pressed("menu_up") or event.is_action_pressed("menu_down"):
		# Obtener el botón actualmente enfocado
		var focused = get_viewport().gui_get_focus_owner()
		if not focused is Button:
			var first_button = _get_first_focusable_button()
			if first_button:
				first_button.grab_focus()
			return

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
		else: # menu_down
			new_index += 1

		if new_index >= 0 and new_index < buttons.size():
			buttons[new_index].grab_focus()
			# Scroll automático para mantener visible
			var btn_rect = buttons[new_index].get_global_rect()
			var scroll_rect = documents_list.get_global_rect()
			if btn_rect.position.y < scroll_rect.position.y or btn_rect.position.y + btn_rect.size.y > scroll_rect.position.y + scroll_rect.size.y:
				var scroll_container = documents_list.get_parent().get_parent()
				if scroll_container is ScrollContainer:
					var target_scroll = btn_rect.position.y - scroll_rect.position.y
					scroll_container.scroll_vertical = target_scroll

		# Consumir el evento de forma robusta
		var viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()

func open() -> void:
	visible = true
	_populate_list()
	await get_tree().process_frame
	var first_button = _get_first_focusable_button()
	if first_button:
		first_button.grab_focus()

func close() -> void:
	visible = false

func _update_scroll_indicator() -> void:
	if not scroll_indicator:
		return
	var v_scroll = doc_viewer.get_v_scroll_bar()
	if v_scroll:
		# Comparar el valor máximo con el tamaño de página
		var needs_scroll = v_scroll.max_value > v_scroll.page
		scroll_indicator.visible = needs_scroll

func _populate_list() -> void:
	for child in documents_list.get_children():
		child.queue_free()
	
	if DocumentManager.is_empty():
		empty_label.visible = true
		documents_list.visible = false
		viewer_texture.visible = false
		return
	else:
		empty_label.visible = false
		documents_list.visible = true
		viewer_texture.visible = true
	
	var collections_order = ["aldren", "ricardo", "doroti", "otros"]
	for col_id in collections_order:
		var docs = DocumentManager.get_documents(col_id)
		if docs.is_empty():
			continue
		
		# Encabezado de colección
		var header_label = Label.new()
		header_label.text = _get_collection_display_name(col_id)
		header_label.add_theme_font_size_override("font_size", 10)
		header_label.add_theme_font_override("font", custom_font)
		header_label.add_theme_color_override("font_color", Color("#472228"))
		
		# Sombra para el texto de la cabecera
		header_label.add_theme_color_override("font_shadow_color", Color("47222862")) 
		header_label.add_theme_constant_override("shadow_offset_x", 0)
		header_label.add_theme_constant_override("shadow_offset_y", 0)
		header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var header_container = MarginContainer.new()
		header_container.add_child(header_label)
		header_container.add_theme_constant_override("margin_top", HEADER_TOP_MARGIN)
		header_container.add_theme_constant_override("margin_bottom", HEADER_BOTTOM_MARGIN)
		documents_list.add_child(header_container)

		var pages = docs.keys()
		pages.sort()
		var btn_list = []
		for page in pages:
			var doc = docs[page]
			var btn_container = _create_document_button(doc)
			documents_list.add_child(btn_container)
			btn_list.append(btn_container)
		
		# Añadir separadores entre botones 
		if btn_list.size() > 1:
			for i in range(btn_list.size() - 1):
				var separator = _create_separator()
				var btn_index = btn_list[i].get_index()
				documents_list.add_child(separator)
				documents_list.move_child(separator, btn_index + 1)

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

func _create_document_button(doc: DocumentItem) -> Button:
	var btn = Button.new()
	
	# Texto personalizado según colección
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
	
	# Configuración de texto
	var text_color = Color("#514130")
	var focus_text_color = Color("b07b00ff")
	
	# Estilos de Texto
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_pressed_color", focus_text_color)
	btn.add_theme_color_override("font_focus_color", focus_text_color)
	btn.add_theme_color_override("font_hover_color", focus_text_color)
	
	# Estilos de Botón
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
	
	# Fuente
	if custom_font:
		btn.add_theme_font_override("font", custom_font)
	btn.add_theme_font_size_override("font_size", 8)
	
	# Alineación y tamaño
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.custom_minimum_size = Vector2(0, 14)
	
	btn.focus_entered.connect(_on_document_focused.bind(doc))
	return btn

func _get_first_focusable_button() -> Button:
	for child in documents_list.get_children():
		if child is Button:
			return child
	return null

func _on_document_focused(doc: DocumentItem) -> void:
	var text = "[center][font_size=11]%s[/font_size][/center]\n\n[font_size=8]%s[/font_size]" % [doc.title, doc.text_content]
	doc_viewer.bbcode_text = text
	await get_tree().process_frame
	await get_tree().process_frame
	doc_viewer.scroll_to_line(0)
	await get_tree().process_frame
	_update_scroll_indicator()

func _get_collection_display_name(collection_id: String) -> String:
	match collection_id:
		"aldren": return "Diario de Aldren Valen"
		"ricardo": return "Bitácoras de Ricardo Santos"
		"doroti": return "Apuntes de la Devota Doroti"
		"otros": return "Otros documentos"
		_: return collection_id.capitalize()
	
