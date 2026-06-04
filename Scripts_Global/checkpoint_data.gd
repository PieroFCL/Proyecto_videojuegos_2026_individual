extends Resource
class_name CheckpointData

# Metadatos
@export var version: String = "1.0"
@export var timestamp: String = ""

# Nivel y posición del jugador
@export var level_path: String = ""
@export var player_position: Vector2 = Vector2.ZERO
@export var player_facing: Vector2 = Vector2.DOWN

# Estadísticas y equipamiento
@export var player_hp: int = 0
@export var base_max_hp: int = 90
@export var base_attack: int = 12
@export var base_defense: int = 4
@export var base_speed: int = 8
@export var equipped_weapon: String = ""
@export var equipped_armor: String = ""
@export var equipped_seal: String = ""

# Inventario (objetos normales)
@export var inventory: Dictionary = {}

# Documentos (estructura de DocumentManager)
@export var documents: Dictionary = {}

# Estado del mundo (WorldStateManager)
@export var collected_items: Array[String] = []
@export var defeated_enemies: Array[String] = []
@export var opened_doors: Array[String] = []
@export var triggered_events: Array[String] = []
