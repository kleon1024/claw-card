extends Control
## Expedition map — scrollable vertical node graph with bezier connections.
## Player clicks connected nodes to progress through the area.

const MAP_WIDTH := 7
const COL_SPACING := 160.0
const ROW_SPACING := 150.0
const MAP_MARGIN := Vector2(80, 100)
const NODE_RADIUS := 34.0

const BG_COLOR := Color(0.82, 0.76, 0.65)
const AVAILABLE_GLOW := Color(0.6, 0.3, 0.1, 0.8)
const VISITED_DIM := Color(0.5, 0.45, 0.35, 0.6)
const LINE_COLOR := Color(0.45, 0.38, 0.28, 0.7)  # unvisited: lighter brown, more visible
const LINE_ACTIVE := Color(0.95, 0.75, 0.15, 1.0)  # bright gold
const LINE_VISITED := Color(0.9, 0.25, 0.15, 1.0)  # bright red
const LOCKED_COLOR := Color(0.65, 0.6, 0.55, 0.5)

const AREA_BACKGROUNDS := [
	"res://assets/sprites/battle_bg_forest.png",
	"res://assets/sprites/battle_bg_mountain.png",
	"res://assets/sprites/battle_bg_volcano.png",
]

var _scroll: ScrollContainer
var _map_container: Control
var _node_controls: Dictionary = {}  # node_id -> MapNode (inner class)
var _line_draw: Control  # custom draw node for connection lines
var _title_label: Label
var _hp_label: Label
var _gold_label: Label
var _deck_label: Label
var _glow_tweens: Array = []  # active pulse tweens


func _ready() -> void:
	_build_ui()
	_render_map()


func _build_ui() -> void:
	# Parchment background (StS-style light map)
	var bg_texture := TextureRect.new()
	var paper_path := "res://assets/ui/paper_bg.png"
	if ResourceLoader.exists(paper_path):
		bg_texture.texture = load(paper_path)
	else:
		# Fallback: solid parchment color
		var fallback := ColorRect.new()
		fallback.color = BG_COLOR
		fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		add_child(fallback)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_texture.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg_texture.modulate = Color(0.9, 0.85, 0.75, 1.0)
	add_child(bg_texture)

	# Subtle overlay (very light, just for slight contrast)
	var bg_overlay := ColorRect.new()
	bg_overlay.color = Color(0.0, 0.0, 0.0, 0.1)
	bg_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg_overlay)

	# Top info bar
	var top_bar := PanelContainer.new()
	top_bar.layout_mode = 1
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.06
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.72, 0.66, 0.55, 0.95)
	top_style.content_margin_left = 20
	top_style.content_margin_right = 20
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_bar.add_theme_stylebox_override("panel", top_style)
	add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	top_hbox.add_theme_constant_override("separation", 30)
	top_bar.add_child(top_hbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	top_hbox.add_child(_title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 20)
	_hp_label.add_theme_color_override("font_color", Color(0.2, 0.5, 0.2))
	top_hbox.add_child(_hp_label)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(0.6, 0.45, 0.1))
	top_hbox.add_child(_gold_label)

	_deck_label = Label.new()
	_deck_label.add_theme_font_size_override("font_size", 20)
	_deck_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	top_hbox.add_child(_deck_label)

	# Scroll container for the map
	_scroll = ScrollContainer.new()
	_scroll.layout_mode = 1
	_scroll.anchor_left = 0.05
	_scroll.anchor_right = 0.76
	_scroll.anchor_top = 0.08
	_scroll.anchor_bottom = 0.95
	add_child(_scroll)

	_map_container = Control.new()
	_scroll.add_child(_map_container)

	# Line container (holds Line2D nodes for connections)
	# Add BEFORE map nodes so lines render behind nodes
	_line_draw = Control.new()
	_map_container.add_child(_line_draw)

	# Legend panel (right side, StS-style)
	_build_legend()


func _render_map() -> void:
	# Clear existing node controls
	for key in _node_controls:
		var ctrl: Control = _node_controls[key]
		if is_instance_valid(ctrl):
			ctrl.queue_free()
	_node_controls.clear()

	# Kill active tweens
	for tw in _glow_tweens:
		if tw is Tween and tw.is_valid():
			tw.kill()
	_glow_tweens.clear()

	if not ExpeditionManager.is_run_active:
		return

	# Update info bar
	_title_label.text = "Area %d: %s" % [
		ExpeditionManager.current_area + 1,
		ExpeditionManager.get_current_area_name()
	]
	_hp_label.text = "HP %d/%d" % [ExpeditionManager.player_hp, ExpeditionManager.player_max_hp]
	_gold_label.text = "Gold %d" % ExpeditionManager.gold
	_deck_label.text = "Deck %d" % ExpeditionManager.deck.size()

	var available: Array = ExpeditionManager.get_available_nodes()
	var total_rows: int = ExpeditionManager.map_nodes.size()

	# Calculate map container size
	var container_w: float = MAP_WIDTH * COL_SPACING + MAP_MARGIN.x * 2.0
	var container_h: float = total_rows * ROW_SPACING + MAP_MARGIN.y * 2.0
	_map_container.custom_minimum_size = Vector2(container_w, container_h)

	# Render nodes (bottom-up: row 0 at bottom, boss at top)
	for row_idx in range(total_rows):
		var row: Array = ExpeditionManager.map_nodes[row_idx]
		var visual_row: int = total_rows - 1 - row_idx  # flip for display

		for node in row:
			var node_info: Dictionary = ExpeditionManager.NODE_TYPES.get(node.type, {})
			var node_color: Color = node_info.get("color", Color.GRAY)

			var is_available: bool = node.id in available
			var is_visited: bool = node.id in ExpeditionManager.visited_nodes

			var base_x: float = MAP_MARGIN.x + node.col * COL_SPACING
			var base_y: float = MAP_MARGIN.y + visual_row * ROW_SPACING
			var offset: Vector2 = node.get("position_offset", Vector2.ZERO)
			var pos := Vector2(base_x + offset.x, base_y + offset.y)

			var map_node := _MapNodeControl.new()
			map_node.node_type = node.type
			map_node.node_color = node_color
			map_node.radius = NODE_RADIUS
			map_node.is_available = is_available
			map_node.is_visited = is_visited
			map_node.position = pos
			map_node.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)

			if is_available:
				map_node.mouse_default_cursor_shape = CURSOR_POINTING_HAND
				map_node.gui_input.connect(_on_map_node_input.bind(node.id))
				# Glow pulse on all available nodes
				var glow_tween: Tween = create_tween().set_loops()
				glow_tween.tween_property(map_node, "glow_alpha", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
				glow_tween.tween_property(map_node, "glow_alpha", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
				_glow_tweens.append(glow_tween)

			# Starting nodes (row 0): pulsing scale animation
			if row_idx == 0:
				map_node.pivot_offset = Vector2(NODE_RADIUS, NODE_RADIUS)
				var scale_tween: Tween = create_tween().set_loops()
				scale_tween.tween_property(map_node, "scale", Vector2(1.15, 1.15), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				scale_tween.tween_property(map_node, "scale", Vector2(1.0, 1.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_glow_tweens.append(scale_tween)

			_map_container.add_child(map_node)
			_node_controls[node.id] = map_node

	# Player position marker on the last visited node
	_add_player_marker()

	# Set container size so ScrollContainer knows the scroll extent
	var map_w: float = MAP_WIDTH * COL_SPACING + MAP_MARGIN.x * 2
	var map_h: float = total_rows * ROW_SPACING + MAP_MARGIN.y * 2
	_map_container.custom_minimum_size = Vector2(map_w, map_h)
	_line_draw.custom_minimum_size = Vector2(map_w, map_h)
	_line_draw.size = Vector2(map_w, map_h)

	# Wait a frame for layout, then draw connection lines
	await get_tree().process_frame
	_draw_connection_lines()


	# Scroll to show available nodes
	await get_tree().process_frame
	_scroll_to_available()


func _get_node_center(node_id: String) -> Vector2:
	"""Get the visual center of a node control."""
	var ctrl: Control = _node_controls.get(node_id)
	if ctrl == null:
		return Vector2.ZERO
	return ctrl.position + Vector2(NODE_RADIUS, NODE_RADIUS)


func _draw_connection_lines() -> void:
	"""Create Line2D nodes for all map connections."""
	# Clear old lines (Line2D children of _map_container)
	for child in _map_container.get_children():
		if child is Line2D:
			child.queue_free()

	if not ExpeditionManager.is_run_active:
		return
	var available: Array = ExpeditionManager.get_available_nodes()
	var line_count: int = 0

	for row_idx in range(ExpeditionManager.map_nodes.size()):
		var row: Array = ExpeditionManager.map_nodes[row_idx]
		for node in row:
			if not _node_controls.has(node.id):
				continue
			var from_center: Vector2 = _get_node_center(node.id)

			for target_id in node.connections:
				if not _node_controls.has(target_id):
					print("[MAP] Target %s not in _node_controls!" % target_id)
					continue
				var to_center: Vector2 = _get_node_center(target_id)
				line_count += 1

				var is_active: bool = (
					node.id in ExpeditionManager.visited_nodes
					and target_id in available
				)
				var is_visited_path: bool = (
					node.id in ExpeditionManager.visited_nodes
					and target_id in ExpeditionManager.visited_nodes
				)
				var color: Color
				var width: float = 4.0
				if is_active:
					color = LINE_ACTIVE
					width = 6.0
				elif is_visited_path:
					color = LINE_VISITED
					width = 5.0
				else:
					color = LINE_COLOR

				# Bezier curved connection (StS-style)
				var curve := Curve2D.new()
				var distance := from_center.distance_to(to_center)
				var ctrl_mag := distance * 0.3
				# Vertical S-curves: pull up from source, down into target
				curve.add_point(from_center, Vector2.ZERO, Vector2(0, -ctrl_mag))
				curve.add_point(to_center, Vector2(0, ctrl_mag), Vector2.ZERO)

				if not is_active and not is_visited_path:
					# Dotted line for unvisited paths
					var points := curve.get_baked_points()
					var dash_len := 12
					var gap_len := 6
					var i := 0
					while i < points.size() - 1:
						var seg_line := Line2D.new()
						var end_i := mini(i + dash_len, points.size() - 1)
						for j in range(i, end_i + 1):
							seg_line.add_point(points[j])
						seg_line.width = width
						seg_line.default_color = color
						seg_line.antialiased = true
						_map_container.add_child(seg_line)
						_map_container.move_child(seg_line, 0)
						i += dash_len + gap_len
				else:
					# Solid line for visited/active paths
					var line := Line2D.new()
					line.points = curve.get_baked_points()
					line.width = width
					line.default_color = color
					line.antialiased = true
					_map_container.add_child(line)
					_map_container.move_child(line, 0)



func _scroll_to_available() -> void:
	"""Smoothly scroll to show available nodes."""
	var available: Array = ExpeditionManager.get_available_nodes()
	if available.is_empty():
		return
	var first_ctrl: Control = _node_controls.get(available[0])
	if first_ctrl:
		var target_y: float = first_ctrl.position.y - _scroll.size.y / 2.0
		var tween: Tween = create_tween()
		tween.tween_property(
			_scroll, "scroll_vertical",
			int(max(0, target_y)), 0.4
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_map_node_input(event: InputEvent, node_id: String) -> void:
	"""Handle click on a map node control."""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_node_clicked(node_id)


func _on_node_clicked(node_id: String) -> void:
	var node: Dictionary = ExpeditionManager.select_node(node_id)
	if node.is_empty():
		return

	match node.type:
		"battle", "elite":
			ExpeditionManager.setup_battle_state(node)
		"boss":
			ExpeditionManager.setup_battle_state(node)
		"event":
			GameManager.go_to_scene("res://scenes/event_scene.tscn")
		"shop":
			GameManager.go_to_scene("res://scenes/shop_scene.tscn")
		"rest":
			GameManager.go_to_scene("res://scenes/rest_scene.tscn")


func _build_legend() -> void:
	"""Build a StS-style legend panel on the right side."""
	var legend := VBoxContainer.new()
	legend.layout_mode = 1
	legend.anchor_left = 0.78
	legend.anchor_right = 0.98
	legend.anchor_top = 0.12
	legend.anchor_bottom = 0.65
	add_child(legend)

	# Legend background — dark semi-transparent with rounded corners
	var legend_panel := PanelContainer.new()
	var legend_style := StyleBoxFlat.new()
	legend_style.bg_color = Color(0.12, 0.1, 0.08, 0.85)
	legend_style.border_color = Color(0.45, 0.38, 0.25, 0.6)
	legend_style.border_width_left = 2
	legend_style.border_width_right = 2
	legend_style.border_width_top = 2
	legend_style.border_width_bottom = 2
	legend_style.corner_radius_top_left = 14
	legend_style.corner_radius_top_right = 14
	legend_style.corner_radius_bottom_left = 14
	legend_style.corner_radius_bottom_right = 14
	legend_style.content_margin_left = 18
	legend_style.content_margin_right = 18
	legend_style.content_margin_top = 16
	legend_style.content_margin_bottom = 16
	legend_panel.add_theme_stylebox_override("panel", legend_style)
	legend.add_child(legend_panel)

	var legend_vbox := VBoxContainer.new()
	legend_vbox.add_theme_constant_override("separation", 8)
	legend_panel.add_child(legend_vbox)

	var legend_title := Label.new()
	legend_title.text = "Legend"
	legend_title.add_theme_font_size_override("font_size", 20)
	legend_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	legend_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend_vbox.add_child(legend_title)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.5, 0.45, 0.35, 0.4))
	legend_vbox.add_child(sep)

	var entries := [
		["⚔", "Battle", Color(0.7, 0.3, 0.25)],
		["☠", "Elite", Color(0.8, 0.5, 0.1)],
		["★", "Boss", Color(0.8, 0.2, 0.2)],
		["?", "Event", Color(0.3, 0.5, 0.7)],
		["$", "Shop", Color(0.6, 0.5, 0.1)],
		["♨", "Rest", Color(0.3, 0.6, 0.35)],
	]
	for entry in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var icon_label := Label.new()
		icon_label.text = entry[0]
		icon_label.add_theme_font_size_override("font_size", 22)
		icon_label.add_theme_color_override("font_color", entry[2])
		icon_label.custom_minimum_size.x = 30
		row.add_child(icon_label)

		var name_label := Label.new()
		name_label.text = entry[1]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		row.add_child(name_label)

		legend_vbox.add_child(row)

	# Line legend
	var line_sep := HSeparator.new()
	line_sep.add_theme_color_override("separator", Color(0.5, 0.45, 0.35, 0.5))
	legend_vbox.add_child(line_sep)

	var path_entries := [
		["——", "Visited", Color(0.9, 0.25, 0.15)],
		["━━", "Active", Color(0.95, 0.75, 0.15)],
		["- - -", "Unvisited", Color(0.55, 0.48, 0.38)],
	]
	for entry in path_entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var icon_label := Label.new()
		icon_label.text = entry[0]
		icon_label.add_theme_font_size_override("font_size", 16)
		icon_label.add_theme_color_override("font_color", entry[2])
		icon_label.custom_minimum_size.x = 40
		row.add_child(icon_label)

		var name_label := Label.new()
		name_label.text = entry[1]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		row.add_child(name_label)

		legend_vbox.add_child(row)


func _add_player_marker() -> void:
	"""Add a bright marker on the last visited node to show player position."""
	if ExpeditionManager.visited_nodes.is_empty():
		return
	var last_visited: String = ExpeditionManager.visited_nodes[-1]
	var ctrl: Control = _node_controls.get(last_visited)
	if ctrl == null:
		return
	var marker := _PlayerMarker.new()
	marker.position = Vector2(ctrl.position.x + NODE_RADIUS - 14, ctrl.position.y + NODE_RADIUS * 2 + 4)
	marker.size = Vector2(28, 28)
	_map_container.add_child(marker)

	# Pulsing bounce on the player marker
	marker.pivot_offset = Vector2(14, 14)
	var bounce_tween: Tween = create_tween().set_loops()
	bounce_tween.tween_property(marker, "position:y", marker.position.y - 4.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bounce_tween.tween_property(marker, "position:y", marker.position.y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tweens.append(bounce_tween)


# ---------------------------------------------------------------------------
# Inner class: player position marker (small bright triangle)
# ---------------------------------------------------------------------------
class _PlayerMarker extends Control:
	func _draw() -> void:
		# Bright yellow upward arrow — easy to spot
		var points := PackedVector2Array([
			Vector2(14, 0),   # top center
			Vector2(26, 14),  # right wing
			Vector2(18, 12),  # right notch
			Vector2(18, 26),  # right base
			Vector2(10, 26),  # left base
			Vector2(10, 12),  # left notch
			Vector2(2, 14),   # left wing
		])
		draw_colored_polygon(points, Color(1.0, 0.85, 0.1, 0.95))
		draw_polyline(points, Color(0.7, 0.5, 0.0, 0.9), 2.0, true)


# ---------------------------------------------------------------------------
# Inner class: custom-drawn map node with icon text
# ---------------------------------------------------------------------------
class _MapNodeControl extends Control:
	const NODE_ICONS := {
		"battle": "⚔",
		"elite": "☠",
		"event": "?",
		"shop": "$",
		"rest": "♨",
		"boss": "★",
	}

	var node_type: String = "battle"
	var node_color: Color = Color.GRAY
	var radius: float = 28.0
	var is_available: bool = false
	var is_visited: bool = false
	var glow_alpha: float = 1.0:
		set(value):
			glow_alpha = value
			queue_redraw()

	func _ready() -> void:
		size = Vector2(radius * 2, radius * 2)

	func _draw() -> void:
		var center := Vector2(radius, radius)
		var icon_text: String = NODE_ICONS.get(node_type, "?")

		if is_visited:
			# Visited: brown filled circle + check mark
			draw_circle(center, radius, Color(0.45, 0.38, 0.28, 0.8))
			draw_arc(center, radius, 0, TAU, 32, Color(0.35, 0.28, 0.18), 2.5, true)
			_draw_centered_text("✓", center, 24, Color(0.9, 0.85, 0.7, 0.9))
		elif is_available:
			# Available: dark circle with colored border + large icon
			var glow_color := Color(node_color.r, node_color.g, node_color.b, glow_alpha * 0.25)
			draw_circle(center, radius + 10, glow_color)
			draw_circle(center, radius, Color(0.2, 0.18, 0.14, 0.92))
			draw_arc(center, radius, 0, TAU, 32, node_color, 3.5, true)
			_draw_centered_text(icon_text, center, 26, Color(0.95, 0.9, 0.8))
		else:
			# Locked: subtle circle with smaller icon
			draw_circle(center, radius, Color(0.72, 0.67, 0.58, 0.45))
			draw_arc(center, radius, 0, TAU, 32, Color(0.6, 0.55, 0.45, 0.35), 2.0, true)
			_draw_centered_text(icon_text, center, 20, Color(0.55, 0.5, 0.4, 0.5))

	func _draw_centered_text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
		var font: Font = ThemeDB.fallback_font
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(pos.x - text_size.x / 2.0, pos.y + text_size.y / 4.0)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
