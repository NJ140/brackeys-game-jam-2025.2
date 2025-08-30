extends Node2D

func _ready() -> void:
	EventBus.TOWER.built.connect(add_tower)

func add_tower(tower:Tower,pos:Vector2):
	add_child(tower)
	tower.global_position = pos 
	
