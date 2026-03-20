extends Node
## Scene transition manager with fade effects.
## Routes: title -> expedition -> battle -> reward -> expedition -> boss -> victory.

var current_enemy_id: String = ""
var current_deck: Array = []
var current_area_id: String = ""

const BATTLE_SCENE := "res://scenes/battle_scene.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const EXPEDITION_MAP_SCENE := "res://scenes/expedition_map.tscn"
const CARD_REWARD_SCENE := "res://scenes/card_reward.tscn"
const SHOP_SCENE := "res://scenes/shop_scene.tscn"
const EVENT_SCENE := "res://scenes/event_scene.tscn"
const REST_SCENE := "res://scenes/rest_scene.tscn"
const RUN_COMPLETE_SCENE := "res://scenes/run_complete.tscn"
const FADE_DURATION := 0.3

var _fade_rect: ColorRect
var _pause_menu: CanvasLayer


func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade_rect)

	# Pause menu (layer 90, handles Escape key)
	var pause_script: GDScript = load("res://scripts/ui/pause_menu.gd") as GDScript
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(pause_script)
	add_child(_pause_menu)


func start_battle(enemy_id: String, deck: Array = [], area_id: String = "") -> void:
	current_enemy_id = enemy_id
	current_deck = deck
	current_area_id = area_id
	await _fade_out()
	get_tree().change_scene_to_file(BATTLE_SCENE)
	await get_tree().process_frame
	await get_tree().process_frame
	var battle_scene = get_tree().current_scene
	if battle_scene and battle_scene.has_method("start_battle"):
		battle_scene.start_battle(current_enemy_id, current_deck, current_area_id)
	await _fade_in()


func on_battle_complete(winner: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if ExpeditionManager.is_run_active:
		var battle_scene = get_tree().current_scene
		var final_hp: int = 0
		if battle_scene and battle_scene.state:
			final_hp = battle_scene.state.player_hp
		ExpeditionManager.apply_battle_result(winner == "player", final_hp)
		if winner == "player":
			var node := ExpeditionManager._find_node(ExpeditionManager.current_node_id)
			if node.get("type", "") == "boss":
				ExpeditionManager.advance_after_boss()
				if not ExpeditionManager.is_run_active:
					await _fade_out()
					get_tree().change_scene_to_file(RUN_COMPLETE_SCENE)
					await _fade_in()
				else:
					await _fade_out()
					get_tree().change_scene_to_file(EXPEDITION_MAP_SCENE)
					await _fade_in()
			else:
				await _fade_out()
				get_tree().change_scene_to_file(CARD_REWARD_SCENE)
				await _fade_in()
		else:
			# Player defeated — show run complete (defeat) screen
			await _fade_out()
			get_tree().change_scene_to_file(RUN_COMPLETE_SCENE)
			await _fade_in()
	else:
		go_to_menu()


func go_to_menu() -> void:
	await _fade_out()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	await _fade_in()


func go_to_title() -> void:
	go_to_menu()


func go_to_scene(scene_path: String) -> void:
	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await _fade_in()


func go_to_expedition_map() -> void:
	go_to_scene(EXPEDITION_MAP_SCENE)


func start_expedition() -> void:
	ExpeditionManager.start_run(randi())
	await _fade_out()
	get_tree().change_scene_to_file(EXPEDITION_MAP_SCENE)
	await _fade_in()


func _fade_out() -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tw.finished


func _fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tw.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
