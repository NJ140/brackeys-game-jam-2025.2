class_name EnemyPath extends Path2D

func add_enemy(enemy:EnemyUnit):
	add_child(enemy)
	enemy.current_path = self
