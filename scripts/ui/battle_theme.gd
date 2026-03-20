class_name BattleTheme
## Static color palette and style helpers for battle UI.

# Deep Sea Cozy Palette
const BASE: Color = Color(0.04, 0.055, 0.1)
const SURFACE: Color = Color(0.067, 0.094, 0.157)
const SURFACE_LIGHT: Color = Color(0.1, 0.13, 0.2)
const BORDER: Color = Color(0.15, 0.18, 0.25, 0.5)
const ACCENT: Color = Color(0.94, 0.63, 0.19)
const TEAL: Color = Color(0.19, 0.75, 0.69)
const CORAL: Color = Color(1.0, 0.42, 0.42)
const SEA_GREEN: Color = Color(0.42, 1.0, 0.69)
const PEARL: Color = Color(0.91, 0.88, 0.83)
const DIM: Color = Color(0.45, 0.48, 0.55)
const GOLD: Color = Color(1.0, 0.85, 0.25)

const ENEMY_COLORS := {
	"slime_scout": Color(0.3, 0.75, 0.3),
	"shadow_fox": Color(0.4, 0.25, 0.55),
	"frost_mage": Color(0.25, 0.5, 0.85),
	"stone_guardian": Color(0.55, 0.45, 0.3),
	"flame_brute": Color(0.85, 0.3, 0.1),
	"fire_elemental": Color(0.95, 0.45, 0.1),
	"region_boss": Color(0.7, 0.15, 0.15),
	"forest_boss": Color(0.2, 0.55, 0.2),
	"mountain_boss": Color(0.5, 0.4, 0.25),
	"volcano_boss": Color(0.9, 0.2, 0.08),
}

const AREA_BG_MAP := {
	"forest": "res://assets/sprites/battle_bg_forest.png",
	"mountain": "res://assets/sprites/battle_bg_mountain.png",
	"volcano": "res://assets/sprites/battle_bg_volcano.png",
}


static func make_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func style_hp_bar(bar: ProgressBar, ratio: float) -> void:
	var bg_s := StyleBoxFlat.new()
	bg_s.bg_color = Color(0.06, 0.07, 0.12)
	bg_s.corner_radius_top_left = 5
	bg_s.corner_radius_top_right = 5
	bg_s.corner_radius_bottom_left = 5
	bg_s.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", bg_s)

	var fill := StyleBoxFlat.new()
	fill.corner_radius_top_left = 5
	fill.corner_radius_top_right = 5
	fill.corner_radius_bottom_left = 5
	fill.corner_radius_bottom_right = 5
	if ratio > 0.6:
		fill.bg_color = SEA_GREEN.lerp(GOLD, (1.0 - ratio) / 0.4)
	else:
		fill.bg_color = GOLD.lerp(CORAL, (0.6 - ratio) / 0.6)
	bar.add_theme_stylebox_override("fill", fill)


static func style_button(btn: Button) -> void:
	var tex_normal = load("res://assets/ui/kenney/btn_blue.png")
	var tex_pressed = load("res://assets/ui/kenney/btn_blue_pressed.png")
	if tex_normal:
		var n := StyleBoxTexture.new()
		n.texture = tex_normal
		n.texture_margin_left = 12
		n.texture_margin_right = 12
		n.texture_margin_top = 8
		n.texture_margin_bottom = 8
		n.content_margin_left = 16
		n.content_margin_right = 16
		n.content_margin_top = 8
		n.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", n)
		var h := n.duplicate()
		h.modulate_color = Color(1.2, 1.2, 1.3)
		btn.add_theme_stylebox_override("hover", h)
		if tex_pressed:
			var p := StyleBoxTexture.new()
			p.texture = tex_pressed
			p.texture_margin_left = 12
			p.texture_margin_right = 12
			p.texture_margin_top = 8
			p.texture_margin_bottom = 8
			p.content_margin_left = 16
			p.content_margin_right = 16
			p.content_margin_top = 10
			p.content_margin_bottom = 6
			btn.add_theme_stylebox_override("pressed", p)
		var d := n.duplicate()
		d.modulate_color = Color(0.4, 0.4, 0.45)
		btn.add_theme_stylebox_override("disabled", d)
	else:
		var n := StyleBoxFlat.new()
		n.bg_color = Color(0.08, 0.15, 0.28)
		n.corner_radius_top_left = 12; n.corner_radius_top_right = 12
		n.corner_radius_bottom_left = 12; n.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", PEARL)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.32, 0.38))
