extends Node
class_name HolidayEvents
# Autoload: HolidayEvents1 -> res://scripts/systems/calendar/HolidayEvents.gd

var holidays = [
	{
		"id": "christmas",
		"day_in_year": 120,
		"name": "Karácsony",
		"effects": {
			"money": 2000,
			"guest_mult": 1.15
		},
		"note": "Ünnepi forgalom"
	}
]

func _ready() -> void:
	_connect_bus()

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.new_day":
			_kezel_napvaltas(int(payload.get("day", 1)))
		_:
			pass

func _kezel_napvaltas(nap_index: int) -> void:
	var nap = max(1, int(nap_index))
	var nap_evben = _nap_evben_ertek(nap)
	var talalat = _keres_unnep(nap_evben)
	if talalat.is_empty():
		return
	_triggel_unnep(talalat, nap, nap_evben)

func _nap_evben_ertek(nap_index: int) -> int:
	return ((max(1, nap_index) - 1) % 120) + 1

func _keres_unnep(nap_evben: int) -> Dictionary:
	for adat_any in holidays:
		var adat = adat_any if adat_any is Dictionary else {}
		if int(adat.get("day_in_year", -1)) == nap_evben:
			return adat
	return {}

func _triggel_unnep(adat: Dictionary, nap_index: int, nap_evben: int) -> void:
	var nev = str(adat.get("name", adat.get("id", "Ünnep")))
	var megjegyzes = str(adat.get("note", ""))
	var effects_any = adat.get("effects", {})
	var effects = effects_any if effects_any is Dictionary else {}
	var plusz_penz = int(effects.get("money", 0))
	var vendeg_mult = float(effects.get("guest_mult", 1.0))
	if plusz_penz != 0:
		_add_money(plusz_penz, "%s bónusz" % nev)
	if vendeg_mult != 1.0:
		_erosit_vendeg_szorzot(vendeg_mult)
	var buff_szoveg = _buff_szoveg(plusz_penz, vendeg_mult)
	var szoveg = "🎉 %s! %s (Év napja: %d, Globális nap: %d)" % [nev, buff_szoveg, nap_evben, nap_index]
	if megjegyzes != "":
		szoveg += " – %s" % megjegyzes
	_notifikal(szoveg)

func _buff_szoveg(penz: int, vendeg_mult: float) -> String:
	var reszletek = []
	if penz > 0:
		reszletek.append("+%d Ft" % penz)
	if vendeg_mult > 1.0:
		reszletek.append("vendégszorzó x%.2f" % vendeg_mult)
	if reszletek.is_empty():
		return "Különleges esemény"
	return ", ".join(reszletek)

func _add_money(osszeg: int, reason: String) -> void:
	var econ = get_tree().root.get_node_or_null("EconomySystem1")
	if econ != null and econ.has_method("add_money"):
		econ.call("add_money", osszeg, reason)

func _erosit_vendeg_szorzot(multiplier: float) -> void:
	var season_node = get_tree().root.get_node_or_null("SeasonSystem1")
	if season_node != null and season_node.has_method("add_guest_bonus_for_today"):
		season_node.call("add_guest_bonus_for_today", multiplier)

func _notifikal(szoveg: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")
