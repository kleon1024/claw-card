extends Control
## Battle scene orchestrator — delegates UI to BattleTheme, EndOverlay, CardHand, BeastPanel.
## Manages battle flow: start → play cards → end turn → victory/defeat.

signal battle_finished(winner: String)

var engine: BattleEngine
var state: BattleState

# UI refs
var _turn_lbl: Label
var _combo_lbl: Label
var _deck_lbl: Label
var _hp_lbl: Label
var _gold_lbl: Label
var _energy_hbox: HBoxContainer
var _energy_orbs: Array = []
var _enemy_name_lbl: Label
var _enemy_animator: CharacterAnimator
var _enemy_portrait_bg: ColorRect
var _enemy_hp_bar: ProgressBar
var _enemy_hp_lbl: Label
var _enemy_intent_lbl: Label
var _enemy_status_hbox: HBoxContainer
var _player_animator: CharacterAnimator
var _player_hp_bar: ProgressBar
var _player_hp_lbl: Label
var _player_status_hbox: HBoxContainer
var _player_str_lbl: Label
var _player_blk_lbl: Label
var _beast_panel: BeastPanel
var _hand: CardHand
var _end_turn_btn: Button
var _log_rtl: RichTextLabel
var _end_overlay: EndOverlay
var _bg_sprite: TextureRect
var _shake_tween: Tween
var _draw_pile_lbl: Label
var _discard_pile_lbl: Label
var _last_enemy_hp_ratio: float = 1.0
var _last_player_hp_ratio: float = 1.0
var _last_enemy_statuses: Dictionary = {}
var _last_player_statuses: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = BattleTheme.BASE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	_bg_sprite = TextureRect.new()
	_bg_sprite.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_sprite.modulate = Color(1, 1, 1, 0.7)
	_bg_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_sprite)

	var bottom_vignette := ColorRect.new()
	bottom_vignette.layout_mode = 1
	bottom_vignette.anchor_left = 0.0; bottom_vignette.anchor_right = 1.0
	bottom_vignette.anchor_top = 0.45; bottom_vignette.anchor_bottom = 1.0
	bottom_vignette.color = Color(0.0, 0.0, 0.0, 0.35)
	bottom_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_vignette)

	_build_top_bar()
	_build_energy_display()
	_build_enemy_area()
	_build_combat_log()
	_build_player_area()

	_beast_panel = BeastPanel.new()
	_beast_panel.layout_mode = 1
	_beast_panel.anchor_left = 0.22; _beast_panel.anchor_right = 0.55
	_beast_panel.anchor_top = 0.48; _beast_panel.anchor_bottom = 0.58
	add_child(_beast_panel)

	_hand = CardHand.new()
	_hand.layout_mode = 1
	_hand.anchor_left = 0.10; _hand.anchor_right = 0.82
	_hand.anchor_top = 0.55; _hand.anchor_bottom = 1.0
	_hand.card_clicked.connect(_on_card_clicked)
	add_child(_hand)

	_end_turn_btn = Button.new()
	_end_turn_btn.text = "END TURN"
	_end_turn_btn.layout_mode = 1
	_end_turn_btn.anchor_left = 0.86; _end_turn_btn.anchor_right = 0.98
	_end_turn_btn.anchor_top = 0.60; _end_turn_btn.anchor_bottom = 0.72
	_end_turn_btn.pressed.connect(_on_end_turn)
	_end_turn_btn.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	BattleTheme.style_button(_end_turn_btn)
	add_child(_end_turn_btn)

	_draw_pile_lbl = BattleTheme.make_label("Draw: 0", 14, BattleTheme.DIM)
	_draw_pile_lbl.layout_mode = 1
	_draw_pile_lbl.anchor_left = 0.02; _draw_pile_lbl.anchor_right = 0.10
	_draw_pile_lbl.anchor_top = 0.69; _draw_pile_lbl.anchor_bottom = 0.73
	_draw_pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_draw_pile_lbl)

	_discard_pile_lbl = BattleTheme.make_label("Disc: 0", 14, BattleTheme.DIM)
	_discard_pile_lbl.layout_mode = 1
	_discard_pile_lbl.anchor_left = 0.86; _discard_pile_lbl.anchor_right = 0.98
	_discard_pile_lbl.anchor_top = 0.73; _discard_pile_lbl.anchor_bottom = 0.77
	_discard_pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_discard_pile_lbl)

	_end_overlay = EndOverlay.new()
	_end_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_end_overlay.visible = false
	_end_overlay.continue_pressed.connect(func(): GameManager.on_battle_complete(state.winner))
	add_child(_end_overlay)


func _build_top_bar() -> void:
	var top_bar := Control.new()
	top_bar.layout_mode = 1
	top_bar.anchor_left = 0.0; top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0; top_bar.anchor_bottom = 0.045
	add_child(top_bar)

	var top_bg := ColorRect.new()
	top_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	top_bg.color = Color(0.0, 0.0, 0.0, 0.4)
	top_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(top_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	hbox.offset_left = 12; hbox.offset_right = -12
	top_bar.add_child(hbox)

	_turn_lbl = BattleTheme.make_label("Turn 0", 18, BattleTheme.DIM)
	hbox.add_child(_turn_lbl)
	_combo_lbl = BattleTheme.make_label("Combo 0", 18, BattleTheme.DIM)
	hbox.add_child(_combo_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	_hp_lbl = BattleTheme.make_label("HP 80/80", 16, BattleTheme.CORAL)
	hbox.add_child(_hp_lbl)
	_gold_lbl = BattleTheme.make_label("Gold 0", 16, BattleTheme.GOLD)
	hbox.add_child(_gold_lbl)
	_deck_lbl = BattleTheme.make_label("Deck 0  Disc 0  Exh 0", 16, BattleTheme.DIM)
	hbox.add_child(_deck_lbl)


func _build_energy_display() -> void:
	var container := Control.new()
	container.layout_mode = 1
	container.anchor_left = 0.02; container.anchor_right = 0.10
	container.anchor_top = 0.58; container.anchor_bottom = 0.68
	add_child(container)

	var energy_bg := ColorRect.new()
	energy_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	energy_bg.color = Color(0.0, 0.0, 0.0, 0.5)
	energy_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(energy_bg)

	_energy_hbox = HBoxContainer.new()
	_energy_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_energy_hbox.add_theme_constant_override("separation", 4)
	_energy_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(_energy_hbox)


func _build_enemy_area() -> void:
	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchor_left = 0.50; vbox.anchor_right = 0.80
	vbox.anchor_top = 0.03; vbox.anchor_bottom = 0.48
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	_enemy_name_lbl = BattleTheme.make_label("Enemy", 28, BattleTheme.PEARL)
	_enemy_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_enemy_name_lbl)

	_enemy_portrait_bg = ColorRect.new()
	_enemy_portrait_bg.custom_minimum_size = Vector2(0, 200)
	_enemy_portrait_bg.color = Color(0, 0, 0, 0)
	_enemy_portrait_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_enemy_portrait_bg)

	_enemy_animator = CharacterAnimator.new()
	_enemy_animator.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_enemy_portrait_bg.add_child(_enemy_animator)

	_enemy_hp_bar = ProgressBar.new()
	_enemy_hp_bar.custom_minimum_size = Vector2(0, 24)
	_enemy_hp_bar.show_percentage = false
	BattleTheme.style_hp_bar(_enemy_hp_bar, 1.0)
	vbox.add_child(_enemy_hp_bar)

	_enemy_hp_lbl = Label.new()
	_enemy_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_enemy_hp_lbl.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_enemy_hp_lbl.add_theme_font_size_override("font_size", 16)
	_enemy_hp_lbl.add_theme_color_override("font_color", Color.WHITE)
	_enemy_hp_bar.add_child(_enemy_hp_lbl)

	_enemy_intent_lbl = BattleTheme.make_label("Intent: ???", 20, BattleTheme.DIM)
	_enemy_intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_enemy_intent_lbl)

	_enemy_status_hbox = HBoxContainer.new()
	_enemy_status_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_status_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_enemy_status_hbox)


func _build_combat_log() -> void:
	var container := Control.new()
	container.layout_mode = 1
	container.anchor_left = 0.78; container.anchor_right = 0.98
	container.anchor_top = 0.05; container.anchor_bottom = 0.55
	container.modulate = Color(1, 1, 1, 0.5)
	add_child(container)

	var log_bg := NinePatchRect.new()
	log_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	log_bg.texture = load("res://assets/ui/kenney/panel_inset_blue.png")
	log_bg.patch_margin_left = 12; log_bg.patch_margin_right = 12
	log_bg.patch_margin_top = 12; log_bg.patch_margin_bottom = 12
	log_bg.modulate = Color(1, 1, 1, 0.7)
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(log_bg)

	var log_vbox := VBoxContainer.new()
	log_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	log_vbox.add_theme_constant_override("separation", 4)
	log_vbox.offset_left = 8; log_vbox.offset_right = -8
	log_vbox.offset_top = 6; log_vbox.offset_bottom = -6
	container.add_child(log_vbox)

	log_vbox.add_child(BattleTheme.make_label("COMBAT LOG", 11, BattleTheme.DIM))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	log_vbox.add_child(scroll)

	_log_rtl = RichTextLabel.new()
	_log_rtl.bbcode_enabled = true
	_log_rtl.fit_content = true
	_log_rtl.size_flags_horizontal = SIZE_EXPAND_FILL
	_log_rtl.add_theme_font_size_override("normal_font_size", 11)
	_log_rtl.add_theme_color_override("default_color", Color(0.65, 0.68, 0.75))
	scroll.add_child(_log_rtl)


func _build_player_area() -> void:
	var vbox := VBoxContainer.new()
	vbox.layout_mode = 1
	vbox.anchor_left = 0.08; vbox.anchor_right = 0.30
	vbox.anchor_top = 0.20; vbox.anchor_bottom = 0.58
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	_player_animator = CharacterAnimator.new()
	_player_animator.custom_minimum_size = Vector2(160, 160)
	_player_animator.load_sprite("res://assets/sprites/player_shrimp.png")
	vbox.add_child(_player_animator)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.custom_minimum_size = Vector2(0, 24)
	_player_hp_bar.show_percentage = false
	_player_hp_bar.max_value = 80; _player_hp_bar.value = 80
	BattleTheme.style_hp_bar(_player_hp_bar, 1.0)
	vbox.add_child(_player_hp_bar)

	_player_hp_lbl = Label.new()
	_player_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_hp_lbl.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_player_hp_lbl.add_theme_font_size_override("font_size", 16)
	_player_hp_lbl.add_theme_color_override("font_color", Color.WHITE)
	_player_hp_lbl.text = "80 / 80"
	_player_hp_bar.add_child(_player_hp_lbl)

	_player_status_hbox = HBoxContainer.new()
	_player_status_hbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_player_status_hbox)
	_player_str_lbl = BattleTheme.make_label("", 16, BattleTheme.CORAL)
	vbox.add_child(_player_str_lbl)
	_player_blk_lbl = BattleTheme.make_label("", 16, BattleTheme.TEAL)
	vbox.add_child(_player_blk_lbl)


# ==================================================================
# VFX
# ==================================================================

func _screen_shake(intensity: float = 4.0, duration: float = 0.2) -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for i in range(3):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5))
		_shake_tween.tween_property(self, "position", offset, duration / 6.0)
		_shake_tween.tween_property(self, "position", Vector2.ZERO, duration / 6.0)


func _spawn_popup(value: int, target: Control, type: DamagePopup.PopupType) -> void:
	var popup := DamagePopup.new()
	add_child(popup)
	popup.show_popup(value, target.global_position + target.size * 0.5, type)


func _update_energy_orbs(current: int, max_energy: int) -> void:
	if _energy_orbs.size() != max_energy:
		for orb in _energy_orbs:
			orb.queue_free()
		_energy_orbs.clear()
		for i in range(max_energy):
			var orb := TextureRect.new()
			orb.custom_minimum_size = Vector2(36, 36)
			orb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_energy_hbox.add_child(orb)
			_energy_orbs.append(orb)
	var tex_full = load("res://assets/sprites/energy_full.png")
	var tex_empty = load("res://assets/sprites/energy_empty.png")
	for i in range(_energy_orbs.size()):
		_energy_orbs[i].texture = tex_full if i < current else tex_empty


# ==================================================================
# Battle flow
# ==================================================================

func start_battle(enemy_id: String, deck: Array = [], area: String = "") -> void:
	engine = BattleEngine.new(randi())
	if GameData and not GameData.params.is_empty():
		engine.p.merge(GameData.params, true)

	state = BattleState.new()
	if deck.is_empty():
		deck = GameData.get_starter_deck()
	state.draw_pile = deck.duplicate()
	state.enemy = GameData.get_enemy(enemy_id)
	if state.enemy == null:
		push_error("Enemy not found: " + enemy_id)
		return

	# Background
	if area != "":
		var bg_path: String = BattleTheme.AREA_BG_MAP.get(area, "")
		if bg_path != "":
			var bg_tex = load(bg_path)
			if bg_tex:
				_bg_sprite.texture = bg_tex

	# Enemy setup
	var _ecol: Color = BattleTheme.ENEMY_COLORS.get(enemy_id, Color(0.3, 0.2, 0.2))
	_enemy_portrait_bg.color = Color(_ecol.r, _ecol.g, _ecol.b, 0.0)
	_enemy_name_lbl.text = state.enemy.enemy_name
	_enemy_animator.load_sprite("res://assets/sprites/%s.png" % enemy_id)
	_enemy_animator.spawn_in()
	_player_animator.start_idle()

	engine._select_enemy_intent(state)
	_log("Battle vs %s (HP %d)" % [state.enemy.enemy_name, state.enemy.max_hp], "gold")
	state = engine.start_turn(state)
	_update_ui()


func _on_card_clicked(card_id: String) -> void:
	if state.is_battle_over:
		return

	var card_name := card_id
	for c in state.hand:
		if c.id == card_id:
			card_name = c.name
			break

	var old_ehp: int = state.enemy.current_hp if state.enemy else 0
	var old_blk := state.player_block
	state = engine.apply_action(state, {action_type = Enums.PLAY_CARD, card_id = card_id})

	_log(">> %s" % card_name, "lime")
	if state.enemy:
		var dmg := old_ehp - state.enemy.current_hp
		if dmg > 0:
			_player_animator.attack_lunge(_enemy_animator.global_position)
			_enemy_animator.hurt_shake(6.0)
			_spawn_popup(dmg, _enemy_portrait_bg, DamagePopup.PopupType.DAMAGE)
			_screen_shake(4.0, 0.2)
			_log("   -%d HP (%d/%d)" % [dmg, maxi(state.enemy.current_hp, 0), state.enemy.max_hp], "red")
	var blk := state.player_block - old_blk
	if blk > 0:
		_spawn_popup(blk, _player_hp_bar, DamagePopup.PopupType.BLOCK)
		_log("   +%d Block" % blk, "cyan")

	_update_ui()
	if state.is_battle_over:
		_on_battle_over()


func _on_end_turn() -> void:
	if state.is_battle_over:
		return
	var old_hp := state.player_hp
	var old_ehp: int = state.enemy.current_hp if state.enemy else 0
	state = engine.apply_action(state, {action_type = Enums.END_TURN, card_id = ""})

	_log("--- End Turn ---", "gray")
	var hp_lost := old_hp - state.player_hp
	if hp_lost > 0:
		_enemy_animator.attack_lunge(_player_animator.global_position)
		_player_animator.hurt_shake(8.0)
		_spawn_popup(hp_lost, _player_hp_bar, DamagePopup.PopupType.DAMAGE)
		_screen_shake(6.0, 0.25)
		_log("   Enemy dealt %d (HP %d/%d)" % [hp_lost, maxi(state.player_hp, 0), state.player_max_hp], "orange")
	if state.enemy:
		var sdmg := old_ehp - state.enemy.current_hp
		if sdmg > 0:
			_spawn_popup(sdmg, _enemy_portrait_bg, DamagePopup.PopupType.DAMAGE)
			_log("   Status dealt %d to enemy" % sdmg, "magenta")

	if state.is_battle_over:
		_update_ui()
		_on_battle_over()
		return
	state = engine.start_turn(state)
	_log("=== Turn %d ===" % state.turn, "white")
	_update_ui()


func _update_ui() -> void:
	_turn_lbl.text = "Turn %d" % state.turn
	_combo_lbl.text = "Combo %d" % state.combo_counter
	_combo_lbl.add_theme_color_override("font_color", BattleTheme.GOLD if state.combo_counter >= 3 else BattleTheme.DIM)
	_hp_lbl.text = "HP %d/%d" % [maxi(state.player_hp, 0), state.player_max_hp]
	var _cur_gold: int = ExpeditionManager.gold if ExpeditionManager else 0
	_gold_lbl.text = "Gold %d" % _cur_gold
	_deck_lbl.text = "Deck %d  Disc %d  Exh %d" % [
		state.draw_pile.size(), state.discard_pile.size(), state.exhaust_pile.size()]
	_update_energy_orbs(state.player_energy, state.player_max_energy)
	_draw_pile_lbl.text = "Draw: %d" % state.draw_pile.size()
	_discard_pile_lbl.text = "Disc: %d" % state.discard_pile.size()

	_update_enemy_ui()
	_update_player_ui()

	_beast_panel.update_beasts(state.beast_slots)
	_hand.update_hand(state.hand, state.player_energy, state.combo_counter)
	_end_turn_btn.disabled = state.is_battle_over


func _update_enemy_ui() -> void:
	if not state.enemy:
		return
	var e := state.enemy
	_enemy_hp_bar.max_value = e.max_hp
	_enemy_hp_bar.value = maxi(e.current_hp, 0)
	_enemy_hp_lbl.text = "%d / %d" % [maxi(e.current_hp, 0), e.max_hp]
	var eratio := float(maxi(e.current_hp, 0)) / float(max(e.max_hp, 1))
	if absf(eratio - _last_enemy_hp_ratio) > 0.01:
		BattleTheme.style_hp_bar(_enemy_hp_bar, eratio)
		_last_enemy_hp_ratio = eratio

	# Intent
	if e.intent.is_empty():
		_enemy_intent_lbl.text = "Intent: ???"
		_enemy_intent_lbl.add_theme_color_override("font_color", BattleTheme.DIM)
	else:
		var a: String = e.intent.get("action_type", "")
		var v: int = e.intent.get("value", 0)
		var ex: String = e.intent.get("extra", "")
		var ic := Color.WHITE
		match a:
			"attack": ic = BattleTheme.CORAL
			"defend": ic = BattleTheme.TEAL
			"buff": ic = BattleTheme.GOLD
			"debuff": ic = Color(0.7, 0.3, 0.85)
			"special": ic = BattleTheme.ACCENT
		_enemy_intent_lbl.add_theme_color_override("font_color", ic)
		match a:
			"attack":
				if ex.begins_with("multi_hit_"):
					var p := ex.replace("multi_hit_", "").split("x")
					_enemy_intent_lbl.text = "ATK %sx%s" % [p[0], p[1]]
				else:
					_enemy_intent_lbl.text = "ATK %d" % v
			"defend": _enemy_intent_lbl.text = "DEF +%d" % v
			"buff": _enemy_intent_lbl.text = "BUFF STR +%d" % v
			"debuff": _enemy_intent_lbl.text = "DEBUFF Weak %d" % v
			"special":
				if ex.begins_with("multi_hit_"):
					var p := ex.replace("multi_hit_", "").split("x")
					_enemy_intent_lbl.text = "MULTI %sx%s" % [p[0], p[1]]
				else:
					_enemy_intent_lbl.text = "SPECIAL"
			_: _enemy_intent_lbl.text = "%s %d" % [a.to_upper(), v]

	# Status icons
	var new_statuses := {
		"burn": e.burn, "poison": e.poison, "weak": e.weak,
		"vuln": e.vulnerable, "str": e.strength, "block": e.block}
	if new_statuses != _last_enemy_statuses:
		_last_enemy_statuses = new_statuses
		for child in _enemy_status_hbox.get_children():
			child.queue_free()
		for key in ["burn", "poison", "weak", "vuln", "str", "block"]:
			if new_statuses[key] > 0:
				var icon := StatusIcon.new()
				icon.setup(key, new_statuses[key])
				_enemy_status_hbox.add_child(icon)


func _update_player_ui() -> void:
	_player_hp_bar.max_value = state.player_max_hp
	_player_hp_bar.value = maxi(state.player_hp, 0)
	_player_hp_lbl.text = "%d / %d" % [maxi(state.player_hp, 0), state.player_max_hp]
	var pratio := float(maxi(state.player_hp, 0)) / float(max(state.player_max_hp, 1))
	if absf(pratio - _last_player_hp_ratio) > 0.01:
		BattleTheme.style_hp_bar(_player_hp_bar, pratio)
		_last_player_hp_ratio = pratio

	var new_statuses := {"weak": state.player_weak, "vuln": state.player_vulnerable}
	if new_statuses != _last_player_statuses:
		_last_player_statuses = new_statuses
		for child in _player_status_hbox.get_children():
			child.queue_free()
		for key in ["weak", "vuln"]:
			if new_statuses[key] > 0:
				var icon := StatusIcon.new()
				icon.setup(key, new_statuses[key])
				_player_status_hbox.add_child(icon)
	_player_str_lbl.text = "STR +%d" % state.player_strength if state.player_strength > 0 else ""
	_player_blk_lbl.text = "Block %d" % state.player_block if state.player_block > 0 else ""


func _on_battle_over() -> void:
	if state.winner == "player":
		_log("=== VICTORY! ===", "gold")
	else:
		_log("=== DEFEAT ===", "red")

	if state.winner == "player" and state.enemy:
		_enemy_animator.death_fade()
	elif state.winner != "player":
		_player_animator.death_fade()

	_hand.visible = false
	_end_turn_btn.visible = false
	_end_overlay.show_result(state.winner, state)
	battle_finished.emit(state.winner)


func _log(text: String, color: String = "white") -> void:
	if _log_rtl:
		_log_rtl.append_text("[color=%s]%s[/color]\n" % [color, text])
