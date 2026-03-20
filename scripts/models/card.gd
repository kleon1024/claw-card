class_name CardData
extends RefCounted

var id: String
var name: String
var card_type: String
var energy_cost: int
var elements: Array[String]

# Direct effects
var damage: int
var block: int
var draw: int
var energy_gain: int
var heal: int

# Status effects
var apply_burn: int
var apply_poison: int
var apply_weak: int
var apply_vulnerable: int
var gain_strength: int

# Beast-specific
var clan: String  # "" if none
var beast_hp: int
var trigger_condition: String  # "" if none
var trigger_threshold: int
var trigger_effect: Dictionary  # {} if none

# Artifact-specific
var is_artifact: bool
var artifact_charges: int

# Keywords
var exhaust: bool
var retain: bool
var innate: bool
var chain: bool

var power_budget: float

static func from_dict(d: Dictionary) -> CardData:
	var card = CardData.new()
	card.id = d.get("id", "")
	card.name = d.get("name", "")
	card.card_type = d.get("card_type", "technique")
	card.energy_cost = d.get("energy_cost", 1)
	card.elements = Array(d.get("elements", []), TYPE_STRING, "", null)
	card.damage = d.get("damage", 0)
	card.block = d.get("block", 0)
	card.draw = d.get("draw", 0)
	card.energy_gain = d.get("energy_gain", 0)
	card.heal = d.get("heal", 0)
	card.apply_burn = d.get("apply_burn", 0)
	card.apply_poison = d.get("apply_poison", 0)
	card.apply_weak = d.get("apply_weak", 0)
	card.apply_vulnerable = d.get("apply_vulnerable", 0)
	card.gain_strength = d.get("gain_strength", 0)
	card.clan = d.get("clan", "") if d.get("clan") != null else ""
	card.beast_hp = d.get("beast_hp", 0)
	card.trigger_condition = d.get("trigger_condition", "") if d.get("trigger_condition") != null else ""
	card.trigger_threshold = d.get("trigger_threshold", 1)
	card.trigger_effect = d.get("trigger_effect", {}) if d.get("trigger_effect") != null else {}
	card.is_artifact = d.get("is_artifact", false)
	card.artifact_charges = d.get("artifact_charges", 1)
	card.exhaust = d.get("exhaust", false)
	card.retain = d.get("retain", false)
	card.innate = d.get("innate", false)
	card.chain = d.get("chain", false)
	card.power_budget = d.get("power_budget", 0.0)
	return card

func duplicate_card() -> CardData:
	var card = CardData.new()
	card.id = id; card.name = name; card.card_type = card_type
	card.energy_cost = energy_cost; card.elements = elements.duplicate()
	card.damage = damage; card.block = block; card.draw = draw
	card.energy_gain = energy_gain; card.heal = heal
	card.apply_burn = apply_burn; card.apply_poison = apply_poison
	card.apply_weak = apply_weak; card.apply_vulnerable = apply_vulnerable
	card.gain_strength = gain_strength
	card.clan = clan; card.beast_hp = beast_hp
	card.trigger_condition = trigger_condition
	card.trigger_threshold = trigger_threshold
	card.trigger_effect = trigger_effect.duplicate()
	card.is_artifact = is_artifact; card.artifact_charges = artifact_charges
	card.exhaust = exhaust; card.retain = retain
	card.innate = innate; card.chain = chain
	card.power_budget = power_budget
	return card
