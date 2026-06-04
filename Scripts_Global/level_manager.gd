extends Node
# Gestiona la carga y descarga de niveles dentro de CurrentLevelContainer.

var _initialized: bool = false
static var skip_save_on_spawn: bool = false

# Escena de transición visual (fade)
const FADE_SCENE = preload("res://Shared_Assets/Effects/FadeTransition/fade_transition.tscn")

# Contenedor donde se instancian los niveles
@onready var level_container: Node2D = null

# Nivel actualmente cargado
var current_level_instance: Node2D = null
var current_level_path: String = ""

# Altura máxima del nivel actual (en píxeles) para normalizar z_index
var current_level_max_y: int = 0

func _ready() -> void:
	await get_tree().process_frame
	var root = get_tree().current_scene
	if root.has_node("CurrentLevelContainer"):
		level_container = root.get_node("CurrentLevelContainer")
		# No ejecutamos spawn aquí. La inicialización se hará explícitamente.
		# Si hay un nivel estático (por ejemplo, en playground), se usará luego.
		print("LevelManager: Contenedor encontrado. Esperando inicialización.")
	else:
		print("LevelManager: No se encontró 'CurrentLevelContainer' en la escena actual.")

# Cambia al nivel indicado y posiciona al jugador en el EntrancePoint especificado
func change_level(new_level_path: String, entrance_name: String) -> void:
	if not level_container:
		push_error("LevelManager: level_container no disponible")
		return
	print("Cambiando a: ", new_level_path, " entrada: ", entrance_name)

	var fade = FADE_SCENE.instantiate()
	get_tree().root.add_child(fade)
	await fade.fade_out()

	# Limpiar todos los hijos del contenedor
	for child in level_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	current_level_instance = null

	var new_level_scene = load(new_level_path)
	if not new_level_scene:
		push_error("No se pudo cargar: ", new_level_path)
		return

	current_level_instance = new_level_scene.instantiate()
	level_container.add_child(current_level_instance)
	current_level_path = new_level_path
	_update_level_max_y()

	await get_tree().process_frame

	var spawn_data = _get_entrance_spawn_data(entrance_name)
	if spawn_data == null:
		push_error("No se obtuvo datos de entrada: ", entrance_name)
		return

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_data.position
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(spawn_data.direction)
		print("Jugador en ", spawn_data.position, " mirando ", spawn_data.direction)
	else:
		push_warning("No se encontró al jugador")

	await fade.fade_in()
	print("Cambio completado")

# Busca el EntrancePoint por nombre y devuelve su posición y dirección
func _get_entrance_spawn_data(entrance_name: String) -> Variant:
	if not current_level_instance:
		return null

	var entrance_node: Node2D = null

	# Buscar ruta absoluta
	if current_level_instance.has_node(entrance_name):
		entrance_node = current_level_instance.get_node(entrance_name)
	# Buscar dentro de nodo "Entrances"
	elif current_level_instance.has_node("Entrances/" + entrance_name):
		entrance_node = current_level_instance.get_node("Entrances/" + entrance_name)
	else:
		# Fallback: buscar cualquier hijo con ese nombre
		for child in current_level_instance.get_children():
			if child.name == entrance_name:
				entrance_node = child
				break
		if not entrance_node:
			push_error("EntrancePoint '", entrance_name, "' no encontrado")
			return null

	var facing = entrance_node.get_meta("facing_direction", Vector2.DOWN)
	return {"position": entrance_node.global_position, "direction": facing}

# Coloca al jugador en el punto de entrada por defecto del nivel inicial
func apply_initial_spawn() -> void:
	if _initialized:
		push_warning("apply_initial_spawn llamado después de la inicialización. Ignorando.")
		return
	initialize()  # Delegate

# Busca cualquier EntrancePoint en el nivel actual (para spawn de emergencia)
func _find_first_entrance() -> EntrancePoint:
	if current_level_instance.has_node("Entrances"):
		for child in current_level_instance.get_node("Entrances").get_children():
			if child is EntrancePoint:
				return child
	for child in current_level_instance.get_children():
		if child is EntrancePoint:
			return child
	return null

# Calcula la altura máxima del nivel actual a partir de BoundsLayer
func _update_level_max_y() -> void:
	if not current_level_instance:
		return
	var bounds_layer = current_level_instance.get_node_or_null("BoundsLayer")
	if bounds_layer and bounds_layer.tile_set:
		var used_rect = bounds_layer.get_used_rect()
		var tile_size = bounds_layer.tile_set.tile_size
		var max_y = (used_rect.position.y + used_rect.size.y) * tile_size.y
		current_level_max_y = max_y
		print("Nivel cargado, altura máxima (Y): ", current_level_max_y)
	else:
		current_level_max_y = 2000
		push_warning("No se pudo calcular altura del nivel, usando valor por defecto 2000")

# Carga un nivel directamente (sin fade) y posiciona al jugador
func load_level_directly(level_path: String, spawn_position: Vector2, facing_direction: Vector2 = Vector2.DOWN) -> void:
	print("=== load_level_directly: nivel=", level_path, " posición destino=", spawn_position)
	if not level_container:
		push_error("LevelManager: level_container no disponible en load_level_directly")
		return
	
	# Eliminar TODOS los hijos del contenedor (no solo current_level_instance)
	for child in level_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	current_level_instance = null
	
	var new_level_scene = load(level_path)
	if not new_level_scene:
		push_error("No se pudo cargar: ", level_path)
		return
	
	current_level_instance = new_level_scene.instantiate()
	level_container.add_child(current_level_instance)
	current_level_path = level_path
	_update_level_max_y()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_position
		print("=== Jugador posicionado en: ", player.global_position)
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(facing_direction)

func _apply_spawn_to_current_level() -> void:
	if not current_level_instance:
		return
	
	# Si estamos cargando una partida, no aplicar spawn inicial
	if AutosaveManager.is_loading or skip_save_on_spawn:
		print("_apply_spawn_to_current_level: omitido por carga en curso")
		return
	
	# Si ya hay un jugador posicionado (por ejemplo, después de carga), no moverlo
	var player = get_tree().get_first_node_in_group("player")
	if player and player.global_position != Vector2.ZERO:
		return
	
	var entrance_name = "entrance_inicial"
	var spawn_data = _get_entrance_spawn_data(entrance_name)
	if spawn_data == null:
		var any_entrance = _find_first_entrance()
		if any_entrance == null:
			push_warning("No se encontró ningún EntrancePoint para spawn inicial")
			return
		spawn_data = {"position": any_entrance.global_position, "direction": any_entrance.get_meta("facing_direction", Vector2.DOWN)}
		print("Usando EntrancePoint por defecto: ", any_entrance.name)
	
	if player:
		player.global_position = spawn_data.position
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(spawn_data.direction)
		print("Posición inicial: ", spawn_data.position)
		
		# Guardar checkpoint solo si NO estamos cargando una partida
		if not AutosaveManager.is_loading and not skip_save_on_spawn:
			AutosaveManager.save_checkpoint()
	else:
		push_warning("No se encontró al jugador")

# Configura el level_container sin aplicar spawn (útil antes de cargar partida)
func setup_container() -> void:
	if level_container != null:
		return
	await get_tree().process_frame
	var root = get_tree().current_scene
	if root.has_node("CurrentLevelContainer"):
		level_container = root.get_node("CurrentLevelContainer")
		print("LevelManager: Contenedor configurado.")
	else:
		print("LevelManager: No se encontró CurrentLevelContainer.")

func _get_default_spawn_position() -> Vector2:
	return Vector2(224, 152)

func initialize() -> void:
	if _initialized:
		print("LevelManager: Ya inicializado. Ignorando nueva llamada.")
		return
	if current_level_instance != null:
		print("LevelManager: Ya hay un nivel cargado. No se inicializa de nuevo.")
		return
	_initialized = true
	
	await setup_container()
	if level_container == null:
		print("LevelManager: No se pudo configurar el contenedor.")
		return
	
	# Si el contenedor ya tiene un nivel (por ejemplo, estático en playground), lo usamos.
	if level_container.get_child_count() > 0:
		print("LevelManager: El contenedor ya tiene un nivel. Usando ese.")
		current_level_instance = level_container.get_child(0) as Node2D
		current_level_path = current_level_instance.scene_file_path
		_update_level_max_y()
		_apply_spawn_to_current_level()
		return
	
	# Si no hay ningún nivel, cargamos el inicial.
	var initial_level_path = "res://Zones/Catacombs/catacombs_01.tscn"
	var new_level_scene = load(initial_level_path)
	if not new_level_scene:
		push_error("No se pudo cargar nivel inicial: ", initial_level_path)
		return
	current_level_instance = new_level_scene.instantiate()
	level_container.add_child(current_level_instance)
	current_level_path = initial_level_path
	_update_level_max_y()
	
	_apply_spawn_to_current_level()
