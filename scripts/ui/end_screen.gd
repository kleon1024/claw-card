extends ColorRect
class_name EndScreen
## Victory/Defeat overlay with styled text and stats.

signal continue_pressed

@onready var title_label: Label = $VBox/TitleLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var continue_button: Button = $VBox/ContinueButton


func _ready() -> void:
	visible = false
	if continue_button:
		continue_button.pressed.connect(_on_continue)
		# Style button
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.35, 0.55)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		continue_button.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate()
		hover.bg_color = Color(0.25, 0.45, 0.7)
		continue_button.add_theme_stylebox_override("hover", hover)
		continue_button.add_theme_color_override("font_color", Color.WHITE)
		continue_button.add_theme_font_size_override("font_size", 16)
		continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func show_result(winner: String, stats: Dictionary) -> void:
	visible = true

	if title_label:
		title_label.add_theme_font_size_override("font_size", 42)
		if winner == "player":
			title_label.text = "VICTORY!"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			title_label.text = "DEFEAT"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))

	if stats_label:
		stats_label.add_theme_font_size_override("font_size", 16)
		stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		var lines: Array = []
		lines.append("Turns: %d" % stats.get("turns", 0))
		var hp: int = stats.get("player_hp", 0)
		var max_hp: int = stats.get("player_max_hp", 80)
		lines.append("HP remaining: %d / %d" % [hp, max_hp])
		if stats.has("enemy_name"):
			lines.append("Enemy: %s" % stats.get("enemy_name", ""))
		stats_label.text = "\n".join(lines)


func _on_continue() -> void:
	continue_pressed.emit()
