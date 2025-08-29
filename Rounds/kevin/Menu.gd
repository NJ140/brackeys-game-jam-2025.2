# res://menu.gd
extends Control

# ---------- scene refs ----------
@onready var left_rail  : VBoxContainer = $"LeftRail"
@onready var header_lbl : Label         = $"Content/Header"
@onready var page_host  : Control       = $"Content/PageHost"
@onready var overlay    : Control       = $"Overlay"
@onready var selector   : Control       = $"Overlay/Selector"
@onready var bg         : CanvasItem    = ($"Bg" if has_node("Bg") else null)

# ---------- rail options / state ----------
var options      : Array[Button] = []
var index        : int = 0
var in_subpage   : bool = false
var current_page : Control = null
var _sel_tween   : Tween  = null

# ---------- sub-pages ----------
const PAGES := {
	"ITEMS":  preload("res://pages/ItemsPage.tscn"),
	"SKILLS": preload("res://pages/SkillsPage.tscn"),
	"SYSTEM": preload("res://pages/SystemPage.tscn")
}

# =========================================================
# Lifecycle
# =========================================================
func _ready() -> void:
	_collect_options()
	_wire_buttons()
	_style_header()

	_setup_overlay()
	_setup_page_host()
	_update_layout()

	call_deferred("_after_ready")

func _after_ready() -> void:
	await get_tree().process_frame
	if options.is_empty():
		return
	index = clampi(index, 0, options.size() - 1)
	_place_selector_now()
	_update_page()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

# =========================================================
# Input
# =========================================================
func _unhandled_input(e: InputEvent) -> void:
	if get_viewport().is_input_handled():
		return
	if in_subpage:
		if e.is_action_pressed("menu_back") or e.is_action_pressed("ui_cancel"):
			_leave_current_page()
		return

	if e.is_action_pressed("menu_down") or e.is_action_pressed("ui_down"):
		_move(1)
	elif e.is_action_pressed("menu_up") or e.is_action_pressed("ui_up"):
		_move(-1)
	elif e.is_action_pressed("menu_confirm") or e.is_action_pressed("ui_accept") or e.is_action_pressed("ui_right") or e.is_action_pressed("menu_right"):
		_enter_current_page()
	elif e.is_action_pressed("menu_back") or e.is_action_pressed("ui_cancel"):
		queue_free()

# =========================================================
# Rail setup & visuals
# =========================================================
func _collect_options() -> void:
	options.clear()
	if left_rail == null:
		return
	for c in left_rail.get_children():
		if c is Button:
			options.append(c)

func _style_button(b: Button) -> void:
	# Remove background so the red selector can slide behind the label with no black strip
	b.flat = true
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal",   empty)
	b.add_theme_stylebox_override("hover",    empty)
	b.add_theme_stylebox_override("pressed",  empty)
	b.add_theme_stylebox_override("focus",    empty)
	b.add_theme_stylebox_override("disabled", empty)

	# Text tweaks
	b.text = b.text.to_upper()
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_font_size_override("font_size", 26)

func _wire_buttons() -> void:
	for i in options.size():
		var b := options[i]
		_style_button(b)
		for conn in b.pressed.get_connections():
			if conn.callable.get_object() == self:
				b.pressed.disconnect(conn.callable)
		b.pressed.connect(func(): _on_option_pressed(i))

func _on_option_pressed(i: int) -> void:
	_focus_rail_index(i)
	_enter_current_page()

func _move(step: int) -> void:
	if options.is_empty():
		return
	var new_i := (index + step + options.size()) % options.size()
	_focus_rail_index(new_i)

func _focus_rail_index(i: int) -> void:
	if options.is_empty():
		return

	var new_i := clampi(i, 0, options.size() - 1)

	# If the index didn't change, just move the selector and keep the page.
	if new_i == index and current_page != null:
		_tween_selector_to(options[new_i])
		return

	index = new_i
	_tween_selector_to(options[index])
	_update_page_title()
	_update_page()  # <-- switch to the selected sub-page (ITEMS/SKILLS/SYSTEM)


# =========================================================
# Selector placement / animation
# =========================================================
func _setup_overlay() -> void:
	# Layering: bg (way back) < overlay/selector (behind rail text) < content header/grid
	if bg:
		bg.z_index = -100

	if overlay and selector:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = 0
		overlay.offset_top = 0
		overlay.offset_right = 0
		overlay.offset_bottom = 0
		overlay.clip_contents = false
		overlay.z_index = -4              # behind rail labels
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

		selector.z_index = -3
		selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selector.visible = true

func _overlay_local_from_global(global_pos: Vector2) -> Vector2:
	var inv := overlay.get_global_transform_with_canvas().affine_inverse()
	return inv * global_pos

func _selector_target(btn: Button) -> Vector2:
	var global_pt: Vector2 = btn.get_global_rect().position
	return _overlay_local_from_global(global_pt)

func _place_selector_now() -> void:
	if selector == null or overlay == null or options.is_empty():
		return
	var btn: Button = options[index]
	selector.size = btn.size
	selector.position = _selector_target(btn)
	selector.visible = true

func _tween_selector_to(btn: Button) -> void:
	if selector == null or overlay == null or btn == null:
		return
	var dest_pos: Vector2 = _selector_target(btn)
	var dest_size: Vector2 = btn.size

	if _sel_tween != null and _sel_tween.is_running():
		_sel_tween.kill()

	_sel_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sel_tween.tween_property(selector, "position", dest_pos, 0.15)
	_sel_tween.parallel().tween_property(selector, "size", dest_size, 0.15)
	_sel_tween.play()

# =========================================================
# Header + Page Host + Layout
# =========================================================
func _style_header() -> void:
	if header_lbl == null:
		return
	header_lbl.text = ""
	header_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	header_lbl.add_theme_font_size_override("font_size", 34) # smaller title

func _update_page_title() -> void:
	if header_lbl == null or options.is_empty():
		return
	header_lbl.text = options[index].text

func _setup_page_host() -> void:
	if page_host == null:
		return
	page_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_host.offset_left = 0
	page_host.offset_top = 0
	page_host.offset_right = 0
	page_host.offset_bottom = 0
	page_host.clip_contents = false

func _update_layout() -> void:
	if left_rail == null or page_host == null or header_lbl == null:
		return

	var rail_w: int = int(left_rail.size.x)
	var PAD_L := 24
	var PAD_T := 10
	var PAD_R := 24
	var PAD_B := 24

	# Right content area
	page_host.offset_left = rail_w + PAD_L
	page_host.offset_top = 64
	page_host.offset_right = -PAD_R
	page_host.offset_bottom = -PAD_B

	# Title position
	header_lbl.position = Vector2(rail_w + PAD_L, PAD_T)

# =========================================================
# Sub-page show / enter / leave
# =========================================================
func _update_page() -> void:
	_update_page_title()
	_show_page(header_lbl.text)

func _show_page(key: String) -> void:
	if current_page:
		current_page.queue_free()
		current_page = null

	var scene: PackedScene = PAGES.get(key, null)
	if scene == null:
		return

	current_page = scene.instantiate() as Control
	page_host.add_child(current_page)
	_wire_subpage(current_page)

	await get_tree().process_frame
	if current_page:
		current_page.set_anchors_preset(Control.PRESET_FULL_RECT)
		current_page.offset_left = 0
		current_page.offset_top = 0
		current_page.offset_right = 0
		current_page.offset_bottom = 0

func _wire_subpage(page: Node) -> void:
	if page.has_method("focus_out"):
		page.call("focus_out")
	if page.has_signal("request_back"):
		if not page.is_connected("request_back", Callable(self, "_on_subpage_back")):
			page.connect("request_back", Callable(self, "_on_subpage_back"))

func _enter_current_page() -> void:
	if current_page == null:
		return
	in_subpage = true
	if current_page.has_method("focus_in"):
		current_page.call("focus_in")

func _leave_current_page() -> void:
	if current_page and current_page.has_method("focus_out"):
		current_page.call("focus_out")
	in_subpage = false

func _on_subpage_back() -> void:
	_leave_current_page()
