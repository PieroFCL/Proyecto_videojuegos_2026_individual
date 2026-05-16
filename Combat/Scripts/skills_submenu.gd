extends Control

signal skill_selected(skill: SkillResource)
signal closed

# Referencias a los 4 botones (deben existir en la escena con estos nombres)
@onready var slot1: Button = $Panel/GridContainer/SkillSlot1
@onready var slot2: Button = $Panel/GridContainer/SkillSlot2
@onready var slot3: Button = $Panel/GridContainer/SkillSlot3
@onready var slot4: Button = $Panel/GridContainer/SkillSlot4

var slots: Array[Button] = []
var current_skills: Array = [] 

func _ready():
	slots = [slot1, slot2, slot3, slot4]
	# Conectar señales de cada slot
	for i in range(slots.size()):
		slots[i].pressed.connect(_on_slot_pressed.bind(i))

	# Enfocar primer slot no vacío

func initialize(skills_list: Array) -> void:
	current_skills = skills_list  # ahora es Array[SkillResource]
	for i in range(slots.size()):
		if i < current_skills.size():
			var skill = current_skills[i]  # SkillResource
			slots[i].text = _format_skill_text(skill)
			slots[i].disabled = false
		else:
			slots[i].text = "---\n---"
			slots[i].disabled = true

	# Enfocar primer slot no vacío
	for i in range(slots.size()):
		if not slots[i].disabled:
			slots[i].grab_focus()
			break

func _format_skill_text(skill) -> String:
	if skill is SkillResource:
		return skill.get_formatted_text()
	else:
		return str(skill) + "\n" + "?"

func _on_slot_pressed(index: int) -> void:
	if index < current_skills.size():
		var skill = current_skills[index]
		skill_selected.emit(skill)   # emitir el recurso directamente
	closed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		closed.emit()
