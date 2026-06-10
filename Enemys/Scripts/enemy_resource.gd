extends Resource

# Recurso que define las estadísticas y comportamiento de un enemigo.
class_name EnemyResource

# Prefijo usado para animaciones (ej. "diablillo_volador").
@export var animation_prefix: String = "diablillo_volador"

# Identificador único del enemigo (snake_case).
@export var id: String = ""
# Nombre mostrado en la interfaz.
@export var display_name: String = ""
# Puntos de vida máximos del enemigo.
@export var max_hp: int = 10
# Valor de ataque base del enemigo.
@export var attack: int = 3
# Valor de defensa base del enemigo.
@export var defense: int = 1
# Velocidad base para turnos en combate.
@export var speed: int = 5
# Tipo de debilidad: "physical" o "magical".
@export var weakness: String = "physical"
# Indica si es un jefe (usa música especial).
@export var is_boss: bool = false

# Textura para el mundo (movimiento e idle).
@export var sprite_texture: Texture2D = null

# Textura para la pantalla de combate.
@export var combat_texture: Texture2D = null
# Número de columnas de la hoja de combate.
@export var combat_hframes: int = 1
# Número de filas de la hoja de combate.
@export var combat_vframes: int = 1
# Escala del sprite en combate.
@export var combat_scale: Vector2 = Vector2(1.0, 1.0)

# Lista de habilidades que puede usar en combate.
@export var skills: Array[SkillResource] = []

# Objetos que puede soltar
# @export var drop_items: Array[ItemDrop] = []
