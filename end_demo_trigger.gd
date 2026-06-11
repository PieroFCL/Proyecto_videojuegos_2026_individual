extends Area2D
# Dispara fin de demostración al entrar el jugador.

# Texto mostrado en pantalla al finalizar.
@export var demo_end_text: String = "Fin de la Demo"
# Duración del fundido a negro.
@export var fade_duration: float = 1.0
# Tiempo de espera antes de volver al menú.
@export var wait_duration: float = 6.0

# Conecta señal de entrada al área.
func _ready():
	body_entered.connect(_on_body_entered)

# Detecta colisión con el jugador y activa fin.
func _on_body_entered(body: Node2D):
	# Solo reacciona al jugador.
	if not body.is_in_group("player"):
		return
	# Desactiva el trigger para evitar múltiples activaciones.
	set_deferred("monitoring", false)
	
	# Bloquea movimiento del jugador.
	if body.has_method("set_can_act"):
		body.set_can_act(false)
	
	# Crea capa de overlay (dibujo encima de todo).
	var overlay = CanvasLayer.new()
	overlay.layer = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(overlay)
	
	# Fondo negro que cubre toda la pantalla.
	var background = ColorRect.new()
	background.color = Color.BLACK
	background.modulate = Color(1, 1, 1, 0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	
	# Texto centrado del mensaje.
	var label = Label.new()
	label.text = demo_end_text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate = Color(1, 1, 1, 0)
	
	# Carga fuente personalizada si existe.
	var font = load("res://UI/PlayerMenu/Fonts/W95F.otf")
	if font:
		label.add_theme_font_override("font", font)
	overlay.add_child(label)
	
	# Animación de aparición (fade in).
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, fade_duration)
	tween.tween_property(label, "modulate:a", 1.0, fade_duration)
	
	# Espera el tiempo total sin pausar el juego.
	await get_tree().create_timer(fade_duration + wait_duration).timeout
	
	# Limpia overlay y reactiva movimiento.
	overlay.queue_free()
	if body.has_method("set_can_act"):
		body.set_can_act(true)
	
	# Vuelve al menú principal.
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
