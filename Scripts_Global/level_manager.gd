extends Node

## Gestiona la carga y descarga de niveles dentro del CurrentLevelContainer.
## Ahora trabaja con nombres de puntos de entrada (EntrancePoint) en lugar de posiciones absolutas.

# ---- NUEVO FADE: Preload de la escena de transición visual ----
const FADE_SCENE = preload("res://Shared_Assets/Effects/FadeTransition/fade_transition.tscn")
# ----------------------------------------------------------------

# Referencia al contenedor donde se instancian los niveles.
@onready var level_container: Node2D = null

# Nivel actualmente cargado.
var current_level_instance: Node2D = null
var current_level_path: String = ""


func _ready() -> void:
	await get_tree().process_frame
	var root = get_tree().current_scene
	if root.has_node("CurrentLevelContainer"):
		level_container = root.get_node("CurrentLevelContainer")
		await get_tree().process_frame
		apply_initial_spawn()
	else:
		push_error("LevelManager: No se encontró 'CurrentLevelContainer' en la escena principal.")

## Cambia al nivel especificado, haciendo que el jugador aparezca en el EntrancePoint indicado.
## @param new_level_path: Ruta de la escena del nivel (ej. "res://Catacombs/catacombs_02.tscn").
## @param entrance_name: Nombre del nodo EntrancePoint (o ruta relativa dentro del nivel) donde aparecerá.
func change_level(new_level_path: String, entrance_name: String) -> void:
	if not level_container:
		push_error("LevelManager: level_container no disponible.")
		return

	print("LevelManager: Cambiando a nivel: ", new_level_path, " entrada: ", entrance_name)

	# ---- NUEVO FADE: Instanciar el efecto y esperar a que se oscurezca completamente ----
	var fade = FADE_SCENE.instantiate()
	get_tree().root.add_child(fade)
	await fade.fade_out()
	# ----------------------------------------------------------------------------------

	# 1. Eliminar el nivel actual si existe.
	if current_level_instance:
		current_level_instance.queue_free()
		await current_level_instance.tree_exited

	# 2. Cargar e instanciar el nuevo nivel.
	var new_level_scene = load(new_level_path)
	if not new_level_scene:
		push_error("LevelManager: No se pudo cargar la escena: ", new_level_path)
		return

	current_level_instance = new_level_scene.instantiate()
	level_container.add_child(current_level_instance)
	current_level_path = new_level_path

	# 3. Esperar un frame para que el nivel se estabilice.
	await get_tree().process_frame

	# 4. Buscar el punto de entrada y posicionar al jugador.
	var spawn_data = _get_entrance_spawn_data(entrance_name)
	if spawn_data == null:
		push_error("LevelManager: No se pudo obtener datos de entrada: ", entrance_name)
		return

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_data.position
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(spawn_data.direction)
		print("LevelManager: Jugador reposicionado en ", spawn_data.position, " mirando ", spawn_data.direction)
	else:
		push_warning("LevelManager: No se encontró al jugador.")

	# ---- NUEVO FADE: Ahora aclarar la pantalla (fade_in elimina la instancia al terminar) ----
	await fade.fade_in()
	# -----------------------------------------------------------------------------------------

	# Los límites de cámara se actualizarán automáticamente (bounds_provider).
	print("LevelManager: Cambio completado.")

## Busca dentro del nivel actual un EntrancePoint con el nombre dado y devuelve su posición y dirección.
## Soporta dos formatos:
## - Nombre directo: "entrance_cave" (busca en /Entrances/ o directamente en la raíz)
## - Ruta: "Entrances/entrance_north"
func _get_entrance_spawn_data(entrance_name: String) -> Variant:
	if not current_level_instance:
		return null

	var entrance_node: Node2D = null

	# Intentar primero con ruta absoluta desde la raíz del nivel.
	if current_level_instance.has_node(entrance_name):
		entrance_node = current_level_instance.get_node(entrance_name)
	else:
		# Buscar dentro de un posible nodo "Entrances" (organización recomendada)
		if current_level_instance.has_node("Entrances/" + entrance_name):
			entrance_node = current_level_instance.get_node("Entrances/" + entrance_name)
		else:
			# Fallback: buscar cualquier hijo con ese nombre (no recomendado pero útil)
			for child in current_level_instance.get_children():
				if child.name == entrance_name:
					entrance_node = child
					break
			if not entrance_node:
				push_error("LevelManager: EntrancePoint '", entrance_name, "' no encontrado en el nivel.")
				return null

	# Comprobar que realmente es un EntrancePoint (tiene la metadata)
	var facing = entrance_node.get_meta("facing_direction", Vector2.DOWN)
	return {"position": entrance_node.global_position, "direction": facing}

## Coloca al jugador en el punto de entrada por defecto del nivel inicial.
## Busca un EntrancePoint llamado "entrance_inicial", o el primero que encuentre.
func apply_initial_spawn() -> void:
	if not level_container or level_container.get_child_count() == 0:
		push_warning("LevelManager: No hay nivel cargado para aplicar spawn inicial.")
		return

	current_level_instance = level_container.get_child(0) as Node2D
	current_level_path = current_level_instance.scene_file_path

	# Buscar el entrada por defecto
	var entrance_name = "entrance_inicial"
	var spawn_data = _get_entrance_spawn_data(entrance_name)
	if spawn_data == null:
		# Si no existe entrance_inicial, tomar el primer EntrancePoint que encuentre
		var any_entrance = _find_first_entrance()
		if any_entrance == null:
			push_warning("LevelManager: No se encontró ningún EntrancePoint en el nivel inicial.")
			return
		spawn_data = {"position": any_entrance.global_position, "direction": any_entrance.get_meta("facing_direction", Vector2.DOWN)}
		print("LevelManager: Usando EntrancePoint por defecto: ", any_entrance.name)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn_data.position
		if player.has_method("set_facing_direction"):
			player.set_facing_direction(spawn_data.direction)
		print("LevelManager: Posición inicial establecida en ", spawn_data.position)
	else:
		push_warning("LevelManager: No se encontró al jugador.")

## Auxiliar para el spawn inicial: busca cualquier nodo de tipo EntrancePoint dentro del nivel actual.
func _find_first_entrance() -> EntrancePoint:
	# Buscar en /Entrances primero
	if current_level_instance.has_node("Entrances"):
		for child in current_level_instance.get_node("Entrances").get_children():
			if child is EntrancePoint:
				return child
	# Buscar en la raíz
	for child in current_level_instance.get_children():
		if child is EntrancePoint:
			return child
	return null
