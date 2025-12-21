extends Node
class_name TimeSystem
# Autoload: TimeSystem1 -> res://scripts/systems/time/TimeSystem.gd

const MINUTES_PER_DAY := 1440.0
const DAY_START_MINUTE := 6.0 * 60.0

@export var seconds_per_game_minute: float = 1.875 # 45 perces valós nap → 1440 játékperc

var _pause_reasons: Dictionary = {} # reason -> true
var _game_minutes_f: float = DAY_START_MINUTE # 06:00 = indulás (percben)
var _day_start_minutes: float = DAY_START_MINUTE
var _day_index: int = 1
var _day_end_triggered: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()

func _process(delta: float) -> void:
	if is_paused():
		return
	_game_minutes_f += delta / max(0.0001, seconds_per_game_minute)
	if not _day_end_triggered and _game_minutes_f - _day_start_minutes >= MINUTES_PER_DAY:
		_on_day_end()

# -------------------------------------------------------------------
# PAUSE
# -------------------------------------------------------------------

func is_paused() -> bool:
	return _pause_reasons.size() > 0

func pause(reason: String = "") -> void:
	var r = _norm_reason(reason)
	_pause_reasons[r] = true

func resume(reason: String = "") -> void:
	var r = _norm_reason(reason)
	if _pause_reasons.has(r):
		_pause_reasons.erase(r)

func resume_all() -> void:
	_pause_reasons.clear()

func _norm_reason(reason: String) -> String:
	var r = str(reason).strip_edges()
	return r if r != "" else "unknown"

# -------------------------------------------------------------------
# IDŐ LEKÉRDEZÉS
# -------------------------------------------------------------------

func get_game_minutes() -> float:
	return _game_minutes_f

func get_current_game_minutes() -> float:
	# Kompatibilitás: EncounterManager ezt hívja
	return get_game_minutes()

func get_day_progress() -> float:
	# 1 nap = 1440 perc (06:00-tól számolva)
	var minutes_in_day = _game_minutes_f - _day_start_minutes
	return clamp(minutes_in_day / MINUTES_PER_DAY, 0.0, 1.0)

func get_day() -> int:
	return _day_index

# ✅ EZ HIÁNYZOTT – ERRE FAGYOTT KI MINDEN
func get_game_time_string() -> String:
	var total_minutes = int(_game_minutes_f)
	var minutes_in_day = total_minutes % int(MINUTES_PER_DAY)
	var hour = minutes_in_day / 60
	var minute = minutes_in_day % 60
	return "%d. nap %02d:%02d" % [_day_index, hour, minute]

func manual_save() -> void:
	# Stub: ide kerül majd a valódi mentési folyamat
	_log_save("Kézi mentés stub hívva.")

func add_minutes(percek: float) -> void:
	var delta = float(percek)
	if delta == 0.0:
		return
	_game_minutes_f += delta
	if not _day_end_triggered and _game_minutes_f - _day_start_minutes >= MINUTES_PER_DAY:
		_on_day_end()

# -------------------------------------------------------------------
# EVENT BUS
# -------------------------------------------------------------------

func _connect_bus() -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb == null or not eb.has_signal("bus_emitted"):
		return

	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.pause":
			pause(str(payload.get("reason", "")))
		"time.resume":
			resume(str(payload.get("reason", "")))
		"time.resume_all":
			resume_all()
		_:
			pass

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _on_day_end() -> void:
	# Nap zárása → idő megáll, UI felé jelzés
	_day_end_triggered = true
	_game_minutes_f = _day_start_minutes + MINUTES_PER_DAY
	pause("nap_vege")
	_bus("time.pause", {"reason": "nap_vege"})
	_autosave_stub()
	_bus("time.day_end", {"day": _day_index, "time": get_game_time_string()})

func start_next_day() -> void:
	# Napváltás: nap számláló nő, idő vissza 06:00-ra, pause feloldás
	_day_index += 1
	_day_start_minutes += MINUTES_PER_DAY
	_game_minutes_f = _day_start_minutes
	_day_end_triggered = false
	resume("nap_vege")
	_bus("time.resume", {"reason": "nap_vege"})
	_bus("time.new_day", {"day": _day_index, "time": get_game_time_string()})

func _autosave_stub() -> void:
	_log_save("Autosave stub lefutott a nap végén (nap: %d)." % _day_index)

func _log_save(text: String) -> void:
	print("💾 %s" % text)

func has_variable(var_name: StringName) -> bool:
	var target = String(var_name)
	for p in get_property_list():
		if p.has("name") and String(p["name"]) == target:
			return true
	return false
