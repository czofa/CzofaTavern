extends Node

# Autoload neve: GuestServingSystem1

@export var serve_interval: float = 4.0

var _timer = 0.0
var _kiszolgalva_egyszer: Dictionary = {}
var _serve_debug_jelolve: Dictionary = {}

func _ready() -> void:
	print("🟢 GuestServingSystem READY")
	set_process(true)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= serve_interval:
		_timer = 0.0
		serve_all_guests()

func serve_all_guests() -> void:
	var guest_spawner = get_node_or_null("/root/Main/WorldRoot/TavernWorld/GuestSpawner")
	if guest_spawner == null:
		guest_spawner = get_node_or_null("/root/Main/TavernWorld/GuestSpawner")
		if guest_spawner == null:
			push_error("[GUEST_SERVE] ❌ GuestSpawner nem található.")
			return

	if not guest_spawner.has_method("get_active_guests"):
		push_error("[GUEST_SERVE] ❌ GuestSpawner nem tartalmaz get_active_guests metódust.")
		return

	var guests: Array = guest_spawner.get_active_guests()
	_tisztit_inaktiv_szerv_flagok(guests)
	if guests.is_empty():
		return

	var kitchen = get_node_or_null("/root/KitchenSystem1")
	if kitchen == null:
		push_error("[GUEST_SERVE] ❌ KitchenSystem1 nem található.")
		return
	if not kitchen.has_method("consume_item"):
		push_error("[GUEST_SERVE] ❌ KitchenSystem1 nem támogatja a fogyasztást.")
		return

	for guest in guests:
		var vendeg: Variant = guest
		if not is_instance_valid(vendeg):
			continue

		if not vendeg.has_method("has_consumed") or not vendeg.has_method("mark_as_consumed"):
			continue

		if vendeg.has_consumed():
			continue

		if not vendeg.has_variable("reached_seat") or not vendeg.reached_seat:
			continue

		if not vendeg.has_variable("order"):
			continue

		var rendeles_any = vendeg.order
		var order_id = _rendeles_azonosito(rendeles_any)
		if order_id == "":
			continue
		var vendeg_id = vendeg.get_instance_id()
		if _kiszolgalva_egyszer.get(vendeg_id, false):
			continue

		var served: bool = false
		var portions_count: int = 0

		if order_id == "beer":
			portions_count = _beer_adagok_szama(kitchen, order_id)
			if portions_count > 0:
				served = _levon_beer_adag(kitchen, order_id, 1)
		else:
			served = kitchen.consume_item(order_id)

		if served:
			_kiszolgalva_egyszer[vendeg_id] = true
			_serve_debug_jelolve.erase(vendeg_id)
			print("[FLOW_SERVE] siker=true ok=adag_levonva vendeg=%s rendelés=%s" % [vendeg.name, order_id])
			_jelol_fogyasztas(vendeg, vendeg_id)
		else:
			_log_serve_debug(vendeg_id, rendeles_any, order_id, portions_count)

func _rendeles_azonosito(rendeles_any: Variant) -> String:
	var azonosito = ""
	if typeof(rendeles_any) == TYPE_DICTIONARY:
		var adat: Dictionary = rendeles_any
		azonosito = String(adat.get("id", adat.get("item", ""))).strip_edges()
		if azonosito == "":
			azonosito = String(adat.get("nev", "")).strip_edges()
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

func _beer_adagok_szama(kitchen: Variant, item_id: String) -> int:
	if kitchen == null:
		return 0
	if kitchen.has_method("get_total_portions"):
		return int(kitchen.call("get_total_portions", item_id))
	var portions_any = kitchen.get("_portions")
	if portions_any is Dictionary:
		var adat_any = portions_any.get(item_id, {})
		var adat = adat_any if adat_any is Dictionary else {}
		return int(adat.get("total", 0))
	return 0

func _levon_beer_adag(kitchen: Variant, item_id: String, adag: int) -> bool:
	if kitchen == null:
		return false
	if adag <= 0:
		return false
	if not kitchen.has_method("get_total_portions"):
		return false
	var jelenlegi = int(kitchen.call("get_total_portions", item_id))
	if jelenlegi < adag:
		return false
	var adag_meret = 0
	if kitchen.has_method("get_portion_size"):
		adag_meret = int(kitchen.call("get_portion_size", item_id))
	var uj_total = jelenlegi - adag
	if kitchen.has_method("set_portion_data"):
		kitchen.call("set_portion_data", item_id, adag_meret, uj_total)
		return true
	var portions_any = kitchen.get("_portions")
	if portions_any is Dictionary:
		var adat_any = portions_any.get(item_id, {})
		var adat = adat_any if adat_any is Dictionary else {}
		adat["total"] = uj_total
		if adag_meret > 0:
			adat["portion_size"] = adag_meret
		portions_any[item_id] = adat
		kitchen.set("_portions", portions_any)
		return true
	return false

func _jelol_fogyasztas(vendeg: Variant, vendeg_id: int) -> void:
	if vendeg.has_method("mark_as_consumed"):
		vendeg.mark_as_consumed()
	if vendeg.has_method("has_consumed") and vendeg.has_consumed():
		_kapcsol_tavozas_kovetes(vendeg, vendeg_id)
		return
	_indit_tavozas_timer(vendeg, vendeg_id)

func _indit_tavozas_timer(vendeg: Variant, vendeg_id: int) -> void:
	if not (vendeg is Node):
		return
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = randf_range(3.0, 8.0)
	add_child(timer)
	var cb = func() -> void:
		if is_instance_valid(vendeg) and vendeg.has_method("leave"):
			vendeg.leave()
		timer.queue_free()
		_on_guest_exited(vendeg_id)
	timer.timeout.connect(cb)
	timer.start()

func _tisztit_inaktiv_szerv_flagok(guests: Array) -> void:
	var aktiv: Dictionary = {}
	for g in guests:
		if is_instance_valid(g):
			var id = g.get_instance_id()
			aktiv[id] = true
	var torlendo_szolgalt: Array = []
	for kulcs in _kiszolgalva_egyszer.keys():
		if not aktiv.has(kulcs):
			torlendo_szolgalt.append(kulcs)
	for k in torlendo_szolgalt:
		_kiszolgalva_egyszer.erase(k)
	var torlendo_debug: Array = []
	for kulcs in _serve_debug_jelolve.keys():
		if not aktiv.has(kulcs):
			torlendo_debug.append(kulcs)
	for k in torlendo_debug:
		_serve_debug_jelolve.erase(k)

func _kapcsol_tavozas_kovetes(vendeg: Variant, vendeg_id: int) -> void:
	if not (vendeg is Node):
		return
	var cb = Callable(self, "_on_guest_exited").bind(vendeg_id)
	if not vendeg.tree_exited.is_connected(cb):
		vendeg.tree_exited.connect(cb)

func _on_guest_exited(vendeg_id: int) -> void:
	_kiszolgalva_egyszer.erase(vendeg_id)
	_serve_debug_jelolve.erase(vendeg_id)

func _log_serve_debug(vendeg_id: int, rendeles_any: Variant, order_id: String, portions_count: int) -> void:
	if _serve_debug_jelolve.has(vendeg_id):
		return
	_serve_debug_jelolve[vendeg_id] = true
	print("[SERVE_DBG] rendelés_raw=%s azonosító=%s adagok=%d" % [str(rendeles_any), order_id, portions_count])
