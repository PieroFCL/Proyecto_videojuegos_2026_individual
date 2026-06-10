extends Node

# Señal emitida al recoger cualquier objeto.
signal item_collected(item_id: String)

# Señal para abrir o cerrar el menú.
signal menu_toggled(visible: bool)

# Señal para cambios de equipamiento.
signal equipment_changed(slot: String, item_id: String)

# Conecta señales a una función vacía para evitar warnings.
func _ready():
	item_collected.connect(_dummy)
	menu_toggled.connect(_dummy)
	equipment_changed.connect(_dummy)

# Función dummy que recibe argumentos opcionales.
func _dummy(_arg1 = null, _arg2 = null):
	pass
