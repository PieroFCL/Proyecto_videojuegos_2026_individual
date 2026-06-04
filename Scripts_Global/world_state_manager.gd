extends Node

# Listas de IDs únicos
var collected_items: Array[String] = []       # Objetos recolectables ya cogidos
var defeated_enemies: Array[String] = []      # Enemigos especiales (jefes) derrotados
var opened_doors: Array[String] = []          # Puertas abiertas
var triggered_events: Array[String] = []      # Otros eventos únicos (opcional)

# Señal emitida cuando cambia cualquier estado
signal state_changed

# Registro de eventos
func register_collected_item(item_id: String) -> void:
	print("WorldStateManager.register_collected_item: ", item_id)
	if not collected_items.has(item_id):
		collected_items.append(item_id)
		state_changed.emit()
		print("Persistencia: objeto recogido -> ", item_id)
	else:
		print("  ATENCIÓN: el item ya estaba registrado!")

func register_defeated_enemy(enemy_id: String) -> void:
	print("WorldStateManager.register_defeated_enemy: ", enemy_id)
	if not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)
		state_changed.emit()
		print("Persistencia: enemigo derrotado -> ", enemy_id)
	else:
		print("  ATENCIÓN: el enemigo ya estaba registrado!")

func register_opened_door(door_id: String) -> void:
	print("WorldStateManager.register_opened_door: ", door_id)
	if not opened_doors.has(door_id):
		opened_doors.append(door_id)
		state_changed.emit()
		print("Persistencia: puerta abierta -> ", door_id)
	else:
		print("  ATENCIÓN: la puerta ya estaba registrada!")

func register_event(event_id: String) -> void:
	print("WorldStateManager.register_event: ", event_id)
	if not triggered_events.has(event_id):
		triggered_events.append(event_id)
		state_changed.emit()
		print("Persistencia: evento activado -> ", event_id)
	else:
		print("  ATENCIÓN: el evento ya estaba registrado!")

# Consultas
func is_item_collected(item_id: String) -> bool:
	var result = collected_items.has(item_id)
	print("WorldStateManager.is_item_collected(", item_id, ") = ", result)
	return result

func is_enemy_defeated(enemy_id: String) -> bool:
	var result = defeated_enemies.has(enemy_id)
	print("WorldStateManager.is_enemy_defeated(", enemy_id, ") = ", result)
	return result

func is_door_opened(door_id: String) -> bool:
	var result = opened_doors.has(door_id)
	print("WorldStateManager.is_door_opened(", door_id, ") = ", result)
	return result

func is_event_triggered(event_id: String) -> bool:
	var result = triggered_events.has(event_id)
	print("WorldStateManager.is_event_triggered(", event_id, ") = ", result)
	return result

# Reseteo, util para nueva partida	
func reset() -> void:
	collected_items.clear()
	defeated_enemies.clear()
	opened_doors.clear()
	triggered_events.clear()
	state_changed.emit()
	print("Persistencia: todos los estados reiniciados")

func restore_state(data: Dictionary) -> void:
	collected_items = data.get("collected_items", []).duplicate()
	defeated_enemies = data.get("defeated_enemies", []).duplicate()
	opened_doors = data.get("opened_doors", []).duplicate()
	triggered_events = data.get("triggered_events", []).duplicate()
	state_changed.emit()
