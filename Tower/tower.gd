class_name Tower extends CharacterBody2D

enum Type{
	Ranger,
	Warrior,
	Mage,
}

const EnemyLayerMask = 2
const BASE_HEALTH = 20

@onready var attack_timer: Timer = %AttackTimer
@onready var model: CharacterModel= %Model
@onready var attack_range : Area2D= %AttackRange
@onready var projectile_point: Node2D = %Projectile_spawn
@onready var range_visual: Panel = %RangeVisual

@export var base_projectile = preload("res://projectile.tscn")

@export var attack_time := 1
@export var projectile_speed := 300
@export var damage := 1
@export var disabled = false

var dict_enemies_in_range:Dictionary= {}
var current_target = null

func _ready() -> void:
	attack_timer.wait_time = attack_time
	model.sprite_2d.play("default")
	EventBus.UI.new_focus.connect(
		func(e): if e != self: hide_range()
	)
	
func _physics_process(delta: float) -> void:
	if not current_target: return
	var direction = (current_target.position - position)
	model.flip_h = not direction.x > 0 

func _try_attack():
	if disabled: return
	current_target = get_first_enemy()
	if not current_target: return
	var target_pos = get_target_pos()
	if not base_projectile: return
	create_projectile(target_pos)
	model.do_attack_animation()

func create_projectile(target_pos):
	var p :Projectile= base_projectile.instantiate() as Projectile
	p.direction = (target_pos - position).normalized()
	p.speed = projectile_speed
	p.damage = damage
	p.set_target_layer(EnemyLayerMask)
	projectile_point.add_child(p)

func get_target_pos():
	var distance:float= (current_target.global_position - projectile_point.global_position).length()
	var projectile_travle_time := distance/(projectile_speed)
	var target_pos = current_target.next_position(projectile_travle_time)
	return target_pos

func get_first_enemy() -> EnemyUnit:
	var first:EnemyUnit = null
	var enemies := get_enemies_in_range()
	for other:EnemyUnit in enemies:
		if not is_instance_valid(first) or not first:
			first = other
			continue
		if first.progress > other.progress: continue
		first = other
	return first 

func get_enemies_in_range()-> Array:
	return ( attack_range.get_overlapping_bodies()
			.filter(func(b): return b and b.get_meta("IsEnemy"))
			.map(func(b): return b.get_parent() as EnemyUnit)
	)

func take_damage(dmg:int):
	model.do_damaged_animation()

func heal(add:int):
	pass

func set_attack_time(s:int):
	attack_time = s
	attack_timer.wait_time = s

func show_range():
	range_visual.show()

func hide_range():
	range_visual.hide()

func _on_pickable_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		EventBus.UI.new_focus.emit(self)
		show_range()
	if event.is_action_pressed("right_click"):
		hide_range()
