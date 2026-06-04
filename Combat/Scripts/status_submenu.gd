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

func _ready() -> void:
	set_process_unhandled_input(true)
	# Conectar señales de PlayerStats para actualizaciones automáticas
	PlayerStats.stats_changed.connect(_update_display)
	PlayerStats.health_changed.connect(_update_display)

func initialize(combat_node: Node, _p_speed: int, _e_speed: int, weak_revealed: bool, weak_type: String) -> void:
	combat_scene = combat_node
	weakness_revealed = weak_revealed
	enemy_weakness = weak_type
	_update_display()

func _update_display(_new_hp = 0, _max_hp = 0) -> void:
	_update_player_panel()
	_update_enemy_panel()

func _update_player_panel() -> void:
	var player_stats = PlayerStats.get_stats_dictionary()
	var base_attack = PlayerStats.get_base_attack()
	var base_defense = PlayerStats.get_base_defense()
	var base_speed = PlayerStats.get_base_speed()
	
	var current_attack = player_stats.attack
	var current_defense = player_stats.defense
	var current_speed = player_stats.speed
	
	var attack_bonus = current_attack - base_attack
	var defense_bonus = current_defense - base_defense
	var speed_bonus = current_speed - base_speed
	
	var attack_str = "%d" % current_attack
	if attack_bonus != 0:
		attack_str += " (%+d)" % attack_bonus
	var defense_str = "%d" % current_defense
	if defense_bonus != 0:
		defense_str += " (%+d)" % defense_bonus
	var speed_str = "%d" % current_speed
	if speed_bonus != 0:
		speed_str += " (%+d)" % speed_bonus
	
	player_hp_label.text = "HP: %d/%d" % [player_stats.hp, player_stats.max_hp]
	player_stats_label.text = "Ataque: %s\nDefensa: %s\nVelocidad: %s" % [attack_str, defense_str, speed_str]
	
	# Efectos del jugador (permanentes + temporales)
	var permanent_buffs = PlayerStats.get_permanent_buffs()
	var temporal_mods = PlayerStats.get_active_modifiers()
	var all_effects = _merge_effects(permanent_buffs, temporal_mods)
	player_efectos_label.text = _format_effects(all_effects)

func _update_enemy_panel() -> void:
	if not combat_scene:
		return
	var enemy_current_hp = combat_scene.enemy_current_hp
	var enemy_max_hp = combat_scene.enemy_resource.max_hp
	enemy_hp_label.text = "HP: %d/%d" % [enemy_current_hp, enemy_max_hp]
	
	var weak_text = enemy_weakness.capitalize() if weakness_revealed else "???"
	enemy_debilidad_label.text = "Debilidad: %s" % weak_text
	
	# Efectos del enemigo (solo permanentes)
	var enemy_buffs = combat_scene.enemy_permanent_buffs
	var enemy_effects = []
	for stat in enemy_buffs:
		var data = enemy_buffs[stat]
		enemy_effects.append({
			"name": stat,
			"value": data.value,
			"stacks": data.stacks,
			"is_permanent": true
		})
	enemy_efectos_label.text = _format_effects(enemy_effects)

# Combina buffs permanentes y temporales
func _merge_effects(permanent: Dictionary, temporal: Array) -> Array:
	var effects = []
	for stat in permanent:
		var data = permanent[stat]
		effects.append({
			"name": stat,
			"value": data.value,
			"stacks": data.stacks,
			"is_permanent": true
		})
	for m in temporal:
		effects.append({
			"name": m.stat,
			"value": m.value,
			"stacks": 1,
			"is_permanent": false
		})
	return effects

func _format_effects(effects: Array) -> String:
	if effects.is_empty():
		return "Ninguno"
	var lines = []
	for e in effects:
		var stat_name = ""
		match e["name"]:
			"attack": stat_name = "Ataque"
			"defense": stat_name = "Defensa"
			"speed": stat_name = "Velocidad"
			_: stat_name = e["name"].capitalize()
		if e["is_permanent"]:
			lines.append("%s %+d (%d)" % [stat_name, e["value"], e["stacks"]])
		else:
			lines.append("%s %+d" % [stat_name, e["value"]])
	return "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	print("STATE_SUBMENU _unhandled_input: event=", event.as_text(), " visible=", visible)
	if event.is_action_pressed("menu_cancel") or event.is_action_released("menu_cancel"):
		closed.emit()
		_consume_event()
	elif event is InputEventKey and event.keycode == KEY_Q:
		closed.emit()
		_consume_event()

func _consume_event() -> void:
	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()

# Limpiar conexiones al salir (opcional pero recomendado)
func _exit_tree() -> void:
	if PlayerStats.stats_changed.is_connected(_update_display):
		PlayerStats.stats_changed.disconnect(_update_display)
	if PlayerStats.health_changed.is_connected(_update_display):
		PlayerStats.health_changed.disconnect(_update_display)

func reset_state() -> void:
	set_process_unhandled_input(true)
