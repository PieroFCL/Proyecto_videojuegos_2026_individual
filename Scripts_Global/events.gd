extends Node

## Señal emitida al recoger cualquier objeto
signal item_collected(item_id: String)

## Señal para abrir/cerrar menú (pausa)
signal menu_toggled(visible: bool)

## Señal para cambios de equipamiento
signal equipment_changed(slot: String, item_id: String)
