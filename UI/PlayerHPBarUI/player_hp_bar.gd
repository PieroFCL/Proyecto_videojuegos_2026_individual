extends CanvasLayer

@onready var hp_bar: ProgressBar = $ProgressBar
@onready var hp_icon: TextureRect = $TextureRect
@onready var button_inventory: Control = $ButtonInventory   # Referencia al botón

var last_level_path: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	PlayerStats.health_changed.connect(_update_hp)
	_update_hp(PlayerStats.current_hp, PlayerStats.current_max_hp)

func _update_hp(new_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp

func _process(_delta: float) -> void:
	# Ocultar barra durante combate o menús
	visible = not get_tree().paused and CombatManager.combat_scene_instance == null
	
	# Actualizar visibilidad del botón solo en catacombs_01
	var current_path = _get_current_level_path()
	if current_path != last_level_path:
		last_level_path = current_path
		button_inventory.visible = current_path.ends_with("catacombs_01.tscn")

func _get_current_level_path() -> String:
	var root = get_tree().root
	var playground = root.get_node_or_null("Playground")
	if playground:
		var level_container = playground.get_node_or_null("CurrentLevelContainer")
		if level_container and level_container.get_child_count() > 0:
			var current_level = level_container.get_child(0)
			return current_level.scene_file_path
	return ""
