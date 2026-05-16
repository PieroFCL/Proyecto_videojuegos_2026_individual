extends Node
# Sistema central de estadísticas del jugador.

# Valores base editables desde el inspector
@export var base_max_hp: int = 100
@export var base_attack: int = 30
@export var base_defense: int = 10
@export var base_speed: int = 10

# Valores actuales calculados dinámicamente mediante getters
var current_hp: int:
	get:
		return _current_hp
var current_max_hp: int:
	get:
		return _calculate_max_hp()
var current_attack: int:
	get:
		return _calculate_attack()
var current_defense: int:
	get:
		return _calculate_defense()
var current_speed: int:
	get:
		return _calculate_speed()

# Vida actual del jugador (modificable directamente)
var _current_hp: int = 0

# IDs de los objetos equipados actualmente
var equipped_weapon_id: String = ""
var equipped_armor_id: String = ""

# Lista de modificadores temporales activos (buffos o debuffos)
var _modifiers: Array[StatModifier] = []

var equipped_seal_id: String = ""

# Diccionario para buffs permanentes (acumulables hasta max_stacks)
# Estructura: { "stat": { "value": int, "stacks": int, "max_stacks": int } }
var _permanent_buffs: Dictionary = {}

# Señal emitida cuando cambian las estadísticas (equipamiento, buffos, etc.)
signal stats_changed()
# Señal emitida cuando cambia la vida (para actualizar la UI)
signal health_changed(new_hp: int, max_hp: int)
# Señal emitida cuando el jugador muere
signal died()

# Inicializa la vida al máximo y emite señales iniciales
func _ready() -> void:
	_current_hp = base_max_hp
	stats_changed.emit()
	health_changed.emit(current_hp, current_max_hp)
	print(" PlayerStats inicializado: HP = ", current_hp, "/", current_max_hp)

# Reinicia los buffs permanentes acumulados durante el combate anterior.
# Se debe llamar al iniciar un nuevo combate.
func reset_combat_buffs() -> void:
	_permanent_buffs.clear()
	stats_changed.emit()
	print(" Buffs permanentes de combate reiniciados")

# Devuelve una copia de los modificadores activos (para UI)
func get_active_modifiers() -> Array[StatModifier]:
	return _modifiers.duplicate()

# Calcula la vida máxima (base + bonificaciones futuras)
func _calculate_max_hp() -> int:
	var bonus = 0
	return base_max_hp + bonus

# Calcula el ataque actual teniendo en cuenta el arma equipada, buffs permanentes y temporales
func _calculate_attack() -> int:
	var value = base_attack
	if not equipped_weapon_id.is_empty():
		var weapon = InventoryManager.get_item_resource(equipped_weapon_id)
		if weapon and weapon.has_method("get_attack_bonus"):
			value += weapon.get_attack_bonus()
	return _get_stat_with_buffs(value, "attack")

# Calcula la defensa actual teniendo en cuenta la armadura equipada, buffs permanentes y temporales
func _calculate_defense() -> int:
	var value = base_defense
	if not equipped_armor_id.is_empty():
		var armor = InventoryManager.get_item_resource(equipped_armor_id)
		if armor and armor.has_method("get_defense_bonus"):
			value += armor.get_defense_bonus()
	return _get_stat_with_buffs(value, "defense")

# Calcula la velocidad actual aplicando buffs permanentes y temporales
func _calculate_speed() -> int:
	var value = base_speed
	return _get_stat_with_buffs(value, "speed")

# Aplica todos los modificadores temporales activos a una estadística base
func _apply_modifiers(base_value: int, stat: String) -> int:
	var result = base_value
	for mod in _modifiers:
		if mod.stat == stat:
			result += mod.value
	return result

# Añade un modificador temporal (buffo/debuffo) que durará cierta cantidad de turnos
func add_modifier(stat: String, value: int, turns: int) -> void:
	var mod = StatModifier.new()
	mod.stat = stat
	mod.value = value
	mod.remaining_turns = turns
	_modifiers.append(mod)
	stats_changed.emit()
	print(" Modificador añadido: ", stat, " ", value, " durante ", turns, " turnos")

# Reduce la duración de los modificadores temporales al final de cada turno y elimina los expirados
func process_turn_modifiers() -> void:
	var i = 0
	while i < _modifiers.size():
		_modifiers[i].remaining_turns -= 1
		if _modifiers[i].remaining_turns <= 0:
			_modifiers.remove_at(i)
		else:
			i += 1
	stats_changed.emit()

# Aplica daño al jugador, emite señales y verifica muerte
func take_damage(amount: int) -> void:
	_current_hp = max(0, _current_hp - amount)
	health_changed.emit(current_hp, current_max_hp)
	print(" Daño recibido: ", amount, " - HP restante: ", current_hp)
	if current_hp <= 0:
		died.emit()

# Devuelve las habilidades disponibles en combate (arma + sello, más patada dirigida si falta ofensiva)
func get_combat_skills() -> Array[SkillResource]:
	var skills: Array[SkillResource] = []
	
	# Habilidades del arma equipada
	if not equipped_weapon_id.is_empty():
		var weapon = InventoryManager.get_item_resource(equipped_weapon_id)
		if weapon and weapon.has_method("get_skills"):
			var weapon_skills = weapon.get_skills()
			if weapon_skills is Array:
				skills.append_array(weapon_skills)
	
	# Habilidades del sello equipado
	if not equipped_seal_id.is_empty():
		var seal = InventoryManager.get_item_resource(equipped_seal_id)
		if seal and seal.has_method("get_skills"):
			var seal_skills = seal.get_skills()
			if seal_skills is Array:
				skills.append_array(seal_skills)
	
	# Si no hay habilidades ofensivas (damage > 0) y el total es menor a 4, añadir Patada Dirigida
	var has_offensive = false
	for s in skills:
		if s.damage > 0:
			has_offensive = true
			break
	if not has_offensive and skills.size() < 4:
		var patada = load("res://Inventory/Items/Skills/patada_dirigida.tres")
		if patada:
			skills.append(patada)
	
	# Limitar a 4 habilidades
	return skills.slice(0, 4)

# Cura al jugador sin exceder la vida máxima
func heal(amount: int) -> void:
	_current_hp = min(current_max_hp, _current_hp + amount)
	health_changed.emit(current_hp, current_max_hp)
	print(" Curado: ", amount, " - HP actual: ", current_hp)

# Restaura toda la vida al máximo
func restore_full_health() -> void:
	_current_hp = current_max_hp
	health_changed.emit(current_hp, current_max_hp)
	print(" Vida restaurada al máximo")

# Equipa un sello por su ID
func equip_seal(item_id: String) -> void:
	print(" equip_seal llamado con ID: ", item_id)
	equipped_seal_id = item_id
	stats_changed.emit()

# Desequipa el sello actual
func unequip_seal() -> void:
	print(" Desequipando sello")
	equipped_seal_id = ""
	stats_changed.emit()

# Añade un buff permanente acumulable (para habilidades de equipo)
func add_permanent_buff(stat: String, value: int, max_stacks: int = 2) -> void:
	if not _permanent_buffs.has(stat):
		_permanent_buffs[stat] = { "value": 0, "stacks": 0, "max_stacks": max_stacks }
	var buff = _permanent_buffs[stat]
	if buff.stacks < buff.max_stacks:
		buff.value += value
		buff.stacks += 1
		stats_changed.emit()
		print(" Buff permanente de ", stat, " +", value, " (", buff.stacks, "/", buff.max_stacks, ")")
	else:
		print(" Ya se alcanzó el máximo de stacks para ", stat)

# Calcula el valor de un atributo con buffs permanentes y temporales
func _get_stat_with_buffs(base: int, stat: String) -> int:
	var result = base
	# Añadir buffs permanentes
	if _permanent_buffs.has(stat):
		result += _permanent_buffs[stat].value
	# Añadir buffs temporales (modificadores)
	result = _apply_modifiers(result, stat)
	return max(0, result)

# Equipa un arma por su ID y actualiza estadísticas
func equip_weapon(item_id: String) -> void:
	print(" equip_weapon llamado con ID: ", item_id)
	equipped_weapon_id = item_id
	print(" equipped_weapon_id ahora es: ", equipped_weapon_id)
	stats_changed.emit()

# Equipa una armadura por su ID y actualiza estadísticas
func equip_armor(item_id: String) -> void:
	print(" equip_armor llamado con ID: ", item_id)
	equipped_armor_id = item_id
	print(" equipped_armor_id ahora es: ", equipped_armor_id)
	stats_changed.emit()

# Desequipa el arma actual
func unequip_weapon() -> void:
	print(" Desequipando arma")
	equipped_weapon_id = ""
	stats_changed.emit()

# Desequipa la armadura actual
func unequip_armor() -> void:
	print(" Desequipando armadura")
	equipped_armor_id = ""
	stats_changed.emit()

# Devuelve un diccionario con todas las estadísticas actuales (útil para UI)
func get_stats_dictionary() -> Dictionary:
	return {
		"hp": current_hp,
		"max_hp": current_max_hp,
		"attack": current_attack,
		"defense": current_defense,
		"speed": current_speed
	}
