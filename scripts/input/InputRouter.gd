extends Node
class_name InputRouter
# Autoload name: InputRouter1
# File: res://scripts/input/InputRouter.gd

const ACT_TOGGLE_BOOK := "toggle_book_menu"
const ACT_CLOSE_POPUPS := "close_all_popups"
const ACT_INTERACT := "interact"
const ACT_SET_MODE_RTS := "set_mode_rts"
const ACT_SET_MODE_FPS := "set_mode_fps"
const ACT_TOGGLE_MODE := "toggle_mode"

const KEY_PANIC_UNLOCK := KEY_F6
const KEY_TEST_ENCOUNTER := KEY_F9
const KEY_TOGGLE_LOCK := KEY_F10

const KEY_MODE_RTS := KEY_F2
const KEY_MODE_FPS := KEY_F3
const KEY_MODE_TOGGLE := KEY_F4

@export var debug_notify: bool = true

var _lock_reasons: Dictionary = {} # reason -> true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_connect_bus()
	_notify("InputRouter ready")

func _exit_tree() -> void:
	_disconnect_bus()

func _input(event: InputEvent) -> void:
	if event == null:
		return

	# --------- KEY fallback (biztos) ---------
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey

		if k.keycode == KEY_PANIC_UNLOCK:
			_panic_unlock()
			return

		if k.keycode == KEY_TOGGLE_LOCK:
			_toggle_lock("debug")
			return

		if k.keycode == KEY_TEST_ENCOUNTER:
			_request_test_encounter()
			return

		# ESC mindig mehet
		if k.keycode == KEY_ESCAPE:
			_emit_close_popups()
			return

		# DIAG: E-t mindig jelezzük
		if k.keycode == KEY_E:
			_notify("INPUT: E pressed")

			if is_locked():
				_notify("E ignored: INPUT LOCK %s" % str(_lock_reasons.keys()))
				return

			_emit_interact()
			_notify("INTERACT SENT")
			return

		# LOCK alatt semmi más gameplay
		if is_locked():
			return

		match k.keycode:
			KEY_MODE_RTS:
				_set_mode("RTS")
				return
			KEY_MODE_FPS:
				_set_mode("FPS")
				return
			KEY_MODE_TOGGLE:
				_toggle_mode()
				return
			KEY_M:
				_emit_toggle_book()
				return

	# --------- Action alapú (InputMap) ---------
	if is_locked():
		return

	if _pressed(ACT_SET_MODE_RTS, event):
		_set_mode("RTS")
		return
	if _pressed(ACT_SET_MODE_FPS, event):
		_set_mode("FPS")
		return
	if _pressed(ACT_TOGGLE_MODE, event):
		_toggle_mode()
		return

	if _pressed(ACT_TOGGLE_BOOK, event):
		_emit_toggle_book()
		return
	if _pressed(ACT_CLOSE_POPUPS, event):
		_emit_close_popups()
		return
	if _pressed(ACT_INTERACT, event):
		_emit_interact()
		_notify("INTERACT SENT (action)")
		return

# -------------------- Lock API --------------------

func is_locked() -> bool:
	return _lock_reasons.size() > 0

func _lock(reason: String) -> void:
	var r := str(reason).strip_edges()
	if r == "":
		r = "unknown"
	_lock_reasons[r] = true
	_notify("INPUT LOCKED: %s" % r)

func _unlock(reason: String) -> void:
	var r := str(reason).strip_edges()
	if r == "":
		r = "unknown"
	if _lock_reasons.has(r):
		_lock_reasons.erase(r)
	_notify("INPUT UNLOCK: %s" % r)

func _toggle_lock(reason: String) -> void:
	if _lock_reasons.has(reason):
		_unlock(reason)
	else:
		_lock(reason)

func _panic_unlock() -> void:
	_lock_reasons.clear()
	_notify("PANIC UNLOCK (F6)")
	_bus("time.clear", {"reason":"panic"})
	_bus("input.unlock", {"reason":"panic"})

# -------------------- EventBus wiring --------------------

func _get_bus_node() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb := _get_bus_node()
	if eb == null:
		_notify("InputRouter: EventBus1 missing")
		return

	if eb.has_signal("request_set_input_locked"):
		var cb := Callable(self, "_on_request_set_input_locked")
		if not eb.is_connected("request_set_input_locked", cb):
			eb.connect("request_set_input_locked", cb)

	if eb.has_signal("bus_emitted"):
		var cb2 := Callable(self, "_on_bus")
		if not eb.is_connected("bus_emitted", cb2):
			eb.connect("bus_emitted", cb2)

func _disconnect_bus() -> void:
	var eb := _get_bus_node()
	if eb == null:
		return

	var cb := Callable(self, "_on_request_set_input_locked")
	if eb.has_signal("request_set_input_locked") and eb.is_connected("request_set_input_locked", cb):
		eb.disconnect("request_set_input_locked", cb)

	var cb2 := Callable(self, "_on_bus")
	if eb.has_signal("bus_emitted") and eb.is_connected("bus_emitted", cb2):
		eb.disconnect("bus_emitted", cb2)

func _on_request_set_input_locked(locked: bool, reason: String) -> void:
	if locked:
		_lock(reason)
	else:
		_unlock(reason)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"input.lock":
			_lock(str(payload.get("reason", "modal")))
		"input.unlock":
			_unlock(str(payload.get("reason", "modal")))
		"time.pause":
			_lock(str(payload.get("reason", "time")))
		"time.resume":
			_unlock(str(payload.get("reason", "time")))
		"time.clear":
			_lock_reasons.clear()
			_notify("INPUT CLEAR (time.clear)")
		_:
			pass

# -------------------- Mode control --------------------

func _set_mode(mode: String) -> void:
	_bus("mode.set", {"mode": mode})
	_notify("MODE: %s" % str(mode).to_upper())

	var eb := _get_bus_node()
	if eb != null and eb.has_signal("request_set_game_mode"):
		eb.emit_signal("request_set_game_mode", str(mode))

func _toggle_mode() -> void:
	_bus("mode.toggle", {})
	_notify("MODE: TOGGLE")

# -------------------- Emits --------------------

func _emit_toggle_book() -> void:
	var eb := _get_bus_node()
	if eb != null and eb.has_signal("request_toggle_book_menu"):
		eb.emit_signal("request_toggle_book_menu")

func _emit_close_popups() -> void:
	var eb := _get_bus_node()
	if eb != null and eb.has_signal("request_close_all_popups"):
		eb.emit_signal("request_close_all_popups")

func _emit_interact() -> void:
	var eb := _get_bus_node()
	if eb != null and eb.has_signal("request_interact"):
		eb.emit_signal("request_interact")

# -------------------- Helpers --------------------

func _request_test_encounter() -> void:
	_bus("encounter.request", {"id":"test_judge"})

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := _get_bus_node()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _pressed(action_name: String, event: InputEvent) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)

func _notify(text: String) -> void:
	if not debug_notify:
		return

	var eb := _get_bus_node()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(text))
