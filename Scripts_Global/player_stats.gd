extends Node
# Sistema central de estadísticas del jugador.

# Valor base de vida máxima.
@export var base_max_hp: int = 90
# Valor base de ataque.
@export var base_attack: int = 12
# Valor base de defensa.
@export var base_defense: int = 4
# Valor base de velocidad.
@export var base_speed: int = 8

# Devuelve la vida actual del jugador.
var current_hp: int:
	get:
		return _current_hp
		
# Devuelve la vida máxima calculada dinámicamente.
var current_max_hp: int:
	get:
		return _calculate_max_hp()
		
# Devuelve el ataque actual con bonificaciones.
var current_attack: int:
	get:
		return _calculate_attack()
		
# Devuelve la defensa actual con bonificaciones.
var current_defense: int:
	get:
		return _calculate_defense()
		
# Devuelve la velocidad actual con bonificaciones.
var current_speed: int:
	get:
		return _calculate_speed()

# Almacena internamente la vida actual del jugador.
var _current_hp: int = 0

# ID del arma actualmente equipada.
var equipped_weapon_id: String = ""
# ID de la armadura actualmente equipada.
var equipped_armor_id: String = ""

# Lista de modificadores temporales activos (buffos/debuffos).
var _modifiers: Array[StatModifier] = []

# ID del sello mágico actualmente equipado.
var equipped_seal_id: String = ""

# Diccionario de buffs permanentes acumulables (valor, acumulaciones, máximo).
var _permanent_buffs: Dictionary = {}

# Señal emitida cuando cambian las estadísticas (equipamiento, buffos, etc.).
signal stats_changed()
# Señal emitida cuando cambia la vida (para actualizar la UI).
signal health_changed(new_hp: int, max_hp: int)
# Señal emitida cuando el jugador muere.
signal died()

# Inicializa la vida al máximo y emite señales iniciales.
func _ready() -> void:
	_current_hp = base_max_hp
	stats_changed.emit()
	health_changed.emit(current_hp, current_max_hp)
	print(" PlayerStats inicializado: HP = ", current_hp, "/", current_max_hp)

# Reinicia los buffs permanentes acumulados durante el combate anterior.
func reset_combat_buffs() -> void:
	_permanent_buffs.clear()
	stats_changed.emit()
	print(" Buffs permanentes de combate reiniciados")

# Devuelve una copia de los modificadores activos para la UI.
func get_active_modifiers() -> Array[StatModifier]:
	return _modifiers.duplicate()

# Calcula la vida máxima (base + bonificaciones futuras).
func _calculate_max_hp() -> int:
	var bonus = 0
	return base_max_hp + bonus

# Calcula el ataque actual considerando arma, buffs permanentes y temporales.
func _calculate_attack() -> int:
	var value = base_attack
	if not equipped_weapon_id.is_empty():
		var weapon = InventoryManager.get_item_resource(equipped_weapon_id)
		if weapon and weapon.has_method("get_attack_bonus"):
			value += weapon.get_attack_bonus()
	return _get_stat_with_buffs(value, "attack")

# Calcula la defensa actual considerando armadura y buffs.
func _calculate_defense() -> int:
	var value = base_defense
	if not equipped_armor_id.is_empty():
		var armor = InventoryManager.get_item_resource(equipped_armor_id)
		if armor and armor.has_method("get_defense_bonus"):
			value += armor.get_defense_bonus()
	return _get_stat_with_buffs(value, "defense")

# Calcula la velocidad actual aplicando buffs permanentes y temporales.
func _calculate_speed() -> int:
	var value = base_speed
	return _get_stat_with_buffs(value, "speed")

# Aplica todos los modificadores temporales a un valor base.
func _apply_modifiers(base_value: int, stat: String) -> int:
	var result = base_value
	for mod in _modifiers:
		if mod.stat == stat:
			result += mod.value
	return result

# Añade un modificador temporal que dura cierta cantidad de turnos.
func add_modifier(stat: String, value: int, turns: int) -> void:
	var mod = StatModifier.new()
	mod.stat = stat
	mod.value = value
	mod.remaining_turns = turns
	_modifiers.append(mod)
	stats_changed.emit()
	print(" Modificador añadido: ", stat, " ", value, " durante ", turns, " turnos")

# Reduce la duración de los modificadores temporales y elimina los expirados.
func process_turn_modifiers() -> void:
	var i = 0
	while i < _modifiers.size():
		_modifiers[i].remaining_turns -= 1
		if _modifiers[i].remaining_turns <= 0:
			_modifiers.remove_at(i)
		else:
			i += 1
	stats_changed.emit()

# Aplica daño al jugador, emite señales y verifica muerte.
func take_damage(amount: int) -> void:
	_current_hp = max(0, _current_hp - amount)
	health_changed.emit(current_hp, current_max_hp)
	print(" Daño recibido: ", amount, " - HP restante: ", current_hp)
	if current_hp <= 0:
		died.emit()

# Devuelve habilidades disponibles en combate (arma, sello y patada dirigida).
func get_combat_skills() -> Array[SkillResource]:
	var skills: Array[SkillResource] = []
	print("get_combat_skills: arma = ", equipped_weapon_id, " sello = ", equipped_seal_id)
	
	# Habilidades del arma equipada.
	if not equipped_weapon_id.is_empty():
		var weapon = InventoryManager.get_item_resource(equipped_weapon_id)
		if weapon and weapon.has_method("get_skills"):
			var weapon_skills = weapon.get_skills()
			if weapon_skills is Array:
				skills.append_array(weapon_skills)
				print("  Arma aporta ", weapon_skills.size(), " habilidades")
			else:
				print("  Arma: get_skills no devolvió un array")
		else:
			print("  Arma no encontrada o sin método get_skills")
	
	# Habilidades del sello equipado.
	if not equipped_seal_id.is_empty():
		var seal = InventoryManager.get_item_resource(equipped_seal_id)
		if seal and seal.has_method("get_skills"):
			var seal_skills = seal.get_skills()
			if seal_skills is Array:
				skills.append_array(seal_skills)
				print("  Sello aporta ", seal_skills.size(), " habilidades")
			else:
				print("  Sello: get_skills no devolvió un array")
		else:
			print("  Sello no encontrado o sin método get_skills")
	
	# Añade Patada Dirigida si no hay ofensiva y hay espacio.
	var has_offensive = false
	for s in skills:
		if s.damage > 0:
			has_offensive = true
			break
	if not has_offensive and skills.size() < 4:
		var patada = load("res://Inventory/Items/Skills/patada_dirigida.tres")
		if patada:
			skills.append(patada)
			print("  Añadida Patada Dirigida (por falta de ofensiva)")
		else:
			print("  ERROR: No se pudo cargar patada_dirigida.tres")
	
	print("get_combat_skills: total habilidades = ", skills.size())
	return skills.slice(0, 4)
	
# Cura al jugador sin superar la vida máxima.
func heal(amount: int) -> void:
	_current_hp = min(current_max_hp, _current_hp + amount)
	health_changed.emit(current_hp, current_max_hp)
	print(" Curado: ", amount, " - HP actual: ", current_hp)

# Restablece toda la vida del jugador al máximo.
func restore_full_health() -> void:
	_current_hp = current_max_hp
	health_changed.emit(current_hp, current_max_hp)
	print(" Vida restaurada al máximo")

# Asigna un sello mágico por su ID.
func equip_seal(item_id: String) -> void:
	print(" equip_seal llamado con ID: ", item_id)
	equipped_seal_id = item_id
	stats_changed.emit()

# Elimina el sello mágico equipado actualmente.
func unequip_seal() -> void:
	print(" Desequipando sello")
	equipped_seal_id = ""
	stats_changed.emit()

# Agrega un buff permanente acumulable, para habilidades de equipo.
func add_permanent_buff(stat: String, value: int, max_stacks: int = 2) -> bool:
	if not _permanent_buffs.has(stat):
		_permanent_buffs[stat] = { "value": 0, "stacks": 0, "max_stacks": max_stacks }
	var buff = _permanent_buffs[stat]
	if buff.stacks < buff.max_stacks:
		buff.value += value
		buff.stacks += 1
		stats_changed.emit()
		print(" Buff permanente de ", stat, " +", value, " (", buff.stacks, "/", buff.max_stacks, ")")
		return true
	else:
		print(" Ya se alcanzó el máximo de stacks para ", stat)
		return false

# Calcula valor final de atributo incluyendo buffs permanentes y temporales.
func _get_stat_with_buffs(base: int, stat: String) -> int:
	var result = base
	# Aplica los buffs permanentes almacenados.
	if _permanent_buffs.has(stat):
		result += _permanent_buffs[stat].value
	# Aplica los modificadores temporales.
	result = _apply_modifiers(result, stat)
	return max(0, result)

# Equipa arma por su ID y actualiza estadísticas.
func equip_weapon(item_id: String) -> void:
	print(" equip_weapon llamado con ID: ", item_id)
	equipped_weapon_id = item_id
	print(" equipped_weapon_id ahora es: ", equipped_weapon_id)
	stats_changed.emit()

# Equipa armadura por su ID y actualiza estadísticas.
func equip_armor(item_id: String) -> void:
	print(" equip_armor llamado con ID: ", item_id)
	equipped_armor_id = item_id
	print(" equipped_armor_id ahora es: ", equipped_armor_id)
	stats_changed.emit()

# Elimina arma actualmente equipada.
func unequip_weapon() -> void:
	print(" Desequipando arma")
	equipped_weapon_id = ""
	stats_changed.emit()

# Elimina armadura actualmente equipada.
func unequip_armor() -> void:
	print(" Desequipando armadura")
	equipped_armor_id = ""
	stats_changed.emit()

# Devuelve diccionario con todas las estadísticas actuales para la UI.
func get_stats_dictionary() -> Dictionary:
	return {
		"hp": current_hp,
		"max_hp": current_max_hp,
		"attack": current_attack,
		"defense": current_defense,
		"speed": current_speed
	}

# Devuelve ataque base (sin buffs de combate, pero con equipamiento).
func get_base_attack() -> int:
	var value = base_attack
	if not equipped_weapon_id.is_empty():
		var weapon = InventoryManager.get_item_resource(equipped_weapon_id)
		if weapon and weapon.has_method("get_attack_bonus"):
			value += weapon.get_attack_bonus()
	return value

# Devuelve defensa base (sin buffs de combate, pero con equipamiento).
func get_base_defense() -> int:
	var value = base_defense
	if not equipped_armor_id.is_empty():
		var armor = InventoryManager.get_item_resource(equipped_armor_id)
		if armor and armor.has_method("get_defense_bonus"):
			value += armor.get_defense_bonus()
	return value

# Devuelve velocidad base (sin buffs de combate).
func get_base_speed() -> int:
	return base_speed

# Retorna una copia de los buffs permanentes (para la UI).
func get_permanent_buffs() -> Dictionary:
	return _permanent_buffs.duplicate()

# Asigna un nuevo valor a la vida actual y emite la señal.
func set_current_hp(new_hp: int) -> void:
	_current_hp = clamp(new_hp, 0, current_max_hp)
	health_changed.emit(_current_hp, current_max_hp)
	print("DEBUG: set_current_hp -> nueva vida = ", _current_hp)

# Restablece todas las estadísticas y equipamiento a sus valores por defecto.
func reset_to_default() -> void:
	base_max_hp = 90
	base_attack = 12
	base_defense = 4
	base_speed = 8
	_current_hp = base_max_hp
	equipped_weapon_id = ""
	equipped_armor_id = ""
	equipped_seal_id = ""
	_permanent_buffs.clear()
	_modifiers.clear()
	stats_changed.emit()
	health_changed.emit(_current_hp, current_max_hp)
