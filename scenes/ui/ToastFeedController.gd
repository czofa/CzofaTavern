extends PanelContainer
class_name TopToastController

@export var max_szelesseg: float = 720.0
@export var alap_ttl: float = 2.5

@onready var _label: Label = $MarginContainer/ToastLabel

var _timer: Timer

func _ready() -> void:
	_ensure_timer()
	_beallit_alap_layout()
	_connect_event_bus()
	visible = false

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
		push_warning("TopToast: EventBus/EventBus1 nem található.")
		return
	if not eb.has_signal("notification_requested"):
		push_warning("TopToast: hiányzik a 'notification_requested' signal.")
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

func _ensure_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_hide_toast)

func _beallit_alap_layout() -> void:
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_toast(text: String, kind: String = "info", ttl: float = 2.5, important: bool = false) -> void:
	var tiszta = text.strip_edges()
	if tiszta == "":
		return
	if not _fontos_uzenet(tiszta, kind, important):
		return

	_label.text = tiszta
	_alkalmaz_tipus_stilus(kind)
	_frissit_meret()
	visible = true

	_timer.stop()
	var cel_ttl = ttl if ttl > 0.0 else alap_ttl
	if cel_ttl > 0.0:
		_timer.wait_time = cel_ttl
		_timer.start()

func _hide_toast() -> void:
	visible = false

func _on_notification_requested(text: String) -> void:
	var kind = _kind_szovegbol(text)
	show_toast(text, kind, alap_ttl, false)

func _kind_szovegbol(text: String) -> String:
	if text.find("❌") >= 0:
		return "error"
	if text.find("⚠️") >= 0:
		return "warn"
	return "info"

func _fontos_uzenet(text: String, kind: String, important: bool) -> bool:
	if important:
		return true
	return kind == "warn" or kind == "error"

func _alkalmaz_tipus_stilus(kind: String) -> void:
	match kind:
		"error":
			_label.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2))
		"warn":
			_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
		_:
			_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _frissit_meret() -> void:
	_label.custom_minimum_size = Vector2(0.0, 0.0)
	var alap_meret = _label.get_combined_minimum_size()
	var cel_szelesseg = min(alap_meret.x, max_szelesseg)
	_label.custom_minimum_size = Vector2(cel_szelesseg, 0.0)
	var min_meret = _label.get_combined_minimum_size()
	custom_minimum_size = Vector2(min_meret.x + 32.0, min_meret.y + 20.0)
	var felso = 16.0
	var viewport_meret = get_viewport().get_visible_rect().size
	var x = (viewport_meret.x - custom_minimum_size.x) * 0.5
	position = Vector2(x, felso)
	size = custom_minimum_size
