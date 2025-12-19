extends Node
class_name GameKernel
# Autoload: GameKernel1 -> res://scripts/core/GameKernel.gd

# -----------------------------------------------------------------------------
# GameKernel1 – globális állapot (csak state, nincs UI/world referencia)
# -----------------------------------------------------------------------------

const MODE_RTS := "RTS"
const MODE_FPS := "FPS"

var _mode: String = MODE_RTS
var _paused: bool = false
var _day_index: int = 1

func _ready() -> void:
	_connect_bus()
	_emit_mode()

func _exit_tree() -> void:
	_disconnect_bus()

# --- Public API (későbbi rendszerek ezt fogják kérdezni) ---
func get_mode() -> String: return _mode
func is_paused() -> bool: return _paused
func get_day() -> int: return _day_index

func set_mode(mode: String) -> void:
	var m := _norm_mode(mode)
	if m == _mode: return
	_mode = m
	_emit_mode()

func set_paused(p: bool, _reason: String = "") -> void:
	_paused = p

func next_day() -> void:
	_day_index += 1

# --- EventBus1 wiring (request_set_game_mode + bus topics) ---
func _get_bus_node() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb := _get_bus_node()
	if eb == null: return

	# request_set_game_mode (klasszikus)
	if eb.has_signal("request_set_game_mode"):
		var cb := Callable(self, "_on_request_set_game_mode")
		if not eb.is_connected("request_set_game_mode", cb):
			eb.connect("request_set_game_mode", cb)

	# generic bus
	if eb.has_signal("bus_emitted"):
		var cb2 := Callable(self, "_on_bus")
		if not eb.is_connected("bus_emitted", cb2):
			eb.connect("bus_emitted", cb2)

func _disconnect_bus() -> void:
	var eb := _get_bus_node()
	if eb == null: return
	var cb := Callable(self, "_on_request_set_game_mode")
	if eb.has_signal("request_set_game_mode") and eb.is_connected("request_set_game_mode", cb):
		eb.disconnect("request_set_game_mode", cb)
	var cb2 := Callable(self, "_on_bus")
	if eb.has_signal("bus_emitted") and eb.is_connected("bus_emitted", cb2):
		eb.disconnect("bus_emitted", cb2)

func _on_request_set_game_mode(mode: String) -> void:
	set_mode(mode)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.pause":
			set_paused(true, str(payload.get("reason", "")))
		"time.resume":
			set_paused(false, str(payload.get("reason", "")))
		"mode.set":
			set_mode(str(payload.get("mode", MODE_RTS)))
		_:
			pass

func _emit_mode() -> void:
	var eb := _get_bus_node()
	if eb != null and eb.has_signal("game_mode_changed"):
		eb.emit_signal("game_mode_changed", _mode)

func _norm_mode(mode: String) -> String:
	return MODE_FPS if str(mode).strip_edges().to_upper() == MODE_FPS else MODE_RTS
