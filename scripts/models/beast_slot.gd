class_name BeastSlotData
extends RefCounted

var card: CardData
var current_hp: int
var triggers_this_turn: int = 0
var total_triggers: int = 0

static func create(beast_card: CardData) -> BeastSlotData:
	var slot = BeastSlotData.new()
	slot.card = beast_card
	slot.current_hp = beast_card.beast_hp
	return slot

func duplicate_slot() -> BeastSlotData:
	var slot = BeastSlotData.new()
	slot.card = card.duplicate_card()
	slot.current_hp = current_hp
	slot.triggers_this_turn = triggers_this_turn
	slot.total_triggers = total_triggers
	return slot
