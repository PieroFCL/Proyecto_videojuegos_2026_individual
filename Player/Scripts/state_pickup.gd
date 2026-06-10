extends State
class_name StatePickup

# Duración de animación de recogida.
@export var pickup_duration: float = 0.5

# Referencia objeto recolectable que jugador está recogiendo actualmente.
var collectable: CollectableItem = null

# Tiempo restante de animación de recogida, se decrementa en process().
var time_left: float = 0.0

# Configura estado al entrar, actualiza sprite, bloquea mov. y reproduce anim.
func enter() -> void:
	# Cambia las texturas de arma y armadura al estado Pickup (si existen).
	player._update_weapon_visual("Pickup")
	player._update_armor_visual("Pickup")
	print("Pickup: enter")
	# Si no hay objeto asociado, vuelve inmediatamente a Idle.
	if collectable == null:
		print("Pickup: sin objeto, volviendo a Idle")
		state_machine.change_state(state_machine.get_node("Idle"))
		return
	
	print("Pickup: objeto válido")
	# Detiene cualquier movimiento residual del jugador.
	player.velocity = Vector2.ZERO
	
	var anim_name = "pickup_player_desarmado"
	# Si existe la animación de recogida, la reproduce; si no, solo pausa.
	if player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name)
		print("Pickup: animación")
	else:
		print("Pickup: sin animación, solo pausa")
	
	# Inicia la cuenta regresiva.
	time_left = pickup_duration
	print("Pickup: tiempo ", time_left)

# Se ejecuta cada frame mientras el estado está activo.
func process(delta: float) -> State:
	# Mantiene al jugador completamente quieto durante la recogida.
	player.velocity = Vector2.ZERO
	time_left -= delta
	# Cuando el tiempo se acaba, se recolecta el objeto.
	if time_left <= 0.0:
		print("Pickup: recolectando")
		# Recolecta el objeto, lo añade al inventario y lo elimina del mapa.
		if collectable:
			collectable.collect()
			collectable = null
		# Transiciona de vuelta al estado Idle.
		state_machine.change_state(state_machine.get_node("Idle"))
	return null

# Se ejecuta al salir del estado.
func exit() -> void:
	print("Pickup: exit")
	# Detiene la animación de recogida si aún se está reproduciendo.
	if player.animation_player.current_animation == "pickup_player_desarmado":
		player.animation_player.stop()
