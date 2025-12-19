# res://scripts/town/VillageManagerNPC.gd
extends Node3D
class_name VillageManagerNPC

@export var trigger_area_path: NodePath = ^"Area3D"

var _area: Area3D = null

func _ready() -> void:
	_cache_area()
	_try_connect_area_signals()

func interact() -> void:
	_toast("Falumenedzser: területfejlesztések hamarosan")

func _cache_area() -> void:
	_area = null
	if trigger_area_path == NodePath("") or str(trigger_area_path) == "":
		return
	var n := get_node_or_null(trigger_area_path)
	if n is Area3D:
		_area = n as Area3D

func _try_connect_area_signals() -> void:
	if _area == null:
		return
	var enter_cb := Callable(self, "_on_area_body_entered")
	var exit_cb := Callable(self, "_on_area_body_exited")
	if _area.has_signal("body_entered") and not _area.is_connected("body_entered", enter_cb):
		_area.connect("body_entered", enter_cb)
	if _area.has_signal("body_exited") and not _area.is_connected("body_exited", exit_cb):
		_area.connect("body_exited", exit_cb)

func _on_area_body_entered(_body: Node) -> void:
	pass

func _on_area_body_exited(_body: Node) -> void:
	pass

func _eb() -> Node:
	var root := get_tree().root
	var eb1 := root.get_node_or_null("EventBus1")
	if eb1 != null:
		return eb1
	return root.get_node_or_null("EventBus")

func _toast(text: String) -> void:
	var eb := _eb()
	if eb == null:
		return

	# 1) klasszikus toast
	if eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
		return

	# 2) fallback: bus toast
	if eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text": text})
