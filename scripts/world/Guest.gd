extends CharacterBody3D
class_name Guest

@export var navigation_agent_path: NodePath = ^"NavigationAgent3D"
@export var sebesseg: float = 2.5
@export var cel_tavolsag: float = 0.35
@export var fogyasztasi_ido: float = 5.0
@export var fizetes_kesleltetes: float = 1.2

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

func _ready() -> void:
	_nav = get_node_or_null(navigation_agent_path) as NavigationAgent3D
	_seat_manager = get_tree().root.get_node_or_null("SeatManager1")
	_connect_nav()
	set_physics_process(true)
	set_process(true)

func _physics_process(_delta: float) -> void:
	if _nav == null:
		reached_seat = true
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
	_cel_pont = target
	reached_seat = false
	if _nav != null and target != null:
		_nav.target_position = target.global_position

func set_order(new_order: Variant) -> void:
	if typeof(new_order) == TYPE_DICTIONARY:
		var adat: Dictionary = new_order
		var tisztitott: Dictionary = {
			"id": str(adat.get("id", adat.get("item", ""))).strip_edges(),
			"tipus": str(adat.get("tipus", adat.get("type", ""))).strip_edges(),
			"ar": int(adat.get("ar", adat.get("price", 0)))
		}
		order = tisztitott
		return

	if typeof(new_order) == TYPE_STRING:
		var o = str(new_order).strip_edges()
		if o != "":
			order = {
				"id": o,
				"tipus": "",
				"ar": 0
			}

func is_served() -> bool:
	return _kiszolgalva

func has_consumed() -> bool:
	return _kiszolgalva

func mark_as_consumed() -> void:
	if _kiszolgalva:
		return
	_kiszolgalva = true
	_fogyasztasi_idozito = 0.0
	print("[GUEST_SERVE] Vendég megkapta a rendelést: %s" % _rendeles_szoveg())
	_try_start_fogyasztas()

func _on_cel_elerve() -> void:
	reached_seat = true
	velocity = Vector3.ZERO
	print("[GUEST_SEAT] Vendég célhoz ért: %s" % name)
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

func _szek_felszabadit() -> void:
	if _seat_manager != null and _seat_manager.has_method("free_seat_by_guest"):
		_seat_manager.call("free_seat_by_guest", self)

func _try_start_fogyasztas() -> void:
	if not _kiszolgalva:
		return
	if not reached_seat:
		return
	if _elfogyasztva:
		return
	# Itt nincs azonnali akció, a _process ütemezetten számolja az időt.

func _befejez_fogyasztas() -> void:
	if _elfogyasztva:
		return
	_elfogyasztva = true
	_fizetesi_idozito = 0.0
	print("[GUEST_ORDER] Vendég elfogyasztotta: %s" % _rendeles_szoveg())

func _fizet_es_tavozik() -> void:
	if _fizetve:
		return
	_fizetve = true
	var osszeg = int(order.get("ar", 0))
	if osszeg <= 0:
		osszeg = 500
	var reason = "Vendég fogyasztás: %s" % _rendeles_szoveg()
	var econ = get_tree().root.get_node_or_null("EconomySystem1")
	if econ != null and econ.has_method("add_money"):
		econ.call("add_money", osszeg, reason)
		print("[GUEST_PAY] Fizetés rögzítve (%d Ft): %s" % [osszeg, _rendeles_szoveg()])
	else:
		push_warning("[GUEST_PAY] EconomySystem nem elérhető, fizetés kihagyva")
	leave()

func leave() -> void:
	print("[GUEST_LEAVE] Vendég távozik: %s" % name)
	_szek_felszabadit()
	queue_free()

func _rendeles_szoveg() -> String:
	if order.is_empty():
		return "ismeretlen rendelés"
	var id = str(order.get("id", "ismeretlen"))
	var tipus = str(order.get("tipus", ""))
	return "%s (%s)" % [id, tipus]
