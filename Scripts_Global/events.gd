extends Node

## Señal emitida al recoger cualquier objeto
signal item_collected(item_id: String)

## Señal para abrir/cerrar menú (pausa)
signal menu_toggled(visible: bool)

## Señal para cambios de equipamiento
signal equipment_changed(slot: String, item_id: String)

func _ready():
	# Conexiones dummy para evitar warnings (no afectan el juego)
	item_collected.connect(_dummy)
	menu_toggled.connect(_dummy)
	equipment_changed.connect(_dummy)

func _dummy(_arg1 = null, _arg2 = null):
	pass
