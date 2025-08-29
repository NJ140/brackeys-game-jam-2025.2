# res://pages/SkillNode.gd
extends Button

@export var skill_id: String = ""
@export var title: String = "Skill"
@export var max_level: int = 3

var level: int = 0
var locked: bool = true
var available: bool = false
var selected: bool = false

const C_BG_LOCKED   := Color8(24, 24, 24)
const C_BG_AVAIL    := Color8(32, 64, 32)
const C_BG_TAKEN    := Color8(40, 40, 80)
const C_BG_HILITE   := Color8(220, 0, 40)
const C_TEXT        := Color8(245, 245, 245)

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	toggle_mode = false
	clip_text = true
	_refresh()

func set_state(_level: int, _locked: bool, _available: bool) -> void:
	level = _level
	locked = _locked
	available = _available
	_refresh()

func set_selected(v: bool) -> void:
	selected = v
	_refresh()

func _refresh() -> void:
	var status := ""
	if locked:
		status = "LOCKED"
	elif level >= max_level:
		status = "MAX"
	elif available:
		status = "READY"
	else:
		status = "..."
	text = "%s\nLV %d / %d  [%s]" % [title, level, max_level, status]

	var bg := C_BG_LOCKED
	if not locked and level > 0:
		bg = C_BG_TAKEN
	elif available and level == 0:
		bg = C_BG_AVAIL
	if selected:
		bg = C_BG_HILITE

	add_theme_color_override("font_color", C_TEXT)
	add_theme_color_override("font_shadow_color", Color8(10,10,10))
	add_theme_constant_override("shadow_outline_size", 2)
	add_theme_color_override("disabled_font_color", C_TEXT.darkened(0.4))
	add_theme_color_override("font_hover_color", C_TEXT)
	add_theme_color_override("font_pressed_color", C_TEXT)

	# Simple background via StyleBoxFlat
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_size = 4
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("disabled", sb)

	custom_minimum_size = Vector2(210, 110)
