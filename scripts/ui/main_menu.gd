extends Control
## Title screen with background image, lobster mascot, and menu buttons.
## Hidden debug panel (Ctrl+D) retains the old enemy selection for testing.

var _debug_panel: VBoxContainer
var _debug_visible: bool = false
var _bg_texture: TextureRect
var _bg_overlay: ColorRect
var _overlay_tween: Tween
var _lobster: CharacterAnimator
var _settings_menu: Control
var _continue_btn: Button

const TITLE_COLOR := Color(1.0, 0.85, 0.45)
const SUBTITLE_COLOR := Color(0.6, 0.6, 0.7)

const ENEMIES := [
	["TUTORIAL", [
		["Slime Scout (HP 28)", "slime_scout"],
	]],
	["EASY", [
		["Shadow Fox (HP 42)", "shadow_fox"],
		["Frost Mage (HP 45)", "frost_mage"],
	]],
	["MEDIUM", [
		["Stone Guardian (HP 72)", "stone_guardian"],
		["Flame Brute (HP 62)", "flame_brute"],
		["Fire Elemental (HP 55)", "fire_elemental"],
	]],
	["BOSS", [
		["Region Boss (HP 95)", "region_boss"],
		["Forest Boss (HP 85)", "forest_boss"],
		["Mountain Boss (HP 100)", "mountain_boss"],
		["Volcano Boss (HP 115)", "volcano_boss"],
	]],
]


func _ready() -> void:
	for child in get_children():
		child.queue_free()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_D and event.ctrl_pressed:
		_debug_visible = not _debug_visible
		if _debug_panel:
			_debug_panel.visible = _debug_visible


func _build_ui() -> void:
	# --- Background image ---
	_bg_texture = TextureRect.new()
	_bg_texture.texture = load("res://assets/sprites/title_bg.png")
	_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bg_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)
	add_child(_bg_texture)

	# --- Dark overlay for readability ---
	_bg_overlay = ColorRect.new()
	_bg_overlay.color = Color(0.0, 0.0, 0.0, 0.25)
	_bg_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_bg_overlay)
	_start_bg_animation()

	# --- Center column ---
	var center := VBoxContainer.new()
	center.layout_mode = 1
	center.anchor_left = 0.25; center.anchor_right = 0.75
	center.anchor_top = 0.08; center.anchor_bottom = 0.92
	center.add_theme_constant_override("separation", 12)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	# Title with shadow
	var title_container := Control.new()
	title_container.custom_minimum_size = Vector2(0, 64)
	title_container.size_flags_horizontal = SIZE_EXPAND_FILL
	center.add_child(title_container)

	var title_shadow := Label.new()
	title_shadow.text = "SHRIMP TRAVEL CLAW"
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_shadow.add_theme_font_size_override("font_size", 56)
	title_shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.6))
	title_shadow.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	title_shadow.offset_left = 3; title_shadow.offset_top = 3
	title_container.add_child(title_shadow)

	var title := Label.new()
	title.text = "SHRIMP TRAVEL CLAW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	title_container.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Card Combat"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", SUBTITLE_COLOR)
	center.add_child(subtitle)

	# Lobster mascot
	_lobster = CharacterAnimator.new()
	_lobster.custom_minimum_size = Vector2(128, 128)
	_lobster.size_flags_horizontal = SIZE_SHRINK_CENTER
	_lobster.load_sprite("res://assets/sprites/player_shrimp.png")
	center.add_child(_lobster)
	_lobster.call_deferred("start_idle")

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	# --- Menu buttons ---
	# Continue button (only visible if a saved run exists)
	_continue_btn = _make_menu_button("Continue Expedition", Color(0.3, 0.7, 0.4))
	_continue_btn.pressed.connect(_on_continue_expedition)
	_continue_btn.visible = SaveManager.has_run_save()
	center.add_child(_continue_btn)

	var btn_expedition := _make_menu_button("New Expedition", Color(0.2, 0.5, 0.9))
	btn_expedition.pressed.connect(_on_new_expedition)
	center.add_child(btn_expedition)

	var btn_settings := _make_menu_button("Settings", Color(0.4, 0.4, 0.5))
	btn_settings.pressed.connect(_on_settings)
	center.add_child(btn_settings)

	# Settings overlay (rendered on top of everything)
	var settings_script: GDScript = load("res://scripts/ui/settings_menu.gd") as GDScript
	_settings_menu = Control.new()
	_settings_menu.set_script(settings_script)
	_settings_menu.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_settings_menu)

	# --- Debug panel (hidden) ---
	_debug_panel = VBoxContainer.new()
	_debug_panel.visible = false
	_debug_panel.layout_mode = 1
	_debug_panel.anchor_left = 0.65; _debug_panel.anchor_right = 0.98
	_debug_panel.anchor_top = 0.05; _debug_panel.anchor_bottom = 0.95
	add_child(_debug_panel)

	var debug_title := Label.new()
	debug_title.text = "DEBUG BATTLE (Ctrl+D)"
	debug_title.add_theme_font_size_override("font_size", 14)
	debug_title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	_debug_panel.add_child(debug_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_debug_panel.add_child(scroll)
	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(scroll_vbox)

	for tier_data in ENEMIES:
		var tier_name: String = tier_data[0]
		var enemies: Array = tier_data[1]
		var tier_lbl := Label.new()
		tier_lbl.text = "-- %s --" % tier_name
		tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_lbl.add_theme_font_size_override("font_size", 12)
		tier_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		scroll_vbox.add_child(tier_lbl)

		for enemy_info in enemies:
			var label: String = enemy_info[0]
			var enemy_id: String = enemy_info[1]
			var btn := Button.new()
			btn.text = label
			btn.custom_minimum_size = Vector2(0, 36)
			btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
			btn.pressed.connect(_on_debug_battle.bind(enemy_id))
			btn.add_theme_font_size_override("font_size", 14)
			scroll_vbox.add_child(btn)


func _on_new_expedition() -> void:
	SaveManager.clear_run_save()
	GameManager.start_expedition()


func _on_continue_expedition() -> void:
	if SaveManager.load_run():
		GameManager.go_to_expedition_map()
	else:
		push_warning("Failed to load saved run")


func _on_settings() -> void:
	_settings_menu.show_menu()


func _on_debug_battle(enemy_id: String) -> void:
	GameManager.start_battle(enemy_id)


func _start_bg_animation() -> void:
	_overlay_tween = create_tween().set_loops()
	_overlay_tween.tween_property(
		_bg_overlay, "color", Color(0.0, 0.0, 0.05, 0.55), 8.0
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_overlay_tween.tween_property(
		_bg_overlay, "color", Color(0.0, 0.0, 0.0, 0.5), 8.0
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _make_menu_button(text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 56)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND

	# Determine which Kenney texture set to use
	var is_blue := accent.b > 0.7 and accent.r < 0.4
	var base_name := "btn_blue" if is_blue else "btn_brown"
	var tex_dir := "res://assets/ui/kenney/"

	# Normal state
	var tex_normal = load(tex_dir + base_name + ".png")
	var n := StyleBoxTexture.new()
	n.texture = tex_normal
	n.texture_margin_left = 12; n.texture_margin_right = 12
	n.texture_margin_top = 8; n.texture_margin_bottom = 8
	n.content_margin_left = 20; n.content_margin_right = 20
	n.content_margin_top = 12; n.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", n)

	# Hover state — brighter modulate
	var h := StyleBoxTexture.new()
	h.texture = tex_normal
	h.texture_margin_left = 12; h.texture_margin_right = 12
	h.texture_margin_top = 8; h.texture_margin_bottom = 8
	h.content_margin_left = 20; h.content_margin_right = 20
	h.content_margin_top = 12; h.content_margin_bottom = 12
	h.modulate_color = Color(1.3, 1.3, 1.3)
	btn.add_theme_stylebox_override("hover", h)

	# Pressed state — use _pressed texture
	var tex_pressed = load(tex_dir + base_name + "_pressed.png")
	var p := StyleBoxTexture.new()
	p.texture = tex_pressed
	p.texture_margin_left = 12; p.texture_margin_right = 12
	p.texture_margin_top = 8; p.texture_margin_bottom = 8
	p.content_margin_left = 20; p.content_margin_right = 20
	p.content_margin_top = 12; p.content_margin_bottom = 12
	btn.add_theme_stylebox_override("pressed", p)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9))
	btn.add_theme_font_size_override("font_size", 24)

	return btn
