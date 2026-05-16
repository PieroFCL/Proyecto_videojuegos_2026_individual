extends CanvasLayer

# Referencias UI
@onready var player_sprite: Sprite2D = $CombatUI/PlayerPortrait/PlayerSprite
@onready var enemy_sprite: Sprite2D = $CombatUI/EnemyPortrait/EnemySprite
@onready var player_hp_bar: ProgressBar = $CombatUI/PlayerPortrait/PlayerHPBar
@onready var enemy_hp_bar: ProgressBar = $CombatUI/EnemyPortrait/EnemyHPBar
@onready var message_label: Label = $CombatUI/MessagePanel/MessageLabel
@onready var close_button: Button = $CombatUI/CloseButton
@onready var combat_menu: Control = $CombatUI/CombatMenuUI

# Referencias opcionales a submenús preexistentes (si los has añadido en la escena)
@onready var skills_submenu_pre: Control = $CombatUI/SkillsSubmenu if has_node("CombatUI/SkillsSubmenu") else null
@onready var bag_submenu_pre: Control = $CombatUI/BagSubmenu if has_node("CombatUI/BagSubmenu") else null
@onready var status_submenu_pre: Control = $CombatUI/StatusSubmenu if has_node("CombatUI/StatusSubmenu") else null

# Datos del combate
var enemy: Enemy = null
var enemy_resource: EnemyResource = null
var enemy_current_hp: int = 0
var enemy_modifiers: Array[StatModifier] = []
var weakness_revealed: bool = false

# Estado del combate
enum CombatState { START, PLAYER_TURN, ENEMY_TURN, VICTORY, GAME_OVER }
var current_state: CombatState = CombatState.START

var player_speed: int = 0
var enemy_speed: int = 0
var is_processing_action: bool = false

# Submenú actual (solo se usa si se instancian dinámicamente)
var current_submenu: Control = null

var enemy_permanent_buffs: Dictionary = {}   # { "attack": { "value": 0, "stacks": 0, "max_stacks": 2 } }

func initialize_combat(enemy_node: Enemy) -> void:
	enemy = enemy_node
	enemy_resource = enemy_node.enemy_resource
	enemy_current_hp = enemy_resource.max_hp
	weakness_revealed = false
	enemy_modifiers.clear()
	enemy_permanent_buffs.clear()   
	PlayerStats.reset_combat_buffs() 
	
	# Configurar sprite del jugador
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("get_combat_texture"):
		player_sprite.texture = player_node.get_combat_texture()
		player_sprite.hframes = player_node.get_combat_hframes()
		player_sprite.vframes = player_node.get_combat_vframes()
		player_sprite.scale = player_node.get_combat_scale()
	else:
		player_sprite.texture = preload("res://Player/Sprites/idle_player_desarmado.png")
		player_sprite.hframes = 1
		player_sprite.vframes = 1
		player_sprite.scale = Vector2.ONE
	player_sprite.frame = 0
	
	# Configurar sprite del enemigo
	if enemy_resource and enemy_resource.combat_texture:
		enemy_sprite.texture = enemy_resource.combat_texture
		enemy_sprite.hframes = enemy_resource.combat_hframes
		enemy_sprite.vframes = enemy_resource.combat_vframes
		enemy_sprite.scale = enemy_resource.combat_scale
	else:
		enemy_sprite.texture = preload("res://icon.svg")
		enemy_sprite.hframes = 1
		enemy_sprite.vframes = 1
		enemy_sprite.scale = Vector2.ONE
	enemy_sprite.frame = 0
	
	# Barras de vida
	player_hp_bar.max_value = PlayerStats.current_max_hp
	player_hp_bar.value = PlayerStats.current_hp
	enemy_hp_bar.max_value = enemy_resource.max_hp
	enemy_hp_bar.value = enemy_current_hp
	
	# Conectar señales
	PlayerStats.health_changed.connect(_on_player_health_changed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Conectar señales del menú principal
	if combat_menu:
		var skills_btn = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		var bag_btn = combat_menu.get_node("Panel/VBoxContainer/BagButton")
		var status_btn = combat_menu.get_node("Panel/VBoxContainer/StatusButton")
		
		if skills_btn:
			skills_btn.pressed.connect(_on_skills_pressed)
		if bag_btn:
			bag_btn.pressed.connect(_on_bag_pressed)
		if status_btn:
			status_btn.pressed.connect(_on_status_pressed)
		
		combat_menu.visible = false  # Oculto hasta el turno del jugador
	
	# Velocidades
	player_speed = PlayerStats.current_speed
	enemy_speed = enemy_resource.speed
	
	message_label.text = "¡Combate iniciado!"
	await get_tree().create_timer(1.0).timeout
	
	# Determinar quién empieza
	if player_speed >= enemy_speed:
		current_state = CombatState.PLAYER_TURN
		message_label.text = "Tu turno"
	else:
		current_state = CombatState.ENEMY_TURN
		message_label.text = "Turno del enemigo"
	
	start_turn()

func start_turn() -> void:
	if current_state == CombatState.PLAYER_TURN:
		# Cerrar submenú si estaba abierto
		close_submenu()
		# Mostrar menú principal
		combat_menu.visible = true
		combat_menu.set_process_input(true)
		# Enfocar primer botón
		var first_button = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		if first_button:
			first_button.grab_focus()
	elif current_state == CombatState.ENEMY_TURN:
		combat_menu.visible = false
		await enemy_turn_action()
	elif current_state == CombatState.VICTORY:
		end_combat_with_victory()
	elif current_state == CombatState.GAME_OVER:
		pass

func enemy_turn_action() -> void:
	if is_processing_action:
		return
	is_processing_action = true
	
	# Procesar modificadores del enemigo (por ahora vacío)
	# Atacar
	var enemy_attack = enemy_resource.attack
	var enemy_defense = enemy_resource.defense
	# Aplicar debuffs permanentes al enemigo (si afectan ataque o defensa)
	if enemy_permanent_buffs.has("attack"):
		enemy_attack += enemy_permanent_buffs["attack"].value
	if enemy_permanent_buffs.has("defense"):
		enemy_defense += enemy_permanent_buffs["defense"].value
	var damage = max(1, enemy_attack - PlayerStats.current_defense)
	message_label.text = "El enemigo te ataca y causa %d de daño." % damage
	await get_tree().create_timer(1.0).timeout
	PlayerStats.take_damage(damage)
	await get_tree().create_timer(0.5).timeout
	
	if current_state == CombatState.GAME_OVER or current_state == CombatState.VICTORY:
		is_processing_action = false
		return
	
	current_state = CombatState.PLAYER_TURN
	message_label.text = "Tu turno"
	await get_tree().create_timer(0.5).timeout
	is_processing_action = false
	start_turn()

func _add_enemy_permanent_buff(stat: String, value: int, max_stacks: int = 2) -> void:
	if not enemy_permanent_buffs.has(stat):
		enemy_permanent_buffs[stat] = { "value": 0, "stacks": 0, "max_stacks": max_stacks }
	var buff = enemy_permanent_buffs[stat]
	if buff.stacks < buff.max_stacks:
		buff.value += value
		buff.stacks += 1

func execute_skill(skill: SkillResource) -> void:
	if current_state != CombatState.PLAYER_TURN or is_processing_action:
		return
	is_processing_action = true
	combat_menu.visible = false
	
	if skill.type == "physical" or skill.type == "magical":
		var enemy_defense = enemy_resource.defense
		if enemy_permanent_buffs.has("defense"):
			enemy_defense += enemy_permanent_buffs["defense"].value
		var base_damage = skill.damage + PlayerStats.current_attack - enemy_defense
		var damage = max(1, base_damage)
		
		# Multiplicador por debilidad (si el tipo coincide con la debilidad revelada)
		if weakness_revealed and skill.type == enemy_resource.weakness:
			damage = int(damage * 1.5)
			message_label.text = "¡Debilidad! "
		else:
			message_label.text = ""
		
		enemy_current_hp = max(0, enemy_current_hp - damage)
		enemy_hp_bar.value = enemy_current_hp
		message_label.text += "¡Usas %s! Causas %d de daño." % [skill.name, damage]
		
		# Revelar debilidad en el primer golpe
		if not weakness_revealed and skill.type in ["physical", "magical"]:
			weakness_revealed = true
			message_label.text += " ¡Has descubierto su debilidad!"
			
	elif skill.type == "buff":
		# Buff permanente sobre el jugador
		PlayerStats.add_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
		message_label.text = "¡Usas %s! %s aumenta en %d." % [skill.name, skill.effect_stat.capitalize(), skill.effect_value]
		
	elif skill.type == "debuff":
		# Debuff permanente sobre el enemigo (acumulable hasta max_stacks)
		# Por simplicidad, añadimos un modificador permanente al enemigo (manejado en combat_scene)
		# Aquí implementaremos un sistema similar al de PlayerStats, pero en la misma combat_scene
		_add_enemy_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
		message_label.text = "¡Usas %s! %s del enemigo disminuye en %d." % [skill.name, skill.effect_stat.capitalize(), abs(skill.effect_value)]

	await get_tree().create_timer(1.0).timeout
	
	if enemy_current_hp <= 0:
		current_state = CombatState.VICTORY
		message_label.text = "¡Enemigo derrotado!"
		await get_tree().create_timer(1.0).timeout
		end_combat_with_victory()
		return
	
	current_state = CombatState.ENEMY_TURN
	message_label.text = "Turno del enemigo"
	await get_tree().create_timer(0.5).timeout
	is_processing_action = false
	start_turn()

func use_item(item_id: String) -> void:
	if current_state != CombatState.PLAYER_TURN or is_processing_action:
		return
	is_processing_action = true
	combat_menu.visible = false
	
	var item = InventoryManager.get_item_resource(item_id)
	if not item or item.category != "consumable":
		message_label.text = "No puedes usar ese objeto aquí."
		await get_tree().create_timer(1.0).timeout
		is_processing_action = false
		start_turn()
		return
	
	# Aplicar efecto según tipo de consumible
	if item is ConsumableItem:
		# Curar si tiene hp_restore
		if item.hp_restore > 0:
			PlayerStats.heal(item.hp_restore)
			message_label.text = "Usas %s y recuperas %d HP." % [item.display_name, item.hp_restore]
		
		# Aplicar buff de estadística si tiene effect_stat
		if item.effect_stat != "":
			PlayerStats.add_modifier(item.effect_stat, item.effect_value, item.effect_duration)
			# Construir mensaje según estadística
			var stat_name = ""
			match item.effect_stat:
				"attack": stat_name = "Ataque"
				"defense": stat_name = "Defensa"
				"speed": stat_name = "Velocidad"
				_: stat_name = item.effect_stat.capitalize()
			message_label.text = "Usas %s. ¡%s aumenta en %d por %d turno(s)!" % [item.display_name, stat_name, item.effect_value, item.effect_duration]
		
		InventoryManager.remove_item(item_id, 1)
	
	await get_tree().create_timer(1.0).timeout
	
	# Cambiar turno al enemigo
	current_state = CombatState.ENEMY_TURN
	message_label.text = "Turno del enemigo"
	await get_tree().create_timer(0.5).timeout
	is_processing_action = false
	start_turn()

func open_skills_menu() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
	var skills = PlayerStats.get_combat_skills()
	if skills_submenu_pre:
		close_submenu()
		skills_submenu_pre.visible = true
		current_submenu = skills_submenu_pre
		skills_submenu_pre.initialize(skills)   # ahora pasa Array[SkillResource]
		skills_submenu_pre.skill_selected.connect(_on_skill_selected)
		skills_submenu_pre.closed.connect(_on_submenu_closed)
		combat_menu.visible = false
	else:
		var skills_submenu = preload("res://Combat/SkillsSubmenu.tscn").instantiate()
		add_child(skills_submenu)
		current_submenu = skills_submenu
		skills_submenu.initialize(skills)
		skills_submenu.skill_selected.connect(_on_skill_selected)
		skills_submenu.closed.connect(_on_submenu_closed)

func open_bag_menu() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
	if bag_submenu_pre:
		close_submenu()
		bag_submenu_pre.visible = true
		current_submenu = bag_submenu_pre
		bag_submenu_pre.initialize(self)
		bag_submenu_pre.item_used.connect(_on_item_used)
		bag_submenu_pre.closed.connect(_on_submenu_closed)
		combat_menu.visible = false
	else:
		var bag_submenu = preload("res://Combat/BagSubmenu.tscn").instantiate()
		add_child(bag_submenu)
		current_submenu = bag_submenu
		bag_submenu.initialize(self)
		bag_submenu.item_used.connect(_on_item_used)
		bag_submenu.closed.connect(_on_submenu_closed)

func open_status_menu() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
	if status_submenu_pre:
		close_submenu()
		status_submenu_pre.visible = true
		current_submenu = status_submenu_pre
		status_submenu_pre.initialize(self, player_speed, enemy_speed, weakness_revealed, enemy_resource.weakness)
		status_submenu_pre.closed.connect(_on_submenu_closed)
		combat_menu.visible = false
	else:
		var status_submenu = preload("res://Combat/StatusSubmenu.tscn").instantiate()
		add_child(status_submenu)
		current_submenu = status_submenu
		status_submenu.initialize(self, player_speed, enemy_speed, weakness_revealed, enemy_resource.weakness)
		status_submenu.closed.connect(_on_submenu_closed)

func _on_skill_selected(skill: SkillResource) -> void:
	close_submenu()
	execute_skill(skill)

func _on_item_used(item_id: String) -> void:
	close_submenu()
	use_item(item_id)

func _on_submenu_closed() -> void:
	close_submenu()
	if current_state == CombatState.PLAYER_TURN and not is_processing_action:
		combat_menu.visible = true
		var first_button = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		if first_button:
			first_button.grab_focus()

func close_submenu() -> void:
	if current_submenu:
		# Si es un nodo preexistente, solo lo ocultamos
		if current_submenu == skills_submenu_pre or current_submenu == bag_submenu_pre or current_submenu == status_submenu_pre:
			current_submenu.visible = false
			# Desconectar señales para evitar duplicados la próxima vez
			if current_submenu.has_signal("skill_selected"):
				current_submenu.skill_selected.disconnect(_on_skill_selected)
			if current_submenu.has_signal("item_used"):
				current_submenu.item_used.disconnect(_on_item_used)
			if current_submenu.has_signal("closed"):
				current_submenu.closed.disconnect(_on_submenu_closed)
		else:
			# Si es dinámico, lo liberamos
			current_submenu.queue_free()
		current_submenu = null

func _on_player_health_changed(new_hp: int, max_hp: int) -> void:
	player_hp_bar.value = new_hp
	player_hp_bar.max_value = max_hp
	if new_hp <= 0 and current_state != CombatState.GAME_OVER:
		current_state = CombatState.GAME_OVER
		message_label.text = "Has muerto..."
		combat_menu.visible = false
		close_submenu()
		await get_tree().create_timer(1.5).timeout
		CombatManager.end_combat(false)

func _on_close_button_pressed() -> void:
	CombatManager.end_combat(false)

func end_combat_with_victory() -> void:
	combat_menu.visible = false
	close_submenu()
	await get_tree().create_timer(1.0).timeout
	CombatManager.end_combat(true)

func _exit_tree() -> void:
	if PlayerStats.health_changed.is_connected(_on_player_health_changed):
		PlayerStats.health_changed.disconnect(_on_player_health_changed)

func _on_skills_pressed() -> void:
	open_skills_menu()

func _on_bag_pressed() -> void:
	open_bag_menu()

func _on_status_pressed() -> void:
	open_status_menu()
