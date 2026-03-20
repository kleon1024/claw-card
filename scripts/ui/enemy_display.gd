extends VBoxContainer
class_name EnemyDisplay
## Enemy area with portrait, HP bar, intent display, status effects.

@onready var name_label: Label = $NameLabel
@onready var hp_bar: HPBar = $HPBar
@onready var intent_label: Label = $IntentLabel
@onready var status_label: Label = $StatusLabel
@onready var sprite_rect: ColorRect = $SpriteRect

var _portrait_label: Label  # big initial letter on the portrait
var _portrait_icon: Label   # intent icon on portrait

const INTENT_COLORS := {
	"attack": Color(1.0, 0.3, 0.25),
	"defend": Color(0.3, 0.65, 1.0),
	"buff": Color(1.0, 0.8, 0.15),
	"debuff": Color(0.7, 0.3, 0.85),
	"special": Color(1.0, 0.45, 0.1),
}

const ENEMY_COLORS := {
	"slime_scout": Color(0.3, 0.7, 0.3),
	"shadow_fox": Color(0.35, 0.25, 0.5),
	"frost_mage": Color(0.25, 0.45, 0.8),
	"stone_guardian": Color(0.5, 0.4, 0.3),
	"flame_brute": Color(0.8, 0.3, 0.15),
	"fire_elemental": Color(0.9, 0.4, 0.1),
	"region_boss": Color(0.6, 0.15, 0.15),
	"forest_boss": Color(0.2, 0.5, 0.2),
	"mountain_boss": Color(0.45, 0.35, 0.25),
	"volcano_boss": Color(0.85, 0.2, 0.1),
}

const ENEMY_SYMBOLS := {
	"slime_scout": "S",
	"shadow_fox": "F",
	"frost_mage": "M",
	"stone_guardian": "G",
	"flame_brute": "B",
	"fire_elemental": "E",
	"region_boss": "R",
	"forest_boss": "F",
	"mountain_boss": "M",
	"volcano_boss": "V",
}


func _ready() -> void:
	add_theme_constant_override("separation", 4)

	if name_label:
		name_label.add_theme_font_size_override("font_size", 28)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.85))

	if intent_label:
		intent_label.add_theme_font_size_override("font_size", 20)

	if status_label:
		status_label.add_theme_font_size_override("font_size", 16)

	# Add portrait letter on top of sprite rect
	if sprite_rect:
		_portrait_label = Label.new()
		_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_portrait_label.add_theme_font_size_override("font_size", 64)
		_portrait_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
		_portrait_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		sprite_rect.add_child(_portrait_label)

		# Style the portrait rect
		sprite_rect.custom_minimum_size = Vector2(0, 100)


func setup(enemy: EnemyData) -> void:
	if name_label:
		name_label.text = enemy.enemy_name

	# Set portrait color + symbol
	var enemy_color: Color = ENEMY_COLORS.get(enemy.id, Color(0.3, 0.2, 0.2))
	if sprite_rect:
		sprite_rect.color = enemy_color.lerp(Color.BLACK, 0.5)
		# Add gradient overlay feel
		var highlight := enemy_color.lerp(Color.WHITE, 0.15)
		sprite_rect.color = sprite_rect.color

	if _portrait_label:
		_portrait_label.text = ENEMY_SYMBOLS.get(enemy.id, "?")

	if hp_bar:
		hp_bar.setup(enemy.current_hp, enemy.max_hp)

	update_display(enemy)


func update_display(enemy: EnemyData) -> void:
	if hp_bar:
		hp_bar.set_hp(enemy.current_hp, enemy.max_hp)

	if intent_label:
		if enemy.intent.is_empty():
			intent_label.text = "  ???"
			intent_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		else:
			var action: String = enemy.intent.get("action_type", "")
			var value: int = enemy.intent.get("value", 0)
			var extra: String = enemy.intent.get("extra", "")
			var col: Color = INTENT_COLORS.get(action, Color.WHITE)
			intent_label.add_theme_color_override("font_color", col)

			match action:
				"attack":
					if extra.begins_with("multi_hit_"):
						var parts := extra.replace("multi_hit_", "").split("x")
						intent_label.text = "  ATK %sx%s" % [parts[0], parts[1]]
					else:
						intent_label.text = "  ATK %d" % value
				"defend":
					intent_label.text = "  DEF +%d" % value
				"buff":
					intent_label.text = "  BUFF STR +%d" % value
				"debuff":
					intent_label.text = "  DEBUFF Weak %d" % value
				"special":
					if extra.begins_with("multi_hit_"):
						var parts := extra.replace("multi_hit_", "").split("x")
						intent_label.text = "  MULTI %sx%s" % [parts[0], parts[1]]
					elif extra == "discard_1":
						intent_label.text = "  DISCARD 1 card"
					else:
						intent_label.text = "  SPECIAL"
				_:
					intent_label.text = "  %s %d" % [action.to_upper(), value]

	if status_label:
		var parts: Array = []
		if enemy.burn > 0:
			parts.append("[color=#ff6622]Burn %d[/color]" % enemy.burn)
		if enemy.poison > 0:
			parts.append("[color=#44dd44]Poison %d[/color]" % enemy.poison)
		if enemy.weak > 0:
			parts.append("[color=#aa66dd]Weak %d[/color]" % enemy.weak)
		if enemy.vulnerable > 0:
			parts.append("[color=#ffaa44]Vuln %d[/color]" % enemy.vulnerable)
		if enemy.strength > 0:
			parts.append("[color=#ff4444]STR +%d[/color]" % enemy.strength)
		if enemy.block > 0:
			parts.append("[color=#4488ff]BLK %d[/color]" % enemy.block)
		# Use plain text since Label doesn't support BBCode
		var plain: Array = []
		if enemy.burn > 0: plain.append("Burn %d" % enemy.burn)
		if enemy.poison > 0: plain.append("Poison %d" % enemy.poison)
		if enemy.weak > 0: plain.append("Weak %d" % enemy.weak)
		if enemy.vulnerable > 0: plain.append("Vuln %d" % enemy.vulnerable)
		if enemy.strength > 0: plain.append("STR +%d" % enemy.strength)
		if enemy.block > 0: plain.append("BLK %d" % enemy.block)
		status_label.text = "  ".join(plain)

		if enemy.burn > 0:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.13))
		elif enemy.poison > 0:
			status_label.add_theme_color_override("font_color", Color(0.27, 0.87, 0.27))
		elif plain.size() > 0:
			status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		else:
			status_label.text = ""
