extends CanvasLayer
## Pause menu — overlay with Resume, Settings, Save & Quit.
## Uses PROCESS_MODE_ALWAYS so it works while the tree is paused.
## Triggered by Escape key via _unhandled_input.

const PANEL_COLOR := Color(0.06, 0.06, 0.1, 0.95)
const BORDER_COLOR := Color(0.3, 0.3, 0.4)
const TITLE_COLOR := Color(1.0, 0.85, 0.45)
const ACCENT_RESUME := Color(0.2, 0.6, 0.3)
const ACCENT_SETTINGS := Color(0.4, 0.4, 0.5)
const ACCENT_QUIT := Color(0.7, 0.2, 0.2)

var _overlay: Control
var _settings_menu: Control  # SettingsMenu instance
var _is_open: bool = false


func _ready() -> void:
	layer = 90
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	_overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _settings_menu.visible:
			_settings_menu.hide_menu()
		elif _is_open:
			_resume()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_is_open = true
	_overlay.visible = true
	get_tree().paused = true


func _resume() -> void:
	_is_open = false
	_overlay.visible = false
	_settings_menu.hide_menu()
	get_tree().paused = false


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.process_mode = PROCESS_MODE_ALWAYS
	add_child(_overlay)

	# Dark backdrop
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(bg)

	# Center panel
	var panel := PanelContainer.new()
	panel.layout_mode = 1
	panel.anchor_left = 0.35; panel.anchor_right = 0.65
	panel.anchor_top = 0.2; panel.anchor_bottom = 0.8
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_COLOR
	panel_style.corner_radius_top_left = 16; panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16; panel_style.corner_radius_bottom_right = 16
	panel_style.border_width_left = 2; panel_style.border_width_right = 2
	panel_style.border_width_top = 2; panel_style.border_width_bottom = 2
	panel_style.border_color = BORDER_COLOR
	panel_style.content_margin_left = 40; panel_style.content_margin_right = 40
	panel_style.content_margin_top = 30; panel_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", panel_style)
	_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Resume button
	var resume_btn := _make_button("Resume", ACCENT_RESUME)
	resume_btn.pressed.connect(_resume)
	vbox.add_child(resume_btn)

	# Settings button
	var settings_btn := _make_button("Settings", ACCENT_SETTINGS)
	settings_btn.pressed.connect(_show_settings)
	vbox.add_child(settings_btn)

	# Save & Quit button
	var quit_btn := _make_button("Save & Quit", ACCENT_QUIT)
	quit_btn.pressed.connect(_save_and_quit)
	vbox.add_child(quit_btn)

	# Settings menu overlay (child of this canvas layer so it renders on top)
	var settings_script: GDScript = load("res://scripts/ui/settings_menu.gd") as GDScript
	_settings_menu = Control.new()
	_settings_menu.set_script(settings_script)
	_settings_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_menu.process_mode = PROCESS_MODE_ALWAYS
	_overlay.add_child(_settings_menu)


func _show_settings() -> void:
	_settings_menu.show_menu()


func _save_and_quit() -> void:
	if ExpeditionManager.is_run_active:
		SaveManager.save_run()
	get_tree().paused = false
	_is_open = false
	_overlay.visible = false
	GameManager.go_to_menu()


func _make_button(text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 22)

	var n := StyleBoxFlat.new()
	n.bg_color = accent.lerp(Color.BLACK, 0.7)
	n.corner_radius_top_left = 10; n.corner_radius_top_right = 10
	n.corner_radius_bottom_left = 10; n.corner_radius_bottom_right = 10
	n.border_width_left = 2; n.border_width_right = 2
	n.border_width_top = 2; n.border_width_bottom = 2
	n.border_color = accent.lerp(Color.BLACK, 0.4)
	n.content_margin_left = 16; n.content_margin_right = 16
	n.content_margin_top = 8; n.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", n)

	var h := n.duplicate()
	h.bg_color = accent.lerp(Color.BLACK, 0.45)
	h.border_color = accent
	btn.add_theme_stylebox_override("hover", h)

	var p := n.duplicate()
	p.bg_color = accent.lerp(Color.BLACK, 0.6)
	btn.add_theme_stylebox_override("pressed", p)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", accent.lerp(Color.WHITE, 0.4))

	return btn
