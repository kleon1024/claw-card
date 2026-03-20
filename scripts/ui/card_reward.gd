extends Control
## Card reward screen — pick 1 of 3 cards or skip after battle victory.

const BG := Color(0.04, 0.05, 0.08)
const GOLD_COLOR := Color(1.0, 0.85, 0.25)
const BRIGHT := Color(0.92, 0.92, 0.97)
const DIM := Color(0.55, 0.55, 0.65)
const ACCENT := Color(0.3, 0.6, 1.0)

var _card_container: HBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Forest battle background
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_tex = load("res://assets/sprites/battle_bg_forest.png")
	if bg_tex:
		bg.texture = bg_tex
	else:
		var bg_fallback := ColorRect.new()
		bg_fallback.color = BG
		bg_fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		add_child(bg_fallback)
	add_child(bg)

	# Dark overlay for readability
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.06, 0.7)
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchor_left = 0.1
	vbox.anchor_right = 0.9
	vbox.anchor_top = 0.05
	vbox.anchor_bottom = 0.95
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# Title banner
	var banner_container := Control.new()
	banner_container.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(banner_container)

	var banner_tex = load("res://assets/ui/frames/frame_banner.png")
	if banner_tex:
		var banner := NinePatchRect.new()
		banner.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		banner.texture = banner_tex
		banner.patch_margin_left = 24
		banner.patch_margin_right = 24
		banner.patch_margin_top = 12
		banner.patch_margin_bottom = 12
		banner_container.add_child(banner)

	var title := Label.new()
	title.text = "VICTORY — Choose a Card"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GOLD_COLOR)
	banner_container.add_child(title)

	# Gold reward
	var gold_lbl := Label.new()
	gold_lbl.text = "+ %d Gold (Total: %d)" % [
		ExpeditionManager.pending_gold_reward,
		ExpeditionManager.gold
	]
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_lbl.add_theme_font_size_override("font_size", 22)
	gold_lbl.add_theme_color_override("font_color", GOLD_COLOR.lerp(Color.WHITE, 0.3))
	vbox.add_child(gold_lbl)

	# Card container
	_card_container = HBoxContainer.new()
	_card_container.size_flags_vertical = SIZE_EXPAND_FILL
	_card_container.add_theme_constant_override("separation", 30)
	_card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_card_container)

	# Render reward cards
	for card in ExpeditionManager.pending_rewards:
		_add_reward_card(card)

	# Skip button
	var skip_btn := Button.new()
	skip_btn.text = "SKIP"
	skip_btn.custom_minimum_size = Vector2(240, 56)
	skip_btn.pressed.connect(_on_skip)
	skip_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_style_button_blue(skip_btn)
	var btn_center := CenterContainer.new()
	btn_center.add_child(skip_btn)
	vbox.add_child(btn_center)

	# If no rewards, auto-skip
	if ExpeditionManager.pending_rewards.is_empty():
		await get_tree().create_timer(0.5).timeout
		_on_skip()


func _add_reward_card(card: CardData) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	panel.mouse_default_cursor_shape = CURSOR_POINTING_HAND

	# Element color
	var elem_colors := {
		"fire": Color(0.95, 0.25, 0.15), "water": Color(0.15, 0.5, 0.95),
		"earth": Color(0.65, 0.5, 0.25), "lightning": Color(1.0, 0.9, 0.1),
		"void": Color(0.7, 0.2, 0.9),
	}
	var ec := Color(0.4, 0.4, 0.5)
	if card.elements.size() > 0:
		ec = elem_colors.get(card.elements[0], ec)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = ec
	style.shadow_color = ec.lerp(Color.BLACK, 0.6)
	style.shadow_size = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = card.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(name_lbl)

	# Cost + Type row
	var row := HBoxContainer.new()
	vb.add_child(row)
	var cost_lbl := Label.new()
	cost_lbl.text = "[%d]" % card.energy_cost
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", ACCENT)
	row.add_child(cost_lbl)
	var sp := Control.new()
	sp.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(sp)
	var type_lbl := Label.new()
	type_lbl.text = card.card_type.to_upper()
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", DIM)
	row.add_child(type_lbl)

	# Elements
	var elem_names: Array = []
	for e in card.elements:
		elem_names.append(e.to_upper())
	if elem_names.size() > 0:
		var el := Label.new()
		el.text = " + ".join(elem_names)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		el.add_theme_font_size_override("font_size", 12)
		el.add_theme_color_override("font_color", ec)
		vb.add_child(el)

	# Card art
	var art_rect := TextureRect.new()
	art_rect.custom_minimum_size = Vector2(160, 120)
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_tex = load("res://assets/sprites/cards/card_%s.png" % card.id)
	if art_tex:
		art_rect.texture = art_tex
		vb.add_child(art_rect)
	else:
		var placeholder := ColorRect.new()
		placeholder.color = ec.lerp(Color.BLACK, 0.7)
		placeholder.custom_minimum_size = Vector2(160, 120)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(placeholder)

	# Separator
	var sep := Label.new()
	sep.text = "--------------------"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override("font_size", 8)
	sep.add_theme_color_override("font_color", ec.lerp(Color.BLACK, 0.5))
	vb.add_child(sep)

	# Effects
	var lines: Array = []
	if card.damage > 0: lines.append("Deal %d damage." % card.damage)
	if card.block > 0: lines.append("Gain %d block." % card.block)
	if card.draw > 0: lines.append("Draw %d." % card.draw)
	if card.heal > 0: lines.append("Heal %d." % card.heal)
	if card.energy_gain > 0: lines.append("+%d energy." % card.energy_gain)
	if card.apply_burn > 0: lines.append("Apply %d burn." % card.apply_burn)
	if card.apply_poison > 0: lines.append("Apply %d poison." % card.apply_poison)
	if card.apply_weak > 0: lines.append("Apply %d weak." % card.apply_weak)
	if card.apply_vulnerable > 0: lines.append("Apply %d vulnerable." % card.apply_vulnerable)
	if card.gain_strength > 0: lines.append("Gain %d strength." % card.gain_strength)
	if card.card_type == Enums.BEAST:
		lines.append("Beast HP %d." % card.beast_hp)
		if card.clan != "":
			lines.append("Clan: %s" % card.clan.replace("_", " ").capitalize())
	var eff := Label.new()
	eff.text = "\n".join(lines)
	eff.size_flags_vertical = SIZE_EXPAND_FILL
	eff.add_theme_font_size_override("font_size", 15)
	eff.add_theme_color_override("font_color", BRIGHT)
	vb.add_child(eff)

	# Keywords
	var kws: Array = []
	if card.exhaust: kws.append("EXHAUST")
	if card.chain: kws.append("CHAIN")
	if card.retain: kws.append("RETAIN")
	if card.innate: kws.append("INNATE")
	if kws.size() > 0:
		var kl := Label.new()
		kl.text = " / ".join(kws)
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 12)
		kl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.25))
		vb.add_child(kl)

	_card_container.add_child(panel)

	# Click handler
	var card_id: String = card.id
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_selected(card_id)
	)

	# Hover with scale effect
	panel.mouse_entered.connect(func():
		var hover := style.duplicate()
		hover.bg_color = style.bg_color.lerp(Color.WHITE, 0.06)
		hover.shadow_size = 12
		hover.border_color = ec.lerp(Color.WHITE, 0.3)
		panel.add_theme_stylebox_override("panel", hover)
		var tw := panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.12)
	)
	panel.mouse_exited.connect(func():
		panel.add_theme_stylebox_override("panel", style)
		var tw := panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.1)
	)
	# Set pivot to center for scale effect
	panel.resized.connect(func():
		panel.pivot_offset = panel.size / 2.0
	)


func _on_card_selected(card_id: String) -> void:
	ExpeditionManager.apply_reward(card_id)
	GameManager.go_to_expedition_map()


func _on_skip() -> void:
	ExpeditionManager.skip_reward()
	GameManager.go_to_expedition_map()


func _style_button_blue(btn: Button) -> void:
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
	else:
		var n := StyleBoxFlat.new()
		n.bg_color = ACCENT.lerp(Color.BLACK, 0.4)
		n.corner_radius_top_left = 8
		n.corner_radius_top_right = 8
		n.corner_radius_bottom_left = 8
		n.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _style_button(btn: Button, _accent: Color) -> void:
	var tex_normal = load("res://assets/ui/kenney/btn_brown.png")
	var tex_pressed = load("res://assets/ui/kenney/btn_brown_pressed.png")
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
	else:
		var n := StyleBoxFlat.new()
		n.bg_color = _accent.lerp(Color.BLACK, 0.6)
		n.corner_radius_top_left = 8
		n.corner_radius_top_right = 8
		n.corner_radius_bottom_left = 8
		n.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
