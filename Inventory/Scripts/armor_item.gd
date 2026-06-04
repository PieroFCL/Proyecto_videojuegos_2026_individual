extends ItemResource
class_name ArmorItem

@export var defense_bonus: int = 0     # Defensa adicional al equipar

@export var idle_texture: Texture2D    # Sprite para estado Idle (13x4)
@export var walk_texture: Texture2D    # Sprite para estado Walk (13x4)
@export var pickup_texture: Texture2D  # Sprite para estado Pickup (Vframes=1)

# Propiedades para Combate
@export var combat_texture: Texture2D
@export var combat_hframes: int = 1
@export var combat_vframes: int = 1
@export var combat_scale: Vector2 = Vector2.ONE

# Descripción para la UI del inventario
func get_description() -> String:
	if not flavor_text.is_empty():
		return flavor_text
	return "Un armadura común."

# Devuelve el bono de defensa (usado por PlayerStats)
func get_defense_bonus() -> int:
	return defense_bonus

# Retorna la textura según el estado del jugador
func get_texture_by_state(state_name: String) -> Texture2D:
	match state_name:
		"Idle":   return idle_texture
		"Walk":   return walk_texture
		"Pickup": return pickup_texture
	return null
