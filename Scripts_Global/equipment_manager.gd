extends Node
## Gestiona el equipamiento del jugador y notifica cambios a PlayerStats.

signal equipment_changed(slot: String, item_id: String)

func equip_weapon(item_id: String) -> void:
	PlayerStats.equip_weapon(item_id)
	equipment_changed.emit("weapon", item_id)

func equip_armor(item_id: String) -> void:
	PlayerStats.equip_armor(item_id)
	equipment_changed.emit("armor", item_id)

func unequip_weapon() -> void:
	PlayerStats.unequip_weapon()
	equipment_changed.emit("weapon", "")

func unequip_armor() -> void:
	PlayerStats.unequip_armor()
	equipment_changed.emit("armor", "")

# Nuevos métodos para sello
func equip_seal(item_id: String) -> void:
	PlayerStats.equip_seal(item_id)
	equipment_changed.emit("seal", item_id)

func unequip_seal() -> void:
	PlayerStats.unequip_seal()
	equipment_changed.emit("seal", "")
