class_name EnemyPath extends Path2D

var is_tracking_enemy_count := false
signal no_more_enemies_on_path

func add_enemy(enemy:EnemyUnit):
	add_child(enemy)
	enemy.current_path = self
	set_process(false)

func get_enemy_count() -> Array:
	return get_children().filter(func(c): return c is EnemyUnit)

func start_tracking_enemies():
	if is_tracking_enemy_count: return
	is_tracking_enemy_count = true
	set_process(true)

func _process(_delta: float) -> void:
	if get_enemy_count().size() <= 0 and is_tracking_enemy_count:
		no_more_enemies_on_path.emit()
		set_process(false)
