extends Node

# Almacena los IDs de objetos recolectables que el jugador ya ha cogido.
var collected_items: Array[String] = []
# Almacena los IDs de enemigos especiales que ya han sido derrotados.
var defeated_enemies: Array[String] = []
# Almacena los IDs de puertas que ya han sido abiertas.
var opened_doors: Array[String] = []
# Almacena los IDs de eventos únicos que ya se activaron.
var triggered_events: Array[String] = []

# Señal emitida cuando cualquiera de las listas de estado cambia.
signal state_changed

# Registra un objeto como recogido si no estaba registrado.
func register_collected_item(item_id: String) -> void:
	print("WorldStateManager.register_collected_item: ", item_id)
	if not collected_items.has(item_id):
		collected_items.append(item_id)
		state_changed.emit()
		print("Persistencia: objeto recogido -> ", item_id)
	else:
		print("  ATENCIÓN: el item ya estaba registrado!")

# Registra un enemigo como derrotado si no estaba registrado.
func register_defeated_enemy(enemy_id: String) -> void:
	print("WorldStateManager.register_defeated_enemy: ", enemy_id)
	if not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)
		state_changed.emit()
		print("Persistencia: enemigo derrotado -> ", enemy_id)
	else:
		print("  ATENCIÓN: el enemigo ya estaba registrado!")

# Registra una puerta como abierta si no estaba registrada.
func register_opened_door(door_id: String) -> void:
	print("WorldStateManager.register_opened_door: ", door_id)
	if not opened_doors.has(door_id):
		opened_doors.append(door_id)
		state_changed.emit()
		print("Persistencia: puerta abierta -> ", door_id)
	else:
		print("  ATENCIÓN: la puerta ya estaba registrada!")

# Registra un evento único como activado si no estaba registrado.
func register_event(event_id: String) -> void:
	print("WorldStateManager.register_event: ", event_id)
	if not triggered_events.has(event_id):
		triggered_events.append(event_id)
		state_changed.emit()
		print("Persistencia: evento activado -> ", event_id)
	else:
		print(" El evento ya estaba registrado!")

# Devuelve true si el objeto ya fue recogido, false en caso contrario.
func is_item_collected(item_id: String) -> bool:
	var result = collected_items.has(item_id)
	print("WorldStateManager.is_item_collected(", item_id, ") = ", result)
	return result

# Devuelve true si el enemigo ya fue derrotado, false en caso contrario.
func is_enemy_defeated(enemy_id: String) -> bool:
	var result = defeated_enemies.has(enemy_id)
	print("WorldStateManager.is_enemy_defeated(", enemy_id, ") = ", result)
	return result

# Devuelve true si la puerta ya fue abierta, false en caso contrario.
func is_door_opened(door_id: String) -> bool:
	var result = opened_doors.has(door_id)
	print("WorldStateManager.is_door_opened(", door_id, ") = ", result)
	return result

# Devuelve true si el evento ya fue activado, false en caso contrario.
func is_event_triggered(event_id: String) -> bool:
	var result = triggered_events.has(event_id)
	print("WorldStateManager.is_event_triggered(", event_id, ") = ", result)
	return result

# Limpia todas las listas de estado, útil para comenzar una nueva partida.
func reset() -> void:
	collected_items.clear()
	defeated_enemies.clear()
	opened_doors.clear()
	triggered_events.clear()
	state_changed.emit()
	print("Persistencia: todos los estados reiniciados")

# Restaura el estado completo a partir de un diccionario proporcionado
func restore_state(data: Dictionary) -> void:
	collected_items = data.get("collected_items", []).duplicate()
	defeated_enemies = data.get("defeated_enemies", []).duplicate()
	opened_doors = data.get("opened_doors", []).duplicate()
	triggered_events = data.get("triggered_events", []).duplicate()
	state_changed.emit()
