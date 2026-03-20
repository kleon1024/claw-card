extends ScrollContainer
class_name CombatLog
## Styled combat log with auto-scroll and dark panel.

@onready var rich_text: RichTextLabel = $RichTextLabel


func _ready() -> void:
	# Style the scroll container background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1, 0.7)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)

	if rich_text == null:
		rich_text = RichTextLabel.new()
		rich_text.bbcode_enabled = true
		rich_text.fit_content = true
		rich_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(rich_text)

	if rich_text:
		rich_text.add_theme_font_size_override("normal_font_size", 12)
		rich_text.add_theme_color_override("default_color", Color(0.7, 0.7, 0.75))


func log_message(text: String, color: String = "white") -> void:
	if rich_text:
		rich_text.append_text("[color=%s]%s[/color]\n" % [color, text])
		await get_tree().process_frame
		scroll_vertical = int(rich_text.get_content_height())


func log_damage(source: String, target: String, amount: int) -> void:
	log_message("%s deals [b]%d[/b] to %s" % [source, amount, target], "red")


func log_block(source: String, amount: int) -> void:
	log_message("%s +%d block" % [source, amount], "cyan")


func clear_log() -> void:
	if rich_text:
		rich_text.clear()
