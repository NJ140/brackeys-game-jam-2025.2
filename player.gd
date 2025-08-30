extends Node
# the disembodied player character
@export var tower_scene:=preload("res://Tower/tower.tscn")
@export var health := 20
@export var biscuits:Dictionary[BiscuitEconomy.Flavor,int] = {
	BiscuitEconomy.Flavor.Plain : 10,
}
@export var towers_avalable :Dictionary[Tower.Type,int]

var towers_deplyed :Array[Tower] = []

func _ready() -> void:
	EventBus.ENEMY.reached_end.connect(take_damage)
	EventBus.PLAYER.earn_biscuits.connect(collect_biscuits)
	EventBus.UI.request_new_tower.connect(build_tower)
	EventBus.UI.request_repair_tower.connect(repair_tower)
	EventBus.UI.request_power_up_tower.connect(power_up_tower)
	EventBus.UI.request_level_up_tower.connect(level_up_tower)

	EventBus.PLAYER.update_biscuit_count.emit(biscuits)

func take_damage(strength):
	EventBus.PLAYER.took_damage.emit(strength)
	health = max(health - strength, 0)
	if health <= 0:
		EventBus.PLAYER.lose_game.emit()

func collect_biscuits(new_biscuits:Dictionary):
	for flavor in new_biscuits.keys():
		biscuits.get_or_add(flavor,0) 
		biscuits[flavor] += new_biscuits[flavor]
	EventBus.PLAYER.update_biscuit_count.emit(biscuits)

func build_tower(tower_type:Tower.Type,position):
	var data : Tower.TowerData = Tower.TowerData.GET_TOWER(tower_type)
	if data.cost > biscuits[BiscuitEconomy.Flavor.Plain]:
		EventBus.PLAYER.not_enogh_biscuits.emit()
		return
	biscuits[BiscuitEconomy.Flavor.Plain] -= data.cost
	var new_tower = Tower.CREATE(data)
	EventBus.TOWER.built.emit(new_tower,position)
	EventBus.PLAYER.update_biscuit_count.emit(biscuits)
	pass

func repair_tower(tower,amount):
	EventBus.PLAYER.update_biscuit_count.emit(biscuits)
	pass

func power_up_tower(tower,flavor):
	EventBus.PLAYER.update_biscuit_count.emit(biscuits)
	pass

func level_up_tower(tower):
	EventBus.PLAYER.update_biscuit_count.emit(biscuits)
	pass
