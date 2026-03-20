extends Label
class_name DamagePopup

enum PopupType { DAMAGE, HEAL, BLOCK, STATUS }

const POPUP_COLORS: Dictionary = {
	PopupType.DAMAGE: Color(1.0, 0.3, 0.2),
	PopupType.HEAL: Color(0.3, 1.0, 0.3),
	PopupType.BLOCK: Color(0.3, 0.7, 1.0),
	PopupType.STATUS: Color(1.0, 0.8, 0.2),
}


func show_popup(value: int, pos: Vector2, type: PopupType = PopupType.DAMAGE) -> void:
	match type:
		PopupType.DAMAGE: text = "-%d" % value
		PopupType.HEAL: text = "+%d" % value
		PopupType.BLOCK: text = "+%d BLK" % value
		_: text = str(value)

	var font_sz: int = 24 if type == PopupType.DAMAGE else 20
	add_theme_font_size_override("font_size", font_sz)
	add_theme_color_override("font_color", POPUP_COLORS.get(type, Color.WHITE))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	global_position = pos + Vector2(randf_range(-30, 30), 0)
	modulate.a = 1.0
	visible = true

	var tw: Tween = create_tween()
	tw.tween_property(self, "position:y", position.y - 40.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.15)
	tw.tween_callback(queue_free)
