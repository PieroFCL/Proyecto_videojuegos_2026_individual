extends State
class_name StatePickup

# Duración de la animación de recogida
@export var pickup_duration: float = 0.5

# Objeto que se está recolectando
var collectable: CollectableItem = null

# Tiempo restante para completar la animación
var time_left: float = 0.0

# Al entrar, actualiza sprites, bloquea movimiento y reproduce animación
func enter() -> void:
	player._update_weapon_visual("Pickup")
	player._update_armor_visual("Pickup")
	print("Pickup: enter")
	if collectable == null:
		print("Pickup: sin objeto, volviendo a Idle")
		state_machine.change_state(state_machine.get_node("Idle"))
		return
	
	print("Pickup: objeto válido")
	player.velocity = Vector2.ZERO
	
	var anim_name = "pickup_player_desarmado"
	if player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name)
		print("Pickup: animación")
	else:
		print("Pickup: sin animación, solo pausa")
	
	time_left = pickup_duration
	print("Pickup: tiempo ", time_left)

# Durante el estado, mantiene inmovilidad, cuenta tiempo y recolecta al final
func process(delta: float) -> State:
	player.velocity = Vector2.ZERO
	time_left -= delta
	if time_left <= 0.0:
		print("Pickup: recolectando")
		if collectable:
			collectable.collect()
			collectable = null
		state_machine.change_state(state_machine.get_node("Idle"))
	return null

# Al salir, detiene la animación si estaba sonando
func exit() -> void:
	print("Pickup: exit")
	if player.animation_player.current_animation == "pickup_player_desarmado":
		player.animation_player.stop()
