extends CanvasLayer

# Referencias UI (sin cambios)
@onready var body_sprite: Sprite2D = $CombatUI/PlayerPortrait/BodySprite
@onready var armor_sprite: Sprite2D = $CombatUI/PlayerPortrait/ArmorSprite
@onready var weapon_sprite: Sprite2D = $CombatUI/PlayerPortrait/WeaponSprite
@onready var enemy_sprite: Sprite2D = $CombatUI/EnemyPortrait/EnemySprite
@onready var player_hp_bar: ProgressBar = $CombatUI/PlayerPortrait/PlayerHPBar
@onready var enemy_hp_bar: ProgressBar = $CombatUI/EnemyPortrait/EnemyHPBar
@onready var message_label: Label = $CombatUI/MessagePanel/MessageLabel
@onready var close_button: Button = $CombatUI/CloseButton
@onready var combat_menu: Control = $CombatUI/CombatMenuUI

@onready var player_name_label: Label = $CombatUI/PlayerPortrait/PlayerName
@onready var player_hp_text: Label = $CombatUI/PlayerPortrait/PlayerHPText
@onready var enemy_name_label: Label = $CombatUI/EnemyPortrait/EnemyName
@onready var enemy_hp_text: Label = $CombatUI/EnemyPortrait/EnemyHPText

@onready var skills_submenu_pre: Control = $CombatUI/SkillsSubmenu if has_node("CombatUI/SkillsSubmenu") else null
@onready var bag_submenu_pre: Control = $CombatUI/BagSubmenu if has_node("CombatUI/BagSubmenu") else null
@onready var status_submenu_pre: Control = $CombatUI/StatusSubmenu if has_node("CombatUI/StatusSubmenu") else null

var enemy: Enemy = null
var enemy_resource: EnemyResource = null
var enemy_current_hp: int = 0
var enemy_modifiers: Array[StatModifier] = []
var weakness_revealed: bool = false

enum CombatState { START, PLAYER_TURN, ENEMY_TURN, VICTORY, GAME_OVER }
var current_state: CombatState = CombatState.START

var player_speed: int = 0
var enemy_speed: int = 0
var is_processing_action: bool = false

var current_submenu: Control = null
var enemy_skills: Array[SkillResource] = []
var enemy_permanent_buffs: Dictionary = {}

const MSG_SHORT: float = 0.5
const MSG_NORMAL: float = 1.0
const MSG_LONG: float = 1.5
const MSG_DEATH: float = 1.5
const MSG_VICTORY: float = 1.0

func initialize_combat(enemy_node: Enemy) -> void:
	enemy = enemy_node
	enemy_resource = enemy_node.enemy_resource
	enemy_current_hp = enemy_resource.max_hp
	weakness_revealed = false
	enemy_modifiers.clear()
	enemy_permanent_buffs.clear()   
	enemy_skills = enemy_resource.skills.duplicate()
	PlayerStats.reset_combat_buffs() 
	
	var player_node = get_tree().get_first_node_in_group("player")
	
	# --- CONFIGURAR SPRITE DEL CUERPO (base) ---
	if player_node and player_node.has_method("get_combat_body_texture"):
		body_sprite.texture = player_node.get_combat_body_texture()
		body_sprite.hframes = player_node.get_combat_hframes()
		body_sprite.vframes = player_node.get_combat_vframes()
		body_sprite.scale = player_node.get_combat_scale()
	else:
		body_sprite.texture = preload("res://Player/Sprites/idle_player_desarmado.png")
		body_sprite.hframes = 3
		body_sprite.vframes = 1
		body_sprite.scale = Vector2(0.45, 0.45)
	body_sprite.frame = 0

	# --- CONFIGURAR SPRITE DE ARMADURA (si existe) ---
# --- CONFIGURAR SPRITE DE ARMADURA (si existe) ---
	if player_node and player_node.has_method("get_combat_armor_texture"):
		var tex = player_node.get_combat_armor_texture()
		if tex:
			armor_sprite.texture = tex
			armor_sprite.frame = 0
			# Ocultar el cuerpo si la armadura tiene textura
			body_sprite.visible = false
			print("[CombatScene] Armadura asignada, cuerpo oculto.")
		else:
			armor_sprite.texture = null
			# Si no hay armadura, asegurar que el cuerpo sea visible
			body_sprite.visible = true
			print("[CombatScene] Sin armadura, cuerpo visible.")
	else:
		armor_sprite.texture = null
		body_sprite.visible = true
	
	# --- CONFIGURAR SPRITE DE ARMA (si existe) ---
	if player_node and player_node.has_method("get_combat_weapon_texture"):
		var tex = player_node.get_combat_weapon_texture()
		if tex:
			weapon_sprite.texture = tex
			weapon_sprite.hframes = player_node.get_combat_weapon_hframes()
			weapon_sprite.vframes = player_node.get_combat_weapon_vframes()
			weapon_sprite.scale = player_node.get_combat_weapon_scale()
			weapon_sprite.frame = 0
			print("[CombatScene] Arma asignada. texture=", tex, " hframes=", weapon_sprite.hframes, " vframes=", weapon_sprite.vframes)
		else:
			weapon_sprite.texture = null
			print("[CombatScene] Arma no tiene textura de combate (null)")
	else:
		weapon_sprite.texture = null
		print("[CombatScene] No se pudo obtener textura de arma (player_node sin método o sin arma)")
	
	
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
	
	player_name_label.text = "Jugador"
	enemy_name_label.text = enemy_resource.display_name
	player_hp_text.text = "%d/%d" % [PlayerStats.current_hp, PlayerStats.current_max_hp]
	enemy_hp_text.text = "%d/%d" % [enemy_current_hp, enemy_resource.max_hp]
	
	player_hp_bar.max_value = PlayerStats.current_max_hp
	player_hp_bar.value = PlayerStats.current_hp
	enemy_hp_bar.max_value = enemy_resource.max_hp
	enemy_hp_bar.value = enemy_current_hp
	
	PlayerStats.health_changed.connect(_on_player_health_changed)
	close_button.pressed.connect(_on_close_button_pressed)
	
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
		combat_menu.visible = false
		combat_menu.set_process_input(false)  # Inicialmente inactivo
	
	player_speed = PlayerStats.current_speed
	enemy_speed = enemy_resource.speed
	
	message_label.text = "¡Combate iniciado!"
	await get_tree().create_timer(MSG_NORMAL).timeout
	
	if player_speed >= enemy_speed:
		current_state = CombatState.PLAYER_TURN
		message_label.text = "Tu turno"
	else:
		current_state = CombatState.ENEMY_TURN
		message_label.text = "Turno del enemigo"
	start_turn()

func start_turn() -> void:
	if current_state == CombatState.PLAYER_TURN:
		close_submenu()
		combat_menu.visible = true
		combat_menu.set_process_input(true)
		combat_menu.process_mode = PROCESS_MODE_ALWAYS   # <--- AÑADIR
		var first_button = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		if first_button:
			first_button.grab_focus()
	elif current_state == CombatState.ENEMY_TURN:
		combat_menu.visible = false
		combat_menu.set_process_input(false)  # Desactivar entrada
		await enemy_turn_action()
	elif current_state == CombatState.VICTORY:
		end_combat_with_victory()
	elif current_state == CombatState.GAME_OVER:
		pass

# ---------- Funciones de submenús (corregidas) ----------
func open_skills_menu() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
	if current_submenu == skills_submenu_pre and skills_submenu_pre.visible:
		return
	close_submenu()
	
	var skills = PlayerStats.get_combat_skills()
	print("DEBUG open_skills_menu: habilidades obtenidas = ", skills.size())
	if skills.is_empty():
		print("  ¡ATENCIÓN! La lista de habilidades está vacía. Se añadirá un mensaje de error.")
	
	skills_submenu_pre.visible = true
	current_submenu = skills_submenu_pre
	skills_submenu_pre.initialize(skills)
	
	# Desconectar y reconectar señales
	if skills_submenu_pre.skill_selected.is_connected(_on_skill_selected):
		skills_submenu_pre.skill_selected.disconnect(_on_skill_selected)
	if skills_submenu_pre.closed.is_connected(_on_submenu_closed):
		skills_submenu_pre.closed.disconnect(_on_submenu_closed)
	skills_submenu_pre.skill_selected.connect(_on_skill_selected)
	skills_submenu_pre.closed.connect(_on_submenu_closed)
	
	# Desactivar completamente el menú principal
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	combat_menu.set_process_unhandled_input(false)
	combat_menu.process_mode = PROCESS_MODE_DISABLED
	combat_menu.focus_mode = Control.FOCUS_NONE
	
	# Liberar cualquier foco residual y dar tiempo para que la UI se estabilice
	get_viewport().gui_release_focus()
	await get_tree().process_frame
	
	# Asegurar que el submenú recibe eventos no manejados
	skills_submenu_pre.set_process_unhandled_input(true)
	
	# Si el submenú no tiene botones habilitados, enfocar el propio submenú
	# (ya se hace en initialize, pero lo reforzamos)
	var has_focusable_button = false
	for btn in skills_submenu_pre.slots:
		if not btn.disabled:
			has_focusable_button = true
			break
	if not has_focusable_button:
		skills_submenu_pre.grab_focus()
		print("open_skills_menu: no hay botones habilitados, se enfoca el propio submenú")
	else:
		# Si hay botones, asegurar que el primer botón esté enfocado
		skills_submenu_pre._focus_first_button()

func open_bag_menu() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
	if current_submenu == bag_submenu_pre and bag_submenu_pre.visible:
		return
	close_submenu()
	
	print("DEBUG: Abriendo menú de bolsa")
	bag_submenu_pre.visible = true
	current_submenu = bag_submenu_pre
	bag_submenu_pre.initialize(self)
	
	if bag_submenu_pre.item_used.is_connected(_on_item_used):
		bag_submenu_pre.item_used.disconnect(_on_item_used)
	if bag_submenu_pre.closed.is_connected(_on_submenu_closed):
		bag_submenu_pre.closed.disconnect(_on_submenu_closed)
	bag_submenu_pre.item_used.connect(_on_item_used)
	bag_submenu_pre.closed.connect(_on_submenu_closed)
	
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	combat_menu.set_process_unhandled_input(false)
	combat_menu.process_mode = PROCESS_MODE_DISABLED
	combat_menu.focus_mode = Control.FOCUS_NONE
	
	get_viewport().gui_release_focus()
	bag_submenu_pre.set_process_unhandled_input(true)
	await get_tree().process_frame
	
	if bag_submenu_pre._get_focusable_button_count() == 0:
		bag_submenu_pre.grab_focus()
	else:
		bag_submenu_pre._focus_first_button()

func open_status_menu() -> void:
	if current_state != CombatState.PLAYER_TURN:
		return
	if current_submenu == status_submenu_pre and status_submenu_pre.visible:
		return
	print("DEBUG: Abriendo menú de estado")
	if status_submenu_pre:
		close_submenu()
		status_submenu_pre.reset_state()                     # <--- NUEVO: reinicia estado interno
		status_submenu_pre.visible = true
		status_submenu_pre.set_process_unhandled_input(true) # <--- REACTIVAR
		current_submenu = status_submenu_pre
		status_submenu_pre.initialize(self, player_speed, enemy_speed, weakness_revealed, enemy_resource.weakness)
		if status_submenu_pre.closed.is_connected(_on_submenu_closed):
			status_submenu_pre.closed.disconnect(_on_submenu_closed)
		status_submenu_pre.closed.connect(_on_submenu_closed)
		combat_menu.visible = false
		combat_menu.set_process_input(false)
		combat_menu.set_process_unhandled_input(false)
		combat_menu.process_mode = PROCESS_MODE_DISABLED
		combat_menu.focus_mode = Control.FOCUS_NONE
	else:
		var status_submenu = preload("res://Combat/StatusSubmenu.tscn").instantiate()
		add_child(status_submenu)
		current_submenu = status_submenu
		status_submenu.set_process_unhandled_input(true)
		status_submenu.initialize(self, player_speed, enemy_speed, weakness_revealed, enemy_resource.weakness)
		status_submenu.closed.connect(_on_submenu_closed)
		combat_menu.visible = false
		combat_menu.set_process_input(false)
		combat_menu.set_process_unhandled_input(false)
		combat_menu.process_mode = PROCESS_MODE_DISABLED
		combat_menu.focus_mode = Control.FOCUS_NONE

func _on_skill_selected(skill: SkillResource) -> void:
	close_submenu()
	execute_skill(skill)

func _on_item_used(item_id: String) -> void:
	close_submenu()
	use_item(item_id)

func _on_submenu_closed() -> void:
	print("DEBUG: _on_submenu_closed llamado")
	close_submenu()

	if current_state == CombatState.PLAYER_TURN:
		# Esperar un frame para que la escena se estabilice
		await get_tree().process_frame

		# Reactivar menú principal
		combat_menu.visible = true
		combat_menu.set_process_input(true)
		combat_menu.set_process_unhandled_input(true)
		combat_menu.process_mode = PROCESS_MODE_ALWAYS
		combat_menu.focus_mode = Control.FOCUS_ALL

		# Liberar cualquier foco residual
		get_viewport().gui_release_focus()

		# Enfocar el primer botón y forzar actualización del cursor
		var first_button = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		if first_button:
			first_button.grab_focus()
			first_button.emit_signal("focus_entered")
			if combat_menu.has_method("force_focus_on_button"):
				combat_menu.force_focus_on_button(0)

		print("DEBUG: Menú principal restaurado y enfocado")

func close_submenu() -> void:
	if current_submenu == null:
		return
	# Desconectar señales según el tipo
	if current_submenu == skills_submenu_pre:
		if current_submenu.skill_selected.is_connected(_on_skill_selected):
			current_submenu.skill_selected.disconnect(_on_skill_selected)
		if current_submenu.closed.is_connected(_on_submenu_closed):
			current_submenu.closed.disconnect(_on_submenu_closed)
		# Reiniciar estado interno (opcional, pero recomendado)
		if current_submenu.has_method("reset_state"):
			current_submenu.reset_state()
	elif current_submenu == bag_submenu_pre:
		if current_submenu.item_used.is_connected(_on_item_used):
			current_submenu.item_used.disconnect(_on_item_used)
		if current_submenu.closed.is_connected(_on_submenu_closed):
			current_submenu.closed.disconnect(_on_submenu_closed)
		if current_submenu.has_method("reset_state"):
			current_submenu.reset_state()
	elif current_submenu == status_submenu_pre:
		if current_submenu.closed.is_connected(_on_submenu_closed):
			current_submenu.closed.disconnect(_on_submenu_closed)
		if current_submenu.has_method("reset_state"):
			current_submenu.reset_state()
	else:
		# Submenú dinámico: eliminar directamente
		current_submenu.queue_free()
		current_submenu = null
		return

	# Desactivar entrada y ocultar submenú
	current_submenu.set_process_input(false)
	current_submenu.set_process_unhandled_input(false)
	current_submenu.visible = false
	if current_submenu.has_focus():
		current_submenu.release_focus()
	current_submenu = null

# ---------- Resto de funciones (sin cambios, excepto pequeñas mejoras) ----------
func _select_enemy_skill() -> SkillResource:
	# (sin cambios, es extenso pero correcto)
	if enemy_skills.is_empty():
		return null
	
	var usable_skills: Array[SkillResource] = []
	for skill in enemy_skills:
		var can_use = true
		match skill.type:
			"buff":
				var current_stacks = enemy_permanent_buffs.get(skill.effect_stat, {}).get("stacks", 0)
				if current_stacks >= skill.max_stacks:
					can_use = false
			"debuff":
				var player_buffs = PlayerStats.get_permanent_buffs()
				var current_stacks = player_buffs.get(skill.effect_stat, {}).get("stacks", 0)
				if current_stacks >= skill.max_stacks:
					can_use = false
			_: pass
		if can_use:
			usable_skills.append(skill)
	
	if usable_skills.is_empty():
		for skill in enemy_skills:
			if skill.type in ["physical", "magical"]:
				usable_skills.append(skill)
				break
		if usable_skills.is_empty():
			return null
	
	var hp_percent = float(enemy_current_hp) / float(enemy_resource.max_hp)
	var player_permanent_buffs = PlayerStats.get_permanent_buffs()
	var player_temporal_mods = PlayerStats.get_active_modifiers()
	var player_has_buffs = not player_permanent_buffs.is_empty() or not player_temporal_mods.is_empty()
	
	var best_skill = null
	var best_score = -INF
	
	for skill in usable_skills:
		var score = 0.0
		match skill.type:
			"physical", "magical":
				score = 5.0
			"buff":
				score = 3.0
			"debuff":
				score = 4.0
		if skill.type == "buff" and skill.effect_stat == "defense":
			if hp_percent < 0.3:
				score += 5.0
			elif hp_percent < 0.5:
				score += 2.0
		if player_has_buffs and skill.type == "debuff":
			score += 4.0
		if skill.type in ["physical", "magical"] and hp_percent > 0.7:
			score += 2.0
		if skill.type == "buff" and skill.effect_stat == "attack" and hp_percent > 0.5:
			score += 1.0
		score += randf_range(-0.8, 0.8)
		if score > best_score:
			best_score = score
			best_skill = skill
	return best_skill if best_skill != null else usable_skills[0]

func _execute_enemy_skill(skill: SkillResource) -> void:
	match skill.type:
		"physical", "magical":
			var enemy_attack = enemy_resource.attack
			if enemy_permanent_buffs.has("attack"):
				enemy_attack += enemy_permanent_buffs["attack"].value
			var damage = max(1, skill.damage + enemy_attack - PlayerStats.current_defense)
			message_label.text = "El enemigo usa %s y causa %d de daño." % [skill.name, damage]
			await get_tree().create_timer(MSG_NORMAL).timeout
			PlayerStats.take_damage(damage)
		"buff":
			var applied = _add_enemy_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
			if applied:
				message_label.text = "El enemigo usa %s. Su %s aumenta en %d." % [skill.name, skill.effect_stat.capitalize(), skill.effect_value]
			else:
				message_label.text = "El enemigo usa %s. No tiene efecto (máximo alcanzado)." % skill.name
			await get_tree().create_timer(MSG_LONG).timeout
		"debuff":
			var applied = PlayerStats.add_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
			if applied:
				message_label.text = "El enemigo usa %s. Tu %s disminuye en %d." % [skill.name, skill.effect_stat.capitalize(), abs(skill.effect_value)]
			else:
				message_label.text = "El enemigo usa %s. No tiene efecto (ya tienes el máximo)." % skill.name
			await get_tree().create_timer(MSG_LONG).timeout

func enemy_turn_action() -> void:
	if is_processing_action:
		return
	is_processing_action = true
	var skill = _select_enemy_skill()
	if skill == null:
		var enemy_attack = enemy_resource.attack
		var _enemy_defense = enemy_resource.defense
		if enemy_permanent_buffs.has("attack"):
			enemy_attack += enemy_permanent_buffs["attack"].value
		if enemy_permanent_buffs.has("defense"):
			_enemy_defense += enemy_permanent_buffs["defense"].value
		var damage = max(1, enemy_attack - PlayerStats.current_defense)
		message_label.text = "El enemigo te ataca y causa %d de daño." % damage
		await get_tree().create_timer(MSG_NORMAL).timeout
		PlayerStats.take_damage(damage)
	else:
		await _execute_enemy_skill(skill)
	await get_tree().create_timer(MSG_SHORT).timeout
	if current_state == CombatState.GAME_OVER or current_state == CombatState.VICTORY:
		is_processing_action = false
		return
	current_state = CombatState.PLAYER_TURN
	message_label.text = "Tu turno"
	await get_tree().create_timer(MSG_SHORT).timeout
	is_processing_action = false
	start_turn()

func _add_enemy_permanent_buff(stat: String, value: int, max_stacks: int = 2) -> bool:
	if not enemy_permanent_buffs.has(stat):
		enemy_permanent_buffs[stat] = { "value": 0, "stacks": 0, "max_stacks": max_stacks }
	var buff = enemy_permanent_buffs[stat]
	if buff.stacks < buff.max_stacks:
		buff.value += value
		buff.stacks += 1
		return true
	return false

func execute_skill(skill: SkillResource) -> void:
	print("EJECUTANDO HABILIDAD")
	print("Nombre:", skill.name)
	print("Tipo:", skill.type)
	print("Daño:", skill.damage)
	print("Effect stat:", skill.effect_stat)
	print("Effect value:", skill.effect_value)
	
	if current_state != CombatState.PLAYER_TURN or is_processing_action:
		return
	is_processing_action = true
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	
	if skill.type == "physical" or skill.type == "magical":
		var enemy_defense = enemy_resource.defense
		if enemy_permanent_buffs.has("defense"):
			enemy_defense += enemy_permanent_buffs["defense"].value
		var base_damage = skill.damage + PlayerStats.current_attack - enemy_defense
		var damage = max(1, base_damage)
		if weakness_revealed and skill.type == enemy_resource.weakness:
			damage = int(damage * 1.5)
			message_label.text = "¡Debilidad! "
		else:
			message_label.text = ""
		enemy_current_hp = max(0, enemy_current_hp - damage)
		enemy_hp_bar.value = enemy_current_hp
		message_label.text += "¡Usas %s! Causas %d de daño." % [skill.name, damage]
		enemy_hp_text.text = "%d/%d" % [enemy_current_hp, enemy_resource.max_hp]
		if not weakness_revealed and skill.type in ["physical", "magical"]:
			weakness_revealed = true
			message_label.text += " ¡Has descubierto su debilidad!"
			await get_tree().create_timer(MSG_LONG).timeout
		else:
			await get_tree().create_timer(MSG_NORMAL).timeout
	elif skill.type == "buff":
		var applied = PlayerStats.add_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
		if applied:
			message_label.text = "¡Usas %s! %s aumenta en %d." % [skill.name, skill.effect_stat.capitalize(), skill.effect_value]
		else:
			message_label.text = "¡Usas %s! No tiene efecto (máximo alcanzado)." % skill.name
		await get_tree().create_timer(MSG_LONG).timeout
	elif skill.type == "debuff":
		var applied = _add_enemy_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
		if applied:
			message_label.text = "¡Usas %s! %s del enemigo disminuye en %d." % [skill.name, skill.effect_stat.capitalize(), abs(skill.effect_value)]
		else:
			message_label.text = "¡Usas %s! No tiene efecto (el enemigo ya tiene el máximo)." % skill.name
		await get_tree().create_timer(MSG_LONG).timeout
	
	if enemy_current_hp <= 0:
		current_state = CombatState.VICTORY
		message_label.text = "¡Enemigo derrotado!"
		await get_tree().create_timer(MSG_VICTORY).timeout
		end_combat_with_victory()
		return
	
	current_state = CombatState.ENEMY_TURN
	message_label.text = "Turno del enemigo"
	await get_tree().create_timer(MSG_SHORT).timeout
	is_processing_action = false
	start_turn()

func use_item(item_id: String) -> void:
	if current_state != CombatState.PLAYER_TURN or is_processing_action:
		return
	is_processing_action = true
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	
	var item = InventoryManager.get_item_resource(item_id)
	if not item or item.category != "consumable":
		message_label.text = "No puedes usar ese objeto aquí."
		await get_tree().create_timer(MSG_NORMAL).timeout
		is_processing_action = false
		start_turn()
		return
	
	if item is ConsumableItem:
		if item.hp_restore > 0:
			PlayerStats.heal(item.hp_restore)
			message_label.text = "Usas %s y recuperas %d HP." % [item.display_name, item.hp_restore]
		if item.effect_stat != "":
			PlayerStats.add_modifier(item.effect_stat, item.effect_value, item.effect_duration)
			var stat_name = ""
			match item.effect_stat:
				"attack": stat_name = "Ataque"
				"defense": stat_name = "Defensa"
				"speed": stat_name = "Velocidad"
				_: stat_name = item.effect_stat.capitalize()
			message_label.text = "Usas %s. ¡%s aumenta en %d por %d turno(s)!" % [item.display_name, stat_name, item.effect_value, item.effect_duration]
		InventoryManager.remove_item(item_id, 1)
	
	await get_tree().create_timer(MSG_NORMAL).timeout
	current_state = CombatState.ENEMY_TURN
	message_label.text = "Turno del enemigo"
	await get_tree().create_timer(MSG_SHORT).timeout
	is_processing_action = false
	start_turn()

func _on_player_health_changed(new_hp: int, max_hp: int) -> void:
	player_hp_bar.value = new_hp
	player_hp_bar.max_value = max_hp
	player_hp_text.text = "%d/%d" % [new_hp, max_hp] 
	if new_hp <= 0 and current_state != CombatState.GAME_OVER:
		current_state = CombatState.GAME_OVER
		message_label.text = "Has muerto..."
		combat_menu.visible = false
		combat_menu.set_process_input(false)
		close_submenu()
		await get_tree().create_timer(MSG_DEATH).timeout
		CombatManager.end_combat(false)

func _on_close_button_pressed() -> void:
	CombatManager.end_combat(false)

func end_combat_with_victory() -> void:
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	close_submenu()
	await get_tree().create_timer(MSG_VICTORY).timeout
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
