extends ItemResource
class_name WeaponItem

# Bono de ataque que otorga el arma cuando está equipada.
@export var attack_bonus: int = 0

# Lista de habilidades (SkillResource) que el arma proporciona al jugador.
@export var skills: Array[SkillResource] = []

# Textura para la animación Idle en el mundo.
@export var idle_texture: Texture2D

# Textura para la animación Walk en el mundo (misma disposición que el cuerpo).
@export var walk_texture: Texture2D

# Textura para la animación Pickup (recolección) en el mundo, con Vframes = 1.
@export var pickup_texture: Texture2D

# Textura que se mostrará en la pantalla de combate.
@export var combat_texture: Texture2D

# Número de columnas de la hoja de sprites de combate.
@export var combat_hframes: int = 3

# Número de filas de la hoja de sprites de combate.
@export var combat_vframes: int = 1

# Escala del sprite de combate para ajustar su tamaño en la interfaz.
@export var combat_scale: Vector2 = Vector2.ONE

# Devuelve la descripción textual del arma para la UI del inventario.
func get_description() -> String:
	# Si existe texto flavor_text; si no, se devuelve un texto genérico.
	if not flavor_text.is_empty():
		return flavor_text
	return "Un arma común."

# Devuelve el bono de ataque que el arma otorga al jugador.
func get_attack_bonus() -> int:
	return attack_bonus

# Retorna la textura de animación correspondiente al estado del jugador.
func get_texture_by_state(state_name: String) -> Texture2D:
	match state_name:
		"Idle":
			return idle_texture
		"Walk":
			return walk_texture
		"Pickup":
			return pickup_texture
	return null

# Devuelve el array de habilidades que el arma desbloquea.
func get_skills() -> Array[SkillResource]:
	return skills
