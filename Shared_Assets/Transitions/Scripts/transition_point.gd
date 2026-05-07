extends Area2D
class_name TransitionPoint

## Ruta de la escena a la que teletransporta (ej. "res://Catacombs/catacombs_02.tscn")
@export var target_level: String = ""

## Nombre del EntrancePoint dentro del nivel destino donde aparecerá el jugador.
## Ejemplo: "entrance_from_catacombs01"
@export var target_entrance: String = "entrance_inicial"

## (Opcional) Pequeño retraso para evitar múltiples activaciones
var can_transition: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Asegurar que detecte al jugador (capa 3 -> valor 4)
	collision_mask = 4
	print("TransitionPoint lista: ", name, " -> ", target_level, " : ", target_entrance)

func _on_body_entered(body: Node2D) -> void:
	if not can_transition:
		return
	if body.is_in_group("player") or body.name == "player":
		can_transition = false
		_teleport()
		# Reactivar después de un tiempo prudencial (la transición puede durar unos frames)
		await get_tree().create_timer(0.5).timeout
		can_transition = true

func _teleport() -> void:
	if target_level.is_empty():
		push_error("TransitionPoint: target_level no especificado.")
		return
	if target_entrance.is_empty():
		push_error("TransitionPoint: target_entrance no especificado.")
		return

	# Ya no cargamos la escena aquí; se lo dejamos al LevelManager.
	LevelManager.change_level(target_level, target_entrance)
