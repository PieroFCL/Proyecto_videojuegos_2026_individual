extends Node2D

const FADE_SCENE = preload("res://Shared_Assets/Effects/FadeTransition/fade_transition.tscn")

func _ready():
	# Ocultar jugador al inicio (se mostrará después del fade)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.visible = false

	await LevelManager.setup_container()
	
	if AutosaveManager.pending_load_slot != -1:
		LevelManager.skip_save_on_spawn = true
		var slot = AutosaveManager.pending_load_slot
		AutosaveManager.pending_load_slot = -1
		await AutosaveManager.load_game(slot)
		LevelManager.skip_save_on_spawn = false
	else:
		LevelManager.initialize()
		var fade = FADE_SCENE.instantiate()
		var color_rect = fade.get_node("ColorRect")
		color_rect.modulate = Color(1,1,1)
		get_tree().root.add_child(fade)
		
		# Una vez completada la transición, mostrar el jugador
		if player:
			player.visible = true

		await get_tree().process_frame
		await fade.fade_in()
		fade.queue_free()
		
	AudioManager.play_ambient_music()
