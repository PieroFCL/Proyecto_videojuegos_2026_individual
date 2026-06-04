class_name DescriptionPanel extends Panel

@onready var title_label: RichTextLabel = $TitleItemLabel
# Etiqueta del nombre del objeto.
@onready var desc_label: RichTextLabel = $DescriptionItemLabel
# Etiqueta del texto narrativo (flavor_text).
@onready var stats_label: RichTextLabel = $StatsItemLabel
# Etiqueta de beneficios numéricos (ataque, defensa, curación, etc.).

# Muestra la descripción del objeto recibido.
func show_description(item_res: ItemResource) -> void:
	title_label.text = item_res.display_name
	var flavor = item_res.flavor_text if "flavor_text" in item_res else ""
	desc_label.text = flavor if not flavor.is_empty() else "Sin descripción adicional."
	stats_label.text = _get_stats_text(item_res)
	visible = true

# Oculta el panel de descripción.
func hide_description() -> void:
	visible = false

# Genera el texto de estadísticas según la categoría del objeto.
func _get_stats_text(item_res: ItemResource) -> String:
	match item_res.category:
		"consumable":
			if item_res.has_method("get_hp_restore"):
				return "▸ Restaura %d HP" % item_res.get_hp_restore()
		"weapon":
			if item_res.has_method("get_attack_bonus"):
				return "▸ Ataque +%d" % item_res.get_attack_bonus()
		"armor":
			if item_res.has_method("get_defense_bonus"):
				return "▸ Defensa +%d" % item_res.get_defense_bonus()
		"seal":
			return "▸ Otorga habilidades especiales"
	return ""
