class_name Tower extends CharacterBody2D

enum Type{
	Ranger,
	Warrior,
	Mage,
}

const EnemyLayerMask := 2
const BASE_HEALTH := 20
@onready var attack_timer: Timer = %AttackTimer
@onready var model: CharacterModel= %Model
@onready var attack_range : Area2D= %AttackRange
@onready var projectile_point: Node2D = %Projectile_spawn
@onready var range_visual: Panel = %RangeVisual
@onready var shoot_sfx: AudioStreamPlayer = %ShootSFX

static var tower_scene:=preload("res://Tower/tower.tscn")
@export var base_projectile = preload("res://projectile.tscn")

@export var type := Type.Ranger
@export var projectile_speed := 300 #pixels/sec
@export var disabled = false

var abilities := []
var dict_enemies_in_range:Dictionary= {}
var current_target = null

## Stats
var health := BASE_HEALTH
var range := 200 # pixel radius
@export var damage := 1
@export var attack_time :float= 0.1 ## attack rate in seconds

var powers := []
var modifiers := []

func _ready() -> void:
	attack_timer.wait_time = attack_time
	model.sprite_2d.play("default")
	EventBus.UI.tower_selected.connect(
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
	shoot_sfx.play()
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") or event.is_action_pressed("right_click"):
		hide_range()

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
		EventBus.UI.tower_selected.emit(self)
		show_range()
func set_data(data:TowerData):
	type = data.type
	
func add_power():
	pass

func get_value():
	pass

func get_sell_value():
	pass

func sell_tower():
	pass

static func CREATE(data:TowerData):
	var tower:Tower= tower_scene.instantiate()
	tower.type = data.type
	tower.health = data.health
	tower.range = data.range
	tower.damage = data.damage
	tower.attack_time = data.attack_time
	tower.projectile_speed = data.projectile_speed
	tower.abilities = data.abilities
	return tower

class TowerData extends Resource:
	@export var type:Tower.Type
	@export var cost:int
	@export var health:int
	@export var range:int
	@export var damage:int
	@export var attack_time:int
	@export var projectile_speed:int
	@export var abilities:Array
	
	func _init(type,cost,health,range,damage,attack_time,projectile_speed,abilities) -> void:
		self.type = type
		self.cost = cost
		self.health = health
		self.range = range
		self.damage = damage
		self.attack_time = attack_time
		self.projectile_speed = projectile_speed
		self.abilities = abilities
	
	static func GET_TOWER(type:Tower.Type):
		match type:
			Tower.Type.Ranger: return RANGER()
			Tower.Type.Warrior: return WARRIOR()
			Tower.Type.Mage: return MAGE()
		return RANGER()
		
	static func RANGER():
		var new_tower_data = TowerData.new(Type.Ranger,3,15,200,1,1,300,[])
		return new_tower_data
	
	static func WARRIOR():
		var new_tower_data = TowerData.new(Type.Warrior,5,30,100,2,0.75,150,[])
		return new_tower_data
	
	static func MAGE():
		var new_tower_data = TowerData.new(Type.Mage,5,8,300,1,2,200,[])
		return new_tower_data
