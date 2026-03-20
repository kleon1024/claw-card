class_name Synergy
extends RefCounted
## Port of src/synergy.py — clan synergy system (Auto Chess layer).
## Pure function: takes a BattleState, returns an additive effects dict.


static func calc_active_synergies(state: BattleState) -> Dictionary:
	## Count beasts per clan, apply WILD logic, look up synergy table.
	##
	## Algorithm (from spec section 5):
	##   1. Count beasts per clan on field.
	##   2. WILD counts toward ALL clans that already have members.
	##   3. If wild_count >= 2, also grant to clans with zero real members.
	##   4. Look up highest qualifying tier from GameData synergy table.
	##   5. Return combined (additive) effect dict.

	var clan_counts: Dictionary = {}
	var wild_count := 0

	for slot in state.beast_slots:
		if slot == null:
			continue
		if slot.card.clan == Enums.WILD:
			wild_count += 1
		elif slot.card.clan != "":
			clan_counts[slot.card.clan] = clan_counts.get(slot.card.clan, 0) + 1

	# Wild beasts count toward each clan that has real members
	for clan_key in clan_counts.keys():
		clan_counts[clan_key] += wild_count

	# If wild_count >= 2, also count for clans with zero real members
	if wild_count >= 2:
		var all_clans := [
			Enums.FLAME_TRIBE, Enums.DEEP_SEA, Enums.MOUNTAIN,
			Enums.STORM, Enums.VOID_BORN,
		]
		for clan_key in all_clans:
			if clan_key not in clan_counts:
				clan_counts[clan_key] = wild_count

	# Resolve highest qualifying tier per clan from synergy data
	var synergy_table: Dictionary = {}
	if GameData != null:
		synergy_table = GameData.synergies

	var active_effects: Dictionary = {}
	for clan_key in clan_counts:
		var count: int = clan_counts[clan_key]
		if clan_key not in synergy_table:
			continue
		var tiers: Dictionary = synergy_table[clan_key]

		# Find highest qualifying threshold
		var best_tier := 0
		var tier_keys: Array = tiers.keys()
		tier_keys.sort()
		tier_keys.reverse()
		for threshold in tier_keys:
			var t: int = int(threshold)  # JSON keys may be strings
			if count >= t:
				best_tier = t
				break

		if best_tier > 0:
			var tier_key = str(best_tier)
			if tier_key not in tiers:
				tier_key = best_tier  # try int key
			var effects: Dictionary = tiers[tier_key]
			for key in effects:
				if key == "desc":
					continue
				var value = effects[key]
				if value is bool:
					active_effects[key] = value
				elif key in active_effects:
					active_effects[key] += value
				else:
					active_effects[key] = value

	return active_effects
