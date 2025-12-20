extends Node3D
class_name AnimalProducer

@export var coop_id: String = "coop_1"
@export var animal_id: String = "chicken"
@export var auto_produce: bool = true

var _next_production_minutes: float = 0.0
var _last_production_minutes: float = 0.0
var _initialized: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_state()
	if not _initialized:
		_schedule_next_production()
	_initialized = true

func _process(_delta: float) -> void:
	if not auto_produce:
		return
	_production_tick()

func interact() -> void:
	var data = GardenCatalog.get_animal(animal_id)
	if data.is_empty():
		_notify("❌ Ismeretlen állat: %s" % animal_id)
		return
	if _next_production_minutes <= 0.0:
		_schedule_next_production()
	_notify_status(data)

func _production_tick() -> void:
	var data = GardenCatalog.get_animal(animal_id)
	if data.is_empty():
		return
	var now = _get_minutes()
	if _next_production_minutes <= 0.0:
		_schedule_next_production()
		return
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return
	if now < _next_production_minutes:
		return
	_produce_now(data, now)
	_schedule_next_production_from(now, data)

func _produce_now(data: Dictionary, now: float) -> void:
	var product_id = str(data.get("product_id", ""))
	var yield_grams = int(data.get("yield_grams", 0))
	if product_id == "" or yield_grams <= 0:
		return
	_last_production_minutes = now
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null:
		StockSystem1.add_unbooked(product_id, yield_grams, 0)
		var product_name = GardenCatalog.get_product_name(animal_id)
		_notify("🐔 Tojás termett: %s +%d g (könyveletlen)" % [product_name, yield_grams])
	_save_state()

func _schedule_next_production() -> void:
	var data = GardenCatalog.get_animal(animal_id)
	_schedule_next_production_from(_get_minutes(), data)

func _schedule_next_production_from(now: float, data: Dictionary) -> void:
	if data.is_empty():
		return
	var interval_minutes = float(data.get("interval_minutes", 0.0))
	if interval_minutes <= 0.0:
		return
	_next_production_minutes = now + interval_minutes
	_save_state()

func _notify_status(data: Dictionary) -> void:
	if data.is_empty():
		return
	var eta_text = "ismeretlen"
	if _next_production_minutes > 0.0:
		eta_text = _format_time(_next_production_minutes)
	var animal_name = GardenCatalog.get_animal_name(animal_id)
	var product_name = GardenCatalog.get_product_name(animal_id)
	_notify("🐔 %s termel: következő %s %s körül" % [animal_name, product_name, eta_text])

func _format_time(minutes: float) -> String:
	var total = int(minutes)
	var minutes_in_day = total % 1440
	var hour = minutes_in_day / 60
	var minute = minutes_in_day % 60
	return "%02d:%02d" % [hour, minute]

func _get_minutes() -> float:
	if typeof(TimeSystem1) == TYPE_NIL or TimeSystem1 == null:
		return 0.0
	return TimeSystem1.get_game_minutes()

func _save_state() -> void:
	var gs = _get_game_state()
	if gs == null:
		return
	var values = gs.values
	var animals_state = values.get("garden_animals", {})
	animals_state[coop_id] = {
		"next_at": _next_production_minutes,
		"last_at": _last_production_minutes,
		"animal_id": animal_id
	}
	values["garden_animals"] = animals_state
	gs.values = values

func _load_state() -> void:
	var gs = _get_game_state()
	if gs == null:
		return
	var values = gs.values
	var animals_state = values.get("garden_animals", {})
	var entry = animals_state.get(coop_id, {})
	if entry.is_empty():
		return
	_next_production_minutes = float(entry.get("next_at", 0.0))
	_last_production_minutes = float(entry.get("last_at", 0.0))
	animal_id = str(entry.get("animal_id", animal_id))

func _get_game_state() -> GameState:
	if typeof(GameState1) != TYPE_NIL and GameState1 != null:
		return GameState1
	return null

func _eb() -> Node:
	if not is_inside_tree():
		return null
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")

func _notify(text: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
