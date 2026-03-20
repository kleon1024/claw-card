extends TextureRect
class_name CharacterAnimator
## Tween-based character sprite with idle/attack/hurt/death animations.
## Usage: add to scene, call load_sprite(), then call animation methods.

signal animation_finished(anim_name: String)

var _idle_tween: Tween
var _base_position: Vector2 = Vector2.ZERO
var _is_idle: bool = false

const IDLE_AMPLITUDE := 4.0
const IDLE_DURATION := 1.2


func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func load_sprite(sprite_path: String) -> bool:
	var tex = load(sprite_path)
	if tex:
		texture = tex
		return true
	return false


func start_idle() -> void:
	if _is_idle:
		return
	_is_idle = true
	_base_position = position
	_idle_loop()


func stop_idle() -> void:
	_is_idle = false
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
	position = _base_position


func _idle_loop() -> void:
	if not _is_idle:
		return
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "position:y",
		_base_position.y - IDLE_AMPLITUDE, IDLE_DURATION / 2.0)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(self, "position:y",
		_base_position.y, IDLE_DURATION / 2.0)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func attack_lunge(target_pos: Vector2, duration: float = 0.3) -> void:
	var was_idle := _is_idle
	stop_idle()

	var start_pos := position
	# Lunge direction: move 60% toward target
	var lunge_pos := start_pos.lerp(target_pos, 0.6)

	var tw := create_tween()
	# Lunge forward
	tw.tween_property(self, "position", lunge_pos, duration * 0.4)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Flash white
	tw.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.05)
	# Return
	tw.tween_property(self, "position", start_pos, duration * 0.4)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		_base_position = start_pos
		if was_idle:
			start_idle()
		animation_finished.emit("attack_lunge")
	)


func hurt_shake(intensity: float = 8.0, duration: float = 0.3) -> void:
	var was_idle := _is_idle
	stop_idle()

	var start_pos := position
	var tw := create_tween()
	var shake_count := 4
	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity * 0.3, intensity * 0.3))
		tw.tween_property(self, "position", start_pos + offset,
			duration / float(shake_count * 2))
		tw.tween_property(self, "position", start_pos,
			duration / float(shake_count * 2))

	# Red flash
	tw.parallel().tween_property(self, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, duration * 0.6)

	tw.tween_callback(func():
		position = start_pos
		_base_position = start_pos
		if was_idle:
			start_idle()
		animation_finished.emit("hurt_shake")
	)


func death_fade(duration: float = 0.8) -> void:
	stop_idle()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(0.5, 0.1, 0.1, 1.0), duration * 0.3)
	tw.tween_property(self, "modulate", Color(0.5, 0.1, 0.1, 0.0), duration * 0.7)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		animation_finished.emit("death_fade")
	)


func spawn_in(duration: float = 0.4) -> void:
	scale = Vector2.ZERO
	modulate = Color.WHITE
	modulate.a = 0.0
	pivot_offset = size / 2.0

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE, duration)
	tw.parallel().tween_property(self, "modulate:a", 1.0, duration * 0.5)
	tw.tween_callback(func():
		_base_position = position
		start_idle()
		animation_finished.emit("spawn_in")
	)
