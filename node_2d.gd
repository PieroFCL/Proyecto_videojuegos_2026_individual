extends CharacterBody2D

@onready var anim2 = $AnimationPlayer2
@onready var anim1 = $AnimationPlayer

func _ready():
	anim1.play("new_animation")
