extends Node3D
class_name GardenArea

var _seed_flag_key: String = "garden_initial_seeds_added"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_initial_seeds()

func _ensure_initial_seeds() -> void:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return
	if _seeds_already_given():
		return
	var seeds = GardenCatalog.get_initial_seeds()
	for seed_id in seeds.keys():
		var qty = int(seeds.get(seed_id, 0))
		if qty <= 0:
			continue
		var current_qty = int(StockSystem1.stock.get(seed_id, 0))
		StockSystem1.stock[seed_id] = current_qty + qty
	_mark_seeds_given()

func _seeds_already_given() -> bool:
	var gs = _get_game_state()
	if gs == null:
		return false
	var flags = gs.flags
	return bool(flags.get(_seed_flag_key, false))

func _mark_seeds_given() -> void:
	var gs = _get_game_state()
	if gs == null:
		return
	var flags = gs.flags
	flags[_seed_flag_key] = true
	gs.flags = flags

func _get_game_state() -> GameState:
	if typeof(GameState1) != TYPE_NIL and GameState1 != null:
		return GameState1
	return null
