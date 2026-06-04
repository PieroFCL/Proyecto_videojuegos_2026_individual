extends Node

const AUTO_SAVE_PATH = "user://save_auto.tres"
const MANUAL_SAVE_PATHS = {
	1: "user://save_manual_1.tres",
	2: "user://save_manual_2.tres",
	3: "user://save_manual_3.tres"
}
# Constante legacy para compatibilidad (se mantiene pero se recomienda usar AUTO_SAVE_PATH)
const SAVE_PATH = AUTO_SAVE_PATH

const FADE_SCENE = preload("res://Shared_Assets/Effects/FadeTransition/fade_transition.tscn")
static var is_loading = false

# Identificadores de slots
const AUTO_SLOT_ID = 0
const MANUAL_SLOT_IDS = [1, 2, 3]

static var pending_load_slot: int = -1

func _ready() -> void:
	print("Directorio de guardado: ", OS.get_user_data_dir())
	# Eliminar archivo antiguo si existe (por si acaso)
	if ResourceLoader.exists(SAVE_PATH):
		print("Archivo antiguo eliminado: ", SAVE_PATH)
		var dir = DirAccess.open(OS.get_user_data_dir())
		if dir:
			dir.remove("checkpoint_save.tres")
			print("Archivo checkpoint antiguo eliminado.")

# Devuelve la ruta de archivo para un slot dado
func _get_save_path(slot_id: int) -> String:
	match slot_id:
		0: return AUTO_SAVE_PATH
		1: return MANUAL_SAVE_PATHS[1]
		2: return MANUAL_SAVE_PATHS[2]
		3: return MANUAL_SAVE_PATHS[3]
		_: return ""

# ---- Nuevas funciones para múltiples slots ----

# Guarda el estado actual en un slot específico (0 = auto, 1-3 = manual)
func save_game(slot_id: int) -> bool:
	print("=== save_game INICIO: slot=", slot_id, " path=", _get_save_path(slot_id))
	var path = _get_save_path(slot_id)
	if path.is_empty():
		return false
	
	var data = CheckpointData.new()
	data.version = "1.0"
	data.timestamp = Time.get_datetime_string_from_system()
	
	var level = LevelManager.current_level_instance
	data.level_path = level.scene_file_path if level else ""
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		data.player_position = player.global_position
		if player.has_method("get_cardinal_direction"):
			data.player_facing = player.cardinal_direction
		else:
			data.player_facing = Vector2.DOWN
	else:
		data.player_position = Vector2.ZERO
		data.player_facing = Vector2.DOWN
	
	data.player_hp = PlayerStats.current_hp
	data.base_max_hp = PlayerStats.base_max_hp
	data.base_attack = PlayerStats.base_attack
	data.base_defense = PlayerStats.base_defense
	data.base_speed = PlayerStats.base_speed
	data.equipped_weapon = PlayerStats.equipped_weapon_id
	data.equipped_armor = PlayerStats.equipped_armor_id
	data.equipped_seal = PlayerStats.equipped_seal_id
	
	data.inventory = InventoryManager.get_all_items()
	data.documents = DocumentManager.get_all_data()
	
	data.collected_items = WorldStateManager.collected_items.duplicate()
	data.defeated_enemies = WorldStateManager.defeated_enemies.duplicate()
	data.opened_doors = WorldStateManager.opened_doors.duplicate()
	data.triggered_events = WorldStateManager.triggered_events.duplicate()
	
	var error = ResourceSaver.save(data, path)
	if error == OK:
		print("Partida guardada en slot ", slot_id)
	else:
		print("Error al guardar slot ", slot_id, ": ", error)
	return error == OK

# Carga un slot específico (0 = auto, 1-3 = manual)
func load_game(slot_id: int) -> bool:
	print("=== load_game INICIO: slot=", slot_id, " path=", _get_save_path(slot_id))
	var path = _get_save_path(slot_id)
	print("=== load_game: cargando slot ", slot_id, " desde ", path)
	if not ResourceLoader.exists(path):
		return false
	
	var data: CheckpointData = ResourceLoader.load(path)
	if not data:
		return false
	
	is_loading = true
	
	var fade = FADE_SCENE.instantiate()
	var color_rect = fade.get_node("ColorRect")
	color_rect.modulate = Color(1, 1, 1, 1)
	get_tree().root.add_child(fade)
	await get_tree().process_frame
	
	WorldStateManager.restore_state({
		"collected_items": data.collected_items,
		"defeated_enemies": data.defeated_enemies,
		"opened_doors": data.opened_doors,
		"triggered_events": data.triggered_events
	})
	
	LevelManager.load_level_directly(data.level_path, data.player_position, data.player_facing)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	PlayerStats.base_max_hp = data.base_max_hp
	PlayerStats.base_attack = data.base_attack
	PlayerStats.base_defense = data.base_defense
	PlayerStats.base_speed = data.base_speed
	PlayerStats.equipped_weapon_id = data.equipped_weapon
	PlayerStats.equipped_armor_id = data.equipped_armor
	PlayerStats.equipped_seal_id = data.equipped_seal
	
	print("DEBUG: Cargando checkpoint - HP guardado = ", data.player_hp)
	var restored_hp = max(data.player_hp, 1)
	PlayerStats.set_current_hp(restored_hp)
	print("DEBUG: HP después de set_current_hp = ", PlayerStats.current_hp)
	
	EquipmentManager.force_equipment_refresh()
	InventoryManager.restore_from_dict(data.inventory)
	DocumentManager.restore_data(data.documents)
	
	# Dentro de load_game, después de restaurar todo y antes de return true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.visible = true
	
	await fade.fade_in()
	fade.queue_free()
	
	is_loading = false
	print("Partida cargada del slot ", slot_id)
	print("=== load_game FIN: éxito=", true)
	return true

# Devuelve una lista con los IDs de los slots manuales que tienen guardado
func get_manual_saves() -> Array[int]:
	var saves: Array[int] = []
	for slot_id in MANUAL_SLOT_IDS:
		if ResourceLoader.exists(_get_save_path(slot_id)):
			saves.append(slot_id)
	return saves

# Borra todos los archivos de guardado (todos los slots)
func reset_all_saves() -> void:
	print("=== reset_all_saves llamado (pila: ", get_stack(), ")") # opcional
	for slot_id in [AUTO_SLOT_ID] + MANUAL_SLOT_IDS:
		var path = _get_save_path(slot_id)
		print("   Eliminando: ", path)
		if ResourceLoader.exists(path):
			DirAccess.remove_absolute(path)
	print("Todos los slots de guardado han sido eliminados")

# ---- Funciones legacy (se mantienen para compatibilidad) ----
# Guarda el estado actual en el slot automático
func save_checkpoint() -> void:
	save_game(AUTO_SLOT_ID)

# Carga el último checkpoint (slot automático)
func load_checkpoint() -> bool:
	return await load_game(AUTO_SLOT_ID)
