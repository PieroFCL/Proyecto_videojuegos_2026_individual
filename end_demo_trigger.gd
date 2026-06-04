extends Area2D

@export var demo_end_text: String = "Fin de Versión Funcional"
@export var fade_duration: float = 1.0
@export var wait_duration: float = 6.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return

	set_deferred("monitoring", false)
	
	# Desactivar la capacidad de actuar del jugador (en lugar de pausar todo)
	if body.has_method("set_can_act"):
		body.set_can_act(false)
	
	# Crear overlay (igual que antes)
	var overlay = CanvasLayer.new()
	overlay.layer = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(overlay)
	
	var background = ColorRect.new()
	background.color = Color.BLACK
	background.modulate = Color(1, 1, 1, 0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	
	var label = Label.new()
	label.text = demo_end_text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate = Color(1, 1, 1, 0)
	
	var font = load("res://UI/PlayerMenu/Fonts/W95F.otf")
	if font:
		label.add_theme_font_override("font", font)
	overlay.add_child(label)
	
	# Tween (ahora sin pausa global, funcionará)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, fade_duration)
	tween.tween_property(label, "modulate:a", 1.0, fade_duration)
	
	# Esperar sin pausa (timer normal)
	await get_tree().create_timer(fade_duration + wait_duration).timeout
	
	overlay.queue_free()
	if body.has_method("set_can_act"):
		body.set_can_act(true)
	
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
