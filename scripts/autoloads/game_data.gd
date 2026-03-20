extends Node

var cards: Dictionary = {}
var enemies: Dictionary = {}
var enemy_tiers: Dictionary = {}
var areas: Array = []
var synergies: Dictionary = {}
var params: Dictionary = {}
var starter_deck_ids: Array = []
var constitutional_rules: Dictionary = {}

func _ready() -> void:
	_load_all()
	print("GameData loaded: %d cards, %d enemies, %d areas" % [cards.size(), enemies.size(), areas.size()])

func _load_all() -> void:
	cards = _load_cards()
	enemies = _load_json("res://data/enemies.json")
	enemy_tiers = _load_json("res://data/enemy_tiers.json")
	areas = _load_json("res://data/areas.json")
	synergies = _load_json("res://data/synergies.json")
	var p = _load_json("res://data/params.json")
	params = p.get("default_params", {})
	starter_deck_ids = p.get("starter_deck_ids", [])
	constitutional_rules = p.get("constitutional_rules", {})

func _load_cards() -> Dictionary:
	var raw = _load_json("res://data/cards.json")
	var result: Dictionary = {}
	for d in raw:
		var card = CardData.from_dict(d)
		result[card.id] = card
	return result

func _load_json(path: String) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to load: " + path)
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data

func get_card(card_id: String) -> CardData:
	if cards.has(card_id):
		return cards[card_id].duplicate_card()
	push_error("Card not found: " + card_id)
	return null

func get_enemy(enemy_id: String) -> EnemyData:
	if enemies.has(enemy_id):
		return EnemyData.from_template(enemy_id, enemies[enemy_id])
	push_error("Enemy not found: " + enemy_id)
	return null

func get_starter_deck() -> Array:
	# Base cards (always included)
	var base_ids: Array = ["t_strike", "t_defend", "t_defend"]
	# Random element pool — pick 1 element theme + some variety
	var element_starters := {
		"fire": ["t_strike", "t_kindle", "b_ember_fox"],
		"water": ["t_healing_rain", "t_ocean_current", "b_coral_crab"],
		"earth": ["t_fortify", "t_stone_skin", "b_stone_turtle"],
		"lightning": ["t_quick_draw", "t_flurry", "b_storm_hawk"],
		"void": ["t_void_strike", "t_leech", "b_void_moth"],
	}
	var elements := element_starters.keys()
	var primary: String = elements[randi() % elements.size()]
	var secondary: String = elements[randi() % elements.size()]
	while secondary == primary:
		secondary = elements[randi() % elements.size()]

	var pick_ids: Array = base_ids.duplicate()
	pick_ids.append_array(element_starters[primary])
	# Add 1-2 cards from secondary element
	var sec_cards: Array = element_starters[secondary]
	pick_ids.append(sec_cards[randi() % sec_cards.size()])
	pick_ids.append(sec_cards[randi() % sec_cards.size()])

	var deck: Array = []
	for card_id in pick_ids:
		var card = get_card(card_id)
		if card != null:
			deck.append(card)
	# Fallback if pool is too small
	if deck.size() < 6:
		for card_id in starter_deck_ids:
			var card = get_card(card_id)
			if card != null:
				deck.append(card)
	return deck
