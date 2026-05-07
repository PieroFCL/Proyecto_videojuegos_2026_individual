class_name Player extends CharacterBody2D

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: PlayerStateMachine = $StateMachine

# ---- NUEVO: nodos de interacción ----
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_indicator: Label = $InteractionIndicator
var current_collectable: CollectableItem = null
# ------------------------------------

# DEBUG: cambiar a true para forzar que InteractionArea detecte todas las capas
const DEBUG_MASK_ALL = false  # <--- CAMBIA A true PARA PROBAR

func _ready() -> void:
	state_machine.initialize(self)
	update_animation("idle")
	print("Player - collision_layer: ", collision_layer, " mask: ", collision_mask)
	
	# ---- NUEVO: DEBUG de capas de InteractionArea ----
	print("=== VERIFICACIÓN InteractionArea ===")
	print("InteractionArea collision_layer (antes): ", interaction_area.collision_layer)
	print("InteractionArea collision_mask (antes): ", interaction_area.collision_mask)
	if DEBUG_MASK_ALL:
		print("🔧 MODO DEBUG: Forzando máscara a TODAS las capas")
		interaction_area.collision_mask = 0xFFFFFFFF  # Todas las capas
		print("Nueva máscara: ", interaction_area.collision_mask)
	# ------------------------------------
	
	# Conectar señales de interacción (CORREGIDO: usar area_entered/area_exited)
	print("Cargando InteractionArea: ", interaction_area)
	print("Cargando InteractionIndicator: ", interaction_indicator)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	interaction_indicator.visible = false
	print("InteractionIndicator inicialmente oculto")
	print("========================================\n")

func _process(_delta: float) -> void:
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction.length() > 1.0:
		direction = direction.normalized()

	if direction != Vector2.ZERO:
		cardinal_direction = get_cardinal(direction)

func get_cardinal(dir: Vector2) -> Vector2:
	return Vector2(sign(dir.x), 0) if abs(dir.x) > abs(dir.y) else Vector2(0, sign(dir.y))

func _physics_process(_delta: float) -> void:
	move_and_slide()

func get_anim_direction() -> String:
	if direction != Vector2.ZERO:
		if abs(direction.x) > 0.1:
			return "right" if direction.x > 0 else "left"
		return "down" if direction.y > 0 else "up"

	if abs(cardinal_direction.x) > 0.1:
		return "right" if cardinal_direction.x > 0 else "left"
	return "down" if cardinal_direction.y > 0 else "up"

func update_animation(base_state: String) -> void:
	var dir := get_anim_direction()
	var anim_name := base_state + "_" + dir + "_player_desarmado"

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# ---------- MÉTODO EXISTENTE (para transiciones) ----------
func set_facing_direction(new_direction: Vector2) -> void:
	new_direction = new_direction.normalized()
	if abs(new_direction.x) > 0.1:
		cardinal_direction = Vector2(sign(new_direction.x), 0)
	elif abs(new_direction.y) > 0.1:
		cardinal_direction = Vector2(0, sign(new_direction.y))
	else:
		return
	
	if state_machine and state_machine.current_state:
		var current_state_name = state_machine.current_state.name
		if current_state_name == "Idle":
			update_animation("idle")

# ---- MÉTODOS CORREGIDOS PARA RECOLECCIÓN (usan area_entered/area_exited) ----
func _on_interaction_area_entered(area: Area2D) -> void:
	print("Entró área: ", area.name, " - grupos: ", area.get_groups())
	if area is CollectableItem:
		current_collectable = area as CollectableItem
		interaction_indicator.visible = true
		print("  - ✅ current_collectable asignado, indicador visible")
	else:
		print("  - ❌ No es CollectableItem, ignorado")

func _on_interaction_area_exited(area: Area2D) -> void:
	print("Salió área: ", area.name)
	if area == current_collectable:
		current_collectable = null
		interaction_indicator.visible = false
		print("  - current_collectable liberado, indicador oculto")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("Tecla E presionada, current_collectable = ", current_collectable)
	if event.is_action_pressed("interact") and current_collectable:
		print("Llamando a transición a Pickup")
		var pickup_state = $StateMachine/Pickup as StatePickup
		if pickup_state:
			pickup_state.collectable = current_collectable
			state_machine.change_state(pickup_state)
		else:
			print("ERROR: Estado Pickup no encontrado en StateMachine")
	
	# ---- Para revisar inventario y estadísticas (sin modificar) ----
	if event.is_action_pressed("debug_inventory"):
		print("Inventario actual: ", InventoryManager.get_all_items())
	if event.is_action_pressed("debug_stats"):
		print(PlayerStats.get_stats_dictionary())
