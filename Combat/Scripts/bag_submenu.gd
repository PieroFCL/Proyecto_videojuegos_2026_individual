extends Control

signal item_used(item_id: String)
signal closed

@onready var slot_vida: Button = $Panel/GridContainer/SlotVida
@onready var slot_ataque: Button = $Panel/GridContainer/SlotAtaque
@onready var slot_defensa: Button = $Panel/GridContainer/SlotDefensa
@onready var slot_velocidad: Button = $Panel/GridContainer/SlotVelocidad

var combat_scene: Node = null

# IDs esperados para cada tipo de consumible (deben coincidir con los archivos .tres)
const CONSUMABLE_IDS = {
	"vida": "consumables/elixir_vigor",
	"ataque": "consumables/tonico_furia",
	"defensa": "consumables/brebaje_escamas",
	"velocidad": "consumables/jarabe_sombra"
}

func initialize(combat_node: Node) -> void:
	combat_scene = combat_node
	_refresh_items()

func _refresh_items() -> void:
	var all_items = InventoryManager.get_all_items()
	
	# Actualizar cada ranura pasando el item_id y la cantidad
	_update_slot(slot_vida, CONSUMABLE_IDS["vida"], all_items.get(CONSUMABLE_IDS["vida"], 0))
	_update_slot(slot_ataque, CONSUMABLE_IDS["ataque"], all_items.get(CONSUMABLE_IDS["ataque"], 0))
	_update_slot(slot_defensa, CONSUMABLE_IDS["defensa"], all_items.get(CONSUMABLE_IDS["defensa"], 0))
	_update_slot(slot_velocidad, CONSUMABLE_IDS["velocidad"], all_items.get(CONSUMABLE_IDS["velocidad"], 0))
	
	# Enfocar la primera ranura no vacía
	for btn in [slot_vida, slot_ataque, slot_defensa, slot_velocidad]:
		if not btn.disabled:
			btn.grab_focus()
			break

func _update_slot(button: Button, item_id: String, quantity: int) -> void:
	if quantity > 0:
		var item_res = InventoryManager.get_item_resource(item_id)
		if item_res:
			# Construir primera línea: nombre + cantidad
			var line1 = "%s x%d" % [item_res.display_name, quantity]
			# Segunda línea: efecto (curación o buff)
			var line2 = ""
			if item_res.has_method("get_hp_restore") and item_res.get_hp_restore() > 0:
				line2 = "Restaura %d HP" % item_res.get_hp_restore()
			elif item_res.has_method("get_effect_stat") and item_res.effect_stat != "":
				# Consumible de mejora (buff temporal)
				var stat_name = ""
				match item_res.effect_stat:
					"attack": stat_name = "Ataque"
					"defense": stat_name = "Defensa"
					"speed": stat_name = "Velocidad"
					_: stat_name = item_res.effect_stat.capitalize()
				line2 = "%s +%d (%d turno)" % [stat_name, item_res.effect_value, item_res.effect_duration]
			else:
				line2 = "Efecto especial"
			
			button.text = line1 + "\n" + line2
			button.disabled = false
			# Reconectar señal (por si ya estaba conectada)
			if button.pressed.is_connected(_on_item_pressed):
				button.pressed.disconnect(_on_item_pressed)
			button.pressed.connect(_on_item_pressed.bind(item_id))
		else:
			# Si no se pudo cargar el recurso, mostrar error
			button.text = "Error\n---"
			button.disabled = true
	else:
		button.text = "---\n---"
		button.disabled = true

func _on_item_pressed(item_id: String) -> void:
	item_used.emit(item_id)
	closed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		closed.emit()
