# res://pages/SkillsPage.gd
extends Control

# ---------- demo data (swap for your real data) ----------
const HEROES := {
	"mage": {
		"name": "Mage",
		"points": 3,
		"skills": [
			{"id":"focus", "name":"Arcane Focus", "max":3, "requires":[]},
			{"id":"blink", "name":"Blink",         "max":3, "requires":["focus"]},
			{"id":"storm", "name":"Storm",         "max":3, "requires":["blink"]}
		]
	},
	"knight": {
		"name": "Knight",
		"points": 2,
		"skills": [
			{"id":"guard",  "name":"Guardian Stance", "max":3, "requires":[]},
			{"id":"charge", "name":"Charge",          "max":3, "requires":["guard"]},
			{"id":"smite",  "name":"Smite",           "max":3, "requires":["charge"]}
		]
	}
}

const SKILL_NODE: PackedScene = preload("res://Kevin/pages/SkillNode.tscn")

# ---------- scene refs (resolved safely at runtime) ----------
var header: HBoxContainer = null
var hero_select: OptionButton = null
var points_label: Label = null
var tree_scroll: ScrollContainer = null
var grid: GridContainer = null
var details: RichTextLabel = null

func _wire_nodes() -> void:
	header = get_node_or_null("Header") as HBoxContainer
	hero_select = get_node_or_null("HeroSelect") as OptionButton
	points_label = get_node_or_null("Points") as Label
	tree_scroll = get_node_or_null("Tree") as ScrollContainer
	if tree_scroll:
		grid = tree_scroll.get_node_or_null("Grid") as GridContainer
	else:
		grid = null
	details = get_node_or_null("Details") as RichTextLabel

# ---------- runtime state ----------
var _hero_keys: Array[String] = []
var _current_hero: String = ""
var _points: int = 0                    # total points for this hero
var _spent: int = 0                     # spent this session (simple demo)
var _levels: Dictionary = {}            # { skill_id: int }
var _nodes_by_id: Dictionary = {}       # { skill_id: Control }
var _order_ids: Array[String] = []      # visual order (left->right)
var _selected_index: int = 0

# ---------- lifecycle ----------
func _ready() -> void:
	_wire_nodes()                 # <-- make sure refs exist
	_setup_ui_layout()
	_fill_hero_select()
	if _hero_keys.is_empty():
		push_error("SkillsPage: No heroes in HEROES.")
		return
	_switch_hero(_hero_keys[0])

func _exit_tree() -> void:
	_nodes_by_id.clear()
	_order_ids.clear()

# ---------- UI / layout ----------
func _setup_ui_layout() -> void:
	# Scroll container: horizontal only, row-at-top
	if tree_scroll:
		tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		tree_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
		tree_scroll.custom_minimum_size    = Vector2(0, 240)

	# Grid behaves like a single row that can widen and scroll
	if grid:
		grid.columns = 3                      # will be overridden by skills count
		grid.add_theme_constant_override("h_separation", 48)
		grid.add_theme_constant_override("v_separation", 24)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	if details:
		details.bbcode_enabled = true

	# Only connect if dropdown exists
	if hero_select and not hero_select.item_selected.is_connected(_on_hero_selected):
		hero_select.item_selected.connect(_on_hero_selected)

func _fill_hero_select() -> void:
	if hero_select:
		hero_select.clear()
	_hero_keys.clear()
	# Use the dict order; convert keys to String explicitly
	for k in HEROES.keys():
		var key: String = String(k)
		_hero_keys.append(key)
		if hero_select:
			hero_select.add_item(HEROES[key].get("name", key))

# ---------- hero switching ----------
func _on_hero_selected(i: int) -> void:
	if i < 0 or i >= _hero_keys.size():
		return
	_switch_hero(_hero_keys[i])

func _switch_hero(key: String) -> void:
	_current_hero = key
	var data: Dictionary = HEROES.get(_current_hero, {}) as Dictionary
	_points = int(data.get("points", 0))
	_spent = 0

	# Reset levels
	_levels.clear()
	for s in (data.get("skills", []) as Array):
		var sid: String = String((s as Dictionary).get("id", ""))
		_levels[sid] = 0

	_build_grid_from(data.get("skills", []) as Array)
	_recompute_availability()
	_update_points_label()
	_selected_index = 0
	_ensure_selected_visuals()
	_update_details()

# ---------- build grid ----------
func _build_grid_from(skills: Array) -> void:
	if grid == null:
		return

	# Clear previous nodes
	for c in grid.get_children():
		(c as Node).queue_free()
	_nodes_by_id.clear()
	_order_ids.clear()

	# one row: set columns to the number of skills
	grid.columns = max(1, skills.size())

	# Create tiles left->right
	for s in skills:
		var sd: Dictionary = s as Dictionary
		var sid: String = String(sd.get("id", ""))
		var title: String = String(sd.get("name", sid))
		var max_level: int = int(sd.get("max", 3))

		var node: Control = SKILL_NODE.instantiate() as Control
		node.set("skill_id", sid)
		node.set("title", title)
		node.set("max_level", max_level)

		# Connect click -> attempt upgrade
		if node.has_signal("pressed"):
			node.connect("pressed", Callable(self, "_on_skill_pressed").bind(sid))
		elif node.has_signal("clicked"):
			node.connect("clicked", Callable(self, "_on_skill_pressed").bind(sid))

		grid.add_child(node)
		_nodes_by_id[sid] = node
		_order_ids.append(sid)

	# Let layout settle so spacing/scroll are correct
	await get_tree().process_frame
	if grid: grid.queue_sort()
	await get_tree().process_frame

# ---------- availability / details ----------
func _recompute_availability() -> void:
	var skills: Array = (HEROES.get(_current_hero, {}) as Dictionary).get("skills", []) as Array
	for s in skills:
		var sd: Dictionary = s as Dictionary
		var sid: String = String(sd.get("id", ""))
		var reqs: Array = sd.get("requires", []) as Array

		var ok := true
		for r in reqs:
			if int(_levels.get(String(r), 0)) <= 0:
				ok = false
				break

		var n: Control = _nodes_by_id.get(sid, null) as Control
		if n != null and n.has_method("set"):
			n.set("available", ok)
			# Ready = available and not maxed
			n.set("ready", ok and int(_levels.get(sid, 0)) < int(sd.get("max", 3)))

func _update_points_label() -> void:
	if points_label:
		points_label.text = "SP: %d" % max(0, _points - _spent)

func _update_details() -> void:
	if details == null:
		return
	details.text = ""
	if _order_ids.is_empty():
		return

	# Describe currently selected tile
	var sid: String = _order_ids[_selected_index]
	var skills: Array = (HEROES.get(_current_hero, {}) as Dictionary).get("skills", []) as Array
	var sd: Dictionary = _find_skill_def(sid, skills)
	if sd.is_empty():
		return

	var lvl: int = int(_levels.get(sid, 0))
	var maxl: int = int(sd.get("max", 3))
	var reqs: Array = sd.get("requires", []) as Array

	details.clear()
	details.append_text("[b]%s[/b]\n" % String(sd.get("name", sid)))
	details.append_text("Level: %d / %d\n" % [lvl, maxl])
	if reqs.is_empty():
		details.append_text("Requires: (none)\n")
	else:
		details.append_text("Requires: %s\n" % ", ".join(reqs))

# ---------- selection / input ----------
func _unhandled_input(event: InputEvent) -> void:
	if !_is_active():
		return

	if event.is_action_pressed("menu_left"):
		_move_selection(-1); accept_event()
	elif event.is_action_pressed("menu_right"):
		_move_selection(1); accept_event()
	elif event.is_action_pressed("menu_confirm"):
		_try_upgrade_selected(); accept_event()

func _is_active() -> bool:
	# page is active if it's visible and inside tree
	return is_inside_tree() and visible

func _move_selection(step: int) -> void:
	if _order_ids.is_empty():
		return
	_selected_index = clampi(_selected_index + step, 0, _order_ids.size() - 1)
	_ensure_selected_visuals()
	_update_details()
	_scroll_selected_into_view()

func _ensure_selected_visuals() -> void:
	if grid == null:
		return
	var children: Array = grid.get_children()
	if children.is_empty():
		return

	_selected_index = clampi(_selected_index, 0, children.size() - 1)
	for i in children.size():
		var c: Control = children[i] as Control
		if c and c.has_method("set_selected"):
			c.call("set_selected", i == _selected_index)

func _scroll_selected_into_view() -> void:
	# Keep the selected tile in view for horizontal scrolling
	if tree_scroll == null or _order_ids.is_empty():
		return
	var sid: String = _order_ids[_selected_index]
	var node: Control = _nodes_by_id.get(sid, null) as Control
	if node == null:
		return
	var rect: Rect2 = node.get_global_rect()
	var view: Rect2 = tree_scroll.get_global_rect()
	if rect.position.x < view.position.x:
		tree_scroll.scroll_horizontal = max(0, tree_scroll.scroll_horizontal - int(view.position.x - rect.position.x) - 24)
	elif rect.end.x > view.end.x:
		tree_scroll.scroll_horizontal += int(rect.end.x - view.end.x) + 24

# ---------- click/upgrade ----------
func _on_skill_pressed(skill_id: String) -> void:
	# Select clicked and try upgrade
	var idx := _order_ids.find(skill_id)
	if idx >= 0:
		_selected_index = idx
	_ensure_selected_visuals()
	_update_details()
	_try_upgrade_selected()

func _try_upgrade_selected() -> void:
	if grid == null or grid.get_child_count() == 0:
		return

	var node: Control = grid.get_child(_selected_index) as Control
	if node == null:
		return

	var v: Variant = node.get("skill_id")
	var sid: String = String(v)

	var sd: Dictionary = _find_skill_def(sid, (HEROES.get(_current_hero, {}) as Dictionary).get("skills", []) as Array)
	if sd.is_empty():
		return

	var maxl: int = int(sd.get("max", 3))
	var cur: int = int(_levels.get(sid, 0))
	var pts_left: int = max(0, _points - _spent)

	# Basic rule: must be ready (prereqs met), not maxed, and have points
	var ready := true
	var reqs: Array = sd.get("requires", []) as Array
	for r in reqs:
		if int(_levels.get(String(r), 0)) <= 0:
			ready = false
			break

	if not ready or cur >= maxl or pts_left <= 0:
		return

	_levels[sid] = cur + 1
	_spent += 1
	_update_points_label()
	_recompute_availability()
	_update_details()
	_ensure_selected_visuals()

# ---------- helpers ----------
func _find_skill_def(sid: String, skills: Array) -> Dictionary:
	for s in skills:
		var sd: Dictionary = s as Dictionary
		if String(sd.get("id","")) == sid:
			return sd
	return {}
