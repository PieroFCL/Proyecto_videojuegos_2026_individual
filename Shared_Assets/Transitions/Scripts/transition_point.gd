extends Area2D
class_name TransitionPoint

# Ruta de la escena del nivel al que se teletransportará el jugador.
@export var target_level: String = ""

# Nombre del EntrancePoint dentro del nivel destino donde aparecerá el jugador.
@export var target_entrance: String = "entrance_inicial"

# Tiempo mínimo que debe transcurrir entre cualquier transición de nivel.
@export var global_cooldown: float = 1.5

# Momento de última transición registrada, compartido entre las TransitionPoint.
static var last_transition_time: float = 0.0

# Indica si este punto de transición puede activarse actualmente.
var can_transition: bool = true

# Conecta señal de entrada de cuerpo y configura la máscara para detectar jugador.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_mask = 4  # Detecta al jugador (capa 3 -> valor 4)
	print("TransitionPoint: ", name, " -> ", target_level, " : ", target_entrance)

# Se ejecuta cuando cuerpo entra en área, verifica cooldown y activa la transición.
func _on_body_entered(body: Node2D) -> void:
	# Ignora si este punto ya ha sido activado recientemente.
	if not can_transition:
		return
	# Solo reacciona al jugador (por grupo o nombre).
	if not (body.is_in_group("player") or body.name == "player"):
		return
	
	# Obtiene el tiempo actual en segundos.
	var current_time = Time.get_ticks_msec() / 1000.0
	# Si no ha pasado suficiente tiempo desde la última transición global, bloquea.
	if current_time - last_transition_time < global_cooldown:
		print("Transición bloqueada por cooldown global")
		return
	
	# Marca como activado y actualiza el tiempo global.
	can_transition = false
	last_transition_time = current_time
	_teleport()
	
	# Reactiva después de medio segundo para permitir futuras transiciones.
	await get_tree().create_timer(0.5).timeout
	can_transition = true

# Realiza cambio de nivel llamando al LevelManager con los parámetros de destino.
func _teleport() -> void:
	# Verifica que los datos de destino estén configurados.
	if target_level.is_empty():
		push_error("TransitionPoint: target_level no especificado.")
		return
	if target_entrance.is_empty():
		push_error("TransitionPoint: target_entrance no especificado.")
		return
	LevelManager.change_level(target_level, target_entrance)
