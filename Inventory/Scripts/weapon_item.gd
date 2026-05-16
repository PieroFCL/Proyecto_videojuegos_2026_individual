extends ItemResource
class_name WeaponItem

# Bono de ataque que otorga el arma
@export var attack_bonus: int = 0

# Lista de habilidades que otorga el arma (1 o 2)
@export var skills: Array[SkillResource] = []

# Textura para animación Idle (debe coincidir con disposición del cuerpo)
@export var idle_texture: Texture2D

# Textura para animación Walk (misma disposición que el cuerpo)
@export var walk_texture: Texture2D

# Textura para animación Pickup (debe tener Vframes = 1)
@export var pickup_texture: Texture2D

# Descripción del arma para la UI del inventario
func get_description() -> String:
	if not flavor_text.is_empty():
		return flavor_text
	return "Un arma común."

# Devuelve el bono de ataque (usado por PlayerStats)
func get_attack_bonus() -> int:
	return attack_bonus

# Retorna la textura según el estado actual del jugador (Idle, Walk o Pickup)
func get_texture_by_state(state_name: String) -> Texture2D:
	match state_name:
		"Idle":
			return idle_texture
		"Walk":
			return walk_texture
		"Pickup":
			return pickup_texture
	return null

# Retorna el ID de la habilidad que desbloquea esta arma (si tiene)
func get_skills() -> Array[SkillResource]:
	return skills
