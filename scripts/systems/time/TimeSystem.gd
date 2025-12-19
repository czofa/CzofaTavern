extends Node
class_name TimeSystem
# Autoload: TimeSystem1 -> res://scripts/systems/time/TimeSystem.gd

@export var seconds_per_game_minute: float = 0.25

var _pause_reasons: Dictionary = {} # reason -> true
var _game_minutes_f: float = 12.0 * 60.0 # 12:00 = indulás (percben)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()

func _process(delta: float) -> void:
	if is_paused():
		return
	_game_minutes_f += delta / max(0.0001, seconds_per_game_minute)

# -------------------------------------------------------------------
# PAUSE
# -------------------------------------------------------------------

func is_paused() -> bool:
	return _pause_reasons.size() > 0

func pause(reason: String = "") -> void:
	var r := _norm_reason(reason)
	_pause_reasons[r] = true

func resume(reason: String = "") -> void:
	var r := _norm_reason(reason)
	if _pause_reasons.has(r):
		_pause_reasons.erase(r)

func resume_all() -> void:
	_pause_reasons.clear()

func _norm_reason(reason: String) -> String:
	var r := str(reason).strip_edges()
	return r if r != "" else "unknown"

# -------------------------------------------------------------------
# IDŐ LEKÉRDEZÉS
# -------------------------------------------------------------------

func get_game_minutes() -> float:
	return _game_minutes_f

func get_day_progress() -> float:
	# 1 nap = 1440 perc
	return clamp(_game_minutes_f / 1440.0, 0.0, 1.0)

# ✅ EZ HIÁNYZOTT – ERRE FAGYOTT KI MINDEN
func get_game_time_string() -> String:
	var total_minutes := int(_game_minutes_f)
	var day := total_minutes / 1440 + 1
	var minutes_in_day := total_minutes % 1440
	var hour := minutes_in_day / 60
	var minute := minutes_in_day % 60
	return "%d. nap %02d:%02d" % [day, hour, minute]

# -------------------------------------------------------------------
# EVENT BUS
# -------------------------------------------------------------------

func _connect_bus() -> void:
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb == null or not eb.has_signal("bus_emitted"):
		return

	var cb := Callable(self, "_on_bus")
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
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)
