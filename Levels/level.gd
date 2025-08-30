extends Node2D

@onready var transition := $Fade/AnimationPlayer

func _ready():
	transition.play("fade_in")
