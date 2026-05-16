class_name Player extends CharacterBody2D

var cardinal_direction: Vector2 = Vector2.DOWN  # Última dirección cardinal registrada
var direction: Vector2 = Vector2.ZERO           # Entrada de movimiento actual

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: PlayerStateMachine = $StateMachine

# Nodos de capas para equipamiento
@onready var body_sprite: Sprite2D = $Sprites/BodySprite
@onready var armor_sprite: Sprite2D = $Sprites/ArmorSprite
@onready var weapon_sprite: Sprite2D = $Sprites/WeaponSprite

# Nodos de interacción
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_indicator: Label = $InteractionIndicator
var current_collectable: CollectableItem = null

# Textura y frames para el combate (hoja de sprites)
@export var combat_texture: Texture2D = null
@export var combat_hframes: int = 1
@export var combat_vframes: int = 1
@export var combat_scale: Vector2 = Vector2(1.0, 1.0)

# Almacenar equipamiento actual y texturas precargadas
var current_weapon_id: String = ""        # ID del arma equipada
var current_armor_id: String = ""         # ID de la armadura equipada
var weapon_textures: Dictionary = {}      # Texturas del arma por estado (Idle, Walk, Pickup)
var armor_textures: Dictionary = {}       # Texturas de la armadura por estado

var can_act: bool = true

const DEBUG_MASK_ALL = false

# Inicializa el jugador y conecta señales
func _ready() -> void:
	state_machine.initialize(self)
	update_animation("idle")
	print("Capa jugador: ", collision_layer, " máscara: ", collision_mask)
	
	# Depuración de área de interacción
	print("Área interact - capa: ", interaction_area.collision_layer, " máscara: ", interaction_area.collision_mask)
	if DEBUG_MASK_ALL:
		print("Debug: máscara total")
		interaction_area.collision_mask = 0xFFFFFFFF
	
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	interaction_indicator.visible = false
	print("Indicador [E] oculto")
	
	# Conectar señales de equipamiento y estado
	EquipmentManager.equipment_changed.connect(_on_equipment_changed)
	state_machine.state_changed.connect(_on_state_changed)

# Procesa entrada de movimiento y sincroniza sprites de equipamiento
func _process(_delta: float) -> void:
	if not can_act or get_tree().paused:
		return
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction.length() > 1.0:
		direction = direction.normalized()

	if direction != Vector2.ZERO:
		cardinal_direction = get_cardinal(direction)

	# Sincronizar frame_coords de equipamiento (excepto en Pickup)
	var current_state = ""
	if state_machine.current_state:
		current_state = state_machine.current_state.name
	if current_state != "Pickup":
		if current_armor_id != "" and armor_sprite.texture:
			armor_sprite.frame_coords = body_sprite.frame_coords
		if current_weapon_id != "" and weapon_sprite.texture:
			weapon_sprite.frame_coords = body_sprite.frame_coords
	
	# Calcular z_index
	z_index = int(global_position.y) + 500

func set_can_act(value: bool) -> void:
	can_act = value
	if not can_act:
		# Opcional: detener cualquier movimiento actual
		velocity = Vector2.ZERO
	print("Jugador can_act = ", can_act)

# Método para obtener la textura de combate (podría cambiar con equipamiento)
func get_combat_texture() -> Texture2D:
	return combat_texture

func get_combat_hframes() -> int:
	return combat_hframes

func get_combat_vframes() -> int:
	return combat_vframes

func get_combat_scale() -> Vector2:
	return combat_scale

# Reduce la dirección a un eje cardinal dominante
func get_cardinal(dir: Vector2) -> Vector2:
	return Vector2(sign(dir.x), 0) if abs(dir.x) > abs(dir.y) else Vector2(0, sign(dir.y))

# Aplica movimiento y colisiones, verifica no estar en combate
func _physics_process(_delta: float) -> void:
	if not can_act or get_tree().paused:
		return
	move_and_slide()

# Devuelve la dirección actual de la animación (right/left/down/up)
func get_anim_direction() -> String:
	if direction != Vector2.ZERO:
		if abs(direction.x) > 0.1:
			return "right" if direction.x > 0 else "left"
		return "down" if direction.y > 0 else "up"

	if abs(cardinal_direction.x) > 0.1:
		return "right" if cardinal_direction.x > 0 else "left"
	return "down" if cardinal_direction.y > 0 else "up"

# Cambia la animación según el estado base y la dirección, actualiza texturas
func update_animation(base_state: String) -> void:
	var dir := get_anim_direction()
	var anim_name := base_state + "_" + dir + "_player_desarmado"
	var state_name = state_machine.current_state.name
	
	_update_weapon_visual(state_name)
	_update_armor_visual(state_name)
	
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# Ajusta la dirección cardinal del personaje cuando cambia la orientación (ej. al teletransportarse)
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

# ---- Sistema de sprites por equipamiento ----

# Actualiza las texturas del arma/armadura cuando se equipa o desequipa un objeto
func _on_equipment_changed(slot: String, item_id: String) -> void:
	if slot == "weapon":
		current_weapon_id = item_id
		var weapon_res = InventoryManager.get_item_resource(current_weapon_id)
		if weapon_res and weapon_res.has_method("get_texture_by_state"):
			weapon_textures["Idle"] = weapon_res.get_texture_by_state("Idle")
			weapon_textures["Walk"] = weapon_res.get_texture_by_state("Walk")
			weapon_textures["Pickup"] = weapon_res.get_texture_by_state("Pickup")
			print("Texturas arma cargadas")
		else:
			weapon_textures.clear()
			print("ERROR: Texturas arma no cargadas")
		_update_weapon_visual(state_machine.current_state.name)
	elif slot == "armor":
		current_armor_id = item_id
		var armor_res = InventoryManager.get_item_resource(current_armor_id)
		if armor_res and armor_res.has_method("get_texture_by_state"):
			armor_textures["Idle"] = armor_res.get_texture_by_state("Idle")
			armor_textures["Walk"] = armor_res.get_texture_by_state("Walk")
			armor_textures["Pickup"] = armor_res.get_texture_by_state("Pickup")
			print("Texturas armadura cargadas")
		else:
			armor_textures.clear()
			print("ERROR: Texturas armadura no cargadas")
		_update_armor_visual(state_machine.current_state.name)

# Asigna la textura del arma según el estado actual
func _update_weapon_visual(state_name: String) -> void:
	if current_weapon_id.is_empty() or not weapon_textures.has(state_name):
		weapon_sprite.texture = null
	else:
		weapon_sprite.texture = weapon_textures[state_name]

# Asigna la textura de la armadura según el estado actual (con depuración)
func _update_armor_visual(state_name: String) -> void:
	if current_armor_id.is_empty() or not armor_textures.has(state_name):
		armor_sprite.texture = null
	else:
		var tex = armor_textures[state_name]
		var _old_frame = armor_sprite.frame_coords
		armor_sprite.texture = tex
		if armor_sprite.texture:
			armor_sprite.texture = armor_sprite.texture

# Ajusta los vframes de las capas de equipamiento según el estado del jugador
func _on_state_changed(state_name: String) -> void:
	match state_name:
		"Pickup":
			weapon_sprite.vframes = 1
			armor_sprite.vframes = 1
		"Idle", "Walk", "WalkFast":
			weapon_sprite.vframes = 4
			armor_sprite.vframes = 4
	var visual_state = state_name
	if visual_state == "WalkFast":
		visual_state = "Walk"
	_update_weapon_visual(visual_state)
	_update_armor_visual(visual_state)

# ---- Métodos de recolección (interacción) ----

# Detecta entrada de área interactiva (objeto recolectable)
func _on_interaction_area_entered(area: Area2D) -> void:
	print("Área entró: ", area.name)
	if area is CollectableItem:
		current_collectable = area as CollectableItem
		interaction_indicator.visible = true
		print("  Objeto cerca")

# Detecta salida de área interactiva
func _on_interaction_area_exited(area: Area2D) -> void:
	print("Área salió: ", area.name)
	if area == current_collectable:
		current_collectable = null
		interaction_indicator.visible = false
		print("  Objeto ya no cerca")

# Maneja entrada de teclado (interacción y depuración)
func _input(event: InputEvent) -> void:
	if not can_act or get_tree().paused:
		return
	
	if event.is_action_pressed("interact"):
		print("Tecla E presionada, objeto: ", current_collectable)
		if current_collectable:
			print("Iniciar recogida")
			var pickup_state = $StateMachine/Pickup as StatePickup
			if pickup_state:
				pickup_state.collectable = current_collectable
				state_machine.change_state(pickup_state)
			else:
				print("ERROR: Estado Pickup no encontrado")
	
	# Depuración opcional (puedes eliminarlas o mantenerlas)
	if event.is_action_pressed("debug_inventory"):
		print("Inventario: ", InventoryManager.get_all_items())
	if event.is_action_pressed("debug_stats"):
		print(PlayerStats.get_stats_dictionary())
