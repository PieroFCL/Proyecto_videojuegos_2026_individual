extends ItemResource
class_name WeaponItem

@export var attack_bonus: int = 0
@export var skill_unlock_id: String = ""  # ID habilidad desbloqueable

func get_description() -> String:
	var text = "Ataque +%d" % attack_bonus
	if not skill_unlock_id.is_empty():
		text += "\nHabilidad desbloqueada: %s" % skill_unlock_id
	return text

func get_attack_bonus() -> int:
	return attack_bonus
