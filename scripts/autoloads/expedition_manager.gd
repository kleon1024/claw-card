extends Node
## ExpeditionManager — run state and map generation for expedition mode.
## Autoload: holds persistent state across scenes during a single run.

signal run_started()
signal node_selected(node: Dictionary)
signal battle_completed(won: bool)
signal area_completed(area_index: int)
signal run_completed(victory: bool)

# ---------------------------------------------------------------------------
# Run state
# ---------------------------------------------------------------------------
var is_run_active: bool = false
var current_area: int = 0        # 0=forest, 1=mountain, 2=volcano
var current_floor: int = 0       # row within current area map
var map_nodes: Array = []        # Array of rows, each row is Array of node dicts
var visited_nodes: Array = []    # Array of node IDs that have been completed
var current_node_id: String = "" # last visited node
var deck: Array = []             # Array[CardData], evolves during run
var gold: int = 0
var player_hp: int = 80
var player_max_hp: int = 80
var run_seed: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Stats
var battles_won: int = 0
var elites_defeated: int = 0
var cards_collected: int = 0
var gold_earned: int = 0

# Pending reward state (set after battle, consumed by reward scene)
var pending_rewards: Array = []   # Array[CardData]
var pending_gold_reward: int = 0

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const AREA_NAMES := ["Verdant Forest", "Stone Peaks", "Volcanic Caldera"]
const AREA_BG_COLORS := [
	Color(0.08, 0.14, 0.06),  # forest green
	Color(0.12, 0.1, 0.08),   # stone brown
	Color(0.16, 0.06, 0.04),  # volcano red
]
const NODE_TYPES := {
	"battle": {"icon": "X", "color": Color(0.9, 0.3, 0.2)},
	"elite":  {"icon": "!", "color": Color(0.85, 0.15, 0.6)},
	"event":  {"icon": "?", "color": Color(0.3, 0.7, 0.9)},
	"shop":   {"icon": "$", "color": Color(1.0, 0.85, 0.2)},
	"rest":   {"icon": "~", "color": Color(0.3, 0.9, 0.4)},
	"boss":   {"icon": "W", "color": Color(1.0, 0.2, 0.1)},
}
const ROWS_PER_AREA := 6
const MAP_WIDTH := 7
const NUM_PATHS := 6
const STARTER_GOLD := 50

# ---------------------------------------------------------------------------
# Run lifecycle
# ---------------------------------------------------------------------------

func start_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = randi()
	run_seed = seed_value
	rng.seed = run_seed
	is_run_active = true
	current_area = 0
	current_floor = 0
	map_nodes = []
	visited_nodes = []
	current_node_id = ""
	deck = GameData.get_starter_deck()
	gold = STARTER_GOLD
	player_hp = 80
	player_max_hp = 80
	battles_won = 0
	elites_defeated = 0
	cards_collected = 0
	gold_earned = 0
	pending_rewards = []
	pending_gold_reward = 0
	_generate_area_map(current_area)
	run_started.emit()


func end_run(victory: bool) -> void:
	is_run_active = false
	run_completed.emit(victory)


func get_current_area_name() -> String:
	if current_area < AREA_NAMES.size():
		return AREA_NAMES[current_area]
	return "Unknown"


func get_current_area_data() -> Dictionary:
	if current_area < GameData.areas.size():
		return GameData.areas[current_area]
	return {}

# ---------------------------------------------------------------------------
# Node selection
# ---------------------------------------------------------------------------

func get_available_nodes() -> Array:
	"""Return node IDs the player can click (connected to last visited, or row 0 if none)."""
	if visited_nodes.is_empty():
		# Start of area: all row-0 nodes are available
		var result: Array = []
		if map_nodes.size() > 0:
			for node in map_nodes[0]:
				result.append(node.id)
		return result
	# Find last visited node and return its connections
	var last_node := _find_node(current_node_id)
	if last_node.is_empty():
		return []
	return last_node.get("connections", [])


func select_node(node_id: String) -> Dictionary:
	"""Select a node to visit. Returns the node data dict."""
	var available := get_available_nodes()
	if node_id not in available:
		push_error("Node %s is not available" % node_id)
		return {}
	var node := _find_node(node_id)
	if node.is_empty():
		return {}
	visited_nodes.append(node_id)
	current_node_id = node_id
	current_floor = node.row
	node_selected.emit(node)
	return node


func _find_node(node_id: String) -> Dictionary:
	for row in map_nodes:
		for node in row:
			if node.id == node_id:
				return node
	return {}

# ---------------------------------------------------------------------------
# Battle integration
# ---------------------------------------------------------------------------

func setup_battle_state(node: Dictionary) -> void:
	"""Configure GameManager for a battle from the given node."""
	var enemy_id: String = node.get("enemy_id", "")
	if enemy_id.is_empty():
		push_error("Node has no enemy_id")
		return
	# Derive area_id from current_area for battle backgrounds
	var area_id := ""
	match current_area:
		0: area_id = "forest"
		1: area_id = "mountain"
		2: area_id = "volcano"
	GameManager.start_battle(enemy_id, deck.duplicate(), area_id)


func apply_battle_result(won: bool, final_hp: int) -> void:
	"""Called after battle completes. Persists HP, generates rewards."""
	if won:
		player_hp = max(1, final_hp)
		battles_won += 1
		var node := _find_node(current_node_id)
		var is_elite: bool = node.get("type", "") == "elite"
		if is_elite:
			elites_defeated += 1
		# Generate rewards
		pending_gold_reward = _calc_gold_reward(node)
		gold += pending_gold_reward
		gold_earned += pending_gold_reward
		pending_rewards = _generate_card_rewards(3, is_elite)
	else:
		player_hp = 0
		end_run(false)
	battle_completed.emit(won)


func apply_reward(card_id: String) -> void:
	"""Add a reward card to the run deck."""
	for card in pending_rewards:
		if card.id == card_id:
			deck.append(card.duplicate_card())
			cards_collected += 1
			break
	pending_rewards = []


func skip_reward() -> void:
	pending_rewards = []

# ---------------------------------------------------------------------------
# Area progression
# ---------------------------------------------------------------------------

func advance_after_boss() -> void:
	"""Called after boss defeated. Move to next area or end run."""
	current_area += 1
	current_floor = 0
	visited_nodes = []
	current_node_id = ""
	if current_area >= GameData.areas.size():
		end_run(true)
	else:
		_generate_area_map(current_area)
		area_completed.emit(current_area - 1)

# ---------------------------------------------------------------------------
# Rest stop
# ---------------------------------------------------------------------------

func apply_rest_heal() -> void:
	var heal_amount := int(player_max_hp * 0.3)
	player_hp = min(player_max_hp, player_hp + heal_amount)


func apply_rest_remove_card(card_index: int) -> void:
	if card_index >= 0 and card_index < deck.size():
		deck.remove_at(card_index)

# ---------------------------------------------------------------------------
# Shop
# ---------------------------------------------------------------------------

func buy_card(card_id: String, price: int) -> bool:
	if gold < price:
		return false
	var card = GameData.get_card(card_id)
	if card == null:
		return false
	gold -= price
	deck.append(card)
	cards_collected += 1
	return true


func sell_card(card_index: int, refund: int) -> bool:
	if card_index < 0 or card_index >= deck.size():
		return false
	deck.remove_at(card_index)
	gold += refund
	return true

# ---------------------------------------------------------------------------
# Map generation
# ---------------------------------------------------------------------------

func _generate_area_map(area_index: int) -> void:
	"""Generate a 6-row branching map using path-walking algorithm."""
	map_nodes = []
	var area_data: Dictionary = {}
	if area_index < GameData.areas.size():
		area_data = GameData.areas[area_index]

	# Step 1: Initialize grid — all columns for all rows as empty slots
	var grid: Array = []  # Array[Array[Dictionary or null]]
	for row_idx in range(ROWS_PER_AREA):
		var row: Array = []
		for col_idx in range(MAP_WIDTH):
			row.append(null)
		grid.append(row)

	# Step 2: Generate random starting columns (4-6 paths, at least 2 unique)
	var starting_cols: Array = []
	var unique_count: int = 0
	while unique_count < 2:
		starting_cols = []
		unique_count = 0
		var num_paths: int = rng.randi_range(4, NUM_PATHS)
		for _i in range(num_paths):
			var col: int = rng.randi_range(0, MAP_WIDTH - 1)
			if not starting_cols.has(col):
				unique_count += 1
			starting_cols.append(col)

	# Step 3: Walk paths upward, populate nodes, build connections
	# Track connections as Dictionary of "row,col" -> Array of "row,col" strings
	var connection_map: Dictionary = {}

	for start_col in starting_cols:
		var current_col: int = start_col
		for row_idx in range(ROWS_PER_AREA - 2):  # rows 0 to 3 (rest and boss rows handled separately)
			var next_col: int = current_col
			var attempts: int = 0
			while attempts < 20:
				next_col = clampi(current_col + rng.randi_range(-1, 1), 0, MAP_WIDTH - 1)
				if not _would_cross_existing_path(grid, connection_map, row_idx, current_col, next_col):
					break
				attempts += 1

			if grid[row_idx][current_col] == null:
				grid[row_idx][current_col] = _create_node(area_index, area_data, row_idx, current_col)

			if grid[row_idx + 1][next_col] == null:
				grid[row_idx + 1][next_col] = _create_node(area_index, area_data, row_idx + 1, next_col)

			var from_key: String = "%d,%d" % [row_idx, current_col]
			var to_key: String = "%d,%d" % [row_idx + 1, next_col]
			if not connection_map.has(from_key):
				connection_map[from_key] = []
			if to_key not in connection_map[from_key]:
				connection_map[from_key].append(to_key)

			current_col = next_col

		# Connect this path's last node (row 3) to a rest node (row 4)
		var rest_col: int = clampi(current_col + rng.randi_range(-1, 1), 0, MAP_WIDTH - 1)
		if grid[ROWS_PER_AREA - 2][rest_col] == null:
			grid[ROWS_PER_AREA - 2][rest_col] = _create_node(area_index, area_data, ROWS_PER_AREA - 2, rest_col)
		var rest_from: String = "%d,%d" % [ROWS_PER_AREA - 3, current_col]
		var rest_to: String = "%d,%d" % [ROWS_PER_AREA - 2, rest_col]
		if not connection_map.has(rest_from):
			connection_map[rest_from] = []
		if rest_to not in connection_map[rest_from]:
			connection_map[rest_from].append(rest_to)

	# Step 4: Single boss node in middle column
	var boss_col: int = MAP_WIDTH / 2
	# Clear any nodes on boss row from path walking
	for col_idx in range(MAP_WIDTH):
		grid[ROWS_PER_AREA - 1][col_idx] = null
	grid[ROWS_PER_AREA - 1][boss_col] = _create_node(area_index, area_data, ROWS_PER_AREA - 1, boss_col)

	# All rest-row nodes connect to boss
	for col_idx in range(MAP_WIDTH):
		if grid[ROWS_PER_AREA - 2][col_idx] != null:
			var from_key: String = "%d,%d" % [ROWS_PER_AREA - 2, col_idx]
			var boss_key: String = "%d,%d" % [ROWS_PER_AREA - 1, boss_col]
			connection_map[from_key] = [boss_key]

	# Step 5: Build map_nodes (only populated nodes) and wire connections
	map_nodes = []
	for row_idx in range(ROWS_PER_AREA):
		var row: Array = []
		for col_idx in range(MAP_WIDTH):
			if grid[row_idx][col_idx] != null:
				row.append(grid[row_idx][col_idx])
		map_nodes.append(row)

	# Wire connection IDs into each node
	for row_idx in range(ROWS_PER_AREA):
		for col_idx in range(MAP_WIDTH):
			var node: Variant = grid[row_idx][col_idx]
			if node == null:
				continue
			var from_key: String = "%d,%d" % [row_idx, col_idx]
			if connection_map.has(from_key):
				for to_key in connection_map[from_key]:
					var parts: PackedStringArray = to_key.split(",")
					var target_row: int = int(parts[0])
					var target_col: int = int(parts[1])
					var target: Variant = grid[target_row][target_col]
					if target != null and target.id not in node.connections:
						node.connections.append(target.id)


func _create_node(area_index: int, area_data: Dictionary, row_idx: int, col_idx: int) -> Dictionary:
	"""Create a single map node with type based on row rules."""
	var node_type: String = _determine_node_type(row_idx)
	var node_id: String = "a%d_r%d_c%d" % [area_index, row_idx, col_idx]
	var node: Dictionary = {
		"id": node_id,
		"type": node_type,
		"row": row_idx,
		"col": col_idx,
		"connections": [],
		"enemy_id": "",
		"completed": false,
		"position_offset": Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-8.0, 8.0)),
	}

	# Assign enemy for combat nodes
	match node_type:
		"battle":
			node.enemy_id = _pick_battle_enemy(area_data, row_idx)
		"elite":
			node.enemy_id = _pick_elite_enemy()
		"boss":
			node.enemy_id = area_data.get("boss", "region_boss")

	return node


func _determine_node_type(row_idx: int) -> String:
	"""Assign node type based on row: 0=battle, 1-3=mixed, 4=rest, 5=boss."""
	match row_idx:
		0:
			return "battle"
		4:
			return "rest"
		5:
			return "boss"
		_:
			return _random_mid_node_type()


func _would_cross_existing_path(grid: Array, connection_map: Dictionary, row: int, from_col: int, to_col: int) -> bool:
	"""Check if a connection from (row, from_col) to (row+1, to_col) crosses an existing path."""
	# Check left neighbour going right
	if from_col > 0 and to_col > from_col:
		var left_key: String = "%d,%d" % [row, from_col - 1]
		if connection_map.has(left_key):
			for target_key in connection_map[left_key]:
				var parts: PackedStringArray = target_key.split(",")
				var target_col: int = int(parts[1])
				if target_col > to_col:
					return true

	# Check right neighbour going left
	if from_col < MAP_WIDTH - 1 and to_col < from_col:
		var right_key: String = "%d,%d" % [row, from_col + 1]
		if connection_map.has(right_key):
			for target_key in connection_map[right_key]:
				var parts: PackedStringArray = target_key.split(",")
				var target_col: int = int(parts[1])
				if target_col < to_col:
					return true

	return false


func _random_mid_node_type() -> String:
	"""Weighted random: battle 50%, event 25%, shop 15%, elite 10%."""
	var roll := rng.randf()
	if roll < 0.50:
		return "battle"
	elif roll < 0.75:
		return "event"
	elif roll < 0.90:
		return "shop"
	else:
		return "elite"


func _pick_battle_enemy(area_data: Dictionary, row: int) -> String:
	"""Pick an enemy based on area pool and row difficulty."""
	var pool: Array = area_data.get("enemy_pool", ["slime_scout"])
	if pool.is_empty():
		return "slime_scout"
	# Early rows (0-1): prefer tier 1-2, later rows (2-3): any from pool
	return pool[rng.randi() % pool.size()]


func _pick_elite_enemy() -> String:
	"""Pick a tier-3 enemy for elite encounters."""
	var tier3: Array = GameData.enemy_tiers.get("tier_3", ["stone_guardian"])
	if tier3 is Array and tier3.size() > 0:
		return tier3[rng.randi() % tier3.size()]
	return "stone_guardian"


# ---------------------------------------------------------------------------
# Reward generation
# ---------------------------------------------------------------------------

func _generate_card_rewards(count: int, is_elite: bool) -> Array:
	"""Generate card reward options weighted by area affinity."""
	var area_data := get_current_area_data()
	var reward_weights: Dictionary = area_data.get("reward_weights", {})
	var deck_ids: Dictionary = {}
	for card in deck:
		deck_ids[card.id] = true

	# Build eligible pool: exclude cards already in deck, exclude artifacts from normal rewards
	var eligible: Array = []
	var weights: Array = []
	for card_id in GameData.cards:
		var card = GameData.cards[card_id]
		if deck_ids.has(card_id):
			continue
		if card.is_artifact and not is_elite:
			continue
		var w := 1.0
		for elem in card.elements:
			w *= reward_weights.get(elem, 1.0)
		if card.card_type == "beast":
			w *= 1.5
		eligible.append(card)
		weights.append(w)

	if eligible.is_empty():
		return []

	# Weighted sample without replacement
	var chosen: Array = []
	var remaining_cards := eligible.duplicate()
	var remaining_weights := weights.duplicate()

	for _i in range(min(count, remaining_cards.size())):
		if remaining_cards.is_empty():
			break
		var total := 0.0
		for w in remaining_weights:
			total += w
		if total <= 0:
			break
		var roll := rng.randf() * total
		var cumulative := 0.0
		var pick_idx := 0
		for j in range(remaining_weights.size()):
			cumulative += remaining_weights[j]
			if roll <= cumulative:
				pick_idx = j
				break
		chosen.append(remaining_cards[pick_idx].duplicate_card())
		remaining_cards.remove_at(pick_idx)
		remaining_weights.remove_at(pick_idx)

	return chosen


func _calc_gold_reward(node: Dictionary) -> int:
	var node_type: String = node.get("type", "battle")
	match node_type:
		"elite": return 25 + (rng.randi() % 15)
		"boss": return 50 + (rng.randi() % 25)
		_: return 10 + (rng.randi() % 10)
