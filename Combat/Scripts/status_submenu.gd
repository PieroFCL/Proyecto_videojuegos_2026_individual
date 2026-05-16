extends Control

signal closed

@onready var enemy_hp_label: Label = $EnemyPanel/VBoxContainer/HP
@onready var enemy_debilidad_label: Label = $EnemyPanel/VBoxContainer/Debilidad
@onready var enemy_efectos_label: Label = $EnemyPanel/VBoxContainer/Efectos

@onready var player_hp_label: Label = $PlayerPanel/VBoxContainer/HP
@onready var player_stats_label: Label = $PlayerPanel/VBoxContainer/Stats
@onready var player_efectos_label: Label = $PlayerPanel/VBoxContainer/Efectos

var combat_scene: Node = null
var weakness_revealed: bool = false
var enemy_weakness: String = ""

func initialize(combat_node: Node, p_speed: int, e_speed: int, weak_revealed: bool, weak_type: String) -> void:
	combat_scene = combat_node
	weakness_revealed = weak_revealed
	enemy_weakness = weak_type
	_update_display()

func _update_display() -> void:
	# ---- Panel del Jugador ----
	var player_stats = PlayerStats.get_stats_dictionary()
	var player_mods = PlayerStats.get_active_modifiers()
	player_hp_label.text = "HP: %d/%d" % [player_stats.hp, player_stats.max_hp]
	player_stats_label.text = "Ataque: %d\nDefensa: %d\nVelocidad: %d" % [player_stats.attack, player_stats.defense, player_stats.speed]
	player_efectos_label.text = _format_modifiers(player_mods)
	
	# ---- Panel del Enemigo ----
	var enemy_current_hp = combat_scene.enemy_current_hp
	var enemy_max_hp = combat_scene.enemy_resource.max_hp
	var enemy_mods = combat_scene.enemy_modifiers  # Array de StatModifier
	enemy_hp_label.text = "HP: %d/%d" % [enemy_current_hp, enemy_max_hp]
	
	var weak_text = enemy_weakness.capitalize() if weakness_revealed else "???"
	enemy_debilidad_label.text = "Debilidad: %s" % weak_text
	
	enemy_efectos_label.text = _format_modifiers(enemy_mods)

func _format_modifiers(mods: Array) -> String:
	if mods.is_empty():
		return "Ninguno"
	var lines = []
	for m in mods:
		var stat_name = ""
		match m.stat:
			"attack": stat_name = "Ataque"
			"defense": stat_name = "Defensa"
			"speed": stat_name = "Velocidad"
			_: stat_name = m.stat.capitalize()
		lines.append("%s %+d (%d turnos)" % [stat_name, m.value, m.remaining_turns])
	return "\n".join(lines)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		closed.emit()
