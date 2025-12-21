extends Node3D
class_name FarmPlotInstance

@export var plot_id: String = ""

var _regisztralt: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_regisztralj()
	add_to_group("farm_plot")

func interact() -> void:
	if FarmSystem1 == null:
		_ertesit("❌ Farm rendszer nem elérhető.")
		return
	if plot_id == "":
		_regisztralj()
	if plot_id == "":
		_ertesit("❌ Plot azonosító hiányzik.")
		return
	FarmSystem1.handle_plot_action(plot_id)

func _regisztralj() -> void:
	if _regisztralt:
		return
	if FarmSystem1 == null:
		return
	if plot_id == "":
		plot_id = FarmSystem1.register_plot(global_position)
	if plot_id != "":
		_regisztralt = true

func _ertesit(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
