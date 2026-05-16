extends Control

@onready var skills_button: Button = $Panel/VBoxContainer/SkillsButton
@onready var bag_button: Button = $Panel/VBoxContainer/BagButton
@onready var status_button: Button = $Panel/VBoxContainer/StatusButton

# Capturar tecla Q para cerrar menú (opcional, podríamos salir del combate)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel") and visible:
		# Por ahora no hacemos nada, pero se puede añadir confirmación
		pass
