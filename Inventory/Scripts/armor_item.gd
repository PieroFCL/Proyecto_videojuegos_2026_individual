extends ItemResource
# Recurso que define una armadura equipable.
class_name ArmorItem

# Bono de defensa que otorga al equiparla.
@export var defense_bonus: int = 0
# Textura para animación Idle en el mundo.
@export var idle_texture: Texture2D
# Textura para animación Walk en el mundo.
@export var walk_texture: Texture2D
# Textura para animación Pickup (recolección) en mundo.
@export var pickup_texture: Texture2D

# Textura para pantalla de combate.
@export var combat_texture: Texture2D
# Columnas de la hoja de sprites de combate.
@export var combat_hframes: int = 1
# Filas de la hoja de sprites de combate.
@export var combat_vframes: int = 1
# Escala del sprite de combate.
@export var combat_scale: Vector2 = Vector2.ONE

# Descripción para la UI del inventario.
func get_description() -> String:
	# Usa flavor_text si existe, si no, texto genérico.
	if not flavor_text.is_empty():
		return flavor_text
	return "Un armadura común."

# Devuelve el bono de defensa para PlayerStats.
func get_defense_bonus() -> int:
	return defense_bonus

# Devuelve textura según el estado del jugador.
func get_texture_by_state(state_name: String) -> Texture2D:
	match state_name:
		"Idle":   return idle_texture
		"Walk":   return walk_texture
		"Pickup": return pickup_texture
	return null
