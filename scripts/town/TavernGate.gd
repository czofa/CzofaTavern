extends Area3D
class_name TavernGate

@export var travel_manager_path: NodePath = ^"../../../CoreRoot/TravelTransitionManager"
@export var cel_vilag_path: NodePath = ^"../../TavernWorld"
@export var spawn_jelolo: String = "Spawns/TavernEntryFromTown"
@export var ido_koltseg_perc: int = 60

func interact() -> void:
	var manager = _travel_manager()
	if manager == null:
		_toast("❌ Az utazás vezérlő nem érhető el.")
		return
	if manager.has_method("travel_to"):
		manager.call("travel_to", str(cel_vilag_path), spawn_jelolo, ido_koltseg_perc)
	else:
		_toast("❌ Az utazás vezérlő hibás.")

func _travel_manager() -> Node:
	if travel_manager_path != NodePath("") and has_node(travel_manager_path):
		return get_node(travel_manager_path)
	if travel_manager_path != NodePath("") and get_tree() != null and get_tree().root != null:
		var root = get_tree().root
		if root.has_node(travel_manager_path):
			return root.get_node(travel_manager_path)
	return get_tree().root.find_child("TravelTransitionManager", true, false)

func _toast(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
