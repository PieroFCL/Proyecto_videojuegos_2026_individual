extends ItemResource
# Documento narrativo con colección, página y contenido.
class_name DocumentItem

# Identificador de la colección (aldren, ricardo, doroti, otros).
@export var collection_id: String = ""
# Número de página dentro de la colección.
@export var page_number: int = 1
# Título mostrado en la lista del menú.
@export var title: String = ""
# Contenido completo del documento (texto multilínea).
@export_multiline var text_content: String = ""

# Establece categoría como documento al inicializar.
func _init() -> void:
	category = "document"
