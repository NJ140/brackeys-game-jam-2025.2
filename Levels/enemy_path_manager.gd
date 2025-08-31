extends Node2D

var current_round_paths_cleared = 0
var paths := []

func _ready():
	EventBus.WAVE.spawned.connect(assign_enemy_to_path)
	EventBus.WAVE.no_more_enemies_to_spawn.connect(start_tracking_enemies)
	
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

func get_enemy_count():
	return paths.map(func(p:EnemyPath): return p.get_enemy_count())

func start_tracking_enemies():
	current_round_paths_cleared = 0
	for path:EnemyPath in paths:
		if not path.is_tracking_enemy_count:
			path.start_tracking_enemies()
			path.no_more_enemies_on_path.connect(_on_path_cleared,ConnectFlags.CONNECT_ONE_SHOT)

func _on_path_cleared():
	current_round_paths_cleared += 1
	if current_round_paths_cleared >= paths.size():
		EventBus.WAVE.all_enemies_cleared.emit()
