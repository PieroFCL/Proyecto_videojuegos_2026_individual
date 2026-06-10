extends ItemResource
class_name KeyItem

# Devuelve descripción del objeto para la interfaz.
func get_description() -> String:
	# Usa texto narrativo si existe, si no, texto genérico.
	if not flavor_text.is_empty():
		return flavor_text
	return "Una llave que abre una puerta específica."
