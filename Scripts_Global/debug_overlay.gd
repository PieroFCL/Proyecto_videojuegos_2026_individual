extends CanvasLayer
# Panel de depuración con FPS, memoria y tiempo de frame.

# Indica si el panel de depuración está visible.
var show_debug = false
# Tamaño de la fuente del texto de depuración.
var font_size = 6

# Oculta el panel al iniciar.
func _ready():
	visible = false

# Alterna visibilidad con F1 o acción ui_debug.
func _input(event):
	if event.is_action_pressed("ui_debug") or (event is InputEventKey and event.keycode == KEY_F1):
		show_debug = !show_debug
		visible = show_debug
		get_viewport().set_input_as_handled()

# Actualiza métricas y texto cada frame.
func _process(delta):
	if not show_debug:
		return
	# Obtiene valores de rendimiento actuales.
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000
	var memory = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024 * 1024)
	var video_mem = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024 * 1024)
	
	_update_debug_text(fps, frame_time, memory, video_mem)

# Crea o actualiza etiqueta con los datos.
func _update_debug_text(fps, frame_time, memory, video_mem):
	# Crea etiqueta si no existe.
	if not has_node("DebugLabel"):
		var label = Label.new()
		label.name = "DebugLabel"
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color.WHITE)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.7)
		label.add_theme_stylebox_override("normal", style)
		add_child(label)
	
	var label = $DebugLabel
	label.text = "FPS: %d\nFrame: %.2f ms\nRAM: %.1f MB\nVRAM: %.1f MB" % [fps, frame_time, memory, video_mem]
	label.position = Vector2(10, 10)
