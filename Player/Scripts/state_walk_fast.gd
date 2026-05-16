extends State
class_name StateWalkFast

@export var move_speed: float = 110.0        # Velocidad al correr
@export var animation_speed: float = 1.3    # Velocidad de la animación de caminar

@onready var idle: State = $"../Idle"       # Referencia al estado Idle
@onready var walk: State = $"../Walk"       # Referencia al estado Walk

# Al entrar, actualiza texturas de equipamiento y reproduce animación walk acelerada
func enter() -> void:
	player._update_weapon_visual("Walk")
	player._update_armor_visual("Walk")
	var dir = player.get_anim_direction()
	var anim_name = "walk_" + dir + "_player_desarmado"
	if player.animation_player.has_animation(anim_name):
		player.animation_player.play(anim_name, -1, animation_speed)
	else:
		player.update_animation("walk")

# No requiere limpieza específica
func exit() -> void:
	pass

# Evalúa transiciones: sin dirección -> Idle; sin sprint -> Walk
func process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	if not Input.is_action_pressed("sprint"):
		return walk
	var dir = player.get_anim_direction()
	var anim_name = "walk_" + dir + "_player_desarmado"
	if player.animation_player.current_animation != anim_name:
		if player.animation_player.has_animation(anim_name):
			player.animation_player.play(anim_name, -1, animation_speed)
	return null

# Aplica velocidad de movimiento acelerada
func physics_process(_delta: float) -> State:
	player.velocity = player.direction * move_speed
	return null

# No maneja entrada específica
func handle_input(_event: InputEvent) -> State:
	return null
