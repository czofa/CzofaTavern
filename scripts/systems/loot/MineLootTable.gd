extends Node
class_name MineLootTable

const DATA = {
	"tiers": [
		{
			"min_level": 1,
			"items": [
				{"id": "stone", "w": 60, "value": 15},
				{"id": "copper_ore", "w": 30, "value": 50},
				{"id": "rare_gem", "w": 10, "value": 140}
			]
		},
		{
			"min_level": 6,
			"items": [
				{"id": "iron_ore", "w": 35, "value": 120},
				{"id": "silver_ore", "w": 20, "value": 200},
				{"id": "rare_gem", "w": 15, "value": 200}
			]
		},
		{
			"min_level": 11,
			"items": [
				{"id": "gold_ore", "w": 25, "value": 260},
				{"id": "emerald", "w": 10, "value": 520},
				{"id": "rare_relic", "w": 8, "value": 700}
			]
		}
	]
}

const ITEM_NAMES = {
	"stone": "Kő",
	"copper_ore": "Rézérc",
	"rare_gem": "Ritka drágakő",
	"iron_ore": "Vasérc",
	"silver_ore": "Ezüstérc",
	"gold_ore": "Aranyrög",
	"emerald": "Smaragd",
	"rare_relic": "Ősi relikvia"
}

static func pick_enemy_drops(level: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var drops: Array = []
	var drop_db: int = rng.randi_range(1, 2)
	for i in range(drop_db):
		var item = _pick_item(level, rng)
		if not item.is_empty():
			drops.append(item)
	return drops

static func pick_rock_drop(level: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return _pick_item(level, rng)

static func get_value(item_id: String) -> int:
	var id = str(item_id).strip_edges()
	if id == "":
		return 0
	var best_value: int = 0
	for tier in DATA.get("tiers", []):
		var items = tier.get("items", [])
		for entry in items:
			if str(entry.get("id", "")) == id:
				best_value = int(entry.get("value", best_value))
	return best_value

static func get_display_name(item_id: String) -> String:
	var id = str(item_id).strip_edges()
	if ITEM_NAMES.has(id):
		return str(ITEM_NAMES.get(id, id))
	return id.capitalize()

static func _pick_item(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var tier = _get_tier(level)
	var items = tier.get("items", [])
	if items.is_empty():
		return {}
	var total_weight: int = 0
	for entry in items:
		total_weight += int(entry.get("w", 0))
	if total_weight <= 0:
		return {}
	var roll: int = rng.randi_range(1, total_weight)
	var acc: int = 0
	for entry in items:
		acc += int(entry.get("w", 0))
		if roll <= acc:
			var id = str(entry.get("id", ""))
			if id == "":
				return {}
			return {
				"id": id,
				"value": int(entry.get("value", 0)),
				"qty": 1
			}
	return {}

static func _get_tier(level: int) -> Dictionary:
	var lvl: int = int(level)
	if lvl < 1:
		lvl = 1
	var best: Dictionary = {}
	for tier in DATA.get("tiers", []):
		var min_level: int = int(tier.get("min_level", 1))
		if min_level <= lvl:
			if best.is_empty() or min_level >= int(best.get("min_level", 0)):
				best = tier
	if best.is_empty() and DATA.get("tiers", []).size() > 0:
		best = DATA.get("tiers", [])[0]
	return best
