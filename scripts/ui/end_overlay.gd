extends ColorRect
class_name EndOverlay
## Victory/defeat overlay with character sprite, stats, and continue button.

signal continue_pressed


func show_result(winner: String, battle_state: BattleState) -> void:
	# Hide any previous overlay children
	for child in get_children():
		child.queue_free()

	mouse_filter = Control.MOUSE_FILTER_STOP
	color = Color(0, 0, 0, 0)
	visible = true

	# Fade in
	var overlay_tw: Tween = create_tween()
	overlay_tw.tween_property(self, "color:a", 0.92, 0.5).set_ease(Tween.EASE_OUT)

	var is_win: bool = winner == "player"
	var title_color: Color = BattleTheme.GOLD if is_win else BattleTheme.CORAL
	var title_text: String = "VICTORY!" if is_win else "DEFEAT"

	# Title shadow
	var title_shadow := BattleTheme.make_label(title_text, 64, Color(0, 0, 0, 0.6))
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_shadow.layout_mode = 1
	title_shadow.anchor_left = 0.1; title_shadow.anchor_right = 0.9
	title_shadow.anchor_top = 0.18; title_shadow.anchor_bottom = 0.32
	title_shadow.offset_left = 3; title_shadow.offset_top = 3
	add_child(title_shadow)

	# Title text
	var title := BattleTheme.make_label(title_text, 64, title_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.layout_mode = 1
	title.anchor_left = 0.1; title.anchor_right = 0.9
	title.anchor_top = 0.18; title.anchor_bottom = 0.32
	add_child(title)

	# Character sprite
	var char_sprite := TextureRect.new()
	char_sprite.layout_mode = 1
	char_sprite.anchor_left = 0.42; char_sprite.anchor_right = 0.58
	char_sprite.anchor_top = 0.33; char_sprite.anchor_bottom = 0.55
	char_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	char_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var sprite_path: String
	if is_win:
		sprite_path = "res://assets/sprites/player_shrimp.png"
	elif battle_state.enemy:
		sprite_path = "res://assets/sprites/%s.png" % battle_state.enemy.enemy_id
	else:
		sprite_path = "res://assets/sprites/player_shrimp.png"
	var tex = load(sprite_path)
	if tex:
		char_sprite.texture = tex
	add_child(char_sprite)

	# Stats line
	var enemy_name: String = battle_state.enemy.enemy_name if battle_state.enemy else ""
	var stats_text: String = "Turns: %d   |   HP: %d / %d   |   Enemy: %s" % [
		battle_state.turn, maxi(battle_state.player_hp, 0), battle_state.player_max_hp, enemy_name]
	var stats := BattleTheme.make_label(stats_text, 20, BattleTheme.PEARL)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.layout_mode = 1
	stats.anchor_left = 0.1; stats.anchor_right = 0.9
	stats.anchor_top = 0.58; stats.anchor_bottom = 0.65
	add_child(stats)

	# Continue button
	var btn := Button.new()
	btn.text = "CONTINUE"
	btn.layout_mode = 1
	btn.anchor_left = 0.35; btn.anchor_right = 0.65
	btn.anchor_top = 0.68; btn.anchor_bottom = 0.76
	btn.pressed.connect(func(): continue_pressed.emit())
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	BattleTheme.style_button(btn)
	add_child(btn)
