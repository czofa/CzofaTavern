extends Node3D
class_name FarmExitArea

@export var farm_world_controller_path: NodePath = ^"../FarmWorldController"

func interact() -> void:
	var ctrl = get_node_or_null(farm_world_controller_path)
	if ctrl == null or not ctrl.has_method("return_to_town"):
		_toast("❌ Visszatérési vezérlő hiányzik.")
		return
	ctrl.call("return_to_town")

func _toast(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
