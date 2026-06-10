extends Resource
class_name SkillResource

# Identificador único en snake_case.
@export var id: String = ""
# Nombre visible en la interfaz.
@export var name: String = ""
# Descripción corta para mostrar en UI.
@export var description: String = ""
# Tipo: physical, magical, buff o debuff.
@export var type: String = "physical"
# Daño base (0 si no es ofensiva).
@export var damage: int = 0
# Estadística afectada: attack, defense o speed.
@export var effect_stat: String = ""
# Valor del efecto (positivo para buff, negativo debuff).
@export var effect_value: int = 0
# Si es permanente (true) o temporal (false).
@export var permanent: bool = true
# Número máximo de acumulaciones (si permanent = true).
@export var max_stacks: int = 2
# Textura del icono (opcional).
@export var icon: Texture2D = null

# Duración en turnos si no es permanente.
@export var effect_duration: int = 0

# Devuelve texto formateado para mostrar en submenú de habilidades.
func get_formatted_text() -> String:
	var line1 = name
	var line2 = ""
	if damage > 0:
		line2 = "Daño Base: %d" % damage
	elif effect_value != 0:
		if effect_value > 0:
			line2 = "%s +%d" % [effect_stat.capitalize(), effect_value]
		else:
			line2 = "%s %d" % [effect_stat.capitalize(), effect_value]
	else:
		line2 = "Efecto especial"
	return line1 + "\n" + line2
