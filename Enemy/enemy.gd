class_name EnemyUnit extends PathFollow2D
enum EnemyState{
	Idle,
	Walking,
	Attacking,
	Dead,
}
enum Type{
	Jackle
}
	
const SPEED = 50.0
const BASE_HEALTH = 3

@onready var model: CharacterModel = %Model
@onready var attack_timer: Timer = %AttackTimer
@onready var attack_range: Area2D = %AttackRange
@onready var character_body: CharacterBody2D = $CharacterBody2D

@export var max_health := 3
@export var health:int= min(BASE_HEALTH,max_health)
@export var speed_mul := 1.0
@export var player_damage := 1
@export var tower_damage := 1
@export var unit_type = Type.Jackle
@export var state:= EnemyState.Walking

var current_target = null
var attack_ready = false
var defer_attack = false
var dying = false

var tags:={}
var last_pos = Vector2.ZERO
var current_path :Path2D= null

@export var attack_time := 5.0

func _ready() -> void:
	model.sprite_2d.play("default")
	progress = 0
	set_attack_time(attack_time)

func _physics_process(delta: float) -> void:
	if attack_ready and not model.animation_player.current_animation == "Attack":
		current_target = get_closest_tower_in_range()
		if current_target:
			attack_ready = false
			model.do_attack_animation()
	match state:
		EnemyState.Walking:
			last_pos = position
			progress += SPEED * delta * speed_mul
			model.flip_h = not is_looking_at(last_pos)
			if progress_ratio >= 1.0:
				EventBus.ENEMY.reached_end.emit(player_damage)
				queue_free()
		EnemyState.Attacking:
			if current_target:
				model.flip_h = is_looking_at(current_target.position)

func is_looking_at(pos:Vector2) -> bool:
	var direction = (position - pos).normalized()
	return direction.x > 0

func next_position(travle_time:float):
	current_path = get_parent() if not current_path else current_path
	if not current_path: return position
	var next_progress =  progress + (SPEED * travle_time * speed_mul)
	return current_path.curve.sample_baked(next_progress)

func take_damage(dmg:int):
	health = max(health - dmg,0)
	if health <= 0:
		EventBus.ENEMY.defeted.emit([self.unit_type,self.tags])
		die()
	else:
		model.do_damaged_animation()

func die():
	state = EnemyState.Dead
	set_physics_process(false)
	#model.sprite_2d.position = Vector2.ZERO
	model.scale = Vector2.ONE *.5
	character_body.collision_layer = 0
	model.sprite_2d.play("death")
	
	await model.sprite_2d.animation_looped
	self.queue_free()

func _on_character_body_2d_on_damage(i: int) -> void:
	if is_dead(): return
	take_damage(i)

func _on_attack_timer_timeout() -> void:
	attack_ready = true

func attack():
	if is_dead(): return
	if current_target in attack_range.get_overlapping_bodies():
		current_target.take_damage(tower_damage)
	attack_timer.wait_time = attack_time
	attack_timer.start()

func get_closest_tower_in_range():
	var closest :Tower= null
	var distance_to_closes := INF 
	for tower:Tower in get_towers_in_range():
		if not closest:
			closest = tower
		var distance_to_tower = (position - tower.position).length_squared()
		if distance_to_closes > distance_to_tower:
			closest = tower
			distance_to_closes = distance_to_tower
	return closest

func get_towers_in_range() -> Array:
		return ( attack_range.get_overlapping_bodies()
				.map(func(b): return b as Tower)
		)

func set_attack_time(value:float):
	attack_timer.wait_time = value

func is_dead():
	return state == EnemyState.Dead
