# res://scripts/ui/ToastFeedController.gd
extends Control
class_name ToastFeedController

@export var max_lines: int = 5
@export var toast_duration_sec: float = 2.5
@export var padding: Vector2 = Vector2(12, 10)
@export var line_spacing: int = 6

var _lines: Array[Label] = []
var _timers: Array[Timer] = []

func _ready() -> void:
	_connect_event_bus()
	_ensure_layout()

func _exit_tree() -> void:
	_disconnect_event_bus()

# -----------------------------------------------------------------------------
# EventBus
# -----------------------------------------------------------------------------

func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	if has_node("/root/EventBus1"):
		return get_node("/root/EventBus1")
	return null

func _connect_event_bus() -> void:
	var eb = _get_event_bus()
	if eb == null:
		push_warning("ToastFeedController: EventBus/EventBus1 not found.")
		return
	if not eb.has_signal("notification_requested"):
		push_warning("ToastFeedController: EventBus missing signal 'notification_requested(text)'.")
		return

	var cb = Callable(self, "_on_notification_requested")
	if not eb.is_connected("notification_requested", cb):
		eb.connect("notification_requested", cb)

func _disconnect_event_bus() -> void:
	var eb = _get_event_bus()
	if eb == null:
		return
	var cb = Callable(self, "_on_notification_requested")
	if eb.has_signal("notification_requested") and eb.is_connected("notification_requested", cb):
		eb.disconnect("notification_requested", cb)

# -----------------------------------------------------------------------------
# UI
# -----------------------------------------------------------------------------

func _ensure_layout() -> void:
	# legyen fixen a képernyő bal felső sarkában (ha más kell, később állítjuk)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2(20, 120)

func _on_notification_requested(text: String) -> void:
	if text.strip_edges() == "":
		return

	_add_toast(text)

func _add_toast(text: String) -> void:
	# ha túl sok, a legrégebbit dobjuk
	if _lines.size() >= max_lines:
		_remove_toast(0)

	var lbl = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.clip_text = false
	add_child(lbl)

	_lines.append(lbl)

	var t = Timer.new()
	t.one_shot = true
	t.wait_time = toast_duration_sec
	add_child(t)
	_timers.append(t)

	t.timeout.connect(func(): _remove_toast(_lines.find(lbl)))
	t.start()

	_reflow()

func _remove_toast(index: int) -> void:
	if index < 0 or index >= _lines.size():
		return

	var lbl = _lines[index]
	var t = _timers[index]

	_lines.remove_at(index)
	_timers.remove_at(index)

	if is_instance_valid(lbl):
		lbl.queue_free()
	if is_instance_valid(t):
		t.queue_free()

	_reflow()

func _reflow() -> void:
	var y = padding.y
	for lbl in _lines:
		lbl.position = Vector2(padding.x, y)
		# becsült magasság: minimum 22, hogy biztosan ne fedje egymást
		y += max(22.0, lbl.size.y) + float(line_spacing)
