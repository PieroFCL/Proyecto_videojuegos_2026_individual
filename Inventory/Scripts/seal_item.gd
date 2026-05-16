extends ItemResource
class_name SealItem

# Lista de habilidades que otorga este sello (1 o 2)
@export var skills: Array[SkillResource] = []

# Texturas para el mundo (opcional, se puede usar icon genérico)
@export var world_texture: Texture2D = null

func get_description() -> String:
	if not flavor_text.is_empty():
		return flavor_text
	return "Un pergamino con un sello mágico."

func get_skills() -> Array[SkillResource]:
	return skills
