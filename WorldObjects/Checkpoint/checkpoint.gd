extends Area2D
# Punto de guardado automático en el mundo.

# Si es true, solo se activa una vez.
@export var one_shot: bool = true
# Identificador único para persistencia.
@export var checkpoint_id: String = ""

# Indica si ya fue activado.
var activated: bool = false

# Configura checkpoint y restaura estado persistente.
func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)
	
	# Restaura estado si es one_shot y ya fue activado.
	if one_shot and not checkpoint_id.is_empty():
		activated = WorldStateManager.is_event_triggered(checkpoint_id)
	
	# Activa si el jugador ya está dentro del área.
	var player = get_tree().get_first_node_in_group("player")
	if player and overlaps_body(player):
		_on_body_entered(player)

# Devuelve ID único del checkpoint (prioriza checkpoint_id).
func get_checkpoint_id() -> String:
	return checkpoint_id if not checkpoint_id.is_empty() else str(name)

# Retorna true si el checkpoint ya fue activado.
func is_activated() -> bool:
	return activated

# Restaura estado activado desde guardado.
func set_activated(value: bool) -> void:
	activated = value

# Activa checkpoint al entrar el jugador.
func _on_body_entered(body: Node2D) -> void:
	# Ignora si se está cargando partida.
	if AutosaveManager.is_loading:
		return
	
	print("Cuerpo detectado: ", body.name)
	# Solo activa si no está ya activado y es el jugador.
	if not activated and body.is_in_group("player"):
		# No guarda si el jugador está muerto.
		if PlayerStats.current_hp <= 0:
			print("Checkpoint no guardado (jugador muerto)")
			return
		
		print("Jugador detectado, guardando checkpoint")
		# Marca como activado si es one_shot.
		if one_shot:
			activated = true
			# Registra evento en WorldStateManager para persistencia.
			if not checkpoint_id.is_empty():
				WorldStateManager.register_event(checkpoint_id)
		# Guarda el estado del juego.
		AutosaveManager.save_checkpoint()

# Muestra mensaje temporal en pantalla.
func _show_message(text: String) -> void:
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.add_theme_color_override("font_color", Color.GREEN)
	msg_label.position = Vector2(20, 20)
	get_tree().root.add_child(msg_label)
	await get_tree().create_timer(2.0).timeout
	msg_label.queue_free()
