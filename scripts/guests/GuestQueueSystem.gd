extends Node
class_name GuestQueueSystem

@export var counter_point_path: NodePath = ^"../TavernNav/QueuePoints/CounterPoint"
@export var queue_slots_root_path: NodePath = ^"../TavernNav/QueuePoints/QueueSlots"
@export var guest_spawner_path: NodePath = ^"../GuestSpawner"
@export var alap_kiszolgalasi_ido: float = 4.0
@export var min_kiszolgalasi_ido: float = 1.2
@export var debug_log: bool = false

var _counter_point: Node3D
var _queue_slots_root: Node3D
var _queue_slots: Array[Node3D] = []
var _queue: Array = []
var _guest_spawner: Node
var _queue_dirty: bool = false

func _ready() -> void:
	_cache_nodes()
	_build_queue_slots()
	set_process(true)

func register_guest(guest: Node, seat: Node3D) -> void:
	if guest == null:
		return
	if guest.has_method("set_seat_target"):
		guest.call("set_seat_target", seat)
	if guest.has_method("start_queueing"):
		guest.call("start_queueing")
	_queue.append(guest)
	_queue_dirty = true
	_frissit_queue_poziciok()
	_log("Vendég sorba állt: %s" % guest.name)

func _process(_delta: float) -> void:
	_takarit_queue()
	if _queue.is_empty():
		return
	if _queue_dirty:
		_frissit_queue_poziciok()

	var elso = _queue[0]
	if not is_instance_valid(elso):
		return

	if elso.has_method("is_serving") and elso.call("is_serving"):
		return

	if not _van_kiszolgalo():
		return

	if elso.has_method("is_queue_position_reached") and not elso.call("is_queue_position_reached"):
		return

	if _rendeles_nem_elerheto(elso):
		return

	var ido = _kiszolgalasi_ido()
	if elso.has_method("start_serving"):
		elso.call("start_serving", ido)

func _cache_nodes() -> void:
	_counter_point = get_node_or_null(counter_point_path) as Node3D
	_queue_slots_root = get_node_or_null(queue_slots_root_path) as Node3D
	_guest_spawner = get_node_or_null(guest_spawner_path)

func _build_queue_slots() -> void:
	_queue_slots.clear()
	if _queue_slots_root == null:
		return
	for child in _queue_slots_root.get_children():
		if child is Node3D:
			_queue_slots.append(child)

func _frissit_queue_poziciok() -> void:
	_queue_dirty = false
	for i in range(_queue.size()):
		var vendeg = _queue[i]
		if not is_instance_valid(vendeg):
			continue
		var cel: Node3D = _cel_pont_indexhez(i)
		if cel == null:
			continue
		if vendeg.has_method("set_queue_target"):
			var is_counter = i == 0
			vendeg.call("set_queue_target", cel, is_counter)

func _cel_pont_indexhez(index: int) -> Node3D:
	if index == 0:
		if _counter_point != null:
			return _counter_point
		if not _queue_slots.is_empty():
			return _queue_slots[0]
		return null
	var slot_index = index - 1
	if _queue_slots.is_empty():
		return _counter_point
	if slot_index < _queue_slots.size():
		return _queue_slots[slot_index]
	return _queue_slots[-1]

func _takarit_queue() -> void:
	var torlendo: Array = []
	for vendeg in _queue:
		if not is_instance_valid(vendeg):
			torlendo.append(vendeg)
			continue
		if vendeg.has_method("is_served") and vendeg.call("is_served"):
			torlendo.append(vendeg)
			continue
		if vendeg.has_method("get_state"):
			var allapot = int(vendeg.call("get_state"))
			if allapot == 3:
				torlendo.append(vendeg)
	for vendeg in torlendo:
		_queue.erase(vendeg)
		_queue_dirty = true
	if _queue_dirty:
		_frissit_queue_poziciok()

func _van_kiszolgalo() -> bool:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return true
	if EmployeeSystem1.has_method("is_any_staff_active"):
		return bool(EmployeeSystem1.call("is_any_staff_active"))
	return true

func _kiszolgalasi_ido() -> float:
	var mod = _alkalmazott_speed_mod()
	return max(min_kiszolgalasi_ido, alap_kiszolgalasi_ido + mod)

func _alkalmazott_speed_mod() -> float:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return 0.0
	if not EmployeeSystem1.has_method("get_hired"):
		return 0.0
	var hired_any = EmployeeSystem1.call("get_hired")
	var hired: Array = hired_any if hired_any is Array else []
	if hired.is_empty():
		return 0.0
	var best_speed = 0
	for emp_any in hired:
		var emp = emp_any if emp_any is Dictionary else {}
		best_speed = max(best_speed, int(emp.get("speed", 0)))
	var mod = 1.5 - float(best_speed) * 0.2
	return clamp(mod, -1.5, 2.0)

func _rendeles_nem_elerheto(vendeg: Variant) -> bool:
	if not (vendeg is Node):
		return false
	if not vendeg.has_variable("order"):
		return false
	var order_id = _rendeles_azonosito(vendeg.order)
	if order_id == "":
		return false
	if typeof(GuestServingSystem1) == TYPE_NIL or GuestServingSystem1 == null:
		return false
	if not GuestServingSystem1.has_method("get_available_servings"):
		return false
	var elerheto = int(GuestServingSystem1.call("get_available_servings", order_id))
	if elerheto > 0:
		return false
	if vendeg.has_method("can_try_alternative") and vendeg.call("can_try_alternative"):
		var uj_rend = _ker_alternativ_rendelest()
		var uj_id = _rendeles_azonosito(uj_rend)
		if uj_id != "" and uj_id != order_id:
			if vendeg.has_method("set_order"):
				vendeg.call("set_order", uj_rend)
			if vendeg.has_method("mark_alternative_tried"):
				vendeg.call("mark_alternative_tried")
			_log("Alternatív rendelés: %s → %s" % [order_id, uj_id])
			return true
	if typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		if RecipeTuningSystem1.has_method("register_no_service"):
			RecipeTuningSystem1.call("register_no_service", order_id)
	if vendeg.has_method("leave_no_service"):
		vendeg.call("leave_no_service", "Nincs alapanyag a rendeléshez")
	return true

func _ker_alternativ_rendelest() -> Dictionary:
	if _guest_spawner == null:
		return {}
	if _guest_spawner.has_method("request_alternative_order"):
		var rend_any = _guest_spawner.call("request_alternative_order")
		return rend_any if rend_any is Dictionary else {}
	return {}

func _rendeles_azonosito(rendeles_any: Variant) -> String:
	var azonosito = ""
	if typeof(rendeles_any) == TYPE_DICTIONARY:
		var adat: Dictionary = rendeles_any
		azonosito = String(adat.get("id", adat.get("item", ""))).strip_edges()
	elif typeof(rendeles_any) == TYPE_STRING:
		azonosito = String(rendeles_any).strip_edges()
	return _normalizal_id(azonosito)

func _normalizal_id(raw: String) -> String:
	var tisztitott = raw.strip_edges()
	if tisztitott == "":
		return ""
	var lower = tisztitott.to_lower()
	if lower == "sör" or lower == "sor":
		return "beer"
	if lower == "gulyás":
		return "gulyas"
	return lower

func _log(szoveg: String) -> void:
	if not debug_log:
		return
	print_debug("[SOR] %s" % szoveg)
