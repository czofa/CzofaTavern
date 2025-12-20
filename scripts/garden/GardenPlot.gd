extends Node3D
class_name GardenPlot

@export var plot_id: String = "plot_1"
@export var crop_id: String = "potato"

var _state: String = "empty"
var _planted_at_minutes: float = 0.0
var _ready_at_minutes: float = 0.0
var _ready_announced: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_state()
	_ensure_state_up_to_date(true)

func _process(_delta: float) -> void:
	_ensure_state_up_to_date_tick()

func interact() -> void:
	_ensure_state_up_to_date(true)
	match _state:
		"empty":
			_try_plant()
		"growing":
			_notify_progress()
		"ready":
			_harvest()
		_:
			_state = "empty"

func _ensure_state_up_to_date_tick() -> void:
	_ensure_state_up_to_date(false)

func _ensure_state_up_to_date(allow_notify: bool) -> void:
	if _state == "ready" and allow_notify and not _ready_announced:
		_ready_announced = true
		_save_state()
		_notify("✅ Kész a termés: %s" % _crop_name())
		return
	if _state != "growing":
		return
	var now = _get_minutes()
	if _ready_at_minutes <= 0.0:
		return
	if now >= _ready_at_minutes:
		_state = "ready"
		_save_state()
		if allow_notify and not _ready_announced:
			_ready_announced = true
			_notify("✅ Kész a termés: %s" % _crop_name())

func _try_plant() -> void:
	var data = GardenCatalog.get_crop(crop_id)
	if data.is_empty():
		_notify("❌ Ismeretlen növény: %s" % crop_id)
		return
	var seed_id = str(data.get("seed_id", ""))
	if seed_id == "":
		_notify("❌ A növényhez nem tartozik mag.")
		return
	if not _has_seed(seed_id):
		_notify("❌ Nincs elég mag (%s)." % seed_id)
		return
	if not _consume_seed(seed_id):
		_notify("❌ Nem sikerült elültetni, nincs mag.")
		return
	var now = _get_minutes()
	var grow_minutes = float(data.get("growth_minutes", 0.0))
	_planted_at_minutes = now
	_ready_at_minutes = now + grow_minutes
	_state = "growing"
	_ready_announced = false
	_save_state()
	_notify("🌱 Elültetve: %s (kész: %s)" % [_crop_name(), _format_time(_ready_at_minutes)])

func _notify_progress() -> void:
	if _state != "growing":
		return
	var now = _get_minutes()
	if now >= _ready_at_minutes:
		_state = "ready"
		_save_state()
		if not _ready_announced:
			_ready_announced = true
			_notify("✅ Kész a termés: %s" % _crop_name())
		return
	var remaining = _ready_at_minutes - now
	if remaining < 0.0:
		remaining = 0.0
	var eta = _format_time(_ready_at_minutes)
	var remaining_minutes = int(ceil(remaining))
	_notify("⏳ Növekedés folyamatban: %s (kész: %s, hátra: %d perc)" % [_crop_name(), eta, remaining_minutes])

func _harvest() -> void:
	if _state != "ready":
		_notify_progress()
		return
	var data = GardenCatalog.get_crop(crop_id)
	if data.is_empty():
		_notify("❌ Ismeretlen termény, nem tudom betakarítani.")
		return
	var yield_grams = int(data.get("yield_grams", 0))
	if yield_grams <= 0:
		_notify("❌ A termés nem adható hozzá, yield=0.")
		return
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null:
		StockSystem1.add_unbooked(crop_id, yield_grams, 0)
		_notify("🧺 Betakarítva: %s +%d g (könyveletlen)" % [crop_id, yield_grams])
	else:
		_notify("❌ Készlet rendszer nem elérhető.")
		return
	_state = "empty"
	_planted_at_minutes = 0.0
	_ready_at_minutes = 0.0
	_ready_announced = false
	_save_state()

func _has_seed(seed_id: String) -> bool:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return false
	return StockSystem1.get_qty(seed_id) > 0

func _consume_seed(seed_id: String) -> bool:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return false
	return StockSystem1.remove(seed_id, 1)

func _get_minutes() -> float:
	if typeof(TimeSystem1) == TYPE_NIL or TimeSystem1 == null:
		return 0.0
	return TimeSystem1.get_game_minutes()

func _crop_name() -> String:
	return GardenCatalog.get_crop_name(crop_id)

func _format_time(minutes: float) -> String:
	var total = int(minutes)
	var minutes_in_day = total % 1440
	var hour = minutes_in_day / 60
	var minute = minutes_in_day % 60
	return "%02d:%02d" % [hour, minute]

func _save_state() -> void:
	var gs = _get_game_state()
	if gs == null:
		return
	var values = gs.values
	var garden_state = values.get("garden_plots", {})
	garden_state[plot_id] = {
		"state": _state,
		"planted_at": _planted_at_minutes,
		"ready_at": _ready_at_minutes,
		"crop_id": crop_id,
		"ready_announced": _ready_announced
	}
	values["garden_plots"] = garden_state
	gs.values = values

func _load_state() -> void:
	var gs = _get_game_state()
	if gs == null:
		return
	var values = gs.values
	if not values.has("garden_plots"):
		return
	var garden_state = values.get("garden_plots", {})
	var entry = garden_state.get(plot_id, {})
	if entry.is_empty():
		return
	_state = str(entry.get("state", _state))
	_planted_at_minutes = float(entry.get("planted_at", 0.0))
	_ready_at_minutes = float(entry.get("ready_at", 0.0))
	crop_id = str(entry.get("crop_id", crop_id))
	_ready_announced = bool(entry.get("ready_announced", false))

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
