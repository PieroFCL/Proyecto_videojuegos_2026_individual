extends Node

# Referencia al enemigo que inició el combate
var current_enemy: Enemy = null
# Referencia a la instancia de la escena de combate
var combat_scene_instance: CanvasLayer = null

# Señal que se emite cuando el combate termina (para que el enemigo pueda resetearse)
signal combat_finished(victory: bool)

func start_combat(enemy: Enemy) -> void:
	# Evitar iniciar múltiples combates si ya hay uno activo
	if combat_scene_instance != null:
		print("Ya hay un combate en curso, ignorando...")
		return

	current_enemy = enemy

	# Instanciar la escena de combate (asumimos que está en la ruta correcta)
	combat_scene_instance = preload("res://Combat/combat_scene.tscn").instantiate()
	# Añadirla al árbol (por encima de todo, ya que es CanvasLayer)
	get_tree().root.add_child(combat_scene_instance)

	# Desactivar acciones del jugador ANTES de pausar
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(false)

	# Pausar el juego (detiene movimiento del jugador y demás)
	get_tree().paused = true

	# Inicializar la escena de combate con los datos del enemigo y del jugador
	combat_scene_instance.initialize_combat(current_enemy)

func end_combat(victory: bool) -> void:
	# Emitir señal para que el enemigo pueda resetear su flag in_combat (si no fue destruido)
	combat_finished.emit(victory)
	
	# Eliminar la escena de combate
	if combat_scene_instance:
		combat_scene_instance.queue_free()
		combat_scene_instance = null
	
	# Reanudar el juego
	get_tree().paused = false
	
	# Reactivar acciones del jugador
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(true)
	
	# Si el combate fue una victoria, eliminar al enemigo del mundo
	if victory and current_enemy:
		current_enemy.queue_free()
	
	current_enemy = null
