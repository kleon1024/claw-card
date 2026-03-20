class_name BattleEngine
extends RefCounted
## Port of src/engine.py — deterministic card battle engine.
## Every public method returns a NEW BattleState — input is never mutated.

var rng: RandomNumberGenerator
var p: Dictionary  # RL-tunable params

const ZERO_COST_DAMAGE_CAP := 15

# Conditions whose bonus_damage is already folded into _calc_damage
const _DAMAGE_FOLDED := [
	Enums.ON_PLAY_ATTACK,
	Enums.ON_ELEMENT_MATCH,
	Enums.ON_COMBO,
	Enums.ON_DRAW,
]


func _init(seed_val: int = 0, params: Dictionary = {}) -> void:
	rng = RandomNumberGenerator.new()
	if seed_val != 0:
		rng.seed = seed_val
	p = {
		"COMBO_SCALE": 0.1,
		"VULNERABLE_MULT": 1.5,
		"ELEMENT_MATCH_BONUS": 1.2,
		"ELEMENT_COMBO_BONUS": 0.05,
		"ADAPT_RATE": 0.3,
	}
	p.merge(params, true)


# ==================================================================
# Public API
# ==================================================================

func apply_action(state: BattleState, action: Dictionary) -> BattleState:
	if state.is_battle_over:
		return state
	var s := state.clone()

	if action.action_type == Enums.PLAY_CARD:
		var card := _find_card_in_hand(s, action.card_id)
		if card != null:
			_play_card(s, card)
	elif action.action_type == Enums.USE_ARTIFACT:
		_use_artifact(s, action.card_id)
	elif action.action_type == Enums.END_TURN:
		s = execute_end_turn(s)

	_check_battle_over(s)
	return s


func start_turn(state: BattleState) -> BattleState:
	var s := state.clone()
	s.turn += 1
	s.combo_counter = 0
	s.elements_played_this_turn = []
	s.cards_drawn_this_turn = 0
	s.damage_dealt_this_turn = 0
	s.player_block = 0

	# Reset beast per-turn counters
	for slot in s.beast_slots:
		if slot != null:
			slot.triggers_this_turn = 0

	# Synergy turn-start effects
	var synergies := Synergy.calc_active_synergies(s)
	var bonus_draw: int = synergies.get("bonus_draw", 0)
	var bonus_energy: int = synergies.get("energy_per_turn", 0)
	var bonus_block: int = synergies.get("bonus_block", 0)
	var heal_per_turn: int = synergies.get("heal_per_turn", 0)

	s.player_energy = s.player_max_energy + bonus_energy
	s.player_block += bonus_block
	s.player_hp = mini(s.player_max_hp, s.player_hp + heal_per_turn)

	# Draw cards
	_draw_cards(s, 5 + bonus_draw)

	# Turn-start beast triggers
	_process_triggers(s, Enums.ON_TURN_START, null)

	return s


func execute_end_turn(state: BattleState) -> BattleState:
	var s := state.clone()

	# Turn-end beast triggers
	_process_triggers(s, Enums.ON_TURN_END, null)

	if s.enemy != null:
		# Enemy block resets
		s.enemy.block = 0

		# Apply enemy status effects
		_apply_enemy_status_effects(s)

		# Check if enemy died from status
		if s.enemy.current_hp <= 0:
			_check_battle_over(s)
			return s

		# Enemy executes its intent
		_execute_enemy_intent(s)

		# Check if player died
		if s.player_hp <= 0:
			_check_battle_over(s)
			return s

		# Select next intent
		_select_enemy_intent(s)

		# Increment enemy turn counter
		s.enemy.turn_counter += 1

	# Player status effects decrement
	if s.player_weak > 0:
		s.player_weak -= 1
	if s.player_vulnerable > 0:
		s.player_vulnerable -= 1

	# Player block and thorns reset
	s.player_block = 0
	s.player_thorns = 0

	# Discard hand (retain cards stay)
	for card in s.hand:
		if not card.retain:
			s.discard_pile.append(card)
	var kept: Array = []
	for c in s.hand:
		if c.retain:
			kept.append(c)
	s.hand = kept

	return s


# ==================================================================
# Internal — card play
# ==================================================================

func _play_card(s: BattleState, card: CardData) -> void:
	# Pay energy (chain = free if combo >= 2)
	var effective_cost: int = card.energy_cost
	if card.chain and s.combo_counter >= 2:
		effective_cost = 0

	if s.player_energy < effective_cost:
		return  # cannot play

	s.player_energy -= effective_cost
	s.combo_counter += 1
	s.elements_played_this_turn.append_array(card.elements)

	# Remove from hand (first matching id)
	for i in range(s.hand.size()):
		if s.hand[i].id == card.id:
			s.hand.remove_at(i)
			break

	# Resolve by type
	if card.card_type == Enums.TECHNIQUE:
		_resolve_technique(s, card)
	elif card.card_type == Enums.BEAST:
		_resolve_beast(s, card)
	elif card.card_type == Enums.ARTIFACT:
		_resolve_artifact_from_hand(s, card)


func _resolve_technique(s: BattleState, card: CardData) -> void:
	# Damage
	if card.damage > 0:
		var dmg := _calc_damage(card.damage, s, card)
		_deal_damage_to_enemy(s, dmg)
		s.damage_dealt_this_turn += dmg

	# Block
	if card.block > 0:
		var blk := _calc_block(card.block, s, card)
		s.player_block += blk

	# Draw
	if card.draw > 0:
		_draw_cards(s, card.draw)

	# Energy gain
	s.player_energy += card.energy_gain

	# Heal
	if card.heal > 0:
		s.player_hp = mini(s.player_max_hp, s.player_hp + card.heal)

	# Status effects on enemy
	if s.enemy != null:
		s.enemy.burn += card.apply_burn
		s.enemy.poison += card.apply_poison
		s.enemy.weak += card.apply_weak
		s.enemy.vulnerable += card.apply_vulnerable

	# Player buffs
	s.player_strength += card.gain_strength

	# Beast triggers for technique plays
	if card.damage > 0:
		_process_triggers(s, Enums.ON_PLAY_ATTACK, card)
	if card.block > 0:
		_process_triggers(s, Enums.ON_PLAY_DEFEND, card)
	_process_triggers(s, Enums.ON_ELEMENT_MATCH, card)
	_process_triggers(s, Enums.ON_COMBO, card)

	# Disposition
	if card.exhaust:
		s.exhaust_pile.append(card)
	else:
		s.discard_pile.append(card)


func _resolve_beast(s: BattleState, card: CardData) -> void:
	for i in range(s.beast_slots.size()):
		if s.beast_slots[i] == null:
			s.beast_slots[i] = BeastSlotData.create(card)
			break


func _resolve_artifact_from_hand(s: BattleState, card: CardData) -> void:
	if card.damage > 0 and s.enemy != null:
		_deal_damage_to_enemy(s, card.damage)
	if card.block > 0:
		s.player_block += card.block
	if card.heal > 0:
		s.player_hp = mini(s.player_max_hp, s.player_hp + card.heal)
	if card.draw > 0:
		_draw_cards(s, card.draw)
	# Artifacts always exhaust
	s.exhaust_pile.append(card)


func _use_artifact(s: BattleState, artifact_id: String) -> void:
	var art: CardData = null
	for a in s.artifacts:
		if a.id == artifact_id and a.artifact_charges > 0:
			art = a
			break
	if art == null:
		return

	if art.damage > 0 and s.enemy != null:
		_deal_damage_to_enemy(s, art.damage)
	if art.block > 0:
		s.player_block += art.block
	if art.heal > 0:
		s.player_hp = mini(s.player_max_hp, s.player_hp + art.heal)
	if art.draw > 0:
		_draw_cards(s, art.draw)

	art.artifact_charges -= 1
	if art.artifact_charges <= 0:
		var remaining: Array = []
		for a in s.artifacts:
			if a.id != artifact_id:
				remaining.append(a)
		s.artifacts = remaining


# ==================================================================
# Internal — damage / block formulas
# ==================================================================

func _calc_damage(base: int, s: BattleState, card: CardData) -> int:
	## CRITICAL: combo_counter increments BEFORE this (in _play_card),
	## so the card's own play counts toward its combo multiplier.
	var total_base: int = base + s.player_strength

	# Beast bonus damage (folded into base, not applied again in triggers)
	var beast_bonus := _calc_beast_damage_bonus(s, card)
	total_base += beast_bonus

	# Multiplicative bonuses
	var multiplier := 1.0

	# Combo multiplier
	var combo_scale: float = p["COMBO_SCALE"]
	if s.combo_counter > 1:
		multiplier *= 1.0 + combo_scale * (s.combo_counter - 1)

	# Vulnerability
	if s.enemy != null and s.enemy.vulnerable > 0:
		multiplier *= p["VULNERABLE_MULT"]

	# Player weak: reduce outgoing damage by 25%
	if s.player_weak > 0:
		multiplier *= 0.75

	# Region modifier
	var region_mult: float = s.region_modifiers.get("damage_mult", 1.0)
	multiplier *= region_mult

	# Element matching bonus
	var favored = s.region_modifiers.get("favored_element", "")
	if favored != "" and favored in card.elements:
		multiplier *= p["ELEMENT_MATCH_BONUS"]

	var result := floori(total_base * multiplier)

	# 0-cost cap
	if card.energy_cost == 0:
		result = mini(result, ZERO_COST_DAMAGE_CAP)

	return result


func _calc_block(base: int, s: BattleState, _card: CardData) -> int:
	var total: int = base

	# Beast shield bonuses (ON_PLAY_DEFEND beasts — inline, not via triggers)
	for slot in s.beast_slots:
		if slot == null:
			continue
		if slot.card.trigger_condition == Enums.ON_PLAY_DEFEND:
			if not slot.card.trigger_effect.is_empty():
				total += slot.card.trigger_effect.get("bonus_block", 0)

	var multiplier: float = s.region_modifiers.get("block_mult", 1.0)
	return floori(total * multiplier)


func _calc_beast_damage_bonus(s: BattleState, played_card: CardData) -> int:
	var bonus := 0
	for slot in s.beast_slots:
		if slot == null:
			continue
		if _check_trigger(slot.card, played_card, s):
			var effect: Dictionary = slot.card.trigger_effect
			if not effect.is_empty():
				bonus += effect.get("bonus_damage", 0)
	return bonus


# ==================================================================
# Internal — trigger system
# ==================================================================

func _check_trigger(beast_card: CardData, played_card: CardData, s: BattleState) -> bool:
	var cond: String = beast_card.trigger_condition
	if cond == "":
		return false

	if cond == Enums.ON_PLAY_ATTACK:
		return played_card != null and played_card.damage > 0

	if cond == Enums.ON_PLAY_DEFEND:
		return played_card != null and played_card.block > 0

	if cond == Enums.ON_ELEMENT_MATCH:
		if played_card == null:
			return false
		for elem in beast_card.elements:
			if elem in played_card.elements:
				return true
		return false

	if cond == Enums.ON_COMBO:
		return s.combo_counter >= beast_card.trigger_threshold

	if cond == Enums.ON_TURN_END:
		return true

	if cond == Enums.ON_TURN_START:
		return true

	if cond == Enums.ON_DRAW:
		return s.cards_drawn_this_turn >= beast_card.trigger_threshold

	if cond == Enums.ON_TAKE_DAMAGE:
		return true  # called only when damage actually taken

	return false


func _process_triggers(s: BattleState, condition: String, played_card: CardData) -> void:
	## Two-pass: direct triggers, then chain triggers (ON_BEAST_TRIGGER).
	## When condition is in _DAMAGE_FOLDED, skip bonus_damage to avoid double-count.
	var skip_dmg: bool = condition in _DAMAGE_FOLDED

	var triggered: Array = []  # Array of BeastSlotData

	for slot in s.beast_slots:
		if slot == null:
			continue
		if slot.card.trigger_condition != condition:
			continue
		if not _check_trigger(slot.card, played_card, s):
			continue

		var effect: Dictionary = slot.card.trigger_effect
		if effect.is_empty():
			effect = {}
		_apply_trigger_effect(s, effect, skip_dmg)
		slot.triggers_this_turn += 1
		slot.total_triggers += 1
		triggered.append(slot)

	# Chain triggers (ON_BEAST_TRIGGER)
	if triggered.size() > 0:
		for slot in s.beast_slots:
			if slot == null or slot in triggered:
				continue
			if slot.card.trigger_condition != Enums.ON_BEAST_TRIGGER:
				continue
			var total_other := 0
			for b in triggered:
				total_other += b.triggers_this_turn
			if total_other >= slot.card.trigger_threshold:
				var effect: Dictionary = slot.card.trigger_effect
				if effect.is_empty():
					effect = {}
				_apply_trigger_effect(s, effect, skip_dmg)
				slot.triggers_this_turn += 1
				slot.total_triggers += 1


func _apply_trigger_effect(s: BattleState, effect: Dictionary, skip_damage: bool) -> void:
	if not skip_damage:
		var bonus_dmg: int = effect.get("bonus_damage", 0)
		if bonus_dmg > 0 and s.enemy != null:
			_deal_damage_to_enemy(s, bonus_dmg)
			s.damage_dealt_this_turn += bonus_dmg

	var bonus_blk: int = effect.get("bonus_block", 0)
	if bonus_blk > 0:
		s.player_block += bonus_blk

	var draw_count: int = effect.get("draw", 0)
	if draw_count > 0:
		_draw_cards(s, draw_count)

	var heal_val: int = effect.get("heal", 0)
	if heal_val > 0:
		s.player_hp = mini(s.player_max_hp, s.player_hp + heal_val)

	var thorns_val: int = effect.get("thorns", 0)
	if thorns_val > 0:
		s.player_thorns += thorns_val

	if s.enemy != null:
		s.enemy.weak += effect.get("apply_weak", 0)
		s.enemy.burn += effect.get("apply_burn", 0)


# ==================================================================
# Internal — damage dealing
# ==================================================================

func _deal_damage_to_enemy(s: BattleState, damage: int) -> void:
	if s.enemy == null:
		return
	var blocked := mini(damage, s.enemy.block)
	s.enemy.block -= blocked
	var remaining := damage - blocked
	s.enemy.current_hp -= remaining
	s.enemy.current_hp = maxi(s.enemy.current_hp, 0)


# ==================================================================
# Internal — enemy AI
# ==================================================================

func _execute_enemy_intent(s: BattleState) -> void:
	if s.enemy == null or s.enemy.intent.is_empty():
		return

	var intent: Dictionary = s.enemy.intent
	var action_type: String = intent.get("action_type", "")
	var value: int = intent.get("value", 0)
	var extra: String = intent.get("extra", "")

	# Enrage: enemy strength grows — +1 every 4 turns
	var enrage_bonus: int = s.enemy.turn_counter / 4

	if action_type == "attack":
		var dmg: int = value + s.enemy.strength + enrage_bonus
		if s.enemy.weak > 0:
			dmg = floori(dmg * 0.75)
		if s.player_vulnerable > 0:
			dmg = floori(dmg * 1.5)
		# Apply to player (block absorbs first)
		var had_block: bool = s.player_block > 0
		var effective: int = maxi(0, dmg - s.player_block)
		s.player_block = maxi(0, s.player_block - dmg)
		s.player_hp -= effective
		s.player_hp = maxi(s.player_hp, 0)
		if effective > 0:
			_process_triggers(s, Enums.ON_TAKE_DAMAGE, null)
		# Thorns: reflect damage back when blocking
		if had_block and s.player_thorns > 0:
			s.enemy.current_hp -= s.player_thorns
			s.enemy.current_hp = maxi(s.enemy.current_hp, 0)

	elif action_type == "defend":
		s.enemy.block += value

	elif action_type == "buff":
		s.enemy.strength += value

	elif action_type == "debuff":
		s.player_weak += value

	elif action_type == "special":
		if extra.begins_with("multi_hit_"):
			# Parse "multi_hit_2x6" -> 2 hits of 6 damage
			var parts := extra.replace("multi_hit_", "").split("x")
			var hits: int = int(parts[0])
			var dmg_per_hit: int = int(parts[1])
			for _i in range(hits):
				var hit_dmg: int = dmg_per_hit + s.enemy.strength + enrage_bonus
				if s.enemy.weak > 0:
					hit_dmg = floori(hit_dmg * 0.75)
				if s.player_vulnerable > 0:
					hit_dmg = floori(hit_dmg * 1.5)
				var eff: int = maxi(0, hit_dmg - s.player_block)
				s.player_block = maxi(0, s.player_block - hit_dmg)
				s.player_hp -= eff
				s.player_hp = maxi(s.player_hp, 0)
		elif extra == "discard_1":
			if s.hand.size() > 0:
				var idx: int = rng.randi_range(0, s.hand.size() - 1)
				var discarded: CardData = s.hand[idx]
				s.hand.remove_at(idx)
				s.discard_pile.append(discarded)


func _select_enemy_intent(s: BattleState) -> void:
	if s.enemy == null or s.enemy.intent_pool.is_empty():
		return

	var intents: Array = s.enemy.intent_pool
	var weights: Array = []
	for i_data in intents:
		weights.append(float(i_data.get("weight", 1.0)))

	var adapt_rate: float = p["ADAPT_RATE"]

	# Adaptive: boost defensive if player dealt lots of damage
	if s.damage_dealt_this_turn > 15:
		for i in range(intents.size()):
			if intents[i].get("type", "") == "defend":
				weights[i] *= (1.0 + adapt_rate)

	# Boost aggressive if player is low HP
	if s.player_hp < s.player_max_hp * 0.3:
		for i in range(intents.size()):
			if intents[i].get("type", "") == "attack":
				weights[i] *= (1.0 + adapt_rate * 0.5)

	# Normalize weights
	var total := 0.0
	for w in weights:
		total += w
	if total <= 0:
		total = 1.0
	for i in range(weights.size()):
		weights[i] /= total

	# Weighted random selection
	var roll := rng.randf()
	var cumulative := 0.0
	var chosen: Dictionary = intents[0]
	for i in range(intents.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			chosen = intents[i]
			break

	s.enemy.intent = {
		"action_type": chosen.get("type", "attack"),
		"value": chosen.get("value", 0),
		"target": "player",
		"extra": chosen.get("extra", ""),
	}


# ==================================================================
# Internal — card draw
# ==================================================================

func _draw_cards(s: BattleState, count: int) -> void:
	for _i in range(count):
		if s.draw_pile.is_empty():
			if s.discard_pile.is_empty():
				break
			s.draw_pile = s.discard_pile.duplicate()
			s.discard_pile = []
			_shuffle_array(s.draw_pile)
		if not s.draw_pile.is_empty():
			var drawn: CardData = s.draw_pile.pop_front()
			s.hand.append(drawn)
			s.cards_drawn_this_turn += 1


func _shuffle_array(arr: Array) -> void:
	## Fisher-Yates shuffle using our seeded RNG.
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# ==================================================================
# Internal — enemy status effects
# ==================================================================

func _apply_enemy_status_effects(s: BattleState) -> void:
	if s.enemy == null:
		return

	# Burn: deal damage equal to stacks, then decrement by 1
	if s.enemy.burn > 0:
		s.enemy.current_hp -= s.enemy.burn
		s.enemy.current_hp = maxi(s.enemy.current_hp, 0)
		s.enemy.burn -= 1

	# Poison: deal damage equal to stacks (persistent — no decrement)
	if s.enemy.poison > 0:
		s.enemy.current_hp -= s.enemy.poison
		s.enemy.current_hp = maxi(s.enemy.current_hp, 0)

	# Weak: decrement
	if s.enemy.weak > 0:
		s.enemy.weak -= 1

	# Vulnerable: decrement
	if s.enemy.vulnerable > 0:
		s.enemy.vulnerable -= 1


# ==================================================================
# Internal — battle state checks
# ==================================================================

func _check_battle_over(s: BattleState) -> void:
	if s.is_battle_over:
		return
	if s.enemy != null and s.enemy.current_hp <= 0:
		s.is_battle_over = true
		s.winner = "player"
	elif s.player_hp <= 0:
		s.is_battle_over = true
		s.winner = "enemy"


# ==================================================================
# Internal — helpers
# ==================================================================

static func _find_card_in_hand(s: BattleState, card_id: String) -> CardData:
	for c in s.hand:
		if c.id == card_id:
			return c
	return null
