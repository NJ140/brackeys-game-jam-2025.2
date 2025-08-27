extends Node2D

var paths := []

func _ready():
	EventBus.WAVE.spawned.connect(assign_enemy_to_path)
	
	for child in get_children():
		if child is not EnemyPath: continue
		add_path(child)

func assign_enemy_to_path(enemy:EnemyUnit, perfered_path:int):
	var try_path_id = 0
	if not paths.size() >= perfered_path:
		try_path_id = perfered_path

	paths[try_path_id].add_enemy(enemy)

func add_path(path:EnemyPath):
	paths.append(path)
