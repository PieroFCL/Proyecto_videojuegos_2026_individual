extends Node
# Gestiona equipamiento y notifica cambios a PlayerStats.

# Señal emitida al equipar o desequipar un objeto.
signal equipment_changed(slot: String, item_id: String)

# Equipa un arma y notifica cambio.
func equip_weapon(item_id: String) -> void:
	PlayerStats.equip_weapon(item_id)
	equipment_changed.emit("weapon", item_id)

# Equipa una armadura y notifica cambio.
func equip_armor(item_id: String) -> void:
	PlayerStats.equip_armor(item_id)
	equipment_changed.emit("armor", item_id)

# Desequipa el arma actual y notifica.
func unequip_weapon() -> void:
	PlayerStats.unequip_weapon()
	equipment_changed.emit("weapon", "")

# Desequipa la armadura actual y notifica.
func unequip_armor() -> void:
	PlayerStats.unequip_armor()
	equipment_changed.emit("armor", "")

# Equipa un sello mágico y notifica cambio.
func equip_seal(item_id: String) -> void:
	PlayerStats.equip_seal(item_id)
	equipment_changed.emit("seal", item_id)

# Desequipa el sello actual y notifica.
func unequip_seal() -> void:
	PlayerStats.unequip_seal()
	equipment_changed.emit("seal", "")

# Fuerza actualización visual del equipamiento.
func force_equipment_refresh() -> void:
	# Emite señales para que player.gd actualice sprites.
	equipment_changed.emit("weapon", PlayerStats.equipped_weapon_id)
	equipment_changed.emit("armor", PlayerStats.equipped_armor_id)
	equipment_changed.emit("seal", PlayerStats.equipped_seal_id)
