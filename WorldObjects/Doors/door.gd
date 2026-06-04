extends StaticBody2D

@export var required_item_id: String = ""      # ID de la llave (ej. "llave_cripta")
@export var open_texture: Texture2D = null     # Textura de puerta abierta
@export var close_texture: Texture2D = null    # Textura de puerta cerrada
@export var door_id: String = ""               # Identificador único de la puerta (para persistencia)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var indicator_label: Label = $InteractionIndicator
@onready var indicator_texture: TextureRect = $InteractionIndicator/IndicatorTexture

var is_open: bool = false
var player_near: bool = false

func _ready() -> void:
	# Ocultar el icono inicialmente
	if indicator_texture:
		indicator_texture.visible = false
	indicator_label.visible = false

	# Si la puerta ya está registrada como abierta en WorldStateManager, la abrimos sin consumir llave
	if not door_id.is_empty() and WorldStateManager.is_door_opened(door_id):
		_open_door(true)   # true = carga de estado, no registrar nuevamente
	else:
		# Configurar puerta cerrada
		if close_texture:
			sprite.texture = close_texture
		collision.disabled = false
		is_open = false

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Actualizar el texto del indicador si el jugador está cerca y la puerta no está abierta
	z_index = int(global_position.y) + 500
	if player_near and not is_open:
		_update_indicator_text()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_open:
		player_near = true
		_update_indicator_text()
		indicator_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		indicator_label.visible = false

func _update_indicator_text() -> void:
	if required_item_id.is_empty():
		indicator_label.text = "Abrir puerta"
		if indicator_texture:
			indicator_texture.visible = true
	elif InventoryManager.has_item(required_item_id, 1):
		indicator_label.text = "Usar llave"
		if indicator_texture:
			indicator_texture.visible = true
	else:
		indicator_label.text = "Requiere llave"
		if indicator_texture:
			indicator_texture.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_near and not is_open:
		_try_open()

func _try_open() -> void:
	if required_item_id.is_empty():
		_open_door()
		return
	
	if InventoryManager.has_item(required_item_id, 1):
		InventoryManager.remove_item(required_item_id, 1)
		_open_door()
		_show_message(".")
	else:
		_show_message(".")

func _open_door(load_state: bool = false) -> void:
	is_open = true
	if open_texture:
		sprite.texture = open_texture
	else:
		sprite.visible = false
	collision.disabled = true
	indicator_label.visible = false
	if indicator_texture:
		indicator_texture.visible = false
	
	# Registrar la puerta como abierta solo si no es una carga de estado y tiene ID
	if not load_state and not door_id.is_empty():
		WorldStateManager.register_opened_door(door_id)
	
	# Desactivar el área de interacción para evitar futuras detecciones
	interaction_area.queue_free()

func _show_message(text: String) -> void:
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.add_theme_color_override("font_color", Color.WHITE)
	msg_label.position = Vector2(20, 20)
	get_tree().root.add_child(msg_label)
	await get_tree().create_timer(2.0).timeout
	msg_label.queue_free()
