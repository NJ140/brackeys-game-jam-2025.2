extends Node

@export var rounds := [
	[   # Round 1
		Wave.new(EnemyUnit.Type.Jackle,10,65,40),
	],
]
var enemy_unit_scene = preload("res://Enemy/enemy.tscn")
var current_round_num := 0

func _physics_process(_delta: float) -> void:
	var waves_completed:int = 0
	var current_round = rounds[current_round_num]
	for wave:Wave in current_round:
		if wave.is_done(): 
			waves_completed += 1
			continue
		wave.current_interval = 1 + (wave.current_interval % wave.spawn_interval)
		if not wave.current_interval == 1: continue
		var new_enemy = enemy_unit_scene.instantiate()
		EventBus.WAVE.spawned.emit(new_enemy,wave.perfered_path)
		wave.count -= 1
		
	if waves_completed >= current_round.size():
		EventBus.WAVE.round_ended.emit(current_round_num)

class Wave extends Resource:
	@export var enemy_id:EnemyUnit.Type = EnemyUnit.Type.Jackle
	@export var count:= 0
	@export var spawn_interval := 1
	@export var perfered_path := -1
	var current_interval := 0
	func _init(id:EnemyUnit.Type,count:int,interval:int,delay:=0,perfered_spawn_path:= -1):
		self.enemy_id = id
		self.count = count
		self.spawn_interval = interval
		self.current_interval -= delay
		self.perfered_path = perfered_spawn_path
	func is_done() -> bool:
		return count <= 0
