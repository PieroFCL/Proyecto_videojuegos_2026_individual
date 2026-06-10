class_name StatsPanel extends Panel

@onready var hp_value: Label = $HPValue
# Etiqueta que muestra la vida actual y máxima del jugador.
@onready var attack_value: Label = $AttackValue
# Etiqueta que muestra el valor de ataque del jugador.
@onready var defense_value: Label = $DefenseValue
# Etiqueta que muestra el valor de defensa del jugador.
@onready var speed_value: Label = $SpeedValue
# Etiqueta que muestra el valor de velocidad del jugador.

func _ready() -> void:
	# Conecta señal de cambio de estadísticas para actualizar.
	PlayerStats.stats_changed.connect(_update_display)
	# Conecta señal de cambio de vida para actualizar solo etiqueta de HP.
	PlayerStats.health_changed.connect(_update_hp_only)
	# Realiza actualización inicial de todos los valores al cargar el panel.
	_update_display()

func _update_display() -> void:
	# Obtiene un diccionario con todas estadísticas actuales de jugador.
	var stats = PlayerStats.get_stats_dictionary()
	# Actualiza etiqueta de ataque con el valor actual.
	attack_value.text = str(stats["attack"])
	# Actualiza etiqueta de defensa con el valor actual.
	defense_value.text = str(stats["defense"])
	# Actualiza etiqueta de velocidad con el valor actual.
	speed_value.text = str(stats["speed"])
	# Llama a función que actualiza solo vida para mantener sincronización.
	_update_hp_only()

func _update_hp_only(_new_hp = 0, _max_hp = 0) -> void:
	# Obtiene las estadísticas actuales.
	var stats = PlayerStats.get_stats_dictionary()
	# Formatea el texto de vida.
	hp_value.text = str(stats["hp"]) + " / " + str(stats["max_hp"])
