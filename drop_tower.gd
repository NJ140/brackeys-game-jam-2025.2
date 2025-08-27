extends TextureRect

@export var tower_data := {
	"tower_type": null,
	"abilities": [],
	"level": 0
}
var tower_sprite_frame := preload("res://Tower/tower_sprite_frame.tres")
var current_drag: Node2D = AnimatedSprite2D.new()
var dragged = false
var click_drop_mode = false
var started_motion = false

func _ready() -> void:
	add_child(current_drag)
	set_process(false)
	
func _process(delta: float) -> void:
	if dragged:
		if current_drag.hidden: 
			current_drag.show()
		current_drag.global_position = get_global_mouse_position()
	if Input.is_action_just_released("right_click"):
		end_drag()
	if Input.is_action_just_pressed("left_click") and click_drop_mode:
		drop()


func _gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click") and event is InputEventMouseButton:
		current_drag.sprite_frames = tower_sprite_frame
		current_drag.play("default")
		dragged = true
		set_process(true)
	elif dragged and event is InputEventMouseMotion:
		started_motion = true
	elif Input.is_action_just_released("left_click") and not started_motion:
		click_drop_mode = true
	elif Input.is_action_just_released("left_click") and not click_drop_mode:
		drop()

func drop(): 
	EventBus.TOWER.request_new_tower.emit(tower_data,get_global_mouse_position())
	end_drag()
	pass

func end_drag():
	dragged = false
	click_drop_mode = false
	started_motion = false
	current_drag.hide()
	set_process(false)
