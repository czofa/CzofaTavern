# res://scripts/systems/state/GameState.gd
extends Node
class_name GameState
# Autoload: GameState1

const FactionConfig = preload("res://scripts/systems/factions/FactionConfig.gd")

@export var debug_toast: bool = true

var values: Dictionary = {
	"company_money_ft": 30000,
	"personal_money_ft": 0,
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
	var k = _normalize_key(str(key))
	if k == "":
		return default_value
	if not values.has(k) and k == "company_money_ft" and values.has("money"):
		values[k] = int(values.get("money", default_value))
	if not values.has(k):
		return default_value
	var val: int = int(values.get(k, default_value))
	if k == "company_money_ft":
		_sync_money_alias(val)
	return val

func add_value(key: String, delta: int, reason: String = "") -> void:
	var k = _normalize_key(str(key))
	if k == "":
		return
	var d = int(delta)
	var before = get_value(k, 0)
	values[k] = before + d
	if k == "company_money_ft":
		_sync_money_alias(int(values[k]))

	if debug_toast:
		var r = (" (" + reason + ")") if reason.strip_edges() != "" else ""
		_toast("STATE %s: %d -> %d%s" % [k, before, int(values[k]), r])

func set_value(key: String, value: int, reason: String = "") -> void:
	var k = _normalize_key(str(key))
	if k == "":
		return
	values[k] = int(value)
	if k == "company_money_ft":
		_sync_money_alias(int(values[k]))
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

# ---------------- Frakciók ----------------

func get_faction_value(id: String) -> int:
	var key = _normalize_key(str(id))
	if key == "":
		return FactionConfig.DEFAULT_VALUE
	return get_value(key, FactionConfig.DEFAULT_VALUE)

func add_faction_value(id: String, delta: int, reason: String = "") -> void:
	var key = _normalize_key(str(id))
	if key == "":
		return
	add_value(key, int(delta), reason)

func get_all_factions() -> Array:
	var lista: Array = []
	for entry in FactionConfig.FACTIONS:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id = str(entry.get("id", "")).strip_edges()
		if id == "":
			continue
		var nev = str(entry.get("display_name", id))
		var ikon = str(entry.get("icon", ""))
		lista.append({
			"id": id,
			"display_name": nev,
			"icon": ikon,
			"value": get_faction_value(id)
		})
	return lista

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

func _normalize_key(raw_key: String) -> String:
	var k = raw_key.strip_edges()
	if k == "money":
		return "company_money_ft"
	return k

func _sync_money_alias(value: int) -> void:
	values["money"] = value
	values["company_money_ft"] = value
