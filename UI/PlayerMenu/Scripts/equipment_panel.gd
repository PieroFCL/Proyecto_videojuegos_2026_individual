class_name EquipmentPanel extends Panel

# Icono del arma equipada.
@onready var weapon_icon: TextureRect = $WeaponSlot/WeaponIcon
# Etiqueta del arma equipada.
@onready var weapon_label: Label = $WeaponSlot/WeaponLabel
# Icono de la armadura equipada.
@onready var armor_icon: TextureRect = $ArmorSlot/ArmorIcon
# Etiqueta de la armadura equipada.
@onready var armor_label: Label = $ArmorSlot/ArmorLabel
# Icono del sello mágico equipado.
@onready var seal_icon: TextureRect = $MagicSlot/MagicIcon
# Etiqueta del sello mágico equipado.
@onready var seal_label: Label = $MagicSlot/MagicLabel

# Conecta señal de equipamiento y actualiza la UI.
func _ready() -> void:
	EquipmentManager.equipment_changed.connect(_update_display)
	_update_display()

# Actualiza todos los slots cuando cambia el equipamiento.
func _update_display(_slot: String = "", _item_id: String = "") -> void:
	_update_slot("weapon", PlayerStats.equipped_weapon_id, weapon_icon, weapon_label)
	_update_slot("armor", PlayerStats.equipped_armor_id, armor_icon, armor_label)
	_update_slot("seal", PlayerStats.equipped_seal_id, seal_icon, seal_label)

# Actualiza un slot individual (arma, armadura o sello).
func _update_slot(category: String, item_id: String, icon_rect: TextureRect, label: Label) -> void:
	# Si no hay objeto equipado, muestra texto por defecto.
	if item_id.is_empty():
		icon_rect.texture = null
		label.text = _get_default_name(category)
		return
	# Carga el recurso del objeto equipado.
	var res = InventoryManager.get_item_resource(item_id)
	if res:
		icon_rect.texture = res.icon
		label.text = res.display_name
	else:
		icon_rect.texture = null
		label.text = "Desconocido"

# Devuelve nombre genérico según la categoría del slot.
func _get_default_name(category: String) -> String:
	match category:
		"weapon": return "Arma"
		"armor": return "Armadura"
		"seal": return "Sello"
	return ""
