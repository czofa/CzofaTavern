extends Node

# Autoload neve: GuestServingSystem1

@export var serve_interval: float = 4.0

var _timer = 0.0

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

		var served: bool = false
		var portions_count: int = 0

		if order_id == "beer":
			portions_count = _beer_adagok_szama(kitchen, order_id)
			if portions_count > 0:
				served = _levon_beer_adag(kitchen, order_id, 1)
		else:
			served = kitchen.consume_item(order_id)

		if served:
			vendeg.mark_as_consumed()
		else:
			print("[SERVE_DBG] order_raw=%s order_id=%s portions=%d" % [str(rendeles_any), order_id, portions_count])

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
	if kitchen.has("_portions"):
		var adat_any = kitchen._portions.get(item_id, {})
		var adat = adat_any if adat_any is Dictionary else {}
		return int(adat.get("total", 0))
	return 0

func _levon_beer_adag(kitchen: Variant, item_id: String, adag: int) -> bool:
	if kitchen == null:
		return false
	if adag <= 0:
		return false
	var jelenlegi = _beer_adagok_szama(kitchen, item_id)
	if jelenlegi < adag:
		return false
	if kitchen.has("_portions"):
		var adat_any = kitchen._portions.get(item_id, {})
		var adat = adat_any if adat_any is Dictionary else {}
		adat["total"] = jelenlegi - adag
		kitchen._portions[item_id] = adat
		return true
	return false
