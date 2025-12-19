extends Control
# Nap végi összegző modal – csak UI kezelésért felel

@export var day_label_path: NodePath = ^"Panel/MarginContainer/VBoxContainer/DayLabel"
@export var info_label_path: NodePath = ^"Panel/MarginContainer/VBoxContainer/InfoLabel"
@export var continue_button_path: NodePath = ^"Panel/MarginContainer/VBoxContainer/ContinueButton"

var _day_label: Label
var _info_label: Label
var _continue_button: Button
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var _locked: bool = false

func _ready() -> void:
	day_label_path = day_label_path if day_label_path != NodePath("") else ^"Panel/MarginContainer/VBoxContainer/DayLabel"
	info_label_path = info_label_path if info_label_path != NodePath("") else ^"Panel/MarginContainer/VBoxContainer/InfoLabel"
	continue_button_path = continue_button_path if continue_button_path != NodePath("") else ^"Panel/MarginContainer/VBoxContainer/ContinueButton"

	_day_label = get_node_or_null(day_label_path)
	_info_label = get_node_or_null(info_label_path)
	_continue_button = get_node_or_null(continue_button_path)

	if _continue_button != null and not _continue_button.is_connected("pressed", Callable(self, "_on_continue_pressed")):
		_continue_button.connect("pressed", Callable(self, "_on_continue_pressed"))

	_set_summary_visible(false)
	_connect_bus()

func _show_summary(day_index: int, time_text: String) -> void:
	if _day_label != null:
		_day_label.text = "Nap vége – %d. nap" % day_index
	if _info_label != null:
		_info_label.text = "Idő: %s\nA játék szünetel, folytasd az alvással." % time_text
	_set_summary_visible(true)

func _on_continue_pressed() -> void:
	if TimeSystem1 != null:
		TimeSystem1.start_next_day()
	_set_summary_visible(false)

func _connect_bus() -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.day_end":
			_show_summary(int(payload.get("day", 1)), str(payload.get("time", "")))
		"time.new_day":
			_set_summary_visible(false)
		_:
			pass

func _set_summary_visible(show: bool) -> void:
	visible = show
	if show:
		_prev_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_lock_modal_input()
	else:
		_unlock_modal_input()
		Input.mouse_mode = _prev_mouse_mode if _is_valid_mouse_mode(_prev_mouse_mode) else (Input.MOUSE_MODE_CAPTURED if _is_fps_mode() else Input.MOUSE_MODE_VISIBLE)

func _lock_modal_input() -> void:
	if _locked:
		return
	_bus("input.lock", {"reason":"day_end"})
	_bus("time.pause", {"reason":"day_end"})
	_locked = true

func _unlock_modal_input() -> void:
	if not _locked:
		return
	_bus("input.unlock", {"reason":"day_end"})
	_bus("time.resume", {"reason":"day_end"})
	_locked = false

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _is_fps_mode() -> bool:
	var gk = get_tree().root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true

func _is_valid_mouse_mode(mode_value: int) -> bool:
	return mode_value in [
		Input.MOUSE_MODE_VISIBLE,
		Input.MOUSE_MODE_CAPTURED,
		Input.MOUSE_MODE_CONFINED,
		Input.MOUSE_MODE_CONFINED_HIDDEN,
		Input.MOUSE_MODE_HIDDEN
	]
