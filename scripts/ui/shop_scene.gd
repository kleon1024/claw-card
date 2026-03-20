extends Control
## Shop scene — buy cards, remove cards from deck.

const BG := Color(0.05, 0.04, 0.02)
const GOLD_COLOR := Color(1.0, 0.85, 0.25)
const BRIGHT := Color(0.92, 0.92, 0.97)
const DIM := Color(0.55, 0.55, 0.65)

# Prices
const PRICE_COMMON := 50
const PRICE_UNCOMMON := 75
const PRICE_RARE := 100
const PRICE_REMOVE := 75

var _gold_label: Label
var _shop_cards: Array = []  # Array of {card: CardData, price: int}


func _ready() -> void:
	_generate_shop_inventory()
	_build_ui()


func _generate_shop_inventory() -> void:
	"""Pick 5 random cards for sale."""
	_shop_cards = []
	var rng := ExpeditionManager.rng
	var deck_ids: Dictionary = {}
	for card in ExpeditionManager.deck:
		deck_ids[card.id] = true

	var eligible: Array = []
	for card_id in GameData.cards:
		var card: CardData = GameData.cards[card_id]
		if deck_ids.has(card_id):
			continue
		if card.is_artifact:
			continue
		eligible.append(card)

	eligible.shuffle()
	var count: int = min(5, eligible.size())
	for i in range(count):
		var card: CardData = eligible[i]
		var price := _get_card_price(card)
		_shop_cards.append({"card": card, "price": price})


func _get_card_price(card: CardData) -> int:
	# Price by energy cost as rough rarity proxy
	if card.energy_cost == 0:
		return PRICE_COMMON
	elif card.energy_cost == 1:
		return PRICE_COMMON
	elif card.energy_cost == 2:
		return PRICE_UNCOMMON
	return PRICE_RARE


func _build_ui() -> void:
	# Paper background
	var bg_tex_res = load("res://assets/ui/paper_bg.png")
	if bg_tex_res:
		var bg := TextureRect.new()
		bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.texture = bg_tex_res
		bg.modulate = Color(0.7, 0.65, 0.6, 1.0)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = BG
		bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		add_child(bg)
	# Dark overlay for readability
	var bg_overlay := ColorRect.new()
	bg_overlay.color = Color(0.03, 0.02, 0.01, 0.55)
	bg_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_overlay)

	var main_vbox := VBoxContainer.new()
	main_vbox.layout_mode = 1
	main_vbox.anchor_left = 0.05
	main_vbox.anchor_right = 0.95
	main_vbox.anchor_top = 0.03
	main_vbox.anchor_bottom = 0.95
	main_vbox.add_theme_constant_override("separation", 16)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 30)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", GOLD_COLOR)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.text = "Gold: %d" % ExpeditionManager.gold
	_gold_label.add_theme_font_size_override("font_size", 24)
	_gold_label.add_theme_color_override("font_color", GOLD_COLOR)
	header.add_child(_gold_label)

	# Section: Cards for sale
	var buy_title := Label.new()
	buy_title.text = "-- Cards for Sale --"
	buy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_title.add_theme_font_size_override("font_size", 18)
	buy_title.add_theme_color_override("font_color", DIM)
	main_vbox.add_child(buy_title)

	var card_hbox := HBoxContainer.new()
	card_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	card_hbox.add_theme_constant_override("separation", 16)
	card_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(card_hbox)

	for item in _shop_cards:
		_add_shop_card(card_hbox, item.card, item.price)

	# Section: Remove card
	var remove_title := Label.new()
	remove_title.text = "-- Remove a Card (%dg) --" % PRICE_REMOVE
	remove_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remove_title.add_theme_font_size_override("font_size", 18)
	remove_title.add_theme_color_override("font_color", DIM)
	main_vbox.add_child(remove_title)

	var remove_scroll := ScrollContainer.new()
	remove_scroll.custom_minimum_size = Vector2(0, 120)
	main_vbox.add_child(remove_scroll)

	var remove_hbox := HBoxContainer.new()
	remove_hbox.add_theme_constant_override("separation", 10)
	remove_scroll.add_child(remove_hbox)

	for i in range(ExpeditionManager.deck.size()):
		var card: CardData = ExpeditionManager.deck[i]
		var btn := Button.new()
		btn.text = "%s [%d]" % [card.name, card.energy_cost]
		btn.custom_minimum_size = Vector2(140, 40)
		btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		var can_afford: bool = ExpeditionManager.gold >= PRICE_REMOVE
		btn.disabled = not can_afford
		var idx := i
		btn.pressed.connect(_on_remove_card.bind(idx))
		_style_small_button(btn, Color(0.8, 0.3, 0.2) if can_afford else Color(0.3, 0.3, 0.3))
		remove_hbox.add_child(btn)

	# Leave button
	var leave_btn := Button.new()
	leave_btn.text = "LEAVE SHOP"
	leave_btn.custom_minimum_size = Vector2(200, 50)
	leave_btn.pressed.connect(_on_leave)
	leave_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_style_big_button(leave_btn, Color(0.3, 0.5, 0.7))
	var btn_center := CenterContainer.new()
	btn_center.add_child(leave_btn)
	main_vbox.add_child(btn_center)


func _add_shop_card(container: HBoxContainer, card: CardData, price: int) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 0)
	panel.size_flags_vertical = SIZE_EXPAND_FILL

	var elem_colors := {
		"fire": Color(0.95, 0.25, 0.15), "water": Color(0.15, 0.5, 0.95),
		"earth": Color(0.65, 0.5, 0.25), "lightning": Color(1.0, 0.9, 0.1),
		"void": Color(0.7, 0.2, 0.9),
	}
	var ec := Color(0.4, 0.4, 0.5)
	if card.elements.size() > 0:
		ec = elem_colors.get(card.elements[0], ec)

	var can_afford: bool = ExpeditionManager.gold >= price

	# Use Kenney brown panel as NinePatch background
	var panel_tex = load("res://assets/ui/kenney/panel_brown.png")
	if panel_tex:
		var style := StyleBoxTexture.new()
		style.texture = panel_tex
		style.texture_margin_left = 12
		style.texture_margin_right = 12
		style.texture_margin_top = 12
		style.texture_margin_bottom = 12
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		if not can_afford:
			style.modulate_color = Color(0.5, 0.5, 0.55)
		panel.add_theme_stylebox_override("panel", style)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.14) if can_afford else Color(0.06, 0.06, 0.08)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = ec if can_afford else Color(0.2, 0.2, 0.22)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = card.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.WHITE if can_afford else DIM)
	vb.add_child(name_lbl)

	# Price
	var price_lbl := Label.new()
	price_lbl.text = "%dg" % price
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 20)
	price_lbl.add_theme_color_override("font_color", GOLD_COLOR if can_afford else Color(0.5, 0.3, 0.2))
	vb.add_child(price_lbl)

	# Effects summary
	var lines: Array = []
	if card.damage > 0: lines.append("DMG %d" % card.damage)
	if card.block > 0: lines.append("BLK %d" % card.block)
	if card.draw > 0: lines.append("Draw +%d" % card.draw)
	if card.heal > 0: lines.append("Heal +%d" % card.heal)
	if card.card_type == Enums.BEAST:
		lines.append("Beast HP %d" % card.beast_hp)
	var eff := Label.new()
	eff.text = "\n".join(lines)
	eff.add_theme_font_size_override("font_size", 13)
	eff.add_theme_color_override("font_color", BRIGHT if can_afford else DIM)
	vb.add_child(eff)

	container.add_child(panel)

	if can_afford:
		panel.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		var card_id: String = card.id
		var p: int = price
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_buy_card(card_id, p)
		)


func _on_buy_card(card_id: String, price: int) -> void:
	if ExpeditionManager.buy_card(card_id, price):
		# Remove purchased card from shop list (don't re-roll inventory)
		_shop_cards = _shop_cards.filter(func(item): return item.card.id != card_id)
		for child in get_children():
			child.queue_free()
		_build_ui()


func _on_remove_card(card_index: int) -> void:
	if ExpeditionManager.gold < PRICE_REMOVE:
		return
	if ExpeditionManager.sell_card(card_index, 0):
		ExpeditionManager.gold -= PRICE_REMOVE
		# Rebuild
		for child in get_children():
			child.queue_free()
		_build_ui()


func _on_leave() -> void:
	GameManager.go_to_expedition_map()


func _style_small_button(btn: Button, _color: Color) -> void:
	var tex_normal = load("res://assets/ui/kenney/btn_brown.png")
	if tex_normal:
		var n := StyleBoxTexture.new()
		n.texture = tex_normal
		n.texture_margin_left = 8
		n.texture_margin_right = 8
		n.texture_margin_top = 6
		n.texture_margin_bottom = 6
		n.content_margin_left = 10
		n.content_margin_right = 10
		n.content_margin_top = 4
		n.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", n)
		var h := n.duplicate()
		h.modulate_color = Color(1.2, 1.2, 1.3)
		btn.add_theme_stylebox_override("hover", h)
	else:
		var s := StyleBoxFlat.new()
		s.bg_color = _color.lerp(Color.BLACK, 0.6)
		s.corner_radius_top_left = 6
		s.corner_radius_top_right = 6
		s.corner_radius_bottom_left = 6
		s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _style_big_button(btn: Button, _color: Color) -> void:
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
		var s := StyleBoxFlat.new()
		s.bg_color = _color.lerp(Color.BLACK, 0.55)
		s.corner_radius_top_left = 10
		s.corner_radius_top_right = 10
		s.corner_radius_bottom_left = 10
		s.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
