extends PanelContainer
class_name CardUI
## Game card with art slot, element border, hover lift, click flash.

var card_data: CardData
var _is_playable: bool = true
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

# Set by CardHand
var hand_index: int = 0
var rest_position: Vector2 = Vector2.ZERO
var rest_rotation: float = 0.0

const ELEMENT_COLORS := {
	"fire": Color(0.95, 0.25, 0.15),
	"water": Color(0.15, 0.5, 0.95),
	"earth": Color(0.65, 0.5, 0.25),
	"lightning": Color(1.0, 0.9, 0.1),
	"void": Color(0.7, 0.2, 0.9),
}
const ELEMENT_BG := {
	"fire": Color(0.1, 0.06, 0.06),
	"water": Color(0.05, 0.08, 0.15),
	"earth": Color(0.1, 0.08, 0.05),
	"lightning": Color(0.1, 0.09, 0.04),
	"void": Color(0.08, 0.05, 0.12),
}
const TYPE_COLORS := {
	"technique": Color(0.7, 0.85, 1.0),
	"beast": Color(0.4, 1.0, 0.55),
	"artifact": Color(1.0, 0.85, 0.35),
}


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pivot_offset = size / 2.0
	_build_base_style()


func _build_base_style() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.067, 0.094, 0.157)
	_style_normal.corner_radius_top_left = 14
	_style_normal.corner_radius_top_right = 14
	_style_normal.corner_radius_bottom_left = 14
	_style_normal.corner_radius_bottom_right = 14
	_style_normal.border_width_left = 1
	_style_normal.border_width_right = 1
	_style_normal.border_width_top = 1
	_style_normal.border_width_bottom = 1
	_style_normal.border_color = Color(0.15, 0.18, 0.25, 0.5)
	_style_normal.content_margin_left = 8
	_style_normal.content_margin_right = 8
	_style_normal.content_margin_top = 6
	_style_normal.content_margin_bottom = 6
	_style_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	_style_normal.shadow_size = 4
	_style_normal.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", _style_normal)


func setup(card: CardData, playable: bool = true) -> void:
	card_data = card
	_is_playable = playable

	# Element color
	var elem_color := Color(0.4, 0.4, 0.45)
	var bg_tint := Color(0.067, 0.094, 0.157)
	if card.elements.size() > 0:
		elem_color = ELEMENT_COLORS.get(card.elements[0], elem_color)
		bg_tint = ELEMENT_BG.get(card.elements[0], bg_tint)
		if card.elements.size() >= 2:
			var c2: Color = ELEMENT_COLORS.get(card.elements[1], elem_color)
			elem_color = elem_color.lerp(c2, 0.25)

	# Style
	_style_normal = _style_normal.duplicate() if _style_normal else StyleBoxFlat.new()
	_style_normal.border_color = elem_color if playable else Color(0.2, 0.2, 0.22)
	_style_normal.bg_color = bg_tint if playable else Color(0.04, 0.05, 0.08, 0.7)
	_style_normal.shadow_color = elem_color.lerp(Color.BLACK, 0.7) if playable else Color(0, 0, 0, 0.2)
	add_theme_stylebox_override("panel", _style_normal)

	_style_hover = _style_normal.duplicate()
	_style_hover.bg_color = bg_tint.lerp(Color.WHITE, 0.08)
	_style_hover.border_width_left = 2
	_style_hover.border_width_right = 2
	_style_hover.border_width_top = 2
	_style_hover.border_width_bottom = 2
	_style_hover.border_color = Color(elem_color.r, elem_color.g, elem_color.b, 0.9)
	_style_hover.shadow_size = 6
	_style_hover.shadow_color = elem_color.lerp(Color.BLACK, 0.4)

	# Type color
	var type_color: Color = TYPE_COLORS.get(card.card_type, Color.WHITE)

	var vbox: VBoxContainer = _ensure_vbox()

	# === COST + TYPE ROW ===
	var cost_lbl: Label = vbox.get_node("TopRow/CostLabel")
	cost_lbl.text = "%d" % card.energy_cost
	cost_lbl.add_theme_font_size_override("font_size", 20)
	cost_lbl.add_theme_color_override("font_color",
		Color(0.3, 0.8, 1.0) if playable else Color(0.8, 0.3, 0.3))

	var type_lbl: Label = vbox.get_node("TopRow/TypeLabel")
	type_lbl.text = card.card_type.to_upper()
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", type_color.lerp(Color.GRAY, 0.3))

	# === CARD ART ===
	var art_rect: TextureRect = vbox.get_node("ArtRect")
	var art_path := "res://assets/sprites/cards/card_%s.png" % card.id
	var art_tex = load(art_path)
	if art_tex:
		art_rect.texture = art_tex
		var placeholder: ColorRect = art_rect.get_node_or_null("Placeholder")
		if placeholder:
			placeholder.visible = false
	else:
		var placeholder: ColorRect = art_rect.get_node_or_null("Placeholder")
		if placeholder:
			placeholder.visible = true
			placeholder.color = elem_color.lerp(Color.BLACK, 0.7)
		art_rect.texture = null

	# === NAME ===
	var name_lbl: Label = vbox.get_node("NameLabel")
	name_lbl.text = card.name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color",
		Color.WHITE if playable else Color(0.5, 0.5, 0.55))

	# === SEPARATOR ===
	var sep: Label = vbox.get_node_or_null("Separator")
	if sep:
		sep.text = "-------------------"
		sep.add_theme_color_override("font_color", elem_color.lerp(Color.BLACK, 0.5))
		sep.add_theme_font_size_override("font_size", 7)

	# === EFFECTS ===
	var eff_lbl: Label = vbox.get_node("EffectsLabel")
	var lines: Array = []
	if card.damage > 0:
		lines.append("Deal %d damage." % card.damage)
	if card.block > 0:
		lines.append("Gain %d block." % card.block)
	if card.draw > 0:
		lines.append("Draw %d." % card.draw)
	if card.heal > 0:
		lines.append("Heal %d." % card.heal)
	if card.energy_gain > 0:
		lines.append("+%d energy." % card.energy_gain)
	if card.apply_burn > 0:
		lines.append("Apply %d burn." % card.apply_burn)
	if card.apply_poison > 0:
		lines.append("Apply %d poison." % card.apply_poison)
	if card.apply_weak > 0:
		lines.append("Apply %d weak." % card.apply_weak)
	if card.apply_vulnerable > 0:
		lines.append("Apply %d vulnerable." % card.apply_vulnerable)
	if card.gain_strength > 0:
		lines.append("Gain %d strength." % card.gain_strength)
	if card.card_type == Enums.BEAST:
		lines.append("Beast HP %d." % card.beast_hp)
		if card.clan != "":
			lines.append("Clan: %s" % card.clan.replace("_", " ").capitalize())
	eff_lbl.text = "\n".join(lines)
	eff_lbl.add_theme_font_size_override("font_size", 13)
	eff_lbl.add_theme_color_override("font_color",
		Color(0.85, 0.85, 0.9) if playable else Color(0.45, 0.45, 0.5))

	# === KEYWORDS ===
	var kw_lbl: Label = vbox.get_node_or_null("KeywordsLabel")
	if kw_lbl:
		var kws: Array = []
		if card.exhaust: kws.append("EXHAUST")
		if card.chain: kws.append("CHAIN")
		if card.retain: kws.append("RETAIN")
		if card.innate: kws.append("INNATE")
		kw_lbl.text = " . ".join(kws)
		kw_lbl.add_theme_font_size_override("font_size", 10)
		kw_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.25))

	# === ELEMENT BADGES (icons) ===
	var elem_row: HBoxContainer = vbox.get_node("ElementsRow")
	for child in elem_row.get_children():
		child.queue_free()
	for e in card.elements:
		var icon_path := "res://assets/sprites/elem_%s.png" % e
		var tex = load(icon_path)
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(20, 20)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			elem_row.add_child(icon)

	# Playability visual
	if not playable:
		modulate = Color(0.55, 0.55, 0.55, 0.75)
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		modulate = Color.WHITE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## All position/rotation/scale animation is handled by CardHand.
## CardUI only manages its own visual content (labels, art, style).


func _ensure_vbox() -> VBoxContainer:
	var vbox: VBoxContainer = get_node_or_null("VBox")
	if vbox == null:
		vbox = _build_card_layout()
	return vbox


## Builds the card layout programmatically. Called once, reused by setup().
func _build_card_layout() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	# Top row: cost (left) + type (right)
	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	vbox.add_child(top_row)

	var cost := Label.new()
	cost.name = "CostLabel"
	top_row.add_child(cost)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var tp := Label.new()
	tp.name = "TypeLabel"
	top_row.add_child(tp)

	# Art area
	var art := TextureRect.new()
	art.name = "ArtRect"
	art.custom_minimum_size = Vector2(140, 100)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(art)

	var placeholder := ColorRect.new()
	placeholder.name = "Placeholder"
	placeholder.color = Color(0.15, 0.12, 0.12)
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(placeholder)

	# Card name
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Separator
	var sep := Label.new()
	sep.name = "Separator"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sep)

	# Effects
	var eff := Label.new()
	eff.name = "EffectsLabel"
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD
	eff.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(eff)

	# Keywords
	var kw := Label.new()
	kw.name = "KeywordsLabel"
	kw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(kw)

	# Element badges (icon row)
	var elem_row := HBoxContainer.new()
	elem_row.name = "ElementsRow"
	elem_row.alignment = BoxContainer.ALIGNMENT_CENTER
	elem_row.add_theme_constant_override("separation", 4)
	vbox.add_child(elem_row)

	return vbox
