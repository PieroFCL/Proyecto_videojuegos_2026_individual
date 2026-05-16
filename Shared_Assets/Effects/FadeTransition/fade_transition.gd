extends CanvasLayer

# Señal emitida cuando termina el fade de oscurecimiento
signal fade_out_finished
# Señal emitida cuando termina el fade de aclarado
signal fade_in_finished

# Nodo que aplica el color negro sobre la pantalla
@onready var color_rect: ColorRect = $ColorRect
# Reproductor de animaciones para fade_out y fade_in
@onready var anim_player: AnimationPlayer = $ColorRect/AnimationPlayer

# Inicia el fade out (oscurecer) y espera a que termine
func fade_out() -> void:
	anim_player.play("fade_out")
	await anim_player.animation_finished
	fade_out_finished.emit()

# Inicia el fade in (aclarar) y se destruye al terminar
func fade_in() -> void:
	anim_player.play("fade_in")
	await anim_player.animation_finished
	fade_in_finished.emit()
	queue_free()
