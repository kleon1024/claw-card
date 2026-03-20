extends Control
## Event scene — random narrative events with choices.

const BG := Color(0.04, 0.06, 0.1)
const BRIGHT := Color(0.92, 0.92, 0.97)
const DIM := Color(0.55, 0.55, 0.65)
const ACCENT := Color(0.3, 0.7, 0.9)

# Event templates: each has title, description, and choices.
# Choices have text, and an effect dict: {hp, gold, card_id, remove_card}
const EVENTS := [
	{
		"title": "Mysterious Shrine",
		"desc": "A glowing shrine hums with ancient energy. Offerings are etched into the stone.",
		"choices": [
			{"text": "Pray for strength (Gain 10 gold)", "effect": {"gold": 10}},
			{"text": "Offer blood (Lose 8 HP, gain a random card)", "effect": {"hp": -8, "random_card": true}},
			{"text": "Walk away", "effect": {}},
		],
	},
	{
		"title": "Wounded Traveler",
		"desc": "A fellow traveler lies on the path, injured. They clutch a satchel tightly.",
		"choices": [
			{"text": "Help them (Lose 5 HP, gain 20 gold)", "effect": {"hp": -5, "gold": 20}},
			{"text": "Rob them (Gain 30 gold, lose 10 HP)", "effect": {"hp": -10, "gold": 30}},
			{"text": "Ignore them", "effect": {}},
		],
	},
	{
		"title": "Ancient Library",
		"desc": "Dusty tomes line the shelves. One book pulses with elemental energy.",
		"choices": [
			{"text": "Study the tome (Gain a random card)", "effect": {"random_card": true}},
			{"text": "Sell the books (Gain 25 gold)", "effect": {"gold": 25}},
			{"text": "Leave quietly", "effect": {}},
		],
	},
	{
		"title": "Cursed Fountain",
		"desc": "Dark water bubbles from a cracked fountain. It smells of iron and starlight.",
		"choices": [
			{"text": "Drink deeply (Heal 15 HP)", "effect": {"hp": 15}},
			{"text": "Bottle it (Gain 15 gold)", "effect": {"gold": 15}},
			{"text": "Smash the fountain (Lose 5 HP, gain 25 gold)", "effect": {"hp": -5, "gold": 25}},
		],
	},
	{
		"title": "Gambling Ghost",
		"desc": "A translucent figure beckons you to a game of chance. 'Double or nothing!'",
		"choices": [
			{"text": "Gamble 20 gold (50/50: gain 40 or lose 20)", "effect": {"gamble": 20}},
			{"text": "Gamble 10 HP (50/50: heal 20 or lose 10)", "effect": {"hp_gamble": 10}},
			{"text": "Decline politely", "effect": {}},
		],
	},
	{
		"title": "Elemental Nexus",
		"desc": "Swirling energies converge at this crossroads. You feel your cards resonating.",
		"choices": [
			{"text": "Channel the energy (Gain a random card, lose 5 HP)", "effect": {"random_card": true, "hp": -5}},
			{"text": "Absorb the energy (Heal 10 HP)", "effect": {"hp": 10}},
			{"text": "Pass through quickly", "effect": {}},
		],
	},
	{
		"title": "Merchant's Cache",
		"desc": "A hidden stash behind a false wall. Whoever left this isn't coming back.",
		"choices": [
			{"text": "Take the gold (Gain 35 gold)", "effect": {"gold": 35}},
			{"text": "Take the card (Gain a random card)", "effect": {"random_card": true}},
			{"text": "Leave it (Good karma: Heal 8 HP)", "effect": {"hp": 8}},
		],
	},
]

var _current_event: Dictionary
var _result_label: Label


func _ready() -> void:
	_pick_event()
	_build_ui()


func _pick_event() -> void:
	var idx := ExpeditionManager.rng.randi() % EVENTS.size()
	_current_event = EVENTS[idx]


func _build_ui() -> void:
	# Background
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

	# Event icon
	var icon := Label.new()
	icon.text = "?"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 64)
	icon.add_theme_color_override("font_color", ACCENT)
	vbox.add_child(icon)

	# Title
	var title := Label.new()
	title.text = _current_event.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", BRIGHT)
	vbox.add_child(title)

	# Description with dialog frame background
	var desc_container := Control.new()
	desc_container.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(desc_container)

	var dialog_tex = load("res://assets/ui/frames/frame_dialog.png")
	if dialog_tex:
		var dialog_bg := NinePatchRect.new()
		dialog_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		dialog_bg.texture = dialog_tex
		dialog_bg.patch_margin_left = 16
		dialog_bg.patch_margin_right = 16
		dialog_bg.patch_margin_top = 16
		dialog_bg.patch_margin_bottom = 16
		dialog_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_container.add_child(dialog_bg)

	var desc := Label.new()
	desc.text = _current_event.desc
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	desc.offset_left = 20
	desc.offset_right = -20
	desc.offset_top = 20
	desc.offset_bottom = -20
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", DIM)
	desc_container.add_child(desc)

	# Choices
	for choice in _current_event.choices:
		var btn := Button.new()
		btn.text = choice.text
		btn.custom_minimum_size = Vector2(0, 50)
		btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		var effect: Dictionary = choice.effect
		btn.pressed.connect(_on_choice.bind(effect))
		_style_choice_button(btn)
		vbox.add_child(btn)

	# Result label (hidden until choice made)
	_result_label = Label.new()
	_result_label.text = ""
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 20)
	_result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	_result_label.visible = false
	vbox.add_child(_result_label)


func _on_choice(effect: Dictionary) -> void:
	var results: Array = []

	# Apply HP change
	if effect.has("hp"):
		var hp_change: int = effect.hp
		ExpeditionManager.player_hp = clampi(
			ExpeditionManager.player_hp + hp_change,
			1, ExpeditionManager.player_max_hp
		)
		if hp_change > 0:
			results.append("Healed %d HP" % hp_change)
		else:
			results.append("Lost %d HP" % abs(hp_change))

	# Apply gold change
	if effect.has("gold"):
		var gold_change: int = effect.gold
		ExpeditionManager.gold = max(0, ExpeditionManager.gold + gold_change)
		ExpeditionManager.gold_earned += max(0, gold_change)
		if gold_change > 0:
			results.append("Gained %d gold" % gold_change)
		else:
			results.append("Lost %d gold" % abs(gold_change))

	# Random card
	if effect.get("random_card", false):
		var rewards := ExpeditionManager._generate_card_rewards(1, false)
		if rewards.size() > 0:
			ExpeditionManager.deck.append(rewards[0])
			ExpeditionManager.cards_collected += 1
			results.append("Gained %s" % rewards[0].name)

	# Gamble gold
	if effect.has("gamble"):
		var stake: int = effect.gamble
		if ExpeditionManager.gold >= stake:
			var win: bool = ExpeditionManager.rng.randi() % 2 == 0
			if win:
				ExpeditionManager.gold += stake
				ExpeditionManager.gold_earned += stake
				results.append("Won %d gold!" % stake)
			else:
				ExpeditionManager.gold -= stake
				results.append("Lost %d gold..." % stake)
		else:
			results.append("Not enough gold to gamble")

	# Gamble HP
	if effect.has("hp_gamble"):
		var stake: int = effect.hp_gamble
		var win: bool = ExpeditionManager.rng.randi() % 2 == 0
		if win:
			ExpeditionManager.player_hp = min(
				ExpeditionManager.player_max_hp,
				ExpeditionManager.player_hp + stake * 2
			)
			results.append("Healed %d HP!" % (stake * 2))
		else:
			ExpeditionManager.player_hp = max(1, ExpeditionManager.player_hp - stake)
			results.append("Lost %d HP..." % stake)

	# Show result and transition
	if results.is_empty():
		results.append("Nothing happened")

	_result_label.text = " | ".join(results)
	_result_label.visible = true

	# Disable choice buttons
	for child in _result_label.get_parent().get_children():
		if child is Button:
			child.disabled = true

	# Auto-transition after delay
	await get_tree().create_timer(1.5).timeout
	GameManager.go_to_expedition_map()


func _style_choice_button(btn: Button) -> void:
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
		n.content_margin_top = 10
		n.content_margin_bottom = 10
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
			p.content_margin_top = 12
			p.content_margin_bottom = 8
			btn.add_theme_stylebox_override("pressed", p)
		var d := n.duplicate()
		d.modulate_color = Color(0.4, 0.4, 0.45)
		btn.add_theme_stylebox_override("disabled", d)
	else:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.1, 0.12, 0.18)
		s.corner_radius_top_left = 8
		s.corner_radius_top_right = 8
		s.corner_radius_bottom_left = 8
		s.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", s)
		var d := s.duplicate()
		d.bg_color = Color(0.06, 0.06, 0.08)
		btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", BRIGHT)
	btn.add_theme_color_override("font_disabled_color", DIM)
