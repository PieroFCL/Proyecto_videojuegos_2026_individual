extends ItemResource
# Recurso para objetos consumibles (pociones, buffs temporales).
class_name ConsumableItem

# Cantidad de vida que restaura (cero si no cura).
@export var hp_restore: int = 0
# Estadística afectada: "attack", "defense", "speed" o vacío.
@export var effect_stat: String = ""
# Valor del efecto (positivo para buff).
@export var effect_value: int = 0
# Duración del efecto en turnos (1 para pociones).
@export var effect_duration: int = 1

# Devuelve descripción para la UI del inventario.
func get_description() -> String:
	# Usa texto narrativo si existe, si no, texto genérico.
	if not flavor_text.is_empty():
		return flavor_text
	return "Un objeto común."

# Retorna la cantidad de vida que restaura.
func get_hp_restore() -> int:
	return hp_restore
