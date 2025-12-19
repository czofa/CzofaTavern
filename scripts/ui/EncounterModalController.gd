extends Control
class_name EncounterModalController

@export var panel_path: NodePath = ^"Panel"
@export var title_label_path: NodePath = ^"Panel/VBox/Title"
@export var body_label_path: NodePath = ^"Panel/VBox/Body"
@export var choice_a_path: NodePath = ^"Panel/VBox/ChoiceA"
@export var choice_b_path: NodePath = ^"Panel/VBox/ChoiceB"
@export var backdrop_color: Color = Color(0, 0, 0, 0.55)

var _data: Dictionary = {}
var _panel: Control
var _title: Label
var _body: Label
var _btn_a: Button
var _btn_b: Button
var _backdrop: ColorRect
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0; offset_top = 0; offset_right = 0; offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_cache()
	_ensure_backdrop()
	_connect_bus()
	visible = false

func open_modal(data: Dictionary) -> void:
	_cache()
	_data = data if data != null else {}
	visible = true
	grab_focus()

	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_bus("input.lock", {"reason":"encounter"})
	_bus("time.pause", {"reason":"encounter"})

	_apply_texts()
	call_deferred("_center_panel")

func close_modal() -> void:
	if not visible:
		return
	visible = false

	_bus("input.unlock", {"reason":"encounter"})
	_bus("time.resume", {"reason":"encounter"})

	# ✅ failsafe: ha bármi mégis paused-on ragadna, oldjuk fel
	if get_tree().paused:
		_bus("time.clear", {})
		get_tree().paused = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _is_fps_mode() else Input.MOUSE_MODE_VISIBLE

func _cache() -> void:
	_panel = get_node_or_null(panel_path) as Control
	_title = get_node_or_null(title_label_path) as Label
	_body = get_node_or_null(body_label_path) as Label
	_btn_a = get_node_or_null(choice_a_path) as Button
	_btn_b = get_node_or_null(choice_b_path) as Button

	if _btn_a != null:
		var cba := Callable(self, "_on_choice_a")
		if not _btn_a.pressed.is_connected(cba):
			_btn_a.pressed.connect(cba)

	if _btn_b != null:
		var cbb := Callable(self, "_on_choice_b")
		if not _btn_b.pressed.is_connected(cbb):
			_btn_b.pressed.connect(cbb)

func _ensure_backdrop() -> void:
	_backdrop = get_node_or_null("Backdrop") as ColorRect
	if _backdrop == null:
		_backdrop = ColorRect.new()
		_backdrop.name = "Backdrop"
		add_child(_backdrop)
		move_child(_backdrop, 0)
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.offset_left = 0; _backdrop.offset_top = 0; _backdrop.offset_right = 0; _backdrop.offset_bottom = 0
	_backdrop.color = backdrop_color
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

func _apply_texts() -> void:
	if _title != null: _title.text = str(_data.get("title", "Encounter"))
	if _body != null: _body.text = str(_data.get("body", "..."))

	var choices: Array = _data.get("choices", [])
	if _btn_a != null:
		_btn_a.text = str(choices[0].get("text", "OK")) if choices.size() > 0 else "OK"
	if _btn_b != null:
		_btn_b.visible = (choices.size() > 1)
		if choices.size() > 1:
			_btn_b.text = str(choices[1].get("text", "Másik"))

func _center_panel() -> void:
	if _panel == null:
		return
	var desired := _panel.get_combined_minimum_size()
	if desired.x > 0 and desired.y > 0:
		_panel.size = desired
	var vp := get_viewport_rect().size
	_panel.position = (vp - _panel.size) * 0.5

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE: _resolve_choice(-1); accept_event()
			KEY_1, KEY_Y, KEY_ENTER, KEY_KP_ENTER: _resolve_choice(0); accept_event()
			KEY_2, KEY_N: _resolve_choice(1); accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_resolve_choice(-1); accept_event()

func _on_choice_a() -> void: _resolve_choice(0)
func _on_choice_b() -> void: _resolve_choice(1)

func _resolve_choice(index: int) -> void:
	var encounter_id := str(_data.get("id", "fallback"))
	var choices: Array = _data.get("choices", [])
	var choice_id := "cancel"
	if index >= 0 and index < choices.size():
		choice_id = str(choices[index].get("id", "ok"))
	elif index == 0 and choices.size() == 0:
		choice_id = "ok"

	_bus("encounter.resolved", {"id": encounter_id, "choice": choice_id})
	close_modal()

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _connect_bus() -> void:
	var eb := _eb()
	if eb == null:
		return
	if eb.has_signal("bus_emitted"):
		var cb := Callable(self, "_on_bus")
		if not eb.is_connected("bus_emitted", cb):
			eb.connect("bus_emitted", cb)

func _disconnect_bus() -> void:
	var eb := _eb()
	if eb == null:
		return
	var cb := Callable(self, "_on_bus")
	if eb.has_signal("bus_emitted") and eb.is_connected("bus_emitted", cb):
		eb.disconnect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"ui.modal.open":
			if str(payload.get("kind","")) == "encounter":
				open_modal(payload.get("data", {}))
		"ui.modal.close":
			if str(payload.get("kind","")) == "encounter":
				close_modal()
		_:
			pass

func _is_fps_mode() -> bool:
	var root := get_tree().root
	var gk := root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true
