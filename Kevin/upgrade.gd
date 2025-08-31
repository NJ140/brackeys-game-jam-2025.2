extends MarginContainer

@onready var tower_name :Label= %TowerName
@onready var tower_img :TextureRect= %Preview
@onready var old_health_label :Label= %hpOld
@onready var health_label :Label= %HpNew
@onready var old_range_label :Label= %RangeOld
@onready var range_label :Label= %RangeNew
@onready var old_damage_label :Label= %DamageOld
@onready var damage_label :Label= %DamageNew
@onready var level_label :Label= %LevelLabel
@onready var upgrade_button :Button= %UpgradeButton
@onready var repair_button :Button= %RepairButton
@onready var cancel_button :Button= %CancelButton
@onready var health :ProgressBar= %Health

var tower_selected :Tower= null

func _ready():
	EventBus.UI.tower_selected.connect(on_selcet_tower)
	

func on_selcet_tower(tower:Tower):
	tower_selected = tower
	tower_selected.died.connect(on_tower_death,ConnectFlags.CONNECT_ONE_SHOT)
	var name_of_tower = Tower.type_to_name[tower.type]
	var tower_is_max_level :bool= tower.level - 1 >= Tower.upgrade_sequence[tower.type].size()
	var next_level_data :Tower.TowerData= null
	if not tower_is_max_level:
		next_level_data = Tower.upgrade_sequence[tower.type][tower.level]
	level_label.text = "Level: " + str(tower.level)
	tower_name.text = name_of_tower.capitalize()
	tower_img.texture = tower.model.sprite_2d.sprite_frames.get_frame_texture(name_of_tower,0)
	tower_img.texture
	old_health_label.text = str(tower.max_health)
	old_range_label.text = str(tower.range)
	old_damage_label.text = str(tower.damage)
	health.value = tower.health_bar.value
	if tower_is_max_level:
		health_label.text = "MAX"
		damage_label.text = "MAX"
		range_label.text = "MAX"
	else:
		health_label.text = str(next_level_data.health)
		damage_label.text = str(next_level_data.damage)
		range_label.text = str(next_level_data.range)
	tower.health_bar.value_changed.connect(update_health)
	show()

func update_health(v:float):
	health.value = v
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		hide()
		tower_selected.health_bar.value_changed.disconnect(update_health)
		tower_selected = null
		
func on_tower_death():
	hide()



func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()

func _on_cancel_button_pressed() -> void:
	hide()
