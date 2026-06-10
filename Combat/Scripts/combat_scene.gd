extends CanvasLayer
# Escena principal de combate por turnos.

# Sprite del cuerpo del jugador en combate.
@onready var body_sprite: Sprite2D = $CombatUI/PlayerPortrait/BodySprite
# Sprite de la armadura superpuesta.
@onready var armor_sprite: Sprite2D = $CombatUI/PlayerPortrait/ArmorSprite
# Sprite del arma superpuesta.
@onready var weapon_sprite: Sprite2D = $CombatUI/PlayerPortrait/WeaponSprite
# Sprite del enemigo en combate.
@onready var enemy_sprite: Sprite2D = $CombatUI/EnemyPortrait/EnemySprite
# Barra de vida del jugador.
@onready var player_hp_bar: ProgressBar = $CombatUI/PlayerPortrait/PlayerHPBar
# Barra de vida del enemigo.
@onready var enemy_hp_bar: ProgressBar = $CombatUI/EnemyPortrait/EnemyHPBar
# Etiqueta de mensajes del combate.
@onready var message_label: Label = $CombatUI/MessagePanel/MessageLabel
# Botón para cerrar el combate manualmente.
@onready var close_button: Button = $CombatUI/CloseButton
# Menú principal del combate (habilidades, bolsa, estado).
@onready var combat_menu: Control = $CombatUI/CombatMenuUI

# Nombre del jugador en la interfaz.
@onready var player_name_label: Label = $CombatUI/PlayerPortrait/PlayerName
# Texto numérico de vida del jugador.
@onready var player_hp_text: Label = $CombatUI/PlayerPortrait/PlayerHPText
# Nombre del enemigo en la interfaz.
@onready var enemy_name_label: Label = $CombatUI/EnemyPortrait/EnemyName
# Texto numérico de vida del enemigo.
@onready var enemy_hp_text: Label = $CombatUI/EnemyPortrait/EnemyHPText

# Referencia al submenú de habilidades (preinstanciado).
@onready var skills_submenu_pre: Control = $CombatUI/SkillsSubmenu if has_node("CombatUI/SkillsSubmenu") else null
# Referencia al submenú de bolsa (preinstanciado).
@onready var bag_submenu_pre: Control = $CombatUI/BagSubmenu if has_node("CombatUI/BagSubmenu") else null
# Referencia al submenú de estado (preinstanciado).
@onready var status_submenu_pre: Control = $CombatUI/StatusSubmenu if has_node("CombatUI/StatusSubmenu") else null

# Nodo del enemigo que inició el combate.
var enemy: Enemy = null
# Recurso de estadísticas del enemigo.
var enemy_resource: EnemyResource = null
# Vida actual del enemigo durante el combate.
var enemy_current_hp: int = 0
# Modificadores temporales del enemigo.
var enemy_modifiers: Array[StatModifier] = []
# Indica si la debilidad del enemigo fue revelada.
var weakness_revealed: bool = false

# Posibles estados del combate.
enum CombatState { START, PLAYER_TURN, ENEMY_TURN, VICTORY, GAME_OVER }
# Estado actual del combate.
var current_state: CombatState = CombatState.START

# Velocidad del jugador para orden de turnos.
var player_speed: int = 0
# Velocidad del enemigo para orden de turnos.
var enemy_speed: int = 0
# Evita acciones simultáneas durante el turno.
var is_processing_action: bool = false

# Submenú actualmente abierto.
var current_submenu: Control = null
# Lista de habilidades del enemigo (copia).
var enemy_skills: Array[SkillResource] = []
# Diccionario de buffos/debuffos permanentes del enemigo.
var enemy_permanent_buffs: Dictionary = {}

# Constantes de duración de mensajes.
const MSG_SHORT: float = 0.5
const MSG_NORMAL: float = 1.0
const MSG_LONG: float = 1.5
const MSG_DEATH: float = 1.5
const MSG_VICTORY: float = 1.0

# Configura el combate al iniciar.
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
	
	# Configura sprite base del cuerpo del jugador.
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

	# Configura sprite de armadura si existe.
	if player_node and player_node.has_method("get_combat_armor_texture"):
		var tex = player_node.get_combat_armor_texture()
		if tex:
			armor_sprite.texture = tex
			armor_sprite.frame = 0
			# Oculta el cuerpo si hay armadura.
			body_sprite.visible = false
			print("[CombatScene] Armadura asignada, cuerpo oculto.")
		else:
			armor_sprite.texture = null
			body_sprite.visible = true
			print("[CombatScene] Sin armadura, cuerpo visible.")
	else:
		armor_sprite.texture = null
		body_sprite.visible = true
	
	# Configura sprite de arma si existe.
	if player_node and player_node.has_method("get_combat_weapon_texture"):
		var tex = player_node.get_combat_weapon_texture()
		if tex:
			weapon_sprite.texture = tex
			weapon_sprite.hframes = player_node.get_combat_weapon_hframes()
			weapon_sprite.vframes = player_node.get_combat_weapon_vframes()
			weapon_sprite.scale = player_node.get_combat_weapon_scale()
			weapon_sprite.frame = 0
			print("[CombatScene] Arma asignada. texture=", tex)
		else:
			weapon_sprite.texture = null
			print("[CombatScene] Arma sin textura.")
	else:
		weapon_sprite.texture = null
		print("[CombatScene] No se obtuvo textura de arma.")
	
	# Configura sprite del enemigo.
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
	
	# Configura nombres y textos de vida.
	player_name_label.text = "Jugador"
	enemy_name_label.text = enemy_resource.display_name
	player_hp_text.text = "%d/%d" % [PlayerStats.current_hp, PlayerStats.current_max_hp]
	enemy_hp_text.text = "%d/%d" % [enemy_current_hp, enemy_resource.max_hp]
	
	# Configura barras de vida.
	player_hp_bar.max_value = PlayerStats.current_max_hp
	player_hp_bar.value = PlayerStats.current_hp
	enemy_hp_bar.max_value = enemy_resource.max_hp
	enemy_hp_bar.value = enemy_current_hp
	
	# Conecta señales de salud y botón cerrar.
	PlayerStats.health_changed.connect(_on_player_health_changed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Conecta botones del menú principal.
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
		combat_menu.set_process_input(false)
	
	# Guarda velocidades.
	player_speed = PlayerStats.current_speed
	enemy_speed = enemy_resource.speed
	
	# Muestra mensaje de inicio.
	message_label.text = "¡Combate iniciado!"
	await get_tree().create_timer(MSG_NORMAL).timeout
	
	# Determina quién empieza.
	if player_speed >= enemy_speed:
		current_state = CombatState.PLAYER_TURN
		message_label.text = "Tu turno"
	else:
		current_state = CombatState.ENEMY_TURN
		message_label.text = "Turno del enemigo"
	start_turn()

# Inicia el turno según el estado actual.
func start_turn() -> void:
	if current_state == CombatState.PLAYER_TURN:
		close_submenu()
		combat_menu.visible = true
		combat_menu.set_process_input(true)
		combat_menu.process_mode = PROCESS_MODE_ALWAYS
		var first_button = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		if first_button:
			first_button.grab_focus()
	elif current_state == CombatState.ENEMY_TURN:
		combat_menu.visible = false
		combat_menu.set_process_input(false)
		await enemy_turn_action()
	elif current_state == CombatState.VICTORY:
		end_combat_with_victory()
	elif current_state == CombatState.GAME_OVER:
		pass

# Abre el submenú de habilidades durante el turno del jugador.
func open_skills_menu() -> void:
	# Solo permite abrir en turno del jugador.
	if current_state != CombatState.PLAYER_TURN:
		return
	# Evita reabrir si ya está visible.
	if current_submenu == skills_submenu_pre and skills_submenu_pre.visible:
		return
	# Cierra cualquier submenú actual.
	close_submenu()
	
	# Obtiene habilidades del jugador.
	var skills = PlayerStats.get_combat_skills()
	print("DEBUG open_skills_menu: habilidades obtenidas = ", skills.size())
	if skills.is_empty():
		print("  ¡ATENCIÓN! La lista de habilidades está vacía.")
	
	# Muestra y configura el submenú.
	skills_submenu_pre.visible = true
	current_submenu = skills_submenu_pre
	skills_submenu_pre.initialize(skills)
	
	# Desconecta señales previas para evitar duplicados.
	if skills_submenu_pre.skill_selected.is_connected(_on_skill_selected):
		skills_submenu_pre.skill_selected.disconnect(_on_skill_selected)
	if skills_submenu_pre.closed.is_connected(_on_submenu_closed):
		skills_submenu_pre.closed.disconnect(_on_submenu_closed)
	# Conecta señales actualizadas.
	skills_submenu_pre.skill_selected.connect(_on_skill_selected)
	skills_submenu_pre.closed.connect(_on_submenu_closed)
	
	# Desactiva completamente el menú principal.
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	combat_menu.set_process_unhandled_input(false)
	combat_menu.process_mode = PROCESS_MODE_DISABLED
	combat_menu.focus_mode = Control.FOCUS_NONE
	
	# Libera foco residual y estabiliza UI.
	get_viewport().gui_release_focus()
	await get_tree().process_frame
	
	# Asegura que el submenú reciba eventos no manejados.
	skills_submenu_pre.set_process_unhandled_input(true)
	
	# Verifica si hay botones habilitados en el submenú.
	var has_focusable_button = false
	for btn in skills_submenu_pre.slots:
		if not btn.disabled:
			has_focusable_button = true
			break
	# Enfoca el propio submenú si no hay botones.
	if not has_focusable_button:
		skills_submenu_pre.grab_focus()
		print("open_skills_menu: no hay botones habilitados, se enfoca propio submenú")
	else:
		# Enfoca el primer botón si existen.
		skills_submenu_pre._focus_first_button()

# Abre el submenú de bolsa (consumibles).
func open_bag_menu() -> void:
	# Solo durante el turno del jugador.
	if current_state != CombatState.PLAYER_TURN:
		return
	# Evita abrir si ya está visible.
	if current_submenu == bag_submenu_pre and bag_submenu_pre.visible:
		return
	# Cierra cualquier submenú actual.
	close_submenu()
	
	print("DEBUG: Abriendo menú de bolsa")
	# Muestra y configura el submenú de bolsa.
	bag_submenu_pre.visible = true
	current_submenu = bag_submenu_pre
	bag_submenu_pre.initialize(self)
	
	# Desconecta señales previas para evitar duplicados.
	if bag_submenu_pre.item_used.is_connected(_on_item_used):
		bag_submenu_pre.item_used.disconnect(_on_item_used)
	if bag_submenu_pre.closed.is_connected(_on_submenu_closed):
		bag_submenu_pre.closed.disconnect(_on_submenu_closed)
	# Conecta señales actualizadas.
	bag_submenu_pre.item_used.connect(_on_item_used)
	bag_submenu_pre.closed.connect(_on_submenu_closed)
	
	# Desactiva el menú principal.
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	combat_menu.set_process_unhandled_input(false)
	combat_menu.process_mode = PROCESS_MODE_DISABLED
	combat_menu.focus_mode = Control.FOCUS_NONE
	
	# Libera foco y estabiliza UI.
	get_viewport().gui_release_focus()
	bag_submenu_pre.set_process_unhandled_input(true)
	await get_tree().process_frame
	
	# Enfoca el propio menú si no hay botones.
	if bag_submenu_pre._get_focusable_button_count() == 0:
		bag_submenu_pre.grab_focus()
	else:
		# Enfoca el primer botón si existen.
		bag_submenu_pre._focus_first_button()

# Abre el submenú de estado (estadísticas y efectos).
func open_status_menu() -> void:
	# Solo durante el turno del jugador.
	if current_state != CombatState.PLAYER_TURN:
		return
	# Evita reabrir si ya está visible.
	if current_submenu == status_submenu_pre and status_submenu_pre.visible:
		return
	print("DEBUG: Abriendo menú de estado")
	if status_submenu_pre:
		# Cierra submenú anterior y restablece estado.
		close_submenu()
		status_submenu_pre.reset_state()
		status_submenu_pre.visible = true
		status_submenu_pre.set_process_unhandled_input(true)
		current_submenu = status_submenu_pre
		status_submenu_pre.initialize(self, player_speed, enemy_speed, weakness_revealed, enemy_resource.weakness)
		# Desconecta y reconecta señal de cierre.
		if status_submenu_pre.closed.is_connected(_on_submenu_closed):
			status_submenu_pre.closed.disconnect(_on_submenu_closed)
		status_submenu_pre.closed.connect(_on_submenu_closed)
		# Desactiva menú principal.
		combat_menu.visible = false
		combat_menu.set_process_input(false)
		combat_menu.set_process_unhandled_input(false)
		combat_menu.process_mode = PROCESS_MODE_DISABLED
		combat_menu.focus_mode = Control.FOCUS_NONE
	else:
		# Crea submenú dinámico si no existe preinstanciado.
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

# Ejecuta la habilidad seleccionada y cierra submenú.
func _on_skill_selected(skill: SkillResource) -> void:
	close_submenu()
	execute_skill(skill)

# Usa el objeto seleccionado y cierra submenú.
func _on_item_used(item_id: String) -> void:
	close_submenu()
	use_item(item_id)

# Maneja cierre de submenú y restaura menú principal.
func _on_submenu_closed() -> void:
	print("DEBUG: _on_submenu_closed llamado")
	close_submenu()

	if current_state == CombatState.PLAYER_TURN:
		# Espera un frame para estabilizar escena.
		await get_tree().process_frame

		# Reactiva el menú principal.
		combat_menu.visible = true
		combat_menu.set_process_input(true)
		combat_menu.set_process_unhandled_input(true)
		combat_menu.process_mode = PROCESS_MODE_ALWAYS
		combat_menu.focus_mode = Control.FOCUS_ALL

		# Libera foco residual.
		get_viewport().gui_release_focus()

		# Enfoca el primer botón y actualiza cursor.
		var first_button = combat_menu.get_node("Panel/VBoxContainer/SkillsButton")
		if first_button:
			first_button.grab_focus()
			first_button.emit_signal("focus_entered")
			if combat_menu.has_method("force_focus_on_button"):
				combat_menu.force_focus_on_button(0)

		print("DEBUG: Menú principal restaurado y enfocado")

# Cierra el submenú actual y restaura el menú principal.
func close_submenu() -> void:
	# Sale si no hay submenú activo.
	if current_submenu == null:
		return
	# Desconecta señales según el tipo de submenú.
	if current_submenu == skills_submenu_pre:
		if current_submenu.skill_selected.is_connected(_on_skill_selected):
			current_submenu.skill_selected.disconnect(_on_skill_selected)
		if current_submenu.closed.is_connected(_on_submenu_closed):
			current_submenu.closed.disconnect(_on_submenu_closed)
		# Reinicia estado interno del submenú.
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
		# Submenú dinámico: elimina directamente.
		current_submenu.queue_free()
		current_submenu = null
		return

	# Desactiva procesamiento de entrada y oculta el submenú.
	current_submenu.set_process_input(false)
	current_submenu.set_process_unhandled_input(false)
	current_submenu.visible = false
	# Libera el foco si lo tenía.
	if current_submenu.has_focus():
		current_submenu.release_focus()
	current_submenu = null

# Selecciona la habilidad más adecuada para el enemigo.
func _select_enemy_skill() -> SkillResource:
	# Retorna null si no hay habilidades.
	if enemy_skills.is_empty():
		return null
	
	# Filtra habilidades usables según acumulación máxima.
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
	
	# Si no hay usables, busca una ofensiva.
	if usable_skills.is_empty():
		for skill in enemy_skills:
			if skill.type in ["physical", "magical"]:
				usable_skills.append(skill)
				break
		if usable_skills.is_empty():
			return null
	
	# Calcula puntuación para cada habilidad según situación.
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
		# Bonificaciones según contexto.
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
		# Factor aleatorio para evitar predecibilidad.
		score += randf_range(-0.8, 0.8)
		if score > best_score:
			best_score = score
			best_skill = skill
	# Retorna la mejor habilidad o la primera usable.
	return best_skill if best_skill != null else usable_skills[0]

# Ejecuta la habilidad del enemigo según su tipo.
func _execute_enemy_skill(skill: SkillResource) -> void:
	# Daño físico o mágico.
	match skill.type:
		"physical", "magical":
			var enemy_attack = enemy_resource.attack
			if enemy_permanent_buffs.has("attack"):
				enemy_attack += enemy_permanent_buffs["attack"].value
			var damage = max(1, skill.damage + enemy_attack - PlayerStats.current_defense)
			message_label.text = "El enemigo usa %s y causa %d de daño." % [skill.name, damage]
			await get_tree().create_timer(MSG_NORMAL).timeout
			PlayerStats.take_damage(damage)
		# Buff propio del enemigo.
		"buff":
			var applied = _add_enemy_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
			if applied:
				message_label.text = "El enemigo usa %s. Su %s aumenta en %d." % [skill.name, skill.effect_stat.capitalize(), skill.effect_value]
			else:
				message_label.text = "El enemigo usa %s. No tiene efecto (máximo alcanzado)." % skill.name
			await get_tree().create_timer(MSG_LONG).timeout
		# Debuff al jugador.
		"debuff":
			var applied = PlayerStats.add_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
			if applied:
				message_label.text = "El enemigo usa %s. Tu %s disminuye en %d." % [skill.name, skill.effect_stat.capitalize(), abs(skill.effect_value)]
			else:
				message_label.text = "El enemigo usa %s. No tiene efecto (ya tienes el máximo)." % skill.name
			await get_tree().create_timer(MSG_LONG).timeout

# Ejecuta la acción del turno del enemigo.
func enemy_turn_action() -> void:
	# Evita acciones simultáneas.
	if is_processing_action:
		return
	is_processing_action = true
	# Selecciona una habilidad o ataque básico.
	var skill = _select_enemy_skill()
	if skill == null:
		# Ataque básico (daño físico puro).
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
	# Pequeña pausa después de la acción.
	await get_tree().create_timer(MSG_SHORT).timeout
	# Si el combate terminó, no continúa.
	if current_state == CombatState.GAME_OVER or current_state == CombatState.VICTORY:
		is_processing_action = false
		return
	# Cambia al turno del jugador.
	current_state = CombatState.PLAYER_TURN
	message_label.text = "Tu turno"
	await get_tree().create_timer(MSG_SHORT).timeout
	is_processing_action = false
	start_turn()

# Añade un buff/debuff permanente al enemigo si no alcanzó el máximo.
func _add_enemy_permanent_buff(stat: String, value: int, max_stacks: int = 2) -> bool:
	# Crea entrada si no existe.
	if not enemy_permanent_buffs.has(stat):
		enemy_permanent_buffs[stat] = { "value": 0, "stacks": 0, "max_stacks": max_stacks }
	var buff = enemy_permanent_buffs[stat]
	# Aplica solo si hay espacio para acumular.
	if buff.stacks < buff.max_stacks:
		buff.value += value
		buff.stacks += 1
		return true
	return false

# Ejecuta la habilidad seleccionada por el jugador.
func execute_skill(skill: SkillResource) -> void:
	# Muestra información de depuración.
	print("EJECUTANDO HABILIDAD")
	print("Nombre:", skill.name)
	print("Tipo:", skill.type)
	print("Daño:", skill.damage)
	print("Effect stat:", skill.effect_stat)
	print("Effect value:", skill.effect_value)
	
	# Verifica que sea el turno correcto y no haya acción en curso.
	if current_state != CombatState.PLAYER_TURN or is_processing_action:
		return
	is_processing_action = true
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	
	# Habilidad de daño físico o mágico.
	if skill.type == "physical" or skill.type == "magical":
		var enemy_defense = enemy_resource.defense
		# Aplica buffs de defensa del enemigo.
		if enemy_permanent_buffs.has("defense"):
			enemy_defense += enemy_permanent_buffs["defense"].value
		var base_damage = skill.damage + PlayerStats.current_attack - enemy_defense
		var damage = max(1, base_damage)
		# Multiplica daño si hay debilidad revelada y coincide.
		if weakness_revealed and skill.type == enemy_resource.weakness:
			damage = int(damage * 1.5)
			message_label.text = "¡Debilidad! "
		else:
			message_label.text = ""
		# Aplica daño al enemigo y actualiza UI.
		enemy_current_hp = max(0, enemy_current_hp - damage)
		enemy_hp_bar.value = enemy_current_hp
		message_label.text += "¡Usas %s! Causas %d de daño." % [skill.name, damage]
		enemy_hp_text.text = "%d/%d" % [enemy_current_hp, enemy_resource.max_hp]
		# Revela debilidad en el primer golpe ofensivo.
		if not weakness_revealed and skill.type in ["physical", "magical"]:
			weakness_revealed = true
			message_label.text += " ¡Has descubierto su debilidad!"
			await get_tree().create_timer(MSG_LONG).timeout
		else:
			await get_tree().create_timer(MSG_NORMAL).timeout
	# Habilidad de buff al jugador.
	elif skill.type == "buff":
		var applied = PlayerStats.add_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
		if applied:
			message_label.text = "¡Usas %s! %s aumenta en %d." % [skill.name, skill.effect_stat.capitalize(), skill.effect_value]
		else:
			message_label.text = "¡Usas %s! No tiene efecto (máximo alcanzado)." % skill.name
		await get_tree().create_timer(MSG_LONG).timeout
	# Habilidad de debuff al enemigo.
	elif skill.type == "debuff":
		var applied = _add_enemy_permanent_buff(skill.effect_stat, skill.effect_value, skill.max_stacks)
		if applied:
			message_label.text = "¡Usas %s! %s del enemigo disminuye en %d." % [skill.name, skill.effect_stat.capitalize(), abs(skill.effect_value)]
		else:
			message_label.text = "¡Usas %s! No tiene efecto (el enemigo ya tiene el máximo)." % skill.name
		await get_tree().create_timer(MSG_LONG).timeout
	
	# Verifica si el enemigo fue derrotado.
	if enemy_current_hp <= 0:
		current_state = CombatState.VICTORY
		message_label.text = "¡Enemigo derrotado!"
		await get_tree().create_timer(MSG_VICTORY).timeout
		end_combat_with_victory()
		return
	
	# Cambia al turno del enemigo.
	current_state = CombatState.ENEMY_TURN
	message_label.text = "Turno del enemigo"
	await get_tree().create_timer(MSG_SHORT).timeout
	is_processing_action = false
	start_turn()

# Usa un objeto consumible durante el combate.
func use_item(item_id: String) -> void:
	# Solo permite usar en turno del jugador y sin acción en curso.
	if current_state != CombatState.PLAYER_TURN or is_processing_action:
		return
	is_processing_action = true
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	
	var item = InventoryManager.get_item_resource(item_id)
	# Verifica que el objeto sea consumible.
	if not item or item.category != "consumable":
		message_label.text = "No puedes usar ese objeto aquí."
		await get_tree().create_timer(MSG_NORMAL).timeout
		is_processing_action = false
		start_turn()
		return
	
	if item is ConsumableItem:
		# Aplica curación si tiene hp_restore.
		if item.hp_restore > 0:
			PlayerStats.heal(item.hp_restore)
			message_label.text = "Usas %s y recuperas %d HP." % [item.display_name, item.hp_restore]
		# Aplica buff temporal si tiene effect_stat.
		if item.effect_stat != "":
			PlayerStats.add_modifier(item.effect_stat, item.effect_value, item.effect_duration)
			var stat_name = ""
			match item.effect_stat:
				"attack": stat_name = "Ataque"
				"defense": stat_name = "Defensa"
				"speed": stat_name = "Velocidad"
				_: stat_name = item.effect_stat.capitalize()
			message_label.text = "Usas %s. ¡%s aumenta en %d por %d turno(s)!" % [item.display_name, stat_name, item.effect_value, item.effect_duration]
		# Elimina el objeto del inventario.
		InventoryManager.remove_item(item_id, 1)
	
	# Pausa y cambia turno al enemigo.
	await get_tree().create_timer(MSG_NORMAL).timeout
	current_state = CombatState.ENEMY_TURN
	message_label.text = "Turno del enemigo"
	await get_tree().create_timer(MSG_SHORT).timeout
	is_processing_action = false
	start_turn()

# Actualiza barra de vida al recibir daño o curación.
func _on_player_health_changed(new_hp: int, max_hp: int) -> void:
	player_hp_bar.value = new_hp
	player_hp_bar.max_value = max_hp
	player_hp_text.text = "%d/%d" % [new_hp, max_hp] 
	# Si el jugador muere, termina combate con derrota.
	if new_hp <= 0 and current_state != CombatState.GAME_OVER:
		current_state = CombatState.GAME_OVER
		message_label.text = "Has muerto..."
		combat_menu.visible = false
		combat_menu.set_process_input(false)
		close_submenu()
		await get_tree().create_timer(MSG_DEATH).timeout
		CombatManager.end_combat(false)

# Cierra el combate al presionar el botón de cerrar.
func _on_close_button_pressed() -> void:
	CombatManager.end_combat(false)

# Finaliza el combate con victoria.
func end_combat_with_victory() -> void:
	combat_menu.visible = false
	combat_menu.set_process_input(false)
	close_submenu()
	await get_tree().create_timer(MSG_VICTORY).timeout
	CombatManager.end_combat(true)

# Al salir del árbol, desconecta la señal de salud.
func _exit_tree() -> void:
	if PlayerStats.health_changed.is_connected(_on_player_health_changed):
		PlayerStats.health_changed.disconnect(_on_player_health_changed)

# Abre menú de habilidades al presionar su botón.
func _on_skills_pressed() -> void:
	open_skills_menu()

# Abre menú de bolsa al presionar su botón.
func _on_bag_pressed() -> void:
	open_bag_menu()

# Abre menú de estado al presionar su botón.
func _on_status_pressed() -> void:
	open_status_menu()
