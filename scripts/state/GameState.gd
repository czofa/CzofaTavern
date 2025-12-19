# res://scripts/systems/state/GameState.gd
extends Node
class_name GameState
# Autoload: GameState1

@export var debug_toast: bool = true

var values: Dictionary = {
	"money": 30000,
	"reputation": 0,
	"villagers": 0,
	"authority": 0,
	"underworld": 0,
	"risk": 0,
	"safety": 0
}

var flags: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	if debug_toast:
		_toast("GameState READY")

func get_value(key: String, default_value: int = 0) -> int:
	var k = str(key).strip_edges()
	if k == "":
		return default_value
	if not values.has(k):
		return default_value
	return int(values[k])

func add_value(key: String, delta: int, reason: String = "") -> void:
	var k = str(key).strip_edges()
	if k == "":
		return
	var d = int(delta)
	var before = get_value(k, 0)
	values[k] = before + d

	if debug_toast:
		var r = (" (" + reason + ")") if reason.strip_edges() != "" else ""
		_toast("STATE %s: %d -> %d%s" % [k, before, int(values[k]), r])

func set_value(key: String, value: int, reason: String = "") -> void:
	var k = str(key).strip_edges()
	if k == "":
		return
	values[k] = int(value)
	if debug_toast:
		var r = (" (" + reason + ")") if reason.strip_edges() != "" else ""
		_toast("STATE %s SET: %d%s" % [k, int(values[k]), r])

func set_flag(key: String, value: bool = true) -> void:
	var k = str(key).strip_edges()
	if k == "":
		return
	flags[k] = bool(value)
	if debug_toast:
		_toast("FLAG %s = %s" % [k, str(flags[k])])

# ---------------- Bus ----------------

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"state.add":
			add_value(str(payload.get("key","")), int(payload.get("delta", 0)), str(payload.get("reason","")))
		"state.set":
			set_value(str(payload.get("key","")), int(payload.get("value", 0)), str(payload.get("reason","")))
		"state.flag.set":
			set_flag(str(payload.get("key","")), bool(payload.get("value", true)))
		_:
			pass

func _toast(t: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
