extends Node2D

# Precarga la escena de transición con fundido.
const FADE_SCENE = preload("res://Shared_Assets/Effects/FadeTransition/fade_transition.tscn")

# Configura el mundo al iniciar la escena.
func _ready():
	# Oculta al jugador mientras se aplica el fade.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.visible = false

	# Asegura que LevelManager tenga referencia al contenedor.
	await LevelManager.setup_container()
	
	# Si hay una partida pendiente, la carga.
	if AutosaveManager.pending_load_slot != -1:
		LevelManager.skip_save_on_spawn = true
		var slot = AutosaveManager.pending_load_slot
		AutosaveManager.pending_load_slot = -1
		await AutosaveManager.load_game(slot)
		LevelManager.skip_save_on_spawn = false
	else:
		# Nueva partida: inicializa nivel y muestra fade.
		LevelManager.initialize()
		var fade = FADE_SCENE.instantiate()
		var color_rect = fade.get_node("ColorRect")
		color_rect.modulate = Color(1,1,1)
		get_tree().root.add_child(fade)
		
		# Muestra al jugador tras completar la transición.
		if player:
			player.visible = true

		await get_tree().process_frame
		await fade.fade_in()
		fade.queue_free()
		
	# Reproduce música de ambiente del mundo.
	AudioManager.play_ambient_music()
