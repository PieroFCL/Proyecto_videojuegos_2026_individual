extends ItemResource
class_name KeyItem

# Las llaves no tienen funcionalidad especial más allá de ser un objeto de categoría "key"
func get_description() -> String:
	if not flavor_text.is_empty():
		return flavor_text
	return "Una llave que abre una puerta específica."
