extends State
class_name StateWalkFast

# Velocidad de movimiento del jugador mientras corre.
@export var move_speed: float = 110.0
# Multiplicador de velocidad para la animación de caminar al correr.
@export var animation_speed: float = 1.3

# Referencia al estado Idle para transicionar cuando no hay dirección.
@onready var idle: State = $"../Idle"
# Referencia al estado Walk para transicionar cuando se suelta sprint.
@onready var walk: State = $"../Walk"

# Configura texturas de equipamiento y reproduce animación de caminar fast.
func enter() -> void:
	# Actualiza visualmente el arma y la armadura al estado Walk.
	player._update_weapon_visual("Walk")
	player._update_armor_visual("Walk")
	# Obtiene dirección de animación actual del jugador.
	var dir = player.get_anim_direction()
	# Construye nombre de animación de caminar.
	var anim_name = "walk_" + dir + "_player_desarmado"
	# Si animación existe, reproduce a mayor velocidad.
	if player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name, -1, animation_speed)
	else:
		player.update_animation("walk")

# No realiza ninguna acción al salir del estado.
func exit() -> void:
	pass

# Evalúa las transiciones a otros estados según la entrada y la dirección.
func process(_delta: float) -> State:
	# Si no hay dirección, vuelve al estado Idle.
	if player.direction == Vector2.ZERO:
		return idle
	# Si el jugador no mantiene presionado sprint, vuelve al estado Walk.
	if not Input.is_action_pressed("sprint"):
		return walk
	# Actualiza la animación por si la dirección ha cambiado mientras se corre.
	var dir = player.get_anim_direction()
	var anim_name = "walk_" + dir + "_player_desarmado"
	# Solo cambia la animación si no es la que ya se está reproduciendo.
	if player.animation_player.current_animation != anim_name:
		if player.animation_player.has_animation(anim_name):
			player.animation_player.play(anim_name, -1, animation_speed)
	return null

# Aplica la velocidad de movimiento acelerada al jugador.
func physics_process(_delta: float) -> State:
	player.velocity = player.direction * move_speed
	return null

# No procesa eventos de entrada específicos en este estado.
func handle_input(_event: InputEvent) -> State:
	return null
