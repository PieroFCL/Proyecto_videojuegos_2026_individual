extends Area2D

@export var one_shot: bool = true          # Si es true, solo se activa una vez
@export var checkpoint_id: String = ""   # ID único

var activated: bool = false

func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)
	
	# Restaurar estado desde WorldStateManager si el checkpoint ya fue activado
	if one_shot and not checkpoint_id.is_empty():
		activated = WorldStateManager.is_event_triggered(checkpoint_id)
	
	# Comprobar si el jugador ya está dentro del área (opcional)
	var player = get_tree().get_first_node_in_group("player")
	if player and overlaps_body(player):
		_on_body_entered(player)

# Devuelve el ID del checkpoint (prioriza checkpoint_id, luego name)
func get_checkpoint_id() -> String:
	return checkpoint_id if not checkpoint_id.is_empty() else str(name)

# Devuelve si ya está activado
func is_activated() -> bool:
	return activated

# (Opcional) Para restaurar el estado desde el guardado
func set_activated(value: bool) -> void:
	activated = value

func _on_body_entered(body: Node2D) -> void:
	if AutosaveManager.is_loading:
		return
	
	print("Cuerpo detectado: ", body.name)
	if not activated and body.is_in_group("player"):
		if PlayerStats.current_hp <= 0:
			print("Checkpoint no guardado (jugador muerto)")
			return
		
		print("Jugador detectado, guardando checkpoint")
		if one_shot:
			activated = true
			# Guardar en WorldStateManager para que persista entre cargas
			if not checkpoint_id.is_empty():
				WorldStateManager.register_event(checkpoint_id)
		AutosaveManager.save_checkpoint()

func _show_message(text: String) -> void:
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.add_theme_color_override("font_color", Color.GREEN)
	msg_label.position = Vector2(20, 20)
	get_tree().root.add_child(msg_label)
	await get_tree().create_timer(2.0).timeout
	msg_label.queue_free()
