extends ItemResource
class_name ArmorItem

@export var defense_bonus: int = 0

func get_description() -> String:
	return "Defensa +%d" % defense_bonus

func get_defense_bonus() -> int:
	return defense_bonus
