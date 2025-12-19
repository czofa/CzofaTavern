extends Node3D

@export var run_controller_path: NodePath = ^"../../../../MineWorld/MineRunController"

func interact() -> void:
	var rc = _get_run_controller()
	if rc == null:
		_toast("❌ Bánya bejárat: hiányzik a vezérlő")
		return

	if rc.has_method("start_run"):
		rc.call("start_run")
	else:
		_toast("❌ Bánya bejárat: a vezérlő nem indítható")

func _get_run_controller() -> Node:
	if run_controller_path == NodePath("") or str(run_controller_path) == "":
		return null
	return get_node_or_null(run_controller_path)

func _toast(text: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(text))

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")
