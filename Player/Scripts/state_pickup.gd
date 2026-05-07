extends State
class_name StatePickup

@export var pickup_duration: float = 0.5

var collectable: CollectableItem = null
var time_left: float = 0.0

func enter() -> void:
	print("StatePickup: ENTER")
	if collectable == null:
		print("StatePickup: collectable es null, volviendo a Idle")
		state_machine.change_state(state_machine.get_node("Idle"))
		return
	
	print("StatePickup: collectable es válido")
	# Asegurar que el jugador no se mueva
	player.velocity = Vector2.ZERO
	
	# Reproducir animación (si existe)
	var anim_name = "pickup_player_desarmado"
	if player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name)
		print("Reproduciendo animación: ", anim_name)
	else:
		print("Animación no encontrada: ", anim_name, ", solo pausa")
	
	time_left = pickup_duration
	print("StatePickup: tiempo restante = ", time_left)

func process(delta: float) -> State:
	# Mantener velocidad en cero mientras dure el estado (por si el input intenta modificarla)
	player.velocity = Vector2.ZERO
	
	time_left -= delta
	print("StatePickup: process, time_left = ", time_left)
	if time_left <= 0.0:
		print("StatePickup: tiempo completado, recolectando")
		if collectable:
			collectable.collect()
			collectable = null
		state_machine.change_state(state_machine.get_node("Idle"))
	return null

func exit() -> void:
	print("StatePickup: EXIT")
	if player.animation_player.current_animation == "pickup_player_desarmado":
		player.animation_player.stop()
