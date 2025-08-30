extends Node2D

func _ready() -> void:
	EventBus.TOWER.built.connect(add_tower)

func add_tower(tower,pos):
	add_child(tower)
	tower.pos 
	
