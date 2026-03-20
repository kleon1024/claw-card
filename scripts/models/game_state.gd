class_name BattleState
extends RefCounted

# Player
var player_hp: int = 80
var player_max_hp: int = 80
var player_block: int = 0
var player_strength: int = 0
var player_weak: int = 0
var player_vulnerable: int = 0
var player_thorns: int = 0
var player_energy: int = 2
var player_max_energy: int = 2

# Cards
var hand: Array = []
var draw_pile: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []

# Beasts (3 slots, null = empty)
var beast_slots: Array = [null, null, null]

# Artifacts
var artifacts: Array = []

# Combat
var enemy: EnemyData = null
var turn: int = 0
var combo_counter: int = 0
var elements_played_this_turn: Array[String] = []
var cards_drawn_this_turn: int = 0
var damage_dealt_this_turn: int = 0

# Expedition
var battles_remaining: int = 6
var region_modifiers: Dictionary = {}
var region_id: String = ""
var is_boss: bool = false

# Battle outcome
var is_battle_over: bool = false
var winner: String = ""

func clone() -> BattleState:
	var s = BattleState.new()
	s.player_hp = player_hp; s.player_max_hp = player_max_hp
	s.player_block = player_block; s.player_strength = player_strength
	s.player_weak = player_weak; s.player_vulnerable = player_vulnerable
	s.player_thorns = player_thorns
	s.player_energy = player_energy; s.player_max_energy = player_max_energy
	# Deep copy card arrays
	s.hand = []; for c in hand: s.hand.append(c.duplicate_card())
	s.draw_pile = []; for c in draw_pile: s.draw_pile.append(c.duplicate_card())
	s.discard_pile = []; for c in discard_pile: s.discard_pile.append(c.duplicate_card())
	s.exhaust_pile = []; for c in exhaust_pile: s.exhaust_pile.append(c.duplicate_card())
	# Deep copy beast slots
	s.beast_slots = []
	for slot in beast_slots:
		s.beast_slots.append(slot.duplicate_slot() if slot != null else null)
	# Deep copy artifacts
	s.artifacts = []; for a in artifacts: s.artifacts.append(a.duplicate_card())
	# Copy enemy
	s.enemy = enemy.duplicate_enemy() if enemy != null else null
	s.turn = turn; s.combo_counter = combo_counter
	s.elements_played_this_turn = elements_played_this_turn.duplicate()
	s.cards_drawn_this_turn = cards_drawn_this_turn
	s.damage_dealt_this_turn = damage_dealt_this_turn
	s.battles_remaining = battles_remaining
	s.region_modifiers = region_modifiers.duplicate()
	s.region_id = region_id; s.is_boss = is_boss
	s.is_battle_over = is_battle_over; s.winner = winner
	return s

func get_legal_actions() -> Array:
	var actions: Array = []
	for card in hand:
		var cost = card.energy_cost
		if card.chain and combo_counter >= 2:
			cost = 0
		if cost <= player_energy:
			if card.card_type == Enums.BEAST:
				var has_empty = false
				for slot in beast_slots:
					if slot == null:
						has_empty = true
						break
				if has_empty:
					actions.append({action_type = Enums.PLAY_CARD, card_id = card.id})
			else:
				actions.append({action_type = Enums.PLAY_CARD, card_id = card.id})
	for art in artifacts:
		if art.artifact_charges > 0:
			actions.append({action_type = Enums.USE_ARTIFACT, card_id = art.id})
	actions.append({action_type = Enums.END_TURN, card_id = ""})
	return actions
