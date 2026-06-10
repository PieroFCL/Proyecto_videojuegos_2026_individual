extends Area2D
# Objeto recolectable que se añade al inventario.

class_name CollectableItem

# Recurso con definición del objeto (icono, nombre, efectos).
@export var item_resource: ItemResource = null
# Efecto visual opcional (partículas) al recoger.
@export var pickup_effect: PackedScene = null
# Identificador único para persistencia (evita recolección múltiple).
@export var unique_id: String = ""

# Depuración: se ejecuta al salir del árbol.
func _exit_tree() -> void:
	print("CollectableItem _exit_tree(): ", name, " ha sido eliminado del árbol.")

# Configura el objeto, verifica persistencia y asigna gráficos.
func _ready() -> void:
	print("CollectableItem _ready(): ", name, " unique_id=", unique_id)
	# Si ya fue recogido antes, se elimina.
	if not unique_id.is_empty() and WorldStateManager.is_item_collected(unique_id):
		print("  Objeto ya recogido según WorldStateManager. Eliminando.")
		queue_free()
		return
	
	add_to_group("collectable")
	print("CollectableItem listo: ", name)
	
	# Verifica existencia de colisión.
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape:
		print("Colisión válida")
	else:
		print("ERROR: CollisionShape2D sin forma")
	
	# Asigna textura desde el recurso.
	if item_resource and item_resource.icon:
		$Sprite2D.texture = item_resource.icon
		apply_scale_from_texture()
	else:
		print("Advertencia: item_resource sin icono, usando placeholder")
		$Sprite2D.texture = preload("res://icon.svg")
	
	# Conecta señal de colisión con el jugador.
	body_entered.connect(_on_body_entered)
	
	# Ajusta profundidad (solo consumibles) según posición Y.
	if item_resource and item_resource.category == "consumable" and LevelManager.current_level_max_y > 0:
		z_index = int(global_position.y) + 500

# Detecta cuando el jugador colisiona con el objeto.
func _on_body_entered(body: Node2D) -> void:
	print("Colisión detectada con: ", body.name)

# Evita que collect() se ejecute más de una vez.
var _is_collected: bool = false

# Añade el objeto al inventario y lo elimina del mundo.
func collect() -> void:
	# Previene recolección múltiple.
	if _is_collected:
		print("AVISO: collect() ya fue llamado antes. Ignorando.")
		return
	_is_collected = true
	
	print("=== COLLECT INICIO ===")
	print("  Nombre del objeto: ", name)
	print("  unique_id: '", unique_id, "'")
	
	if item_resource == null:
		push_error("CollectableItem: item_resource es null en ", name)
		return
	
	print("  Recolectado: ", item_resource.id)
	InventoryManager.add_item(item_resource.id, 1)
	Events.item_collected.emit(item_resource.id)
	
	# Registra recogida en WorldStateManager para persistencia.
	if not unique_id.is_empty():
		print("  Registrando unique_id en WorldStateManager: ", unique_id)
		WorldStateManager.register_collected_item(unique_id)
	else:
		print("  unique_id vacío, no se registra persistencia.")
	
	# Instancia efecto visual si existe.
	if pickup_effect:
		var effect = pickup_effect.instantiate()
		get_tree().root.add_child(effect)
		effect.global_position = global_position
		print("  Efecto de recogida instanciado.")
	
	print("  Llamando a queue_free()...")
	queue_free()
	print("  queue_free() ejecutado. (Objeto eliminado al final del frame)")
	print("=== COLLECT FIN ===")

# Escala el sprite según la categoría del objeto.
func apply_scale_from_texture() -> void:
	if item_resource and item_resource.icon:
		var tex = $Sprite2D.texture
		if tex:
			var tex_size = tex.get_size()
			var desired_size = 16
			
			# Ajusta tamaño según tipo de objeto.
			match item_resource.category:
				"consumable":
					desired_size = 20
				"weapon":
					desired_size = 30
				"armor":
					desired_size = 30
				_:
					desired_size = 16
			var scale_factor = desired_size / max(tex_size.x, tex_size.y)
			$Sprite2D.scale = Vector2(scale_factor, scale_factor)
