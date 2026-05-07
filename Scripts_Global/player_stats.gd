extends Node
## Sistema central de estadísticas del jugador.
## Gestiona valores base, modificadores por equipamiento y efectos temporales.

# ---- VALORES BASE (editables desde el inspector) ----
@export var base_max_hp: int = 100
@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_speed: int = 10

# ---- VALORES ACTUALES (calculados dinámicamente) ----
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

# ---- VALORES INTERNOS ----
var _current_hp: int = 0

# ---- EQUIPAMIENTO (IDs de los objetos equipados) ----
var equipped_weapon_id: String = ""
var equipped_armor_id: String = ""

# ---- MODIFICADORES TEMPORALES ----
var _modifiers: Array[StatModifier] = []

# ---- SEÑALES ----
## Se emite cuando cambian las estadísticas (equipamiento, buffos, etc.)
signal stats_changed()
## Se emite cuando la vida cambia (para actualizar la UI)
signal health_changed(new_hp: int, max_hp: int)
## Se emite cuando el jugador muere
signal died()

# ---- INICIALIZACIÓN ----
func _ready() -> void:
	_current_hp = base_max_hp
	stats_changed.emit()
	health_changed.emit(current_hp, current_max_hp)
	print("🔧 PlayerStats inicializado: HP = ", current_hp, "/", current_max_hp)

# ---- CÁLCULO DE ESTADÍSTICAS (con bonificaciones de equipamiento) ----

func _calculate_max_hp() -> int:
	var bonus = 0
	# Aquí se pueden añadir bonificaciones por equipamiento (ej. anillo de vida)
	return base_max_hp + bonus

func _calculate_attack() -> int:
	var value = base_attack
	
	if not equipped_weapon_id.is_empty():
		var weapon = InventoryManager.get_item_resource(equipped_weapon_id)
		print("🔍 weapon obtenido: ", weapon)
		if weapon and weapon.has_method("get_attack_bonus"):
			var bonus = weapon.get_attack_bonus()
			print("🔍 bonus de arma = ", bonus)
			value += bonus
		else:
			print("🔍 NO se pudo obtener el bono - weapon: ", weapon, " | tiene get_attack_bonus? ", weapon.has_method("get_attack_bonus") if weapon else "weapon es null")
	
	value = _apply_modifiers(value, "attack")
	return max(0, value)

func _calculate_defense() -> int:
	var value = base_defense
	
	if not equipped_armor_id.is_empty():
		var armor = InventoryManager.get_item_resource(equipped_armor_id)
		if armor and armor.has_method("get_defense_bonus"):
			value += armor.get_defense_bonus()
	
	value = _apply_modifiers(value, "defense")
	return max(0, value)

func _calculate_speed() -> int:
	var value = base_speed
	value = _apply_modifiers(value, "speed")
	return max(0, value)

# ---- GESTIÓN DE MODIFICADORES TEMPORALES ----

func _apply_modifiers(base_value: int, stat: String) -> int:
	var result = base_value
	for mod in _modifiers:
		if mod.stat == stat:
			result += mod.value
	return result

func add_modifier(stat: String, value: int, turns: int) -> void:
	var mod = StatModifier.new()
	mod.stat = stat
	mod.value = value
	mod.remaining_turns = turns
	_modifiers.append(mod)
	stats_changed.emit()
	print("🔧 Modificador añadido: ", stat, " ", value, " durante ", turns, " turnos")

func process_turn_modifiers() -> void:
	var i = 0
	while i < _modifiers.size():
		_modifiers[i].remaining_turns -= 1
		if _modifiers[i].remaining_turns <= 0:
			_modifiers.remove_at(i)
		else:
			i += 1
	stats_changed.emit()

# ---- MANEJO DE VIDA ----

func take_damage(amount: int) -> void:
	_current_hp = max(0, _current_hp - amount)
	health_changed.emit(current_hp, current_max_hp)
	print("🔧 Daño recibido: ", amount, " - HP restante: ", current_hp)
	if current_hp <= 0:
		died.emit()

func heal(amount: int) -> void:
	_current_hp = min(current_max_hp, _current_hp + amount)
	health_changed.emit(current_hp, current_max_hp)
	print("🔧 Curado: ", amount, " - HP actual: ", current_hp)

func restore_full_health() -> void:
	_current_hp = current_max_hp
	health_changed.emit(current_hp, current_max_hp)
	print("🔧 Vida restaurada al máximo")

# ---- EQUIPAMIENTO (conexión con el sistema de inventario) ----

func equip_weapon(item_id: String) -> void:
	print("🔧 equip_weapon llamado con ID: ", item_id)
	equipped_weapon_id = item_id
	print("🔧 equipped_weapon_id ahora es: ", equipped_weapon_id)
	stats_changed.emit()

func equip_armor(item_id: String) -> void:
	print("🔧 equip_armor llamado con ID: ", item_id)
	equipped_armor_id = item_id
	print("🔧 equipped_armor_id ahora es: ", equipped_armor_id)
	stats_changed.emit()

func unequip_weapon() -> void:
	print("🔧 Desequipando arma")
	equipped_weapon_id = ""
	stats_changed.emit()

func unequip_armor() -> void:
	print("🔧 Desequipando armadura")
	equipped_armor_id = ""
	stats_changed.emit()

# ---- UTILIDADES ----

func get_stats_dictionary() -> Dictionary:
	return {
		"hp": current_hp,
		"max_hp": current_max_hp,
		"attack": current_attack,
		"defense": current_defense,
		"speed": current_speed
	}
