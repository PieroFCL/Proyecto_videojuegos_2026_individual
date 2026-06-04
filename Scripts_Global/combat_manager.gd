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

	# Cerrar y desactivar el inventario y sus subcomponentes para que no interfieran
	var player_menu = get_tree().root.get_node_or_null("Playground/PlayerMenu")
	if player_menu:
		if player_menu.has_method("close_menu"):
			player_menu.close_menu()
		if player_menu.has_method("close_action_menu"):
			player_menu.close_action_menu()
		# Desactivar la entrada del inventario principal
		player_menu.set_process_input(false)
		player_menu.set_process_unhandled_input(false)
		# Desactivar también el panel de documentos (hijo del inventario)
		var docs_panel = player_menu.get_node_or_null("DocumentsPanel")
		if docs_panel:
			docs_panel.set_process_input(false)
			docs_panel.set_process_unhandled_input(false)

	current_enemy = enemy

	# Instanciar la escena de combate
	combat_scene_instance = preload("res://Combat/combat_scene.tscn").instantiate()
	get_tree().root.add_child(combat_scene_instance)

	# Desactivar acciones del jugador ANTES de pausar
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(false)

	# Pausar el juego
	get_tree().paused = true

	# Inicializar el combate
	combat_scene_instance.initialize_combat(current_enemy)

	if enemy.enemy_resource.is_boss:
		AudioManager.play_boss_music()
	else:
		AudioManager.play_combat_music()

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

	# Reactivar la entrada del inventario y del panel de documentos
	var player_menu = get_tree().root.get_node_or_null("Playground/PlayerMenu")
	if player_menu:
		player_menu.set_process_input(true)
		player_menu.set_process_unhandled_input(true)
		var docs_panel = player_menu.get_node_or_null("DocumentsPanel")
		if docs_panel:
			docs_panel.set_process_input(true)
			docs_panel.set_process_unhandled_input(true)

	# Si el combate fue una victoria, eliminar al enemigo del mundo
	if victory and current_enemy:
		current_enemy.queue_free()
	elif not victory:
		# Si el jugador murió, cargar último checkpoint
		await AutosaveManager.load_checkpoint()

	current_enemy = null

	AudioManager.play_ambient_music()
