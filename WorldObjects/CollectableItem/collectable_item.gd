extends Area2D
class_name CollectableItem

# Recurso que define este objeto (arrastrar desde el inspector)
@export var item_resource: ItemResource = null

# Efecto visual opcional (escena de partículas)
@export var pickup_effect: PackedScene = null

# Inicializa el objeto: lo añade al grupo, verifica colisiones, asigna textura y conecta señales
func _ready() -> void:
	add_to_group("collectable")
	print("CollectableItem listo: ", name)
	
	# Verificar colisiones
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape:
		print("Colisión válida")
	else:
		print("ERROR: CollisionShape2D sin forma")
	
	# Asignar textura y escalar
	if item_resource and item_resource.icon:
		$Sprite2D.texture = item_resource.icon
		apply_scale_from_texture()
	else:
		print("Advertencia: item_resource sin icono, usando placeholder")
		$Sprite2D.texture = preload("res://icon.svg")
	
	# Detectar cuando otro cuerpo entra en contacto
	body_entered.connect(_on_body_entered)
	
	# Asignar z_index normalizado solo para consumibles (pociones, elixires)
	if item_resource and item_resource.category == "consumable" and LevelManager.current_level_max_y > 0:
		z_index = int(global_position.y) + 500
	
# Se ejecuta cuando otro cuerpo (ej. el jugador) toca el objeto
func _on_body_entered(body: Node2D) -> void:
	print("Colisión detectada con: ", body.name)

# Llamado por el jugador al recoger el objeto, añade al inventario y lo elimina del mapa
func collect() -> void:
	if item_resource == null:
		push_error("CollectableItem: item_resource es null en ", name)
		return
	
	print("Recolectado: ", item_resource.id)
	InventoryManager.add_item(item_resource.id, 1)
	Events.item_collected.emit(item_resource.id)
	
	if pickup_effect:
		var effect = pickup_effect.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = global_position
	
	queue_free()

# Aplicar la escala desde la textura actual
func apply_scale_from_texture() -> void:
	if item_resource and item_resource.icon:
		var tex = $Sprite2D.texture
		if tex:
			var tex_size = tex.get_size()
			# Tamaño base (píxeles) para la dimensión mayor
			var desired_size = 16
			
			# Ajustar tamaño según la categoría del objeto
			match item_resource.category:
				"consumable":
					desired_size = 20   # Pociones
				"weapon":
					desired_size = 30   # Armas
				"armor":
					desired_size = 30   # Armaduras
				_:
					desired_size = 16   # Por defecto
			var scale_factor = desired_size / max(tex_size.x, tex_size.y)
			$Sprite2D.scale = Vector2(scale_factor, scale_factor)
