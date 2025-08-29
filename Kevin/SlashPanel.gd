extends Control
class_name SlashPanel

@export var color: Color = Color8(228, 0, 43) # Persona-ish red
@export var shadow_color: Color = Color(0, 0, 0, 0.35)
@export var skew_px: float = 28.0
@export var corner: float = 10.0

var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var pts = PackedVector2Array([
		Vector2(r.position.x, r.position.y + corner),
		Vector2(r.position.x + corner, r.position.y),
		Vector2(r.size.x - corner, r.position.y - skew_px),
		Vector2(r.size.x, r.position.y + corner - skew_px),
		Vector2(r.size.x, r.position.y + r.size.y - corner + skew_px),
		Vector2(r.size.x - corner, r.position.y + r.size.y + skew_px),
		Vector2(r.position.x + corner, r.position.y + r.size.y),
		Vector2(r.position.x, r.position.y + r.size.y - corner),
	])
	# shadow
	var shadow_offset := Vector2(6, 6)
	var shadow_pts := PackedVector2Array()
	for p in pts:
		shadow_pts.append(p + shadow_offset)
	draw_polygon(shadow_pts, [shadow_color])
	# fill
	draw_polygon(pts, [color])

func move_to_button(btn: Button, extra_height := 8.0, left_pad := -16.0, right_pad := 40.0) -> void:
	var gpos := btn.get_global_position()
	var gsize := btn.size
	var new_pos := Vector2(gpos.x + left_pad, gpos.y - extra_height/2.0)
	var new_size := Vector2(gsize.x + right_pad - left_pad, gsize.y + extra_height)

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "global_position", new_pos, 0.18)
	_tween.parallel().tween_property(self, "size", new_size, 0.18)
	_tween.tween_callback(Callable(self, "queue_redraw"))
