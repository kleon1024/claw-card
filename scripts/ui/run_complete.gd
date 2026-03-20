extends Control
## Run complete screen — victory or defeat stats for the full expedition.

const BG := Color(0.04, 0.04, 0.06)
const GOLD_COLOR := Color(1.0, 0.85, 0.25)
const VICTORY_COLOR := Color(0.3, 1.0, 0.4)
const DEFEAT_COLOR := Color(1.0, 0.25, 0.2)
const BRIGHT := Color(0.92, 0.92, 0.97)
const DIM := Color(0.55, 0.55, 0.65)


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var is_victory: bool = not ExpeditionManager.is_run_active and ExpeditionManager.player_hp > 0

	# Background
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchor_left = 0.25
	vbox.anchor_right = 0.75
	vbox.anchor_top = 0.1
	vbox.anchor_bottom = 0.85
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# Big title
	var title := Label.new()
	title.text = "EXPEDITION COMPLETE!" if is_victory else "EXPEDITION FAILED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", VICTORY_COLOR if is_victory else DEFEAT_COLOR)
	vbox.add_child(title)

	# Subtitle
	var sub := Label.new()
	if is_victory:
		sub.text = "You conquered all three areas!"
	else:
		var area_name := ExpeditionManager.get_current_area_name()
		sub.text = "Fell in %s" % area_name
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", DIM)
	vbox.add_child(sub)

	# Stats panel
	var stats_panel := PanelContainer.new()
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.07, 0.07, 0.1, 0.9)
	stats_style.corner_radius_top_left = 12
	stats_style.corner_radius_top_right = 12
	stats_style.corner_radius_bottom_left = 12
	stats_style.corner_radius_bottom_right = 12
	stats_style.border_width_left = 2
	stats_style.border_width_right = 2
	stats_style.border_width_top = 2
	stats_style.border_width_bottom = 2
	stats_style.border_color = Color(0.2, 0.2, 0.3)
	stats_style.content_margin_left = 30
	stats_style.content_margin_right = 30
	stats_style.content_margin_top = 20
	stats_style.content_margin_bottom = 20
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	vbox.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 12)
	stats_panel.add_child(stats_vbox)

	_add_stat(stats_vbox, "Areas Cleared", "%d / 3" % ExpeditionManager.current_area)
	_add_stat(stats_vbox, "Battles Won", "%d" % ExpeditionManager.battles_won)
	_add_stat(stats_vbox, "Elites Defeated", "%d" % ExpeditionManager.elites_defeated)
	_add_stat(stats_vbox, "Cards Collected", "%d" % ExpeditionManager.cards_collected)
	_add_stat(stats_vbox, "Gold Earned", "%d" % ExpeditionManager.gold_earned)
	_add_stat(stats_vbox, "Final Deck Size", "%d" % ExpeditionManager.deck.size())
	if is_victory:
		_add_stat(stats_vbox, "HP Remaining", "%d / %d" % [
			ExpeditionManager.player_hp, ExpeditionManager.player_max_hp
		])
	_add_stat(stats_vbox, "Seed", "%d" % ExpeditionManager.run_seed)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var new_run_btn := Button.new()
	new_run_btn.text = "NEW RUN"
	new_run_btn.custom_minimum_size = Vector2(200, 56)
	new_run_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	new_run_btn.pressed.connect(_on_new_run)
	_style_button(new_run_btn, VICTORY_COLOR if is_victory else Color(0.4, 0.6, 0.8))
	btn_hbox.add_child(new_run_btn)

	var menu_btn := Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(200, 56)
	menu_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	menu_btn.pressed.connect(_on_main_menu)
	_style_button(menu_btn, Color(0.4, 0.4, 0.5))
	btn_hbox.add_child(menu_btn)


func _add_stat(container: VBoxContainer, label: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", DIM)
	hbox.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 20)
	val.add_theme_color_override("font_color", BRIGHT)
	hbox.add_child(val)


func _on_new_run() -> void:
	ExpeditionManager.start_run()
	GameManager.go_to_expedition_map()


func _on_main_menu() -> void:
	GameManager.go_to_menu()


func _style_button(btn: Button, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color.lerp(Color.BLACK, 0.6)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = color.lerp(Color.BLACK, 0.3)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate()
	h.bg_color = color.lerp(Color.BLACK, 0.35)
	h.border_color = color
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", color.lerp(Color.WHITE, 0.3))
