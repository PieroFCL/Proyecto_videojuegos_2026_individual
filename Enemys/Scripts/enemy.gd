extends CharacterBody2D
class_name Enemy

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var last_direction: Vector2 = Vector2.DOWN

# Recurso y Estado de Combate
@export var enemy_resource: EnemyResource = null
var in_combat: bool = false

# Movimiento
@export var waypoints: Array[Vector2] = []
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var waypoint_reach_distance: float = 10.0
@export var waypoint_pause_time: float = 1.0

@onready var hitbox: Area2D = $Hitbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

# Añadir variables exportadas (junto a las otras)
@export var is_unique: bool = false          # Si es true, no reaparece al derrotarlo
@export var unique_id: String = ""           # Identificador (obligatorio si is_unique = true)

var is_paused: bool = false
enum EnemyState { PATROL, CHASE }
var current_state: EnemyState = EnemyState.PATROL
var current_waypoint_index: int = 0
var player_ref: Node2D = null

func _ready() -> void:
	# PERSISTENCIA: si es único y ya fue derrotado, desaparecer 
	if is_unique and not unique_id.is_empty() and WorldStateManager.is_enemy_defeated(unique_id):
		queue_free()
		return
	
	$PauseTimer.timeout.connect(_on_pause_timeout)
	if enemy_resource and enemy_resource.sprite_texture:
		sprite.texture = enemy_resource.sprite_texture
	else:
		print("Advertencia: enemigo sin textura asignada")
	
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	CombatManager.combat_finished.connect(_on_combat_finished)
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	else:
		print("Advertencia: DetectionArea no encontrada")

func _physics_process(_delta: float) -> void:
	if in_combat or get_tree().paused:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return
	
	match current_state:
		EnemyState.PATROL:
			if waypoints.is_empty():
				velocity = Vector2.ZERO
			else:
				if is_paused:
					velocity = Vector2.ZERO
				else:
					var target = waypoints[current_waypoint_index]
					var direction = (target - global_position).normalized()
					velocity = direction * patrol_speed
					if global_position.distance_to(target) < waypoint_reach_distance:
						is_paused = true
						velocity = Vector2.ZERO
						$PauseTimer.start(waypoint_pause_time)
						_update_animation()
		EnemyState.CHASE:
			if player_ref:
				var direction = (player_ref.global_position - global_position).normalized()
				velocity = direction * chase_speed
			else:
				current_state = EnemyState.PATROL
				velocity = Vector2.ZERO
	
	move_and_slide()
	_update_animation()

func _process(_delta: float) -> void:
	z_index = int(global_position.y) + 500

func _update_animation() -> void:
	if not enemy_resource or enemy_resource.animation_prefix.is_empty():
		return
	
	var prefix = enemy_resource.animation_prefix
	var dir: Vector2 = Vector2.ZERO
	
	# Determinar si se está moviendo
	var is_moving = velocity.length() > 10.0
	if is_moving:
		dir = velocity.normalized()
		last_direction = dir
	else:
		dir = last_direction
	
	# Calcular sufijo de dirección (down, up, left, right)
	var anim_suffix = "down"
	if abs(dir.x) > abs(dir.y):
		anim_suffix = "right" if dir.x > 0 else "left"
	elif dir.y != 0:
		anim_suffix = "down" if dir.y > 0 else "up"
	
	# Determinar tipo de animación (walk o idle)
	var anim_type = "walk" if is_moving else "idle"
	var anim_name = "%s_%s_%s" % [anim_type, anim_suffix, prefix]
	
	# Si es walk y no existe, intentar con idle (fallback)
	if anim_type == "walk" and not animation_player.has_animation(anim_name):
		anim_name = "idle_%s_%s" % [anim_suffix, prefix]
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	# else: no hay animación, el sprite se queda con la textura estática

func _on_pause_timeout() -> void:
	is_paused = false
	current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
	_update_animation()

func _on_detection_body_entered(body: Node2D) -> void:
	if in_combat: return
	if body.is_in_group("player"):
		player_ref = body
		current_state = EnemyState.CHASE
		is_paused = false          # <-- IMPORTANTE: salir de pausa si estaba
		_update_animation()
		print("DEBUG: Enemigo detectó jugador, estado CHASE")

func _on_detection_body_exited(body: Node2D) -> void:
	if in_combat: return
	if body == player_ref:
		player_ref = null
		current_state = EnemyState.PATROL
		is_paused = false          # <-- también aquí
		_update_animation()
		print("DEBUG: Enemigo perdió al jugador, vuelve a PATROL")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if in_combat: return
	if body.is_in_group("player"):
		in_combat = true
		velocity = Vector2.ZERO
		_start_combat()

func _start_combat() -> void:
	CombatManager.start_combat(self)

func _on_combat_finished(victory: bool) -> void:
	print("DEBUG: combat_finished recibido. victory=", victory, " in_combat=", in_combat)
	
	# Solo el enemigo que participó en el combate maneja la victoria
	if victory:
		if in_combat:
			# Registrar derrota si es único
			if is_unique and not unique_id.is_empty():
				WorldStateManager.register_defeated_enemy(unique_id)
			# No llamamos a queue_free() aquí, CombatManager ya lo hará
		return  # Salimos, los demás enemigos no hacen nada
	
	# A partir de aquí, solo se ejecuta cuando NO hay victoria (huida o muerte del jugador)
	# Detener cualquier temporizador de pausa pendiente
	if $PauseTimer.is_stopped() == false:
		$PauseTimer.stop()
	
	# Esperar dos frames para que la pausa del juego se levante y las áreas se actualicen
	await get_tree().process_frame
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	var within = detection_area and detection_area.overlaps_body(player) if player else false
	print("DEBUG: ¿Jugador dentro del área? ", within)
	
	# Resetear estado del enemigo (solo si no murió)
	in_combat = false
	is_paused = false
	
	if within and player:
		player_ref = player
		current_state = EnemyState.CHASE
	else:
		player_ref = null
		current_state = EnemyState.PATROL
	
	_update_animation()
	print("DEBUG: Nuevo estado - current_state=", current_state, " player_ref=", player_ref, " is_paused=", is_paused)
