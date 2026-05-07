extends CanvasLayer

signal fade_out_finished
signal fade_in_finished

@onready var color_rect: ColorRect = $ColorRect
@onready var anim_player: AnimationPlayer = $ColorRect/AnimationPlayer

# Inicia el fade out (oscurecer)
func fade_out() -> void:
	anim_player.play("fade_out")
	await anim_player.animation_finished
	fade_out_finished.emit()

# Inicia el fade in (aclarar)
func fade_in() -> void:
	anim_player.play("fade_in")
	await anim_player.animation_finished
	fade_in_finished.emit()
	queue_free()  # Elimina la escena al terminar
