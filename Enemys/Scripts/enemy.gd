extends CharacterBody2D
# Enemigo que patrulla, persigue y combate por turnos.
class_name Enemy

# Reproductor de animaciones del enemigo.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Última dirección cardinal registrada.
var last_direction: Vector2 = Vector2.DOWN

# Recurso con estadísticas y habilidades del enemigo.
@export var enemy_resource: EnemyResource = null
# Indica si el enemigo está en combate.
var in_combat: bool = false

# Puntos de patrullaje del enemigo.
@export var waypoints: Array[Vector2] = []
# Velocidad de patrullaje normal.
@export var patrol_speed: float = 60.0
# Velocidad de persecución del jugador.
@export var chase_speed: float = 100.0
# Distancia para considerar waypoint alcanzado.
@export var waypoint_reach_distance: float = 10.0
# Tiempo de pausa al llegar a un waypoint.
@export var waypoint_pause_time: float = 1.0

# Área de colisión que daña al jugador.
@onready var hitbox: Area2D = $Hitbox
# Sprite visual del enemigo.
@onready var sprite: Sprite2D = $Sprite2D
# Área de detección del jugador.
@onready var detection_area: Area2D = $DetectionArea

# Indica si el enemigo es único (no reaparece).
@export var is_unique: bool = false
# Identificador único para enemigos especiales.
@export var unique_id: String = ""

# Estado de pausa entre waypoints.
var is_paused: bool = false
# Posibles estados del enemigo.
enum EnemyState { PATROL, CHASE }
# Estado actual del enemigo.
var current_state: EnemyState = EnemyState.PATROL
# Índice del waypoint actual.
var current_waypoint_index: int = 0
# Referencia al jugador detectado.
var player_ref: Node2D = null

# Inicializa el enemigo y configura señales.
func _ready() -> void:
	# Elimina enemigo único ya derrotado.
	if is_unique and not unique_id.is_empty() and WorldStateManager.is_enemy_defeated(unique_id):
		queue_free()
		return
	
	# Conecta señal del temporizador de pausa.
	$PauseTimer.timeout.connect(_on_pause_timeout)
	# Asigna textura si existe.
	if enemy_resource and enemy_resource.sprite_texture:
		sprite.texture = enemy_resource.sprite_texture
	else:
		print("Advertencia: enemigo sin textura asignada")
	
	# Detecta colisión con el jugador.
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	# Escucha fin de combate.
	CombatManager.combat_finished.connect(_on_combat_finished)
	
	# Configura área de detección.
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	else:
		print("Advertencia: DetectionArea no encontrada")

# Controla movimiento y animación del enemigo.
func _physics_process(_delta: float) -> void:
	# Detiene movimiento si está en combate o juego pausado.
	if in_combat or get_tree().paused:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return
	
	# Lógica según estado actual.
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
					# Alcanza waypoint: pausa y pasa al siguiente.
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

# Actualiza profundidad según posición Y.
func _process(_delta: float) -> void:
	z_index = int(global_position.y) + 500

# Actualiza animación según movimiento y dirección.
func _update_animation() -> void:
	# Verifica recurso de animación.
	if not enemy_resource or enemy_resource.animation_prefix.is_empty():
		return
	
	var prefix = enemy_resource.animation_prefix
	var dir: Vector2 = Vector2.ZERO
	
	# Detecta si el enemigo se mueve.
	var is_moving = velocity.length() > 10.0
	if is_moving:
		dir = velocity.normalized()
		last_direction = dir
	else:
		dir = last_direction
	
	# Calcula sufijo según dirección dominante.
	var anim_suffix = "down"
	if abs(dir.x) > abs(dir.y):
		anim_suffix = "right" if dir.x > 0 else "left"
	elif dir.y != 0:
		anim_suffix = "down" if dir.y > 0 else "up"
	
	# Tipo de animación (walk o idle).
	var anim_type = "walk" if is_moving else "idle"
	var anim_name = "%s_%s_%s" % [anim_type, anim_suffix, prefix]
	
	# Fallback a idle si walk no existe.
	if anim_type == "walk" and not animation_player.has_animation(anim_name):
		anim_name = "idle_%s_%s" % [anim_suffix, prefix]
	
	# Reproduce animación si existe.
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

# Termina pausa y avanza al siguiente waypoint.
func _on_pause_timeout() -> void:
	is_paused = false
	current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
	_update_animation()

# Entra al área de detección del jugador.
func _on_detection_body_entered(body: Node2D) -> void:
	if in_combat: return
	if body.is_in_group("player"):
		player_ref = body
		current_state = EnemyState.CHASE
		is_paused = false
		_update_animation()
		print("DEBUG: Enemigo detectó jugador, estado CHASE")

# Sale del área de detección del jugador.
func _on_detection_body_exited(body: Node2D) -> void:
	if in_combat: return
	if body == player_ref:
		player_ref = null
		current_state = EnemyState.PATROL
		is_paused = false
		_update_animation()
		print("DEBUG: Enemigo perdió al jugador, vuelve a PATROL")

# Inicia combate al colisionar con jugador.
func _on_hitbox_body_entered(body: Node2D) -> void:
	if in_combat: return
	if body.is_in_group("player"):
		in_combat = true
		velocity = Vector2.ZERO
		_start_combat()

# Llama al gestor de combate.
func _start_combat() -> void:
	CombatManager.start_combat(self)

# Maneja fin de combate (victoria o derrota).
func _on_combat_finished(victory: bool) -> void:
	print("DEBUG: combat_finished recibido. victory=", victory, " in_combat=", in_combat)
	
	# Solo el enemigo que combatió reacciona a victoria.
	if victory:
		if in_combat:
			if is_unique and not unique_id.is_empty():
				WorldStateManager.register_defeated_enemy(unique_id)
		return  # CombatManager elimina al enemigo victorioso.
	
	# En caso de huida o muerte del jugador, resetea estado.
	if $PauseTimer.is_stopped() == false:
		$PauseTimer.stop()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	var within = detection_area and detection_area.overlaps_body(player) if player else false
	print("DEBUG: ¿Jugador dentro del área? ", within)
	
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
