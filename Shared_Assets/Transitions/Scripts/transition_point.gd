extends Area2D
class_name TransitionPoint

# Ruta de la escena destino
@export var target_level: String = ""
# Nombre del EntrancePoint dentro del nivel destino
@export var target_entrance: String = "entrance_inicial"

# Cooldown global (en segundos) entre transiciones
@export var global_cooldown: float = 1.5

# Variable estática compartida por todos los TransitionPoint
static var last_transition_time: float = 0.0

# Variable local para evitar múltiples activaciones del mismo nodo
var can_transition: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_mask = 4  # Detecta al jugador (capa 3 -> valor 4)
	print("TransitionPoint: ", name, " -> ", target_level, " : ", target_entrance)

func _on_body_entered(body: Node2D) -> void:
	if not can_transition:
		return
	if not (body.is_in_group("player") or body.name == "player"):
		return
	
	# Comprobar cooldown global
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_transition_time < global_cooldown:
		print("Transición bloqueada por cooldown global")
		return
	
	# Activar transición
	can_transition = false
	last_transition_time = current_time
	_teleport()
	
	# Reactivar el mismo nodo después de un breve tiempo (para que no se quede bloqueado)
	await get_tree().create_timer(0.5).timeout
	can_transition = true

func _teleport() -> void:
	if target_level.is_empty():
		push_error("TransitionPoint: target_level no especificado.")
		return
	if target_entrance.is_empty():
		push_error("TransitionPoint: target_entrance no especificado.")
		return
	LevelManager.change_level(target_level, target_entrance)
