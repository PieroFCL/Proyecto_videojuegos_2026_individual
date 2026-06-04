extends ItemResource
class_name DocumentItem

## Identificador de la colección (ej. "aldren", "ricardo", "doroti", "otros")
@export var collection_id: String = ""

## Número de página dentro de la colección (para ordenar)
@export var page_number: int = 1

## Título del documento (se muestra en la lista)
@export var title: String = ""

## Contenido completo del documento (texto multilínea)
@export_multiline var text_content: String = ""

func _init() -> void:
	category = "document"
