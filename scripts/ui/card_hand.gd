extends Control
class_name CardHand
## Card hand with arc layout, hover lift+scatter, and single-tween-per-card animation.
## Design: hand owns ALL card transforms. Cards only emit signals, never tween themselves.
## Pattern: card_fan_demo (event-driven hover) + gcard_layout (arc math).

signal card_clicked(card_id: String)

const CARD_W: int = 220
const CARD_H: int = 320
const MAX_SPACING: float = 170.0
const ARC_HEIGHT: float = 30.0  # How much center cards lift above edges
const ROT_MAX: float = 5.0  # Max rotation in degrees for edge cards
const HOVER_LIFT: float = 60.0  # Pixels to lift hovered card
const HOVER_SCALE: float = 1.25
const SCATTER: float = 40.0  # Push adjacent cards away on hover
const ANIM_DURATION: float = 0.25
const HOVER_DURATION: float = 0.12

var _cards: Array[CardUI] = []
var _tweens: Dictionary = {}  # CardUI → Tween (one tween per card, always)
var _hovered_index: int = -1


func update_hand(cards: Array, player_energy: int, combo_counter: int) -> void:
	_hovered_index = -1

	# Match by OBJECT REFERENCE, not card ID — critical for duplicate cards (e.g. two Defends)
	var new_refs: Array = []  # CardData object references from game state
	for c in cards:
		new_refs.append(c)

	# Remove CardUI whose card_data object is no longer in the hand
	var to_remove: Array = []
	for card_ui in _cards:
		if card_ui.card_data and not new_refs.has(card_ui.card_data):
			to_remove.append(card_ui)
	for card_ui in to_remove:
		_kill_tween(card_ui)
		_cards.erase(card_ui)
		remove_child(card_ui)
		card_ui.queue_free()

	# Build new card list — match by object reference, not string ID
	var new_list: Array[CardUI] = []
	var matched_uis: Array = []  # Track which CardUIs are already matched
	for card_data in cards:
		var existing: CardUI = null
		for c in _cards:
			if c.card_data == card_data and not matched_uis.has(c):
				existing = c
				matched_uis.append(c)
				break

		if existing:
			var cost: int = card_data.energy_cost
			if card_data.chain and combo_counter >= 2:
				cost = 0
			existing.setup(card_data, cost <= player_energy)
			new_list.append(existing)
		else:
			var card_ui := CardUI.new()
			card_ui.custom_minimum_size = Vector2(CARD_W, CARD_H)
			card_ui.size = Vector2(CARD_W, CARD_H)
			card_ui.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
			add_child(card_ui)

			var cost: int = card_data.energy_cost
			if card_data.chain and combo_counter >= 2:
				cost = 0
			card_ui.setup(card_data, cost <= player_energy)
			card_ui.gui_input.connect(_on_card_input.bind(card_ui))
			card_ui.mouse_entered.connect(_on_card_mouse_entered.bind(card_ui))
			card_ui.mouse_exited.connect(_on_card_mouse_exited.bind(card_ui))
			new_list.append(card_ui)

	# Clean up any unmatched CardUI still in _cards but not in new_list (orphan prevention)
	for card_ui in _cards:
		if not new_list.has(card_ui):
			_kill_tween(card_ui)
			if card_ui.get_parent() == self:
				remove_child(card_ui)
			card_ui.queue_free()

	_cards = new_list
	_apply_layout(ANIM_DURATION)


# === Layout Math ===

func _compute_base_transforms() -> Array:
	## Returns Array of {pos: Vector2, rot: float} for each card in _cards.
	var n: int = _cards.size()
	if n == 0:
		return []

	var cw: float = max(size.x, 800.0)
	var cy: float = size.y * 0.5
	var spacing: float = min(MAX_SPACING, cw / max(n, 1))
	var total_w: float = spacing * (n - 1)

	var result: Array = []
	for i in range(n):
		# Normalized t: -1 (left) to +1 (right)
		var t: float = 0.0
		if n > 1:
			t = (float(i) / float(n - 1)) * 2.0 - 1.0

		# X: centered
		var x: float = (cw - total_w) / 2.0 + spacing * i - CARD_W / 2.0

		# Y: parabolic arc — center cards lift up
		var arc: float = ARC_HEIGHT * (1.0 - t * t)
		var y: float = cy - CARD_H / 2.0 - arc

		# Rotation: linear, edge cards tilted
		var rot: float = t * ROT_MAX

		result.append({pos = Vector2(x, y), rot = rot})
	return result


func _apply_layout(duration: float) -> void:
	var transforms: Array = _compute_base_transforms()
	for i in range(_cards.size()):
		var card_ui: CardUI = _cards[i]
		var tf: Dictionary = transforms[i]

		# Store base transform on card for hover return
		card_ui.hand_index = i
		card_ui.rest_position = tf.pos
		card_ui.rest_rotation = tf.rot

		# Apply hover offset if this card or neighbor of hovered card
		var target_pos: Vector2 = tf.pos
		var target_rot: float = tf.rot
		var target_scale: Vector2 = Vector2.ONE

		if _hovered_index >= 0 and _hovered_index < _cards.size():
			if i == _hovered_index and card_ui._is_playable:
				# Hovered card: lift up, flatten rotation, scale up
				target_pos.y -= HOVER_LIFT
				target_rot = 0.0
				target_scale = Vector2(HOVER_SCALE, HOVER_SCALE)
			else:
				# Scatter: push cards away from hovered card
				var dist: int = i - _hovered_index
				if dist != 0:
					var push: float = SCATTER / float(abs(dist))
					target_pos.x += push * sign(dist)

		card_ui.z_index = 100 if i == _hovered_index else i
		_tween_card(card_ui, target_pos, target_rot, target_scale, duration)


func _tween_card(card_ui: CardUI, pos: Vector2, rot: float, sc: Vector2, duration: float) -> void:
	_kill_tween(card_ui)
	card_ui.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
	var tw: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(card_ui, "position", pos, duration)
	tw.parallel().tween_property(card_ui, "rotation_degrees", rot, duration)
	tw.parallel().tween_property(card_ui, "scale", sc, duration)
	_tweens[card_ui] = tw


func _kill_tween(card_ui: CardUI) -> void:
	if _tweens.has(card_ui):
		var tw: Tween = _tweens[card_ui]
		if tw and tw.is_valid():
			tw.kill()
		_tweens.erase(card_ui)


# === Input Handlers ===

func _on_card_mouse_entered(card_ui: CardUI) -> void:
	var idx: int = _cards.find(card_ui)
	if idx < 0:
		return
	_hovered_index = idx
	_apply_layout(HOVER_DURATION)
	# Style feedback on the card itself
	if card_ui._is_playable and card_ui._style_hover:
		card_ui.add_theme_stylebox_override("panel", card_ui._style_hover)


func _on_card_mouse_exited(card_ui: CardUI) -> void:
	if _cards.find(card_ui) < 0:
		return
	if _hovered_index == _cards.find(card_ui):
		_hovered_index = -1
	_apply_layout(HOVER_DURATION)
	# Style feedback
	if card_ui._style_normal:
		card_ui.add_theme_stylebox_override("panel", card_ui._style_normal)


func _on_card_input(event: InputEvent, card_ui: CardUI) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not card_ui._is_playable or not card_ui.card_data:
		return
	if _cards.find(card_ui) < 0:
		return
	# Click flash
	var flash: Tween = create_tween()
	flash.tween_property(card_ui, "modulate", Color(1.4, 1.4, 1.5), 0.04)
	flash.tween_property(card_ui, "modulate", Color.WHITE, 0.08)
	card_clicked.emit(card_ui.card_data.id)
