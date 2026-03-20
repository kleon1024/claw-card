class_name EnemyData
extends RefCounted

var id: String
var enemy_name: String
var max_hp: int
var current_hp: int
var block: int = 0
var strength: int = 0
var burn: int = 0
var poison: int = 0
var weak: int = 0
var vulnerable: int = 0
var intent: Dictionary = {}
var intent_pool: Array = []
var turn_counter: int = 0

static func from_template(enemy_id: String, template: Dictionary) -> EnemyData:
	var e = EnemyData.new()
	e.id = enemy_id
	e.enemy_name = enemy_id.replace("_", " ").capitalize()
	e.max_hp = template.get("max_hp", 50)
	e.current_hp = e.max_hp
	e.intent_pool = template.get("intents", [])
	return e

func duplicate_enemy() -> EnemyData:
	var e = EnemyData.new()
	e.id = id; e.enemy_name = enemy_name; e.max_hp = max_hp
	e.current_hp = current_hp; e.block = block; e.strength = strength
	e.burn = burn; e.poison = poison; e.weak = weak; e.vulnerable = vulnerable
	e.intent = intent.duplicate(); e.intent_pool = intent_pool.duplicate(true)
	e.turn_counter = turn_counter
	return e
