extends Node
## SaveManager — serializes expedition run state to JSON for save/load.
## Autoload: provides run persistence and run history tracking.

const RUN_SAVE_PATH := "user://run_save.json"
const RUN_HISTORY_PATH := "user://run_history.json"


func save_run() -> void:
	var em: Node = ExpeditionManager
	var deck_ids: Array = []
	for card in em.deck:
		deck_ids.append(card.id)

	# Serialize map nodes — convert Vector2 to array for JSON
	var serialized_map: Array = []
	for row in em.map_nodes:
		var serialized_row: Array = []
		for node in row:
			var n: Dictionary = node.duplicate()
			# Vector2 is not JSON-serializable
			var offset: Vector2 = node.get("position_offset", Vector2.ZERO)
			n["position_offset"] = [offset.x, offset.y]
			serialized_row.append(n)
		serialized_map.append(serialized_row)

	var data: Dictionary = {
		"current_area": em.current_area,
		"current_floor": em.current_floor,
		"current_node_id": em.current_node_id,
		"deck": deck_ids,
		"gold": em.gold,
		"player_hp": em.player_hp,
		"player_max_hp": em.player_max_hp,
		"run_seed": em.run_seed,
		"map_nodes": serialized_map,
		"visited_nodes": em.visited_nodes.duplicate(),
		"battles_won": em.battles_won,
		"elites_defeated": em.elites_defeated,
		"cards_collected": em.cards_collected,
		"gold_earned": em.gold_earned,
	}

	_write_json(RUN_SAVE_PATH, data)


func load_run() -> bool:
	var data: Variant = _read_json(RUN_SAVE_PATH)
	if data == null or not data is Dictionary:
		return false

	var em: Node = ExpeditionManager
	em.is_run_active = true
	em.current_area = data.get("current_area", 0) as int
	em.current_floor = data.get("current_floor", 0) as int
	em.current_node_id = data.get("current_node_id", "") as String
	em.gold = data.get("gold", 0) as int
	em.player_hp = data.get("player_hp", 80) as int
	em.player_max_hp = data.get("player_max_hp", 80) as int
	em.run_seed = data.get("run_seed", 0) as int
	em.rng.seed = em.run_seed
	em.battles_won = data.get("battles_won", 0) as int
	em.elites_defeated = data.get("elites_defeated", 0) as int
	em.cards_collected = data.get("cards_collected", 0) as int
	em.gold_earned = data.get("gold_earned", 0) as int
	em.visited_nodes = data.get("visited_nodes", [])
	em.pending_rewards = []
	em.pending_gold_reward = 0

	# Restore deck from card IDs
	em.deck = []
	var deck_ids: Array = data.get("deck", [])
	for card_id in deck_ids:
		var card: Variant = GameData.get_card(card_id as String)
		if card != null:
			em.deck.append(card)

	# Restore map nodes — convert position_offset arrays back to Vector2
	em.map_nodes = []
	var serialized_map: Array = data.get("map_nodes", [])
	for row in serialized_map:
		var restored_row: Array = []
		for node in row:
			var n: Dictionary = (node as Dictionary).duplicate()
			var offset: Variant = n.get("position_offset", [0, 0])
			if offset is Array and offset.size() >= 2:
				n["position_offset"] = Vector2(offset[0] as float, offset[1] as float)
			else:
				n["position_offset"] = Vector2.ZERO
			restored_row.append(n)
		em.map_nodes.append(restored_row)

	return true


func has_run_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


func clear_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)


func save_run_result(victory: bool, stats: Dictionary = {}) -> void:
	var history: Array = _load_history()
	var entry: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"victory": victory,
		"area_reached": ExpeditionManager.current_area,
		"battles_won": ExpeditionManager.battles_won,
		"elites_defeated": ExpeditionManager.elites_defeated,
		"cards_collected": ExpeditionManager.cards_collected,
		"gold_earned": ExpeditionManager.gold_earned,
	}
	entry.merge(stats)
	history.append(entry)
	_write_json(RUN_HISTORY_PATH, history)


func get_run_history() -> Array:
	return _load_history()


func _load_history() -> Array:
	var data: Variant = _read_json(RUN_HISTORY_PATH)
	if data is Array:
		return data
	return []


func _write_json(path: String, data: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write to %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		push_error("SaveManager: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.data
