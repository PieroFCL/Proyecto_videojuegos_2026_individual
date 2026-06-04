class_name EquipmentPanel extends Panel

@onready var weapon_icon: TextureRect = $WeaponSlot/WeaponIcon
@onready var weapon_label: Label = $WeaponSlot/WeaponLabel
@onready var armor_icon: TextureRect = $ArmorSlot/ArmorIcon
@onready var armor_label: Label = $ArmorSlot/ArmorLabel
@onready var seal_icon: TextureRect = $MagicSlot/MagicIcon
@onready var seal_label: Label = $MagicSlot/MagicLabel

func _ready() -> void:
	EquipmentManager.equipment_changed.connect(_update_display)
	_update_display()

# Actualiza todos los slots al recibir señal.
func _update_display(_slot: String = "", _item_id: String = "") -> void:
	_update_slot("weapon", PlayerStats.equipped_weapon_id, weapon_icon, weapon_label)
	_update_slot("armor", PlayerStats.equipped_armor_id, armor_icon, armor_label)
	_update_slot("seal", PlayerStats.equipped_seal_id, seal_icon, seal_label)

# Actualiza un slot individual.
func _update_slot(category: String, item_id: String, icon_rect: TextureRect, label: Label) -> void:
	if item_id.is_empty():
		icon_rect.texture = null
		label.text = _get_default_name(category)
		return
	var res = InventoryManager.get_item_resource(item_id)
	if res:
		icon_rect.texture = res.icon
		label.text = res.display_name
	else:
		icon_rect.texture = null
		label.text = "Desconocido"

# Devuelve nombre por defecto según categoría.
func _get_default_name(category: String) -> String:
	match category:
		"weapon": return "Arma"
		"armor": return "Armadura"
		"seal": return "Sello"
	return ""
