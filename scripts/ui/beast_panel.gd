extends HBoxContainer
class_name BeastPanel
## 3 beast slots with styled panels matching dark theme.

const CLAN_COLORS := {
	"flame_tribe": Color(0.95, 0.35, 0.2),
	"deep_sea": Color(0.2, 0.5, 0.9),
	"mountain": Color(0.6, 0.5, 0.3),
	"storm": Color(0.9, 0.85, 0.2),
	"void_born": Color(0.65, 0.25, 0.85),
	"wild": Color(0.4, 0.8, 0.35),
}
const EMPTY_BG := Color(0.05, 0.06, 0.1, 0.5)
const FILLED_BG := Color(0.067, 0.094, 0.157, 0.9)
const BORDER_EMPTY := Color(0.15, 0.18, 0.25, 0.4)


func _ready() -> void:
	add_theme_constant_override("separation", 8)


func update_beasts(beast_slots: Array) -> void:
	while get_child_count() < 3:
		add_child(_create_slot())

	for i in range(3):
		var panel: PanelContainer = get_child(i)
		var vbox: VBoxContainer = panel.get_child(0)
		var slot = beast_slots[i] if i < beast_slots.size() else null

		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()

		if slot == null:
			panel.visible = false
		else:
			panel.visible = true
			var clan_color: Color = CLAN_COLORS.get(slot.card.clan, Color(0.4, 0.4, 0.5))
			style.bg_color = FILLED_BG
			style.border_color = clan_color.lerp(Color.BLACK, 0.3)

			vbox.get_node("BeastName").text = slot.card.name
			vbox.get_node("BeastName").add_theme_color_override("font_color", clan_color)

			var clan_text: String = slot.card.clan.replace("_", " ").capitalize() if slot.card.clan != "" else "No Clan"
			vbox.get_node("ClanLabel").text = clan_text
			vbox.get_node("ClanLabel").add_theme_color_override("font_color", clan_color.lerp(Color.WHITE, 0.3))

			var hp_ratio: float = float(slot.current_hp) / float(max(slot.card.beast_hp, 1))
			var hp_color: Color = Color(0.3, 0.9, 0.3) if hp_ratio > 0.5 else Color(0.95, 0.3, 0.2)
			vbox.get_node("HPLabel").text = "HP %d/%d" % [slot.current_hp, slot.card.beast_hp]
			vbox.get_node("HPLabel").add_theme_color_override("font_color", hp_color)

			vbox.get_node("TriggerLabel").text = "Triggers: %d" % slot.total_triggers
			vbox.get_node("TriggerLabel").add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

		panel.add_theme_stylebox_override("panel", style)


func _create_slot() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = EMPTY_BG
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_size = 3
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	for lbl_name in ["BeastName", "ClanLabel", "HPLabel", "TriggerLabel"]:
		var lbl := Label.new()
		lbl.name = lbl_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl)

	return panel
