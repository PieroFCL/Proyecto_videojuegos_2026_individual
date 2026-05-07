extends ItemResource
class_name ConsumableItem

@export var hp_restore: int = 0   # cantidad de vida que restaura

func get_description() -> String:
	if hp_restore > 0:
		return "Restaura %d HP" % hp_restore
	return ""

func get_hp_restore() -> int:
	return hp_restore
