extends Control
## Rest scene — heal HP or remove a card from deck.

const BG := Color(0.04, 0.05, 0.03)
const BRIGHT := Color(0.92, 0.92, 0.97)
const DIM := Color(0.55, 0.55, 0.65)
const HEAL_COLOR := Color(0.3, 0.9, 0.35)
const REMOVE_COLOR := Color(0.9, 0.4, 0.3)

var _deck_container: VBoxContainer
var _mode: String = ""  # "", "remove"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Dark panel background
	var panel_tex = load("res://assets/ui/kenney/panel_brown.png")
	if panel_tex:
		var bg := NinePatchRect.new()
		bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		bg.texture = panel_tex
		bg.patch_margin_left = 12
		bg.patch_margin_right = 12
		bg.patch_margin_top = 12
		bg.patch_margin_bottom = 12
		bg.modulate = Color(0.4, 0.38, 0.35, 1.0)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		var bg := ColorRect.new()
		bg.color = BG
		bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchor_left = 0.2
	vbox.anchor_right = 0.8
	vbox.anchor_top = 0.1
	vbox.anchor_bottom = 0.9
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# Campfire icon
	var fire := Label.new()
	fire.text = "~"
	fire.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fire.add_theme_font_size_override("font_size", 72)
	fire.add_theme_color_override("font_color", Color(1.0, 0.6, 0.15))
	vbox.add_child(fire)

	# Title
	var title := Label.new()
	title.text = "REST STOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BRIGHT)
	vbox.add_child(title)

	# HP display
	var hp_lbl := Label.new()
	hp_lbl.text = "HP: %d / %d" % [ExpeditionManager.player_hp, ExpeditionManager.player_max_hp]
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 22)
	hp_lbl.add_theme_color_override("font_color", HEAL_COLOR)
	vbox.add_child(hp_lbl)

	# Heal button
	var heal_amount := int(ExpeditionManager.player_max_hp * 0.3)
	var heal_btn := Button.new()
	heal_btn.text = "REST — Heal %d HP" % heal_amount
	heal_btn.custom_minimum_size = Vector2(0, 56)
	heal_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	heal_btn.pressed.connect(_on_heal)
	_style_button(heal_btn, HEAL_COLOR)
	vbox.add_child(heal_btn)

	# Remove card button
	var remove_btn := Button.new()
	remove_btn.text = "TOSS — Remove a Card from Deck (%d cards)" % ExpeditionManager.deck.size()
	remove_btn.custom_minimum_size = Vector2(0, 56)
	remove_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	remove_btn.pressed.connect(_on_show_remove)
	_style_button(remove_btn, REMOVE_COLOR)
	vbox.add_child(remove_btn)

	# Deck container (for remove mode)
	_deck_container = VBoxContainer.new()
	_deck_container.add_theme_constant_override("separation", 6)
	_deck_container.visible = false
	vbox.add_child(_deck_container)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	_deck_container.add_child(scroll)

	var deck_list := VBoxContainer.new()
	deck_list.add_theme_constant_override("separation", 4)
	deck_list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(deck_list)

	for i in range(ExpeditionManager.deck.size()):
		var card: CardData = ExpeditionManager.deck[i]
		var btn := Button.new()
		btn.text = "%s  [Cost %d]  %s" % [
			card.name,
			card.energy_cost,
			" + ".join(card.elements).to_upper() if card.elements.size() > 0 else ""
		]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		var idx := i
		btn.pressed.connect(_on_remove_card.bind(idx))
		_style_list_button(btn)
		deck_list.add_child(btn)

	# Cancel remove
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): _deck_container.visible = false)
	cancel_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_style_list_button(cancel_btn)
	_deck_container.add_child(cancel_btn)


func _on_heal() -> void:
	ExpeditionManager.apply_rest_heal()
	GameManager.go_to_expedition_map()


func _on_show_remove() -> void:
	_deck_container.visible = true


func _on_remove_card(card_index: int) -> void:
	ExpeditionManager.apply_rest_remove_card(card_index)
	GameManager.go_to_expedition_map()


func _style_button(btn: Button, _color: Color) -> void:
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
		n.content_margin_top = 12
		n.content_margin_bottom = 12
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
			p.content_margin_top = 14
			p.content_margin_bottom = 10
			btn.add_theme_stylebox_override("pressed", p)
	else:
		var s := StyleBoxFlat.new()
		s.bg_color = _color.lerp(Color.BLACK, 0.65)
		s.corner_radius_top_left = 10
		s.corner_radius_top_right = 10
		s.corner_radius_bottom_left = 10
		s.corner_radius_bottom_right = 10
		s.content_margin_left = 16
		s.content_margin_right = 16
		s.content_margin_top = 12
		s.content_margin_bottom = 12
		btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)


func _style_list_button(btn: Button) -> void:
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
		s.bg_color = Color(0.08, 0.08, 0.12)
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		s.corner_radius_bottom_left = 4
		s.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", BRIGHT)
