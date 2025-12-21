extends Node
class_name FarmLandController

@export var nav_regio_utvonalak: Array[NodePath] = []
@export var build_controller_path: NodePath = ^"../BuildController"
@export var arak: Array = [2000, 5000, 9000, 15000, 25000, 25000]

const ALLAPOT_KULCS := "farm_land_level"
const MAX_SZINT: int = 5

var _nav_regiok: Array = []
var _szint: int = -1
var _build_controller: Node = null

func _ready() -> void:
	_cache_nav_regiok()
	_build_controller = get_node_or_null(build_controller_path)
	_szint = _betoltott_szint()
	_alkalmaz_szint()

func get_szint() -> int:
	return _szint

func van_farm() -> bool:
	return _szint >= 0

func fejlesztheto() -> bool:
	return _szint < MAX_SZINT

func kovetkezo_ar() -> int:
	if not fejlesztheto():
		return 0
	var idx = clamp(_szint + 1, 0, arak.size() - 1)
	return int(arak[idx])

func probal_fejleszteni(reason: String = "Farm bővítés") -> bool:
	if not fejlesztheto():
		_toast("ℹ️ A farm terület már maximális.")
		return false

	var ar: int = kovetkezo_ar()
	if ar > 0 and not _van_penz(ar):
		_toast("❌ Nincs elég pénz: %d Ft szükséges." % ar)
		return false

	if ar > 0:
		_kolt(ar, reason)
	_szint += 1
	_ment_szint()
	_alkalmaz_szint()
	_toast("✅ Farm szint frissítve: %d" % (_szint + 1))
	return true

func _cache_nav_regiok() -> void:
	_nav_regiok.clear()
	for path in nav_regio_utvonalak:
		if path == null or path == NodePath(""):
			continue
		var n = get_node_or_null(path)
		if n is NavigationRegion3D:
			_nav_regiok.append(n)

func _alkalmaz_szint() -> void:
	for i in range(_nav_regiok.size()):
		var regi = _nav_regiok[i] as NavigationRegion3D
		if regi == null:
			continue
		var engedelyezett = _szint >= 0 and i <= _szint
		regi.enabled = engedelyezett
		regi.visible = engedelyezett
	if _build_controller != null and _build_controller.has_method("set_build_enabled"):
		_build_controller.call("set_build_enabled", _szint >= 0)

func _betoltott_szint() -> int:
	var gs = _gs()
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", ALLAPOT_KULCS, -1))
	return -1

func _ment_szint() -> void:
	var gs = _gs()
	if gs != null and gs.has_method("set_value"):
		gs.call("set_value", ALLAPOT_KULCS, _szint, "Farm terület frissítés")

func _gs() -> Node:
	return get_tree().root.get_node_or_null("GameState1")

func _van_penz(osszeg: int) -> bool:
	var penz: int = 0
	if EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		penz = EconomySystem1.get_money()
	elif _gs() != null and _gs().has_method("get_value"):
		penz = int(_gs().call("get_value", "money", 0))
	return penz >= osszeg

func _kolt(osszeg: int, reason: String) -> void:
	var ar = int(osszeg)
	if EconomySystem1 != null:
		EconomySystem1.add_money(-ar, reason)
		return
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "state.add", {
			"key": "money",
			"delta": -ar,
			"reason": reason
		})

func _toast(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
