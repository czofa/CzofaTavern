extends CharacterBody3D
class_name Guest

enum GuestAllapot {
	QUEUEING,
	SERVING,
	SEATED_CONSUME,
	LEAVE_NO_SERVICE
}

@export var navigation_agent_path: NodePath = ^"NavigationAgent3D"
@export var sebesseg: float = 2.5
@export var cel_tavolsag: float = 0.35
@export var fogyasztasi_ido: float = 5.0
@export var fizetes_kesleltetes: float = 1.2
@export var turelem_max: float = 20.0
@export var debug_log: bool = false

var order: Dictionary = {}
var reached_seat: bool = false

var _nav: NavigationAgent3D
var _cel_pont: Node3D
var _seat_manager: Node
var _kiszolgalva: bool = false
var _elfogyasztva: bool = false
var _fogyasztasi_idozito: float = 0.0
var _fizetesi_idozito: float = 0.0
var _fizetve: bool = false
var _szek_felszabaditva: bool = false
var _allapot: GuestAllapot = GuestAllapot.QUEUEING
var _cel_tipus: String = ""
var _cel_elerve: bool = false
var _queue_pont_elerve: bool = false
var _szek_cel: Node3D
var _kiszolgalasi_ido: float = 0.0
var _kiszolgalasi_ido_max: float = 0.0
var _kiszolgalas_kesz: bool = false
var _turelem_ido: float = 0.0
var _morgas_szint1: bool = false
var _morgas_szint2: bool = false
var _alternativa_probalkozott: bool = false

func _ready() -> void:
	_nav = get_node_or_null(navigation_agent_path) as NavigationAgent3D
	_seat_manager = _get_seat_manager()
	_connect_nav()
	set_physics_process(true)
	set_process(true)
	_log("spawn: %s" % name)

func _physics_process(_delta: float) -> void:
	if _nav == null:
		reached_seat = true
		return

	if _cel_elerve:
		velocity = Vector3.ZERO
		return

	if _nav.is_navigation_finished():
		_on_cel_elerve()
		return

	var kov_pont: Vector3 = _nav.get_next_path_position()
	var irany = (kov_pont - global_position)
	irany.y = 0.0

	if irany.length() < 0.01:
		velocity = Vector3.ZERO
		return

	velocity = irany.normalized() * sebesseg
	move_and_slide()
	if reached_seat:
		_try_start_fogyasztas()

func _process(delta: float) -> void:
	_update_turelem(delta)
	if _allapot == GuestAllapot.SERVING and not _kiszolgalas_kesz:
		_kiszolgalasi_ido += delta
		if _kiszolgalasi_ido >= _kiszolgalasi_ido_max:
			_kiszolgalas_kesz = true
			_log("kiszolgálásra kész: %s" % _rendeles_szoveg())

	if _kiszolgalva and reached_seat and not _elfogyasztva:
		_fogyasztasi_idozito += delta
		if _fogyasztasi_idozito >= fogyasztasi_ido:
			_befejez_fogyasztas()
		return

	if _elfogyasztva and not _fizetve:
		_fizetesi_idozito += delta
		if _fizetesi_idozito >= fizetes_kesleltetes:
			_fizet_es_tavozik()

func set_target(target: Node3D) -> void:
	_set_target(target, "")

func set_queue_target(target: Node3D, is_counter: bool = false) -> void:
	_cel_pont = target
	_queue_pont_elerve = false
	_cel_tipus = "queue"
	_set_target(target, "queue")
	if is_counter:
		_log("pult pontra áll: %s" % name)

func set_seat_target(target: Node3D) -> void:
	_szek_cel = target

func start_queueing() -> void:
	_allapot = GuestAllapot.QUEUEING
	_turelem_ido = 0.0
	_morgas_szint1 = false
	_morgas_szint2 = false

func start_serving(serve_time: float) -> void:
	if _allapot != GuestAllapot.QUEUEING:
		return
	_allapot = GuestAllapot.SERVING
	_kiszolgalasi_ido_max = max(0.1, serve_time)
	_kiszolgalasi_ido = 0.0
	_kiszolgalas_kesz = false
	_log("kiszolgálás indul: %s (%.2fs)" % [_rendeles_szoveg(), _kiszolgalasi_ido_max])

func set_order(new_order: Variant) -> void:
	if typeof(new_order) == TYPE_DICTIONARY:
		var adat: Dictionary = new_order
		var tisztitott: Dictionary = {
			"id": str(adat.get("id", adat.get("item", ""))).strip_edges(),
			"tipus": str(adat.get("tipus", adat.get("type", ""))).strip_edges(),
			"ar": int(adat.get("ar", adat.get("price", 0)))
		}
		order = tisztitott

	if typeof(new_order) == TYPE_STRING:
		var o = str(new_order).strip_edges()
		if o != "":
			order = {
				"id": o,
				"tipus": "",
				"ar": 0
			}
	if not order.is_empty():
		_log("rendelés rögzítve: %s → %s" % [name, _rendeles_szoveg()])

func is_served() -> bool:
	return _kiszolgalva

func has_consumed() -> bool:
	return _kiszolgalva

func mark_as_consumed() -> void:
	if _kiszolgalva:
		return
	_kiszolgalva = true
	_fogyasztasi_idozito = 0.0
	_allapot = GuestAllapot.SEATED_CONSUME
	_kiszolgalas_kesz = false
	_turelem_ido = 0.0
	if _szek_cel != null:
		_set_target(_szek_cel, "seat")
	_log("felszolgálva: %s → %s" % [name, _rendeles_szoveg()])
	_try_start_fogyasztas()

func _on_cel_elerve() -> void:
	if _cel_elerve:
		return
	_cel_elerve = true
	velocity = Vector3.ZERO
	if _cel_tipus == "queue":
		_queue_pont_elerve = true
		_log("sor pozíció elérve: %s" % name)
		return
	reached_seat = true
	var szek_nev = "ismeretlen_szek"
	if _cel_pont != null:
		szek_nev = str(_cel_pont.name)
	_log("leült: %s (szék=%s)" % [name, szek_nev])
	_try_start_fogyasztas()

func _connect_nav() -> void:
	if _nav == null:
		return
	_nav.path_desired_distance = cel_tavolsag
	_nav.target_desired_distance = cel_tavolsag
	var cb = Callable(self, "_on_cel_elerve")
	if not _nav.target_reached.is_connected(cb):
		_nav.target_reached.connect(cb)

func _exit_tree() -> void:
	_szek_felszabadit()

func _szek_felszabadit() -> bool:
	if _szek_felszabaditva:
		return true
	var seat_mgr = _get_seat_manager()
	if seat_mgr != null and seat_mgr.has_method("free_seat_by_guest"):
		seat_mgr.call("free_seat_by_guest", self)
		_szek_felszabaditva = true
	return _szek_felszabaditva

func _get_seat_manager() -> Node:
	if _seat_manager == null:
		_seat_manager = get_tree().root.get_node_or_null("SeatManager1")
	return _seat_manager

func _try_start_fogyasztas() -> void:
	if not _kiszolgalva:
		return
	if not reached_seat:
		return
	if _elfogyasztva:
		return
	if _allapot != GuestAllapot.SEATED_CONSUME:
		return
	# Itt nincs azonnali akció, a _process ütemezetten számolja az időt.

func _befejez_fogyasztas() -> void:
	if _elfogyasztva:
		return
	_elfogyasztva = true
	_fizetesi_idozito = 0.0
	_log("elfogyasztva: %s → %s" % [name, _rendeles_szoveg()])

func _fizet_es_tavozik() -> void:
	if _fizetve:
		return
	_fizetve = true
	var osszeg = int(order.get("ar", 0))
	if osszeg <= 0:
		var tuning = RecipeTuningSystem1 if typeof(RecipeTuningSystem1) != TYPE_NIL else null
		if tuning != null and tuning.has_method("get_effective_price"):
			osszeg = int(tuning.call("get_effective_price", str(order.get("id", "")).strip_edges()))
	if osszeg <= 0:
		osszeg = 500
	var reason = "Vendég fogyasztás: %s" % _rendeles_szoveg()
	var econ = get_tree().root.get_node_or_null("EconomySystem1")
	if econ != null and econ.has_method("add_revenue"):
		var tetel_azon = str(order.get("id", "vendeg_fogyasztas"))
		econ.call("add_revenue", osszeg, reason, tetel_azon)
	elif econ != null and econ.has_method("add_money"):
		econ.call("add_money", osszeg, reason)
		_log("fizetve: %s (%d Ft)" % [name, osszeg])
	else:
		push_warning("[GUEST_PAY] EconomySystem nem elérhető, fizetés kihagyva")
	leave()

func leave() -> void:
	var felszabaditva = _szek_felszabadit()
	_log("távozás: %s (szék_felszabadítva=%s)" % [name, str(felszabaditva)])
	queue_free()

func _rendeles_szoveg() -> String:
	if order.is_empty():
		return "ismeretlen rendelés"
	var id = str(order.get("id", "ismeretlen"))
	var tipus = str(order.get("tipus", ""))
	return "%s (%s)" % [id, tipus]

func has_variable(var_name: StringName) -> bool:
	var target = String(var_name)
	for p in get_property_list():
		if p.has("name") and String(p["name"]) == target:
			return true
	return false

func is_queue_position_reached() -> bool:
	return _queue_pont_elerve

func is_ready_for_service() -> bool:
	return _allapot == GuestAllapot.SERVING and _kiszolgalas_kesz

func is_serving() -> bool:
	return _allapot == GuestAllapot.SERVING

func get_state() -> int:
	return int(_allapot)

func can_try_alternative() -> bool:
	return not _alternativa_probalkozott

func mark_alternative_tried() -> void:
	_alternativa_probalkozott = true

func leave_no_service(ok: String) -> void:
	if _allapot == GuestAllapot.LEAVE_NO_SERVICE:
		return
	_allapot = GuestAllapot.LEAVE_NO_SERVICE
	_panasz_es_tavozas(ok)
	leave()

func _set_target(target: Node3D, tipus: String) -> void:
	_cel_pont = target
	_cel_tipus = tipus
	_cel_elerve = false
	reached_seat = false
	if _nav != null and target != null:
		_nav.target_position = target.global_position

func _update_turelem(delta: float) -> void:
	if _allapot != GuestAllapot.QUEUEING and _allapot != GuestAllapot.SERVING:
		return
	if _kiszolgalva:
		return
	if turelem_max <= 0.0:
		return
	_turelem_ido += delta
	var arany = _turelem_ido / turelem_max
	if arany >= 0.5 and not _morgas_szint1:
		_morgas_szint1 = true
		_panasz_uzenet("Vendég morog a sorban.")
	if arany >= 0.8 and not _morgas_szint2:
		_morgas_szint2 = true
		_panasz_uzenet("Vendég türelmetlen, pletyka terjedhet.")
	if _turelem_ido >= turelem_max:
		leave_no_service("Elfogyott a türelem.")

func _panasz_uzenet(szoveg: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)
	_log(szoveg)

func _panasz_es_tavozas(ok: String) -> void:
	_panasz_uzenet("Vendég távozott kiszolgálás nélkül: %s" % ok)

func _log(szoveg: String) -> void:
	if not debug_log:
		return
	print_debug("[GUEST] %s" % szoveg)
