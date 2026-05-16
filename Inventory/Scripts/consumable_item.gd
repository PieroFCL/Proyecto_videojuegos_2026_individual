extends ItemResource
class_name ConsumableItem

@export var hp_restore: int = 0             # Vida que restaura (0 si no)
@export var effect_stat: String = ""       # "attack", "defense", "speed" (vacío si no aplica)
@export var effect_value: int = 0          # Valor del buff (ej. +10)
@export var effect_duration: int = 1       # Turnos que dura (para pociones será 1)

# Descripción para la UI del inventario
func get_description() -> String:
	if not flavor_text.is_empty():
		return flavor_text
	return "Un objeto común."

# Devuelve la cantidad de vida que restaura (usado por PlayerStats)
func get_hp_restore() -> int:
	return hp_restore
