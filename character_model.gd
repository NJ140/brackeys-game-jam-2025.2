class_name CharacterModel extends Node2D

@onready var sprite_2d:AnimatedSprite2D = $Sprite2D
@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var animation_tree:AnimationTree = %AnimationTree

@export var flip_h:bool = false:
	get:
		return scale.x < 0
	set(f):
		scale.x = scale.x if f == flip_h else -scale.x

@export_range(0, 360, 0.1, "radians_as_degrees") var a_rotation := rotation:
	get:
		return rotation
	set(v):
		var nv = -v if flip_h else v
		rotation = nv

func _ready() -> void:
	sprite_2d.play("default")

func do_attack_animation():
	animation_tree.set("parameters/Attack/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#animation_tree.set("parameters/attack_time/seek_request",0)

func do_damaged_animation():
	animation_tree.set("parameters/Damaged/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#animation_tree.set("parameters/damaged_time/seek_request",0)
