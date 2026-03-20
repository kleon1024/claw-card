extends ProgressBar
class_name HPBar
## HP bar with color gradient (green → yellow → red) and tween animation.

@onready var label: Label = $Label

var _tween: Tween
var _is_enemy: bool = false

const COLOR_FULL := Color(0.2, 0.85, 0.3)
const COLOR_MID := Color(0.95, 0.85, 0.15)
const COLOR_LOW := Color(0.95, 0.2, 0.15)
const COLOR_BG := Color(0.15, 0.15, 0.2)


func _ready() -> void:
	# Style the bar
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	add_theme_stylebox_override("background", bg)
	_update_fill_style(1.0)


func setup(current: int, maximum: int) -> void:
	max_value = maximum
	value = current
	_update_label(current, maximum)
	_update_fill_style(float(current) / float(max(maximum, 1)))


func set_hp(current: int, maximum: int) -> void:
	max_value = maximum
	_update_label(current, maximum)
	_update_fill_style(float(current) / float(max(maximum, 1)))

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", float(current), 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _update_label(current: int, maximum: int) -> void:
	if label:
		label.text = "%d / %d" % [current, maximum]
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color.WHITE)


func _update_fill_style(ratio: float) -> void:
	var fill := StyleBoxFlat.new()
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4

	# Green → yellow → red gradient
	if ratio > 0.6:
		fill.bg_color = COLOR_FULL.lerp(COLOR_MID, (1.0 - ratio) / 0.4)
	else:
		fill.bg_color = COLOR_MID.lerp(COLOR_LOW, (0.6 - ratio) / 0.6)

	add_theme_stylebox_override("fill", fill)
