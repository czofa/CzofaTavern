extends Node3D
class_name FarmUpgradeNPC

@export var land_controller_path: NodePath = ^"../FarmLandController"
@export var farm_world_controller_path: NodePath = ^"../FarmWorldController"

func interact() -> void:
	var land = get_node_or_null(land_controller_path)
	if land == null:
		_toast("❌ Területkezelő hiányzik.")
		return
	if not land.has_method("van_farm") or not land.has_method("fejlesztheto"):
		_toast("❌ A farm bővítési logika hiányzik.")
		return
	if not land.call("van_farm"):
		_toast("ℹ️ Előbb vásárold meg a farm területet a faluban.")
		return
	if not land.call("fejlesztheto"):
		_toast("✅ A farm teljesen ki van bővítve.")
		return
	if land.call("probal_fejleszteni", "Farm terület bővítés"):
		var ctrl = get_node_or_null(farm_world_controller_path)
		if ctrl != null and ctrl.has_method("refresh_after_upgrade"):
			ctrl.call("refresh_after_upgrade")

func _toast(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
