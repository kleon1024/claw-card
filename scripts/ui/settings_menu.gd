extends Control
## Settings menu overlay — dark background with volume sliders and fullscreen toggle.
## Built programmatically to match the game's dark UI style.

const PANEL_COLOR := Color(0.08, 0.08, 0.12, 0.95)
const BORDER_COLOR := Color(0.3, 0.3, 0.4)
const TITLE_COLOR := Color(1.0, 0.85, 0.45)
const LABEL_COLOR := Color(0.75, 0.75, 0.8)
const ACCENT_COLOR := Color(0.4, 0.5, 0.9)

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton


func _ready() -> void:
	visible = false
	_build_ui()


func show_menu() -> void:
	# Sync slider values from SettingsManager
	_master_slider.value = SettingsManager.get_master_volume()
	_music_slider.value = SettingsManager.get_music_volume()
	_sfx_slider.value = SettingsManager.get_sfx_volume()
	_fullscreen_check.button_pressed = SettingsManager.get_fullscreen()
	visible = true


func hide_menu() -> void:
	visible = false


func _build_ui() -> void:
	# Dark overlay background
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlay)

	# Center panel
	var panel := PanelContainer.new()
	panel.layout_mode = 1
	panel.anchor_left = 0.3; panel.anchor_right = 0.7
	panel.anchor_top = 0.15; panel.anchor_bottom = 0.85
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
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Volume sliders
	_master_slider = _add_slider_row(vbox, "Master Volume", SettingsManager.get_master_volume())
	_master_slider.value_changed.connect(_on_master_changed)

	_music_slider = _add_slider_row(vbox, "Music Volume", SettingsManager.get_music_volume())
	_music_slider.value_changed.connect(_on_music_changed)

	_sfx_slider = _add_slider_row(vbox, "SFX Volume", SettingsManager.get_sfx_volume())
	_sfx_slider.value_changed.connect(_on_sfx_changed)

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	# Fullscreen toggle
	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 16)
	vbox.add_child(fs_row)
	var fs_label := Label.new()
	fs_label.text = "Fullscreen"
	fs_label.add_theme_font_size_override("font_size", 20)
	fs_label.add_theme_color_override("font_color", LABEL_COLOR)
	fs_label.size_flags_horizontal = SIZE_EXPAND_FILL
	fs_row.add_child(fs_label)
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.button_pressed = SettingsManager.get_fullscreen()
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(_fullscreen_check)

	# Spacer push back button to bottom
	var push := Control.new()
	push.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(push)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(200, 48)
	back_btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	back_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	back_btn.add_theme_font_size_override("font_size", 22)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = ACCENT_COLOR.lerp(Color.BLACK, 0.7)
	btn_style.corner_radius_top_left = 10; btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10; btn_style.corner_radius_bottom_right = 10
	btn_style.border_width_left = 2; btn_style.border_width_right = 2
	btn_style.border_width_top = 2; btn_style.border_width_bottom = 2
	btn_style.border_color = ACCENT_COLOR.lerp(Color.BLACK, 0.4)
	btn_style.content_margin_left = 16; btn_style.content_margin_right = 16
	btn_style.content_margin_top = 8; btn_style.content_margin_bottom = 8
	back_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = ACCENT_COLOR.lerp(Color.BLACK, 0.45)
	btn_hover.border_color = ACCENT_COLOR
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.pressed.connect(hide_menu)
	vbox.add_child(back_btn)


func _add_slider_row(parent: VBoxContainer, label_text: String, initial: float) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.custom_minimum_size = Vector2(0, 24)
	row.add_child(slider)

	return slider


func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_fullscreen(pressed)
