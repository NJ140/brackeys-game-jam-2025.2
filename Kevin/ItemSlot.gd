extends Control
class_name ItemSlot

signal clicked

@export var icon: Texture2D
@export var item_name: String = ""
@export var qty: int = 1

var _selected: bool = false

@onready var _panel: Panel = $Panel
@onready var _icon: TextureRect = $Panel/VBox/Icon
@onready var _label: Label = $Panel/VBox/Name

var _sb_normal := StyleBoxFlat.new()
var _sb_selected := StyleBoxFlat.new()

func _ready() -> void:
	# Style boxes
	for sb in [_sb_normal, _sb_selected]:
		sb.bg_color = Color(0.12, 0.12, 0.12, 0.65)
		sb.corner_radius_top_left = 14
		sb.corner_radius_top_right = 14
		sb.corner_radius_bottom_left = 14
		sb.corner_radius_bottom_right = 14
	_sb_selected.set_border_width_all(3)
	_sb_selected.border_color = Color(1, 1, 1, 0.9)

	# Content
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture = icon

	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color.WHITE)

	_refresh_label()
	_apply_style()  # safe now: onready vars are valid

func set_selected(v: bool) -> void:
	_selected = v
	if is_inside_tree():        # guard against calls before _ready()
		_apply_style()

func _apply_style() -> void:
	if _panel:
		_panel.add_theme_stylebox_override("panel", _sb_selected if _selected else _sb_normal)

func _refresh_label() -> void:
	_label.text = "%s x%d" % [item_name, qty] if qty > 1 else item_name

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked")
