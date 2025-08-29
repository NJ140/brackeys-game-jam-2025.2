extends Node

@export var rounds := [
	[Wave.new(EnemyUnit.Type.Jackle,10,65,40),],
	[Wave.new(EnemyUnit.Type.Jackle,20,40,40),],
]
var enemy_unit_scene = preload("res://Enemy/enemy.tscn")
var current_round_num := -1
var round_ongoing = false

func _ready() -> void:
	EventBus.WAVE.new_round.connect(new_round)
	EventBus.WAVE.all_enemies_cleared.connect(round_ended)

func _physics_process(_delta: float) -> void:
	if round_ongoing:
		do_round()
	else:
		set_physics_process(false)

func do_round():
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
		
	if not waves_completed >= current_round.size(): return
	EventBus.WAVE.no_more_enemies_to_spawn.emit()

func round_ended():
	round_ongoing = false
	if not current_round_num >= rounds.size():
		EventBus.WAVE.round_ended.emit(current_round_num)
	else:
		EventBus.PLAYER.win_game.emit(current_round_num)

func new_round():
	if round_ongoing or current_round_num > rounds.size(): return
	current_round_num += 1
	round_ongoing = true
	if current_round_num >= rounds.size():
		EventBus.WAVE.last_round_started.emit()
	set_physics_process(true)


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
