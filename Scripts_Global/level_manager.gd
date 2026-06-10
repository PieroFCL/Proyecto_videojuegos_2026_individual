extends Node
# Gestiona carga y descarga de niveles en CurrentLevelContainer.

# Indica si ya se inicializó el LevelManager.
var _initialized: bool = false
# Evita guardar checkpoint al spawn durante carga de partida.
static var skip_save_on_spawn: bool = false

# Escena de transición visual con fundido.
const FADE_SCENE = preload("res://Shared_Assets/Effects/FadeTransition/fade_transition.tscn")

# Contenedor donde se instancian los niveles.
@onready var level_container: Node2D = null

# Instancia del nivel actualmente cargado.
var current_level_instance: Node2D = null
# Ruta del nivel actual.
var current_level_path: String = ""

# Altura máxima del nivel para normalizar z_index.
var current_level_max_y: int = 0

# Configura referencia al contenedor sin inicializar nivel.
func _ready() -> void:
	# Espera un frame para que la escena esté lista.
	await get_tree().process_frame
	var root = get_tree().current_scene
	# Busca CurrentLevelContainer en la raíz de la escena.
	if root.has_node("CurrentLevelContainer"):
		level_container = root.get_node("CurrentLevelContainer")
		print("LevelManager: Contenedor encontrado. Esperando inicialización.")
	else:
		print("LevelManager: No se encontró 'CurrentLevelContainer' en la escena actual.")

# Cambia a otro nivel con fade y posiciona al jugador.
func change_level(new_level_path: String, entrance_name: String) -> void:
	# Verifica que el contenedor exista.
	if not level_container:
		push_error("LevelManager: level_container no disponible")
		return
	print("Cambiando a: ", new_level_path, " entrada: ", entrance_name)

	# Inicia fade out (pantalla negra).
	var fade = FADE_SCENE.instantiate()
	get_tree().root.add_child(fade)
	await fade.fade_out()

	# Elimina todos los hijos del contenedor.
	for child in level_container.get_children():
		child.queue_free()
	# Espera un frame para que se liberen.
	await get_tree().process_frame
	current_level_instance = null

	# Carga la nueva escena de nivel.
	var new_level_scene = load(new_level_path)
	if not new_level_scene:
		push_error("No se pudo cargar: ", new_level_path)
		return

	# Instancia y añade el nuevo nivel.
	current_level_instance = new_level_scene.instantiate()
	level_container.add_child(current_level_instance)
	current_level_path = new_level_path
	_update_level_max_y()

	# Estabiliza un frame.
	await get_tree().process_frame

	# Obtiene datos de spawn del punto de entrada.
	var spawn_data = _get_entrance_spawn_data(entrance_name)
	if spawn_data == null:
		push_error("No se obtuvo datos de entrada: ", entrance_name)
		return

	# Posiciona al jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_data.position
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(spawn_data.direction)
		print("Jugador en ", spawn_data.position, " mirando ", spawn_data.direction)
	else:
		push_warning("No se encontró al jugador")

	# Termina la transición.
	await fade.fade_in()
	print("Cambio completado")

# Busca EntrancePoint por nombre y devuelve posición y dirección.
func _get_entrance_spawn_data(entrance_name: String) -> Variant:
	# Verifica que haya un nivel cargado.
	if not current_level_instance:
		return null

	var entrance_node: Node2D = null

	# Busca por ruta absoluta o dentro de nodo Entrances.
	if current_level_instance.has_node(entrance_name):
		entrance_node = current_level_instance.get_node(entrance_name)
	elif current_level_instance.has_node("Entrances/" + entrance_name):
		entrance_node = current_level_instance.get_node("Entrances/" + entrance_name)
	else:
		# Búsqueda de respaldo entre hijos directos.
		for child in current_level_instance.get_children():
			if child.name == entrance_name:
				entrance_node = child
				break
		if not entrance_node:
			push_error("EntrancePoint '", entrance_name, "' no encontrado")
			return null

	# Lee dirección guardada como metadato.
	var facing = entrance_node.get_meta("facing_direction", Vector2.DOWN)
	return {"position": entrance_node.global_position, "direction": facing}

# Coloca jugador en entrada por defecto (delega en initialize).
func apply_initial_spawn() -> void:
	# Evita ejecución después de inicialización.
	if _initialized:
		push_warning("apply_initial_spawn llamado después de la inicialización. Ignorando.")
		return
	initialize()  # Delegate.

# Busca cualquier EntrancePoint en el nivel actual (emergencia).
func _find_first_entrance() -> EntrancePoint:
	# Busca dentro de nodo "Entrances" primero.
	if current_level_instance.has_node("Entrances"):
		for child in current_level_instance.get_node("Entrances").get_children():
			if child is EntrancePoint:
				return child
	# Busca entre hijos directos del nivel.
	for child in current_level_instance.get_children():
		if child is EntrancePoint:
			return child
	return null

# Calcula altura máxima del nivel desde BoundsLayer.
func _update_level_max_y() -> void:
	# Requiere nivel cargado.
	if not current_level_instance:
		return
	var bounds_layer = current_level_instance.get_node_or_null("BoundsLayer")
	if bounds_layer and bounds_layer.tile_set:
		var used_rect = bounds_layer.get_used_rect()
		var tile_size = bounds_layer.tile_set.tile_size
		# Calcula Y máxima (borde inferior).
		var max_y = (used_rect.position.y + used_rect.size.y) * tile_size.y
		current_level_max_y = max_y
		print("Nivel cargado, altura máxima (Y): ", current_level_max_y)
	else:
		# Valor por defecto si no hay BoundsLayer.
		current_level_max_y = 2000
		push_warning("No se pudo calcular altura del nivel, usando valor por defecto 2000")

# Carga nivel directamente sin fade (para restauración de checkpoint).
func load_level_directly(level_path: String, spawn_position: Vector2, facing_direction: Vector2 = Vector2.DOWN) -> void:
	print("=== load_level_directly: nivel=", level_path, " posición destino=", spawn_position)
	# Verifica contenedor.
	if not level_container:
		push_error("LevelManager: level_container no disponible en load_level_directly")
		return
	
	# Elimina todos los hijos del contenedor.
	for child in level_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	current_level_instance = null
	
	# Carga e instancia el nuevo nivel.
	var new_level_scene = load(level_path)
	if not new_level_scene:
		push_error("No se pudo cargar: ", level_path)
		return
	
	current_level_instance = new_level_scene.instantiate()
	level_container.add_child(current_level_instance)
	current_level_path = level_path
	_update_level_max_y()
	
	# Posiciona al jugador directamente.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_position
		print("=== Jugador posicionado en: ", player.global_position)
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(facing_direction)

# Aplica spawn inicial solo si no hay carga en curso.
func _apply_spawn_to_current_level() -> void:
	# Requiere nivel cargado.
	if not current_level_instance:
		return
	
	# Omite si estamos cargando partida.
	if AutosaveManager.is_loading or skip_save_on_spawn:
		print("_apply_spawn_to_current_level: omitido por carga en curso")
		return
	
	# No mover si el jugador ya tiene posición.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.global_position != Vector2.ZERO:
		return
	
	# Busca entrance_inicial.
	var entrance_name = "entrance_inicial"
	var spawn_data = _get_entrance_spawn_data(entrance_name)
	if spawn_data == null:
		# Usa cualquier entrance como respaldo.
		var any_entrance = _find_first_entrance()
		if any_entrance == null:
			push_warning("No se encontró ningún EntrancePoint para spawn inicial")
			return
		spawn_data = {"position": any_entrance.global_position, "direction": any_entrance.get_meta("facing_direction", Vector2.DOWN)}
		print("Usando EntrancePoint por defecto: ", any_entrance.name)
	
	if player:
		# Posiciona al jugador.
		player.global_position = spawn_data.position
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(spawn_data.direction)
		print("Posición inicial: ", spawn_data.position)
		
		# Guarda checkpoint solo si no estamos cargando.
		if not AutosaveManager.is_loading and not skip_save_on_spawn:
			AutosaveManager.save_checkpoint()
	else:
		push_warning("No se encontró al jugador")

# Configura level_container sin aplicar spawn (para carga de partida).
func setup_container() -> void:
	# Evita reconfigurar si ya está asignado.
	if level_container != null:
		return
	await get_tree().process_frame
	var root = get_tree().current_scene
	if root.has_node("CurrentLevelContainer"):
		level_container = root.get_node("CurrentLevelContainer")
		print("LevelManager: Contenedor configurado.")
	else:
		print("LevelManager: No se encontró CurrentLevelContainer.")

# Posición por defecto si no se encuentra entrance_inicial.
func _get_default_spawn_position() -> Vector2:
	return Vector2(224, 152)

# Inicializa LevelManager cargando nivel por defecto o usando existente.
func initialize() -> void:
	# Evita doble inicialización.
	if _initialized:
		print("LevelManager: Ya inicializado. Ignorando nueva llamada.")
		return
	# No hacer nada si ya hay nivel cargado.
	if current_level_instance != null:
		print("LevelManager: Ya hay un nivel cargado. No se inicializa de nuevo.")
		return
	_initialized = true
	
	# Asegura que el contenedor esté configurado.
	await setup_container()
	if level_container == null:
		print("LevelManager: No se pudo configurar el contenedor.")
		return
	
	# Si ya hay un nivel (ej. estático en playground), lo usa.
	if level_container.get_child_count() > 0:
		print("LevelManager: El contenedor ya tiene un nivel. Usando ese.")
		current_level_instance = level_container.get_child(0) as Node2D
		current_level_path = current_level_instance.scene_file_path
		_update_level_max_y()
		_apply_spawn_to_current_level()
		return
	
	# Si no, carga catacombs_01 por defecto.
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
