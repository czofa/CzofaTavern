extends Node
class_name FactionSystem
# Autoload: FactionSystem1

const FactionConfig = preload("res://scripts/systems/factions/FactionConfig.gd")

@export var debug_toast: bool = false

var _local_values: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_defaults()
	_connect_bus()
	if debug_toast:
		_toast("FactionSystem READY")

func get_factions() -> Array:
	return FactionConfig.FACTIONS

func get_faction_value(id: String) -> int:
	var key = _norm_id(id)
	if key == "":
		return 0
	var gs = _get_state()
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", key, _default_value()))
	if _local_values.has(key):
		return int(_local_values[key])
	return _default_value()

func add_faction_value(id: String, delta: int, reason: String = "") -> void:
	var key = _norm_id(id)
	if key == "":
		return
	var current = get_faction_value(key)
	var next_value = current + int(delta)
	var gs = _get_state()
	if gs != null and gs.has_method("set_value"):
		gs.call("set_value", key, next_value, reason)
	else:
		_local_values[key] = next_value
	_emit_changed(key, current, next_value, reason)

func get_faction_status_text(id: String) -> String:
	var key = _norm_id(id)
	if key == "":
		return ""
	var value = get_faction_value(key)
	var data = FactionConfig.get_status_data(value)
	var label = str(data.get("label", ""))
	var desc = str(data.get("description", ""))
	return "%s (%d) – %s" % [label, value, desc]

func _emit_changed(id: String, before: int, after: int, reason: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "faction.changed", {
			"id": id,
			"before": before,
			"after": after,
			"reason": reason
		})

func _default_value() -> int:
	return FactionConfig.DEFAULT_VALUE

func _norm_id(id: String) -> String:
	return str(id).strip_edges().to_lower()

func _init_defaults() -> void:
	for entry in FactionConfig.FACTIONS:
		var key = _norm_id(entry.get("id", ""))
		if key == "":
			continue
		var current = get_faction_value(key)
		if current == 0:
			_set_if_missing(key, _default_value())

func _set_if_missing(key: String, value: int) -> void:
	var gs = _get_state()
	if gs != null and gs.has_method("get_value") and gs.has_method("set_value"):
		var exists = gs.call("get_value", key, -999999)
		if int(exists) == -999999:
			gs.call("set_value", key, value, "alap frakció érték")
		return
	if not _local_values.has(key):
		_local_values[key] = value

func _get_state() -> Node:
	var root = get_tree().root
	var gs = root.get_node_or_null("GameState1")
	if gs != null:
		return gs
	return root.get_node_or_null("GameState")

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"faction.add":
			add_faction_value(str(payload.get("id", "")), int(payload.get("delta", 0)), str(payload.get("reason", "")))
		_:
			pass

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _toast(t: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
