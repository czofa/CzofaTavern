extends Node3D
class_name FarmGate

@export var land_controller_path: NodePath = ^"/root/Main/WorldRoot/FarmWorld/FarmLandController"
@export var farm_world_controller_path: NodePath = ^"/root/Main/WorldRoot/FarmWorld"

var _land: Node = null
var _farm_ctrl: Node = null
var _warned_land: bool = false
var _warned_ctrl: bool = false

func _ready() -> void:
	_cache_nodes()

func interact() -> void:
	_cache_nodes()
	if not _has_farm():
		_toast("Kérlek keresd fel a területmenedzsert.")
		return
	_leptet_farmba()

func _cache_nodes() -> void:
	if land_controller_path != NodePath(""):
		var land = get_node_or_null(land_controller_path)
		if land != null:
			_land = land
		elif not _warned_land:
			printerr("❌ FarmGate: hiányzik a FarmLandController: %s" % land_controller_path)
			_warned_land = true

	if farm_world_controller_path != NodePath(""):
		var ctrl = get_node_or_null(farm_world_controller_path)
		if ctrl != null:
			_farm_ctrl = ctrl
		elif not _warned_ctrl:
			printerr("❌ FarmGate: hiányzik a FarmWorldController: %s" % farm_world_controller_path)
			_warned_ctrl = true

func _has_farm() -> bool:
	if _land != null and _land.has_method("van_farm"):
		return bool(_land.call("van_farm"))
	var gs = _gs()
	if gs != null and gs.has_method("get_value"):
		var szint = int(gs.call("get_value", "farm_land_level", -1))
		return szint >= 0
	return false

func _leptet_farmba() -> void:
	if _farm_ctrl == null or not _farm_ctrl.has_method("enter_from_town"):
		if not _warned_ctrl:
			printerr("❌ FarmGate: hiányzik az átjáró vezérlő: %s" % farm_world_controller_path)
			_warned_ctrl = true
		_toast("❌ A farm átjáró nem érhető el.")
		return
	_farm_ctrl.call("enter_from_town")

func _gs() -> Node:
	return get_tree().root.get_node_or_null("GameState1")

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")

func _toast(szoveg: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)
