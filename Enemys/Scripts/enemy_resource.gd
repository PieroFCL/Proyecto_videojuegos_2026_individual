extends Resource
class_name EnemyResource

@export var id: String = ""                     # Identificador único 
@export var display_name: String = ""           # Nombre visible
@export var max_hp: int = 10
@export var attack: int = 3
@export var defense: int = 1
@export var speed: int = 5
@export var weakness: String = "fisico"   # "fisico" o "magico"

# Textura para el combate (hoja de sprites)
@export var combat_texture: Texture2D = null
@export var combat_hframes: int = 1
@export var combat_vframes: int = 1
@export var combat_scale: Vector2 = Vector2(1.0, 1.0)

# (Opcional) textura para el mundo (movimiento, idle) - ya tenías sprite_texture
@export var sprite_texture: Texture2D = null

# Objetos que puede soltar (se implementará después)
# @export var drop_items: Array[ItemDrop] = []
