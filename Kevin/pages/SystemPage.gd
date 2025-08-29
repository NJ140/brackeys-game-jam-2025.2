extends Control

signal request_back
signal system_action(action: String)

# Root container ("List" or "VBoxContainer")
var list: VBoxContainer

# Rows/controls
var btn_save: Button
var btn_load: Button
var btn_quit: Button

var row_audio: HBoxContainer
var lbl_audio: Label
var sld_audio: HSlider

var row_res: HBoxContainer
var lbl_res: Label
var opt_res: OptionButton

var row_full: HBoxContainer
var lbl_full: Label
var chk_full: CheckBox

# Dialogs
var dlg_info: AcceptDialog
var dlg_quit: ConfirmationDialog

# Nav
var entries: Array[Node] = []
var index: int = 0
var _active: bool = false

# Video
var resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]
var res_idx: int = 0

# Audio
var master_bus: int = 0

const BLACK := Color8(10, 10, 10)
const WHITE := Color8(245, 245, 245)

func _pick_child(parent: Node, names: Array[String]) -> Node:
	for n in names:
		if parent.has_node(n):
			return parent.get_node(n)
	return null

func _ready() -> void:
	# Resolve list container
	if has_node("List"):
		list = $List as VBoxContainer
	elif has_node("VBoxContainer"):
		list = $VBoxContainer as VBoxContainer
	else:
		push_error("SystemPage: expected a child named 'List' or 'VBoxContainer'.")
		return

	set_anchors_preset(Control.PRESET_FULL_RECT)
	list.set_anchors_preset(Control.PRESET_FULL_RECT)
	list.add_theme_constant_override("separation", 8)

	# Grab nodes (tolerant to minor name differences)
	btn_save = _pick_child(list, ["BtnSave"]) as Button
	btn_load = _pick_child(list, ["BtnLoad"]) as Button
	btn_quit = _pick_child(list, ["BtnQuit"]) as Button

	row_audio = _pick_child(list, ["RowAudio"]) as HBoxContainer
	if row_audio:
		lbl_audio = _pick_child(row_audio, ["LblAudio", "Label"]) as Label
		sld_audio = _pick_child(row_audio, ["Vol", "HSlider"]) as HSlider

	row_res = _pick_child(list, ["RowRes"]) as HBoxContainer
	if row_res:
		lbl_res = _pick_child(row_res, ["LblRes", "Label"]) as Label
		opt_res = _pick_child(row_res, ["Res", "OptionButton"]) as OptionButton

	row_full = _pick_child(list, ["RowFull"]) as HBoxContainer
	if row_full:
		lbl_full = _pick_child(row_full, ["LblFull", "Label"]) as Label
		chk_full = _pick_child(row_full, ["Full", "CheckBox"]) as CheckBox

	# Make audio slider actually usable
	if row_audio:
		row_audio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if sld_audio:
		sld_audio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sld_audio.custom_minimum_size = Vector2(260, 0)

	# Style/connect buttons
	for b in [btn_save, btn_load, btn_quit]:
		if b == null:
			continue
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.clip_text = true
		b.text = b.text.to_upper()
	if btn_save: btn_save.pressed.connect(_on_btn_pressed.bind("save"))
	if btn_load: btn_load.pressed.connect(_on_btn_pressed.bind("load"))
	if btn_quit: btn_quit.pressed.connect(_on_btn_pressed.bind("quit"))

	# Nav order (only rows that exist)
	for row in [btn_save, btn_load, row_audio, row_res, row_full, btn_quit]:
		if row != null:
			entries.append(row)

	# Audio init
	master_bus = AudioServer.get_bus_index("Master")
	if sld_audio:
		sld_audio.min_value = 0
		sld_audio.max_value = 100
		sld_audio.step = 5
		sld_audio.value_changed.connect(_on_volume_changed)
		var current_db: float = AudioServer.get_bus_volume_db(master_bus)
		sld_audio.value = int(round(clamp(inverse_lerp(-80.0, 0.0, current_db) * 100.0, 0.0, 100.0)))
		_apply_volume()

	# Resolution init
	if opt_res:
		opt_res.clear()
		for i in resolutions.size():
			var r := resolutions[i]
			opt_res.add_item("%dx%d" % [r.x, r.y])
		opt_res.item_selected.connect(_on_res_selected)
		var sz := DisplayServer.window_get_size()
		res_idx = _closest_res_index(sz)
		opt_res.select(res_idx)

	# Fullscreen init
	if chk_full:
		chk_full.toggled.connect(_on_full_toggled)
		var mode := DisplayServer.window_get_mode()
		chk_full.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	# Dialogs
	dlg_info = AcceptDialog.new()
	dlg_info.title = "System"
	add_child(dlg_info)

	dlg_quit = ConfirmationDialog.new()
	dlg_quit.title = "Quit Game"
	dlg_quit.dialog_text = "Are you sure you want to quit?"
	dlg_quit.confirmed.connect(_do_quit)
	add_child(dlg_quit)

	_refresh_focus_visuals()
	focus_out()

# Focus control
func focus_in() -> void:
	_active = true
	set_process_input(true)

func focus_out() -> void:
	_active = false
	set_process_input(false)

# Input
func _input(event: InputEvent) -> void:
	if !_active:
		return
	if event is InputEventKey and event.is_echo():
		return

	var kind := _entry_kind(index)

	if event.is_action_pressed("menu_back") or event.is_action_pressed("ui_cancel"):
		focus_out()
		emit_signal("request_back")
		return

	if event.is_action_pressed("menu_down") or event.is_action_pressed("ui_down"):
		_move(1); accept_event(); return
	if event.is_action_pressed("menu_up") or event.is_action_pressed("ui_up"):
		_move(-1); accept_event(); return

	if event.is_action_pressed("menu_left") or event.is_action_pressed("ui_left"):
		match kind:
			"button":
				focus_out()
				emit_signal("request_back")
			"slider":
				if sld_audio:
					sld_audio.value = max(sld_audio.min_value, sld_audio.value - sld_audio.step)
					_apply_volume()
					accept_event()
			"option":
				_cycle_resolution(-1); accept_event()
			"check":
				if chk_full:
					chk_full.button_pressed = false
					_apply_fullscreen()
					accept_event()
		return

	if event.is_action_pressed("menu_right") or event.is_action_pressed("ui_right"):
		match kind:
			"button":
				pass
			"slider":
				if sld_audio:
					sld_audio.value = min(sld_audio.max_value, sld_audio.value + sld_audio.step)
					_apply_volume()
					accept_event()
			"option":
				_cycle_resolution(1); accept_event()
			"check":
				if chk_full:
					chk_full.button_pressed = true
					_apply_fullscreen()
					accept_event()
		return

	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("ui_accept"):
		match kind:
			"button":
				_activate_button(entries[index]); accept_event()
			"slider":
				pass
			"option":
				_cycle_resolution(1); accept_event()
			"check":
				if chk_full:
					chk_full.button_pressed = !chk_full.button_pressed
					_apply_fullscreen()
					accept_event()
		return

# Nav helpers
func _move(delta: int) -> void:
	if entries.is_empty():
		return
	index = (index + delta + entries.size()) % entries.size()
	_refresh_focus_visuals()

func _entry_kind(i: int) -> String:
	if entries.is_empty():
		return "button"
	var n := entries[i]
	if n is Button: return "button"
	if n == row_audio: return "slider"
	if n == row_res:   return "option"
	if n == row_full:  return "check"
	return "button"

# Buttons
func _on_btn_pressed(action: String) -> void:
	match action:
		"save":
			_save_settings()
		"load":
			_load_settings()
		"quit":
			dlg_quit.popup_centered()
	emit_signal("system_action", action)

func _activate_button(node: Node) -> void:
	if node == btn_save:
		_save_settings()
	elif node == btn_load:
		_load_settings()
	elif node == btn_quit:
		dlg_quit.popup_centered()

# Save/Load
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	var vol: int = sld_audio if sld_audio == null else int(sld_audio.value)
	cfg.set_value("audio", "volume", vol)
	cfg.set_value("video", "fullscreen", chk_full != null and chk_full.button_pressed)
	cfg.set_value("video", "res_w", resolutions[res_idx].x)
	cfg.set_value("video", "res_h", resolutions[res_idx].y)
	var err := cfg.save("user://settings.cfg")
	dlg_info.dialog_text = "Settings saved." if err == OK else "Failed to save settings (error %d)." % err
	dlg_info.popup_centered()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://settings.cfg")
	if err != OK:
		dlg_info.dialog_text = "No settings file found."
		dlg_info.popup_centered()
		return

	if sld_audio:
		var vol: int = int(cfg.get_value("audio", "volume", sld_audio.value))
		sld_audio.value = clamp(vol, 0, 100)
		_apply_volume()

	if chk_full:
		chk_full.button_pressed = bool(cfg.get_value("video", "fullscreen", chk_full.button_pressed))
		_apply_fullscreen()

	var w: int = int(cfg.get_value("video", "res_w", resolutions[res_idx].x))
	var h: int = int(cfg.get_value("video", "res_h", resolutions[res_idx].y))
	res_idx = _closest_res_index(Vector2i(w, h))
	if opt_res:
		opt_res.select(res_idx)
	_apply_resolution()

	dlg_info.dialog_text = "Settings loaded."
	dlg_info.popup_centered()

func _do_quit() -> void:
	get_tree().quit()

# Apply live settings
func _on_volume_changed(_v: float) -> void:
	_apply_volume()

func _apply_volume() -> void:
	if sld_audio == null:
		return
	var ratio: float = clamp(float(sld_audio.value) / 100.0, 0.0, 1.0)
	var db: float = lerp(-80.0, 0.0, ratio)
	AudioServer.set_bus_volume_db(master_bus, db)

func _on_res_selected(i: int) -> void:
	res_idx = clamp(i, 0, resolutions.size() - 1)
	_apply_resolution()

func _cycle_resolution(step: int) -> void:
	if opt_res == null:
		return
	res_idx = wrapi(res_idx + step, 0, resolutions.size())
	opt_res.select(res_idx)
	_apply_resolution()

func _apply_resolution() -> void:
	var r: Vector2i = resolutions[res_idx]
	if chk_full != null and chk_full.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(r)

func _on_full_toggled(_pressed: bool) -> void:
	_apply_fullscreen()

func _apply_fullscreen() -> void:
	if chk_full != null and chk_full.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_resolution()

func _closest_res_index(sz: Vector2i) -> int:
	var best: int = 0
	var best_score: int = 1_000_000
	for i in resolutions.size():
		var r: Vector2i = resolutions[i]
		var score: int = abs(r.x - sz.x) + abs(r.y - sz.y)
		if score < best_score:
			best_score = score
			best = i
	return best

# Visuals
func _make_font(weight: float) -> Font:
	var sys := SystemFont.new()
	sys.font_names = ["Noto Sans", "Arial"]
	var fv := FontVariation.new()
	fv.base_font = sys
	fv.variation_opentype = {"wght": weight}
	return fv

func _style_button(btn: Button, focused: bool) -> void:
	if btn == null:
		return
	btn.add_theme_font_override("font", _make_font(700.0 if focused else 600.0))
	btn.add_theme_font_size_override("font_size", 32 if focused else 28)
	btn.add_theme_color_override("font_color", WHITE)
	btn.add_theme_color_override("font_shadow_color", BLACK)
	btn.add_theme_constant_override("shadow_outline_size", 2)
	btn.scale = Vector2(1.02, 1.02) if focused else Vector2.ONE

func _style_label(lbl: Label, focused: bool) -> void:
	if lbl == null:
		return
	lbl.add_theme_font_override("font", _make_font(700.0 if focused else 600.0))
	lbl.add_theme_font_size_override("font_size", 28 if focused else 24)
	lbl.add_theme_color_override("font_color", WHITE)
	lbl.add_theme_color_override("font_shadow_color", BLACK)
	lbl.add_theme_constant_override("shadow_outline_size", 2)

func _refresh_focus_visuals() -> void:
	_style_button(btn_save, index == 0)
	_style_button(btn_load, index == 1)
	_style_label(lbl_audio, index == 2)
	_style_label(lbl_res,   index == 3)
	_style_label(lbl_full,  index == 4)
	_style_button(btn_quit, index == 5)
