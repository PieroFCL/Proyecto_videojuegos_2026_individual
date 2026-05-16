extends CharacterBody2D
class_name Enemy

@export var enemy_resource: EnemyResource = null
var in_combat: bool = false

@onready var hitbox: Area2D = $Hitbox
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if enemy_resource and enemy_resource.sprite_texture:
		sprite.texture = enemy_resource.sprite_texture
	else:
		print("Advertencia: enemigo sin textura asignada")
	
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Conectar la señal del CombatManager para resetear el combate si termina sin victoria
	CombatManager.combat_finished.connect(_on_combat_finished)

func _process(delta: float) -> void:
	z_index = int(global_position.y) + 500

func _on_hitbox_body_entered(body: Node2D) -> void:
	if in_combat:
		return
	if body.is_in_group("player"):
		in_combat = true
		_start_combat()

func _start_combat() -> void:
	# Llamar al CombatManager en lugar del placeholder
	CombatManager.start_combat(self)

# Se ejecuta cuando el combate termina (por victoria, huida o muerte del jugador)
func _on_combat_finished(victory: bool) -> void:
	# Solo reseteamos si el combate NO fue una victoria (es decir, el enemigo sigue vivo)
	if not victory:
		in_combat = false
	# Si victory == true, el enemigo será eliminado por CombatManager.end_combat(),
	# así que no necesitamos hacer nada aquí.
