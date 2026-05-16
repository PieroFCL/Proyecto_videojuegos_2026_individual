extends Area2D
class_name TransitionPoint

# Ruta de la escena destino (ej. "res://Catacombs/catacombs_02.tscn")
@export var target_level: String = ""

# Nombre del EntrancePoint dentro del nivel destino (ej. "entrance_from_catacombs01")
@export var target_entrance: String = "entrance_inicial"

# Evita múltiples activaciones durante la transición
var can_transition: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_mask = 4  # Detecta al jugador (capa 3 -> valor 4)
	print("TransitionPoint: ", name, " -> ", target_level, " : ", target_entrance)

# Detecta colisión con el jugador y activa el teletransporte
func _on_body_entered(body: Node2D) -> void:
	if not can_transition:
		return
	if body.is_in_group("player") or body.name == "player":
		can_transition = false
		_teleport()
		await get_tree().create_timer(0.5).timeout
		can_transition = true

# Valida datos y llama al LevelManager para cambiar de nivel
func _teleport() -> void:
	if target_level.is_empty():
		push_error("TransitionPoint: target_level no especificado.")
		return
	if target_entrance.is_empty():
		push_error("TransitionPoint: target_entrance no especificado.")
		return
	LevelManager.change_level(target_level, target_entrance)
