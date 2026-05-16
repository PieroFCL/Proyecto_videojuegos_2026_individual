extends Node

# Diccionario interno: { "item_id": cantidad }
var _items: Dictionary = {}

# Señal emitida cada vez que cambia el inventario
signal inventory_changed(item_id: String, new_quantity: int)

# Añade una cantidad de un objeto
func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	if _items.has(item_id):
		_items[item_id] += amount
	else:
		_items[item_id] = amount
	inventory_changed.emit(item_id, _items[item_id])
	print("Inventario +", amount, " ", item_id, " → ", _items[item_id])

# Elimina una cantidad. Devuelve true si se pudo.
func remove_item(item_id: String, amount: int = 1) -> bool:
	if not _items.has(item_id):
		return false
	if _items[item_id] < amount:
		return false
	_items[item_id] -= amount
	if _items[item_id] == 0:
		_items.erase(item_id)
	inventory_changed.emit(item_id, _items.get(item_id, 0))
	print("Inventario -", amount, " ", item_id, " → ", _items.get(item_id, 0))
	return true

# Devuelve la cantidad actual
func get_quantity(item_id: String) -> int:
	return _items.get(item_id, 0)

# Verifica si tiene al menos 'amount'
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_quantity(item_id) >= amount

# Devuelve una copia del diccionario completo (para UI)
func get_all_items() -> Dictionary:
	return _items.duplicate()

# Carga el recurso completo de un item por su ID (útil para UI)
func get_item_resource(item_id: String) -> ItemResource:
	var path = "res://Inventory/Items/" + item_id + ".tres"
	var exists = ResourceLoader.exists(path)
	print("Cargando ", item_id, " (existe: ", exists, ")")
	if exists:
		var res = load(path)
		return res
	return null
