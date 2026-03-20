extends PanelContainer
class_name StatusIcon

const STATUS_CONFIG: Dictionary = {
	"burn": {"symbol": "F", "color": Color(1.0, 0.4, 0.13), "bg": Color(0.3, 0.1, 0.05)},
	"poison": {"symbol": "P", "color": Color(0.27, 0.87, 0.27), "bg": Color(0.05, 0.2, 0.05)},
	"weak": {"symbol": "W", "color": Color(0.7, 0.5, 0.85), "bg": Color(0.15, 0.08, 0.2)},
	"vuln": {"symbol": "V", "color": Color(1.0, 0.67, 0.27), "bg": Color(0.25, 0.15, 0.05)},
	"str": {"symbol": "S", "color": Color(1.0, 0.3, 0.2), "bg": Color(0.25, 0.06, 0.06)},
	"block": {"symbol": "B", "color": Color(0.4, 0.75, 1.0), "bg": Color(0.06, 0.12, 0.22)},
	"thorns": {"symbol": "T", "color": Color(0.6, 0.8, 0.3), "bg": Color(0.1, 0.15, 0.05)},
}


func setup(status_name: String, stacks: int) -> void:
	var cfg: Dictionary = STATUS_CONFIG.get(status_name, {"symbol": "?", "color": Color.WHITE, "bg": Color(0.1, 0.1, 0.1)})
	custom_minimum_size = Vector2(44, 28)
	var style := StyleBoxFlat.new()
	style.bg_color = cfg.bg
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = cfg.color.lerp(Color.BLACK, 0.4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 2)
	add_child(hbox)

	var sym_lbl := Label.new()
	sym_lbl.text = cfg.symbol
	sym_lbl.add_theme_font_size_override("font_size", 14)
	sym_lbl.add_theme_color_override("font_color", cfg.color)
	hbox.add_child(sym_lbl)

	var count_lbl := Label.new()
	count_lbl.text = str(stacks)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(count_lbl)

	tooltip_text = "%s x%d" % [status_name.capitalize(), stacks]
