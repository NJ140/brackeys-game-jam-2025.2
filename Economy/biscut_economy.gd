extends Node

enum Type {
	Plain,
	Fire,
	Ice,
	Earth,
}

func _ready() -> void:
	EventBus.ENEMY.defeted.connect(generate_enemy_loot_for_player)

func generate_enemy_loot_for_player(defeted_enemy):
	pass
