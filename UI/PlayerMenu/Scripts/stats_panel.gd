class_name StatsPanel extends Panel

@onready var hp_value: Label = $HPValue
@onready var attack_value: Label = $AttackValue
@onready var defense_value: Label = $DefenseValue
@onready var speed_value: Label = $SpeedValue

func _ready() -> void:
	PlayerStats.stats_changed.connect(_update_display)
	PlayerStats.health_changed.connect(_update_hp_only)
	_update_display()

func _update_display() -> void:
	var stats = PlayerStats.get_stats_dictionary()
	attack_value.text = str(stats["attack"])
	defense_value.text = str(stats["defense"])
	speed_value.text = str(stats["speed"])
	_update_hp_only()

func _update_hp_only(_new_hp = 0, _max_hp = 0) -> void:
	var stats = PlayerStats.get_stats_dictionary()
	hp_value.text = str(stats["hp"]) + " / " + str(stats["max_hp"])
