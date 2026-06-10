extends Resource
# Datos guardados de un checkpoint para persistencia.
class_name CheckpointData

# Versión del formato de guardado.
@export var version: String = "1.0"
# Marca de tiempo del guardado.
@export var timestamp: String = ""

# Ruta del nivel actual.
@export var level_path: String = ""
# Posición del jugador en el mundo.
@export var player_position: Vector2 = Vector2.ZERO
# Dirección que mira el jugador al cargar.
@export var player_facing: Vector2 = Vector2.DOWN

# Vida actual del jugador.
@export var player_hp: int = 0
# Vida máxima base del jugador.
@export var base_max_hp: int = 90
# Ataque base del jugador.
@export var base_attack: int = 12
# Defensa base del jugador.
@export var base_defense: int = 4
# Velocidad base del jugador.
@export var base_speed: int = 8
# ID del arma equipada.
@export var equipped_weapon: String = ""
# ID de la armadura equipada.
@export var equipped_armor: String = ""
# ID del sello equipado.
@export var equipped_seal: String = ""

# Diccionario de inventario (ID -> cantidad).
@export var inventory: Dictionary = {}
# Estructura de documentos (colección -> página).
@export var documents: Dictionary = {}

# Objetos recolectados (IDs únicos).
@export var collected_items: Array[String] = []
# Enemigos únicos derrotados (IDs).
@export var defeated_enemies: Array[String] = []
# Puertas abiertas (IDs únicos).
@export var opened_doors: Array[String] = []
# Eventos únicos activados (IDs).
@export var triggered_events: Array[String] = []
