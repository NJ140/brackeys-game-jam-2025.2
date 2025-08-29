extends Node
# the disembodied player character

@export var health := 20
@export var buiscuts:Dictionary[BiscutEconomy.Flavor,int] = {
	BiscutEconomy.Flavor.Plain : 10,
}
@export var towers_avalable :Dictionary[Tower.Type,int]

var towers_deplyed :Array[Tower] = []

func _ready() -> void:
	EventBus.ENEMY.reached_end.connect(take_damage)
	EventBus.PLAYER.earn_buiscuts.connect(collect_biscuits)
	EventBus.UI.request_new_tower.connect(build_tower)
	EventBus.UI.request_repair_tower.connect(repair_tower)
	EventBus.UI.request_power_up_tower.connect(power_up_tower)
	EventBus.UI.request_level_up_tower.connect(level_up_tower)

	EventBus.PLAYER.update_buiscut_count.emit(buiscuts)

func take_damage(strength):
	EventBus.PLAYER.took_damage.emit(strength)
	health = max(health - strength, 0)
	if health <= 0:
		EventBus.PLAYER.lose_game.emit()

func collect_biscuits(new_biscuits:Dictionary[BiscuitEconomy.Flavor,int]):
	for flavor in new_biscuits.keys():
		buiscuts.get_or_add(flavor,0) 
		buiscuts[flavor] += new_biscuits[flavor]
	EventBus.PLAYER.update_buiscut_count.emit(buiscuts)

func build_tower(tower_data):
	EventBus.PLAYER.update_buiscut_count.emit(buiscuts)
	pass

func repair_tower(tower,amount):
	EventBus.PLAYER.update_buiscut_count.emit(buiscuts)
	pass

func power_up_tower(tower,flavor):
	EventBus.PLAYER.update_buiscut_count.emit(buiscuts)
	pass

func level_up_tower(tower):
	EventBus.PLAYER.update_buiscut_count.emit(buiscuts)
	pass
