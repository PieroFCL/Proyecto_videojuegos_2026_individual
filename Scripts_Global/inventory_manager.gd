extends Node

# Diccionario que almacena cantidad por ID del objeto.
var _items: Dictionary = {}

# Señal emitida al cambiar inventario (ID y nueva cantidad).
signal inventory_changed(item_id: String, new_quantity: int)

# Añade una cantidad de un objeto, redirige documentos.
func add_item(item_id: String, amount: int = 1) -> bool:
	# Rechaza cantidades no positivas.
	if amount <= 0:
		return false
	
	# Obtiene el recurso asociado al ID.
	var item_res = get_item_resource(item_id)
	if not item_res:
		print("Error: No se pudo cargar el recurso para ", item_id)
		return false
	
	# Redirige documentos al gestor especializado.
	if item_res is DocumentItem:
		return DocumentManager.add_document(item_res)
	
	# Lógica para objetos normales (armas, consumibles, etc.).
	if _items.has(item_id):
		_items[item_id] += amount
	else:
		_items[item_id] = amount
	# Emite señal de cambio.
	inventory_changed.emit(item_id, _items[item_id])
	print("Inventario +", amount, " ", item_id, " → ", _items[item_id])
	return true

# Elimita una cantidad de un objeto del inventario.
func remove_item(item_id: String, amount: int = 1) -> bool:
	# Verifica existencia y cantidad suficiente.
	if not _items.has(item_id):
		return false
	if _items[item_id] < amount:
		return false
	# Reduce cantidad o elimina entrada si llega a cero.
	_items[item_id] -= amount
	if _items[item_id] == 0:
		_items.erase(item_id)
	# Emite señal con nueva cantidad (cero si fue eliminado).
	inventory_changed.emit(item_id, _items.get(item_id, 0))
	print("Inventario -", amount, " ", item_id, " → ", _items.get(item_id, 0))
	return true

# Devuelve la cantidad actual de un objeto.
func get_quantity(item_id: String) -> int:
	return _items.get(item_id, 0)

# Verifica si se tiene al menos una cantidad específica.
func has_item(item_id: String, amount: int = 1) -> bool:
	return get_quantity(item_id) >= amount

# Devuelve copia del diccionario completo para la UI.
func get_all_items() -> Dictionary:
	return _items.duplicate()

# Carga y devuelve el recurso completo de un objeto por su ID.
func get_item_resource(item_id: String) -> ItemResource:
	var path = "res://Inventory/Items/" + item_id + ".tres"
	var exists = ResourceLoader.exists(path)
	print("Cargando ", item_id, " (existe: ", exists, ")")
	if exists:
		var res = load(path)
		return res
	return null

# Restaura el inventario desde un diccionario guardado.
func restore_from_dict(data: Dictionary) -> void:
	_items = data.duplicate()
	# Señal genérica para refrescar la UI.
	inventory_changed.emit("", 0)

# Vacía completamente el inventario.
func clear() -> void:
	_items.clear()
	inventory_changed.emit("", 0)
