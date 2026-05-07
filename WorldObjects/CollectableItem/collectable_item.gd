extends Area2D
class_name CollectableItem

## Recurso que define este objeto (arrastrar desde el inspector)
@export var item_resource: ItemResource = null

## Efecto visual opcional (escena de partículas)
@export var pickup_effect: PackedScene = null

func _ready() -> void:
	add_to_group("collectable")
	print("=== COLLECTABLEITEM _ready() ===")
	print("Nombre: ", name)
	print("Grupos: ", get_groups())
	
	# Verificar capas de colisión
	print("collision_layer (numérico): ", collision_layer)
	print("collision_mask (numérico): ", collision_mask)
	
	# Verificar si tiene CollisionShape2D y si tiene forma válida
	var collision_shape = $CollisionShape2D
	if collision_shape:
		if collision_shape.shape:
			print("CollisionShape2D presente y tiene forma: ", collision_shape.shape.get_class())
			print("Tamaño/radio aproximado: ", collision_shape.shape.get_rect().size if collision_shape.shape.get_class() == "RectangleShape2D" else "circulo radio: ", collision_shape.shape.radius if collision_shape.shape.get_class() == "CircleShape2D" else "desconocido")
		else:
			print("ERROR: CollisionShape2D no tiene forma asignada")
	else:
		print("ERROR: No se encontró nodo CollisionShape2D como hijo directo")
	
	# Asignar textura
	if item_resource and item_resource.icon:
		$Sprite2D.texture = item_resource.icon
		print("Textura asignada desde item_resource.icon")
	elif item_resource:
		print("item_resource presente pero icon es null")
	else:
		print("item_resource es null, usando textura placeholder")
		$Sprite2D.texture = preload("res://icon.svg")
	
	# Conectar señal de entrada (opcional)
	body_entered.connect(_on_body_entered)
	print("==================================\n")

func _on_body_entered(body: Node2D) -> void:
	print("🔔 CollectableItem: colisión con ", body.name)
	pass

## Llamado por el jugador cuando interactúa con este objeto
func collect() -> void:
	print("CollectableItem.collect() llamado para ", name)
	if item_resource == null:
		push_error("CollectableItem: item_resource es null en ", name)
		return
	
	print("Añadiendo al inventario: ", item_resource.id)
	InventoryManager.add_item(item_resource.id, 1)
	Events.item_collected.emit(item_resource.id)
	
	if pickup_effect:
		var effect = pickup_effect.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = global_position
	
	queue_free()
