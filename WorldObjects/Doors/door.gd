extends StaticBody2D
# Puerta que requiere llave y persiste su estado.

# ID de la llave necesaria para abrir.
@export var required_item_id: String = ""
# Textura cuando la puerta está abierta.
@export var open_texture: Texture2D = null
# Textura cuando la puerta está cerrada.
@export var close_texture: Texture2D = null
# Identificador único para persistencia (WorldStateManager).
@export var door_id: String = ""

# Nodo Sprite para mostrar la textura.
@onready var sprite: Sprite2D = $Sprite2D
# Colisión física de la puerta.
@onready var collision: CollisionShape2D = $CollisionShape2D
# Área para detectar al jugador.
@onready var interaction_area: Area2D = $InteractionArea
# Etiqueta con el texto de interacción.
@onready var indicator_label: Label = $InteractionIndicator
# Icono decorativo junto al texto.
@onready var indicator_texture: TextureRect = $InteractionIndicator/IndicatorTexture

# Estado de la puerta (abierta/cerrada).
var is_open: bool = false
# Indica si el jugador está cerca.
var player_near: bool = false

# Configura la puerta y restaura estado persistente.
func _ready() -> void:
	# Oculta icono y etiqueta inicialmente.
	if indicator_texture:
		indicator_texture.visible = false
	indicator_label.visible = false

	# Restaura estado abierto si ya estaba registrada.
	if not door_id.is_empty() and WorldStateManager.is_door_opened(door_id):
		_open_door(true)   # true = carga de estado, no re-registrar.
	else:
		# Configura estado cerrado por defecto.
		if close_texture:
			sprite.texture = close_texture
		collision.disabled = false
		is_open = false

	# Conecta señales del área de interacción.
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

# Actualiza texto, icono y profundidad cada frame.
func _process(_delta: float) -> void:
	z_index = int(global_position.y) + 500
	# Muestra indicador si jugador cerca y puerta cerrada.
	if player_near and not is_open:
		_update_indicator_text()

# Detecta entrada del jugador al área.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_open:
		player_near = true
		_update_indicator_text()
		indicator_label.visible = true

# Detecta salida del jugador del área.
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		indicator_label.visible = false

# Cambia texto e icono según requisito de llave.
func _update_indicator_text() -> void:
	# Sin llave requerida: mostrar "Abrir puerta".
	if required_item_id.is_empty():
		indicator_label.text = "Abrir puerta"
		if indicator_texture:
			indicator_texture.visible = true
	# Si tiene la llave: mostrar "Usar llave".
	elif InventoryManager.has_item(required_item_id, 1):
		indicator_label.text = "Usar llave"
		if indicator_texture:
			indicator_texture.visible = true
	# Sin llave: mostrar "Requiere llave".
	else:
		indicator_label.text = "Requiere llave"
		if indicator_texture:
			indicator_texture.visible = false

# Captura tecla interactuar cerca de la puerta.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_near and not is_open:
		_try_open()

# Intenta abrir la puerta consumiendo llave si es necesaria.
func _try_open() -> void:
	# Sin requisito, abre directamente.
	if required_item_id.is_empty():
		_open_door()
		return
	# Si tiene la llave, la consume y abre.
	if InventoryManager.has_item(required_item_id, 1):
		InventoryManager.remove_item(required_item_id, 1)
		_open_door()
		_show_message(".")
	else:
		_show_message(".")

# Abre la puerta, cambia textura y registra estado.
func _open_door(load_state: bool = false) -> void:
	is_open = true
	# Cambia textura a abierta o la oculta.
	if open_texture:
		sprite.texture = open_texture
	else:
		sprite.visible = false
	# Desactiva colisión e indicadores.
	collision.disabled = true
	indicator_label.visible = false
	if indicator_texture:
		indicator_texture.visible = false
	
	# Registra en WorldStateManager si no es carga de estado.
	if not load_state and not door_id.is_empty():
		WorldStateManager.register_opened_door(door_id)
	
	# Elimina el área de interacción.
	interaction_area.queue_free()

# Muestra mensaje temporal en pantalla.
func _show_message(text: String) -> void:
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.add_theme_color_override("font_color", Color.WHITE)
	msg_label.position = Vector2(20, 20)
	get_tree().root.add_child(msg_label)
	await get_tree().create_timer(2.0).timeout
	msg_label.queue_free()
