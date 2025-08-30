extends Control

signal request_back   # parent can connect to this

@onready var scroll: ScrollContainer = $Scroll
@onready var grid: GridContainer     = $Scroll/Grid

@export var columns: int = 4
@export var slot_scene: PackedScene   # assign in Inspector, or auto-load below

@export var items: Array[Dictionary] = [
	{"name":"Potion",      "qty":3, "icon": null},
	{"name":"Hi-Potion",   "qty":1, "icon": null},
	{"name":"Antidote",    "qty":6, "icon": null},
	{"name":"Bomb",        "qty":2, "icon": null},
	{"name":"Elixir",      "qty":1, "icon": null},
	{"name":"Ether",       "qty":4, "icon": null},
	{"name":"Smoke Bomb",  "qty":1, "icon": null},
	{"name":"Phoenix",     "qty":2, "icon": null},
]

var slots: Array[ItemSlot] = []
var selected: int = 0
var _ready_ok := false

func _ready() -> void:
	if slot_scene == null:
		if ResourceLoader.exists("res://ui/ItemSlot.tscn"):
			slot_scene = load("res://ui/ItemSlot.tscn")
		elif ResourceLoader.exists("res://ItemSlot.tscn"):
			slot_scene = load("res://ItemSlot.tscn")
		else:
			push_error("ItemsPage: slot_scene missing (assign ItemSlot.tscn).")
			return

	_layout_full_rect()
	_build_grid()
	focus_in()                      # start active when opening
	call_deferred("_select", 0)
	_ready_ok = true

# -- public helpers for parent menu --
func focus_in() -> void:
	set_process_input(true)

func focus_out() -> void:
	set_process_input(false)

# ---- layout ----
func _layout_full_rect() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

# ---- grid build ----
func _build_grid() -> void:
	grid.columns = columns
	for c in grid.get_children():
		c.queue_free()
	slots.clear()

	for i in items.size():
		var inst := slot_scene.instantiate()
		if inst is ItemSlot:
			var slot: ItemSlot = inst
			slot.item_name = String(items[i]["name"])
			slot.qty       = int(items[i]["qty"])
			slot.icon      = items[i]["icon"] as Texture2D
			grid.add_child(slot)                      # add first so _ready runs
			slot.call_deferred("set_selected", false) # style AFTER ready
			slots.append(slot)
			slot.clicked.connect(_on_slot_clicked.bind(i))
			slot.mouse_entered.connect(_on_slot_hovered.bind(i))
		else:
			push_error("ItemsPage: slot_scene isn't an ItemSlot.")
			inst.queue_free()

# ---- input (captures before left menu while active) ----
func _input(event: InputEvent) -> void:
	if !_ready_ok or !is_processing_input():
		return
	if event is InputEventKey and event.is_echo():
		return

	var cols: int = max(1, columns)
	var at_left_edge := (selected % cols) == 0

	# Back (Esc/B/Circle) → stop capturing and notify parent
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_cancel"):
		focus_out()
		emit_signal("request_back")
		return

	if event.is_action_pressed("ui_left"):
		if at_left_edge:
			focus_out()
			emit_signal("request_back")
			return
		_move(-1, 0); accept_event(); return

	if event.is_action_pressed("ui_right"):
		_move(1, 0); accept_event(); return

	if event.is_action_pressed("ui_down"):
		_move(0, 1); accept_event(); return

	if event.is_action_pressed("ui_up"):
		_move(0, -1); accept_event(); return

	if event.is_action_pressed("ui_accept"):
		_activate(); accept_event(); return

func _move(dx: int, dy: int) -> void:
	if slots.is_empty():
		return
	var cols: int = max(1, columns)
	var rows: int = int(ceil(float(slots.size()) / float(cols)))
	var x: int = selected % cols
	var y: int = selected / cols
	x = clampi(x + dx, 0, cols - 1)
	y = clampi(y + dy, 0, rows - 1)
	var new_index: int = y * cols + x
	if new_index >= slots.size():
		new_index = slots.size() - 1
	_select(new_index)

func _select(i: int) -> void:
	if slots.is_empty():
		return
	i = clampi(i, 0, slots.size() - 1)
	if selected != i:
		slots[selected].set_selected(false)
	selected = i
	slots[selected].set_selected(true)
	_ensure_selected_visible()

func _ensure_selected_visible() -> void:
	if is_instance_valid(scroll) and selected >= 0 and selected < slots.size():
		scroll.ensure_control_visible(slots[selected])

func _on_slot_clicked(i: int) -> void:
	_select(i)
	_activate()

func _on_slot_hovered(i: int) -> void:
	_select(i)

func _activate() -> void:
	if slots.is_empty():
		return
	var it: Dictionary = items[selected]
	print("Use item:", String(it.get("name", "Unknown")))
