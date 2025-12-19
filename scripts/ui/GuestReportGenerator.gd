extends Node
class_name GuestReportGenerator
# Autoload: GuestReportGenerator1

@export var debug_toast: bool = true

var guests_today: Array[String] = []
var total_guests: int = 0
var total_income: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	if debug_toast:
		_toast("GuestReportGenerator READY")

func reset() -> void:
	guests_today.clear()
	total_guests = 0
	total_income = 0

func record_guest(name: String, income: int) -> void:
	guests_today.append(name)
	total_guests += 1
	total_income += income
	if debug_toast:
		_toast("Guest %s added (+%dG)" % [name, income])

func generate_report() -> String:
	var report := "Vendégek száma: %d\nBevétel: %dG\n" % [total_guests, total_income]
	report += "Vendégek: %s" % (", ".join(guests_today))
	return report

# --- Bus ---
func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb := _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb := Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match topic:
		"guest.record":
			record_guest(str(payload.get("name", "")), int(payload.get("income", 0)))
		"guest.reset":
			reset()
		_:
			pass

func _toast(t: String) -> void:
	var eb := _eb()
	if eb and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", t)
