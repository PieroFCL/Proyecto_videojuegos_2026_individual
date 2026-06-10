extends Node
# Gestor central de combate: inicia y finaliza combates.

# Enemigo que participa en el combate actual.
var current_enemy: Enemy = null
# Instancia activa de la escena de combate.
var combat_scene_instance: CanvasLayer = null

# Señal emitida al terminar combate (victoria o derrota).
signal combat_finished(victory: bool)

# Inicia un nuevo combate contra un enemigo.
func start_combat(enemy: Enemy) -> void:
	# Evita múltiples combates simultáneos.
	if combat_scene_instance != null:
		print("Ya hay un combate en curso, ignorando...")
		return

	# Cierra y desactiva inventario para evitar interferencias.
	var player_menu = get_tree().root.get_node_or_null("Playground/PlayerMenu")
	if player_menu:
		if player_menu.has_method("close_menu"):
			player_menu.close_menu()
		if player_menu.has_method("close_action_menu"):
			player_menu.close_action_menu()
		# Desactiva entrada del inventario principal.
		player_menu.set_process_input(false)
		player_menu.set_process_unhandled_input(false)
		# Desactiva también el panel de documentos.
		var docs_panel = player_menu.get_node_or_null("DocumentsPanel")
		if docs_panel:
			docs_panel.set_process_input(false)
			docs_panel.set_process_unhandled_input(false)

	current_enemy = enemy

	# Instancia la escena de combate.
	combat_scene_instance = preload("res://Combat/combat_scene.tscn").instantiate()
	get_tree().root.add_child(combat_scene_instance)

	# Bloquea las acciones del jugador antes de pausar.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(false)

	# Pausa el juego.
	get_tree().paused = true

	# Inicializa la escena de combate.
	combat_scene_instance.initialize_combat(current_enemy)

	# Reproduce música según el tipo de enemigo.
	if enemy.enemy_resource.is_boss:
		AudioManager.play_boss_music()
	else:
		AudioManager.play_combat_music()

# Finaliza el combate, indicando si fue victoria o derrota.
func end_combat(victory: bool) -> void:
	# Notifica al enemigo para que resetee su estado.
	combat_finished.emit(victory)

	# Elimina la escena de combate.
	if combat_scene_instance:
		combat_scene_instance.queue_free()
		combat_scene_instance = null

	# Reanuda el juego.
	get_tree().paused = false

	# Reactiva las acciones del jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_can_act"):
		player.set_can_act(true)

	# Reactiva la entrada del inventario y documentos.
	var player_menu = get_tree().root.get_node_or_null("Playground/PlayerMenu")
	if player_menu:
		player_menu.set_process_input(true)
		player_menu.set_process_unhandled_input(true)
		var docs_panel = player_menu.get_node_or_null("DocumentsPanel")
		if docs_panel:
			docs_panel.set_process_input(true)
			docs_panel.set_process_unhandled_input(true)

	# Elimina al enemigo si hubo victoria; si no, carga checkpoint.
	if victory and current_enemy:
		current_enemy.queue_free()
	elif not victory:
		await AutosaveManager.load_checkpoint()

	current_enemy = null

	# Vuelve a la música ambiente del mundo.
	AudioManager.play_ambient_music()
