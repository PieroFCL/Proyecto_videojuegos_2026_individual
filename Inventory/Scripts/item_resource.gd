extends Resource
class_name ItemResource

# Identificador único (ej. "potion_health", "sword_iron")
@export var id: String = ""

# Descripción larga y personalizada
@export var flavor_text: String = ""

# Nombre visible en el inventario
@export var display_name: String = ""

# Icono para el inventario (textura cuadrada pequeña)
@export var icon: Texture2D = null

# Categoría general: "consumable", "weapon", "armor", "quest"
@export var category: String = ""

# Descripción textual (puede sobreescribirse en clases hijas)
func get_description() -> String:
	return ""
