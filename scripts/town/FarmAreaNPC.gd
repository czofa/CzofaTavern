extends Node3D
class_name FarmAreaNPC

@export var farm_world_controller_path: NodePath = ^"../../WorldRoot/FarmWorld"
@export var land_controller_path: NodePath = ^"../../WorldRoot/FarmWorld/FarmLandController"

func interact() -> void:
	var land = get_node_or_null(land_controller_path)
	if land == null:
		_toast("❌ Hiányzik a farm területkezelő.")
		return

	if not land.has_method("van_farm") or not land.has_method("probal_fejleszteni"):
		_toast("❌ A farm terület vezérlése hiányos.")
		return

	if not land.call("van_farm"):
		var ar: int = 0
		if land.has_method("kovetkezo_ar"):
			ar = int(land.call("kovetkezo_ar"))
		_toast("ℹ️ Farm terület ára: %d Ft" % ar)
		if not land.call("probal_fejleszteni", "Farm terület megvásárlása"):
			return

	var ctrl = get_node_or_null(farm_world_controller_path)
	if ctrl == null or not ctrl.has_method("enter_from_town"):
		_toast("❌ Hiányzik a farm átjáró vezérlő.")
		return
	ctrl.call("enter_from_town")

func _toast(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
