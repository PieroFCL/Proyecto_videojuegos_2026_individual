extends ItemResource
class_name SealItem

# Habilidades que este sello otorga al jugador.
@export var skills: Array[SkillResource] = []

# Textura opcional para mostrar en el mundo.
@export var world_texture: Texture2D = null

# Devuelve descripción para la UI del inventario.
func get_description() -> String:
	if not flavor_text.is_empty():
		return flavor_text
	return "Un pergamino con un sello mágico."

# Retorna la lista de habilidades del sello.
func get_skills() -> Array[SkillResource]:
	return skills
