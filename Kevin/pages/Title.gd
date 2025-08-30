# res://Title.gd  (Godot 4.x)
extends Control

@export var next_scene: PackedScene

@onready var play_btn: Button     = %PlayButton
@onready var options_btn: Button  = %OptionsButton
@onready var quit_btn: Button     = %QuitButton

# Will be null if the node doesn't exist – no errors.
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	# Nice default focus
	if play_btn:
		play_btn.grab_focus()

	# Fade in if you made such an animation (optional)
	if anim:
		anim.play("fade_in")

	# Wire buttons (only if they exist)
	if play_btn:
		play_btn.pressed.connect(_start_game)
	if options_btn:
		options_btn.pressed.connect(_open_options)
	if quit_btn:
		quit_btn.pressed.connect(_quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()

func _start_game() -> void:
	if anim:
		anim.play("fade_out")
		await anim.animation_finished
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_warning("No next_scene set on Title.gd")

func _open_options() -> void:
	# placeholder for now
	print("Options pressed")

func _quit() -> void:
	get_tree().quit()
