extends Node
# Almacena documentos por colección y número de página.

# Diccionario anidado: colección -> página -> DocumentItem.
var _collected: Dictionary = {}

# Señal emitida al añadir o modificar documentos.
signal documents_changed

# Agrega documento si no existe, emite señal y retorna éxito.
func add_document(doc: DocumentItem) -> bool:
	# Crea entrada de colección si no existe.
	if not _collected.has(doc.collection_id):
		_collected[doc.collection_id] = {}
	var col = _collected[doc.collection_id]
	# Solo añade si la página no está registrada.
	if not col.has(doc.page_number):
		col[doc.page_number] = doc
		documents_changed.emit()
		print("Documento añadido: ", doc.collection_id, " - ", doc.title)
		return true
	return false

# Devuelve lista de IDs de colecciones con documentos.
func get_collections() -> Array:
	return _collected.keys()

# Retorna diccionario (página -> documento) de una colección.
func get_documents(collection_id: String) -> Dictionary:
	return _collected.get(collection_id, {})

# Indica si no hay ningún documento recolectado.
func is_empty() -> bool:
	return _collected.is_empty()

# Obtiene lista plana de todos los documentos (útil para debug).
func get_all_flat() -> Array:
	var result = []
	for col in _collected:
		for page in _collected[col]:
			result.append(_collected[col][page])
	return result

# Devuelve toda la estructura interna (para guardado).
func get_all_data() -> Dictionary:
	return _collected

# Restaura estructura desde diccionario guardado.
func restore_data(data: Dictionary) -> void:
	_collected = data
	documents_changed.emit()

# Vacía completamente el gestor de documentos.
func clear() -> void:
	_collected.clear()
	documents_changed.emit()
