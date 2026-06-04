extends Node

## Estructura: { collection_id: { page_number: DocumentItem } }
var _collected: Dictionary = {}

## Señal emitida cuando se añade un nuevo documento
signal documents_changed

## Añade un documento si no está ya recolectado.
## Retorna true si se añadió, false si ya existía.
func add_document(doc: DocumentItem) -> bool:
	if not _collected.has(doc.collection_id):
		_collected[doc.collection_id] = {}
	var col = _collected[doc.collection_id]
	if not col.has(doc.page_number):
		col[doc.page_number] = doc
		documents_changed.emit()
		print("Documento añadido: ", doc.collection_id, " - ", doc.title)
		return true
	return false

## Devuelve todas las colecciones que tienen al menos un documento
func get_collections() -> Array:
	return _collected.keys()

## Devuelve un diccionario { page_number: DocumentItem } para una colección
func get_documents(collection_id: String) -> Dictionary:
	return _collected.get(collection_id, {})

## Verifica si no hay documentos recolectados
func is_empty() -> bool:
	return _collected.is_empty()

## (Opcional) Obtiene todos los documentos en una lista plana (para debug)
func get_all_flat() -> Array:
	var result = []
	for col in _collected:
		for page in _collected[col]:
			result.append(_collected[col][page])
	return result

func get_all_data() -> Dictionary:
	return _collected

func restore_data(data: Dictionary) -> void:
	_collected = data
	documents_changed.emit()

func clear() -> void:
	_collected.clear()
	documents_changed.emit()
