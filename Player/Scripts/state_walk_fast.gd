extends State
class_name StateWalkFast

@export var move_speed: float = 110.0       # Velocidad de movimiento
@export var animation_speed: float = 1.3   # Velocidad de reproducción de la animación walk

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"

func enter() -> void:
	# Reproducir animación walk con velocidad acelerada (sin tocar el AnimationPlayer global)
	var dir = player.get_anim_direction()
	var anim_name = "walk_" + dir + "_player_desarmado"
	if player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name, -1, animation_speed)
	else:
		# Fallback
		player.update_animation("walk")

func exit() -> void:
	# No es necesario restaurar nada, porque no se modificó globalmente.
	pass

func process(delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	if not Input.is_action_pressed("sprint"):
		return walk
	# Actualizar la dirección de la animación si el jugador gira
	var dir = player.get_anim_direction()
	var anim_name = "walk_" + dir + "_player_desarmado"
	if player.animation_player.current_animation != anim_name:
		if player.animation_player.has_animation(anim_name):
			player.animation_player.play(anim_name, -1, animation_speed)
	return null

func physics_process(delta: float) -> State:
	player.velocity = player.direction * move_speed
	return null

func handle_input(event: InputEvent) -> State:
	return null
