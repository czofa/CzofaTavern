extends Node
class_name StockSystem
# Autoload neve: StockSystem1

@export var debug_toast: bool = true

# =========================================================
# KÉSZLETEK
# =========================================================

# Könyvelt, felhasználható készlet (gramm/nyersanyag)
var stock: Dictionary = {}
# Példa: { "potato": 120 }

# Könyveletlen készlet + ár (gramm/nyersanyag)
# { item_id : { "qty": int, "unit_price": int, "total_cost": int } }
var stock_unbooked: Dictionary = {}

# Egység alapú belső tárolók (MVP)
var unbooked_g: Dictionary = stock_unbooked
var unbooked_ml: Dictionary = {}
var unbooked_pcs: Dictionary = {}
var booked_ml: Dictionary = {}
var booked_pcs: Dictionary = {}

const LIQUID_ML_IDS = ["sor", "bor", "palinka", "beer"]
var _unit_log_cache: Dictionary = {}
var _cached_kitchen_ingredient_ids: Dictionary = {}

# Napló
var _journal: Array = []

# =========================================================
# READY
# =========================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	if debug_toast:
		_toast("📦 StockSystem READY")

# =========================================================
# KÖNYVELETLEN KÉSZLET (VÁSÁRLÁS)
# =========================================================

func add_unbooked(item_id: String, qty: int, unit_or_price = "", unit_price: int = -1) -> void:
	var id: String = item_id.strip_edges()
	if id == "" or qty <= 0:
		return
	var unit: String = ""
	var ar: int = 0
	if unit_or_price is String:
		unit = str(unit_or_price)
		ar = max(unit_price, 0)
	else:
		ar = int(unit_or_price)
	if ar < 0:
		return
	if unit == "":
		unit = get_item_unit(id)
	var target = _unbooked_dict_for_unit(unit)

	var existing: Dictionary = target.get(id, {
		"qty": 0,
		"unit_price": ar,
		"total_cost": 0
	})

	var current_qty: int = int(existing.get("qty", 0))
	existing["qty"] = current_qty + qty
	existing["unit_price"] = ar
	existing["total_cost"] = int(existing["qty"]) * ar

	target[id] = existing
	if unit == "g":
		stock_unbooked[id] = existing

	_log_journal("UNBOOKED_BUY", id, qty, ar, qty * ar)
	print("[STOCK_ADD] id=%s qty=%d unit=%s" % [id, qty, unit])

	if debug_toast:
		var unit_cimke = _unit_cimke(unit)
		_toast("🛒 Vásárlás: %s +%d %s @ %d Ft/%s (össz: %d Ft)"
			% [id, qty, unit_cimke, ar, unit_cimke, qty * ar])

# A könyvelési panel EZT használja
func get_unbooked_items() -> Array:
	var result: Array = []
	_hozzaad_unbooked_lista(result, unbooked_g, "g")
	_hozzaad_unbooked_lista(result, unbooked_ml, "ml")
	_hozzaad_unbooked_lista(result, unbooked_pcs, "pcs")
	return result

func get_unbooked_qty(item_id: String) -> int:
	var id = item_id.strip_edges()
	var unit = get_item_unit(id)
	var target = _unbooked_dict_for_unit(unit)
	if not target.has(id):
		return 0
	return int(target[id].get("qty", 0))

func get_unbooked_total_cost(item_id: String) -> int:
	var id = item_id.strip_edges()
	var unit = get_item_unit(id)
	var target = _unbooked_dict_for_unit(unit)
	if not target.has(id):
		return 0
	return int(target[id].get("total_cost", 0))

func remove_unbooked(item_id: String, qty: int) -> bool:
	var id: String = item_id.strip_edges()
	var mennyiseg: int = int(qty)
	if mennyiseg <= 0:
		return false
	var unit = get_item_unit(id)
	var target = _unbooked_dict_for_unit(unit)
	if not target.has(id):
		return false
	var entry: Dictionary = target.get(id, {})
	var elerheto: int = int(entry.get("qty", 0))
	if elerheto < mennyiseg:
		return false
	entry["qty"] = elerheto - mennyiseg
	entry["total_cost"] = int(entry.get("unit_price", 0)) * int(entry["qty"])
	if int(entry["qty"]) <= 0:
		target.erase(id)
		if unit == "g":
			stock_unbooked.erase(id)
	else:
		target[id] = entry
		if unit == "g":
			stock_unbooked[id] = entry
	return true

# =========================================================
# KÖNYVELÉS
# =========================================================

func book_item(item_id: String, amount: int, unit: String = "", portion_size_g: int = 0) -> bool:
	var id: String = item_id.strip_edges()
	if id == "" or amount <= 0:
		return false
	var use_unit = unit
	if use_unit == "":
		use_unit = get_item_unit(id)
	var unbooked = _unbooked_dict_for_unit(use_unit)
	if not unbooked.has(id):
		return false

	var entry: Dictionary = unbooked[id] as Dictionary

	var available_qty: int = int(entry.get("qty", 0))
	var book_qty = amount
	if use_unit == "g" and portion_size_g > 0:
		var portions = int(floor(float(amount) / float(portion_size_g)))
		book_qty = portions * portion_size_g
	if book_qty <= 0:
		return false
	if available_qty < book_qty:
		_toast("❌ Nincs elég könyveletlen készlet (%s)" % id)
		return false
	var unit_price: int = int(entry.get("unit_price", 0))
	var total_cost: int = book_qty * unit_price

	# Könyveletlen csökkentése
	entry["qty"] = available_qty - book_qty
	entry["total_cost"] = int(entry["qty"]) * unit_price

	if entry["qty"] <= 0:
		unbooked.erase(id)
		if use_unit == "g":
			stock_unbooked.erase(id)
	else:
		unbooked[id] = entry
		if use_unit == "g":
			stock_unbooked[id] = entry

	# Könyvelt készlet növelése
	var booked = _booked_dict_for_unit(use_unit)
	booked[id] = int(booked.get(id, 0)) + book_qty

	_log_journal("BOOKED", id, book_qty, unit_price, total_cost)
	print("[BOOK] id=%s move=%d unit=%s" % [id, book_qty, use_unit])

	# 💰 AUTOMATIKUS KÖLTSÉG KÖNYVELÉS
	if has_node("/root/EconomySystem1"):
		EconomySystem1.add_expense(total_cost, "Áru könyvelés: %s" % id)

	if debug_toast:
		var unit_cimke = _unit_cimke(use_unit)
		_toast("📘 Könyvelve: %s %d %s → %d Ft" % [id, book_qty, unit_cimke, total_cost])

	return true

# =========================================================
# KÖNYVELT KÉSZLET
# =========================================================

func get_qty(item_id: String) -> int:
	var id = item_id.strip_edges()
	var unit = get_item_unit(id)
	var booked = _booked_dict_for_unit(unit)
	return int(booked.get(id, 0))

func get_booked_items() -> Array:
	var tetelek: Array = []
	for kulcs in stock.keys():
		tetelek.append(String(kulcs))
	for kulcs2 in booked_ml.keys():
		tetelek.append(String(kulcs2))
	for kulcs3 in booked_pcs.keys():
		tetelek.append(String(kulcs3))
	return tetelek

func remove(item_id: String, qty: int) -> bool:
	var id: String = item_id.strip_edges()
	var unit = get_item_unit(id)
	var booked = _booked_dict_for_unit(unit)
	if int(booked.get(id, 0)) < qty:
		return false
	booked[id] = int(booked.get(id, 0)) - qty
	return true

func can_consume_booked(cost_map: Dictionary) -> bool:
	if cost_map == null or cost_map.is_empty():
		return true
	for kulcs in cost_map.keys():
		var id = String(kulcs).strip_edges()
		if id == "":
			continue
		var kell = int(cost_map.get(kulcs, 0))
		if kell <= 0:
			continue
		if get_qty(id) < kell:
			return false
	return true

func consume_booked(cost_map: Dictionary, reason: String = "") -> bool:
	if cost_map == null or cost_map.is_empty():
		return true
	if not can_consume_booked(cost_map):
		return false
	for kulcs in cost_map.keys():
		var id = String(kulcs).strip_edges()
		if id == "":
			continue
		var kell = int(cost_map.get(kulcs, 0))
		if kell <= 0:
			continue
		remove(id, kell)
	_log_journal("BUILD_CONSUME", reason, 0, 0, 0)
	return true

# =========================================================
# EGYSÉG KEZELÉS
# =========================================================

func get_item_unit(item_id: String) -> String:
	var id = item_id.strip_edges().to_lower()
	if id == "":
		return "pcs"
	var unit = "pcs"
	var reason = "default"
	if LIQUID_ML_IDS.has(id):
		unit = "ml"
		reason = "liquid"
	elif _is_kitchen_ingredient(id):
		unit = "g"
		reason = "kitchen"
	if not _unit_log_cache.has(id):
		_unit_log_cache[id] = true
		print("[UNIT_RESOLVE] id=%s unit=%s reason=%s" % [id, unit, reason])
	return unit

func get_inventory_snapshot() -> Array:
	var eredmeny: Array = []
	var kulcsok: Array = []
	_osszegyujt_kulcsok(kulcsok, unbooked_g)
	_osszegyujt_kulcsok(kulcsok, unbooked_ml)
	_osszegyujt_kulcsok(kulcsok, unbooked_pcs)
	_osszegyujt_kulcsok(kulcsok, stock)
	_osszegyujt_kulcsok(kulcsok, booked_ml)
	_osszegyujt_kulcsok(kulcsok, booked_pcs)
	kulcsok.sort()
	for id_any in kulcsok:
		var id = String(id_any).strip_edges()
		if id == "":
			continue
		var unit = get_item_unit(id)
		var warehouse_qty = _get_unbooked_qty_by_unit(id, unit)
		var kitchen_qty = _get_booked_qty_by_unit(id, unit)
		var kitchen_unit = unit
		if unit == "g":
			kitchen_unit = "adag"
			kitchen_qty = _get_kitchen_portions(id)
		eredmeny.append({
			"id": id,
			"warehouse_qty": warehouse_qty,
			"warehouse_unit": unit,
			"kitchen_qty": kitchen_qty,
			"kitchen_unit": kitchen_unit
		})
	return eredmeny

func _get_kitchen_portions(item_id: String) -> int:
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return 0
	if KitchenSystem1.has_method("get_total_portions"):
		return int(KitchenSystem1.call("get_total_portions", item_id))
	return 0

func _get_unbooked_qty_by_unit(item_id: String, unit: String) -> int:
	var target = _unbooked_dict_for_unit(unit)
	if not target.has(item_id):
		return 0
	return int(target[item_id].get("qty", 0))

func _get_booked_qty_by_unit(item_id: String, unit: String) -> int:
	var target = _booked_dict_for_unit(unit)
	return int(target.get(item_id, 0))

func _unbooked_dict_for_unit(unit: String) -> Dictionary:
	match unit:
		"ml":
			return unbooked_ml
		"pcs":
			return unbooked_pcs
		_:
			return unbooked_g

func _booked_dict_for_unit(unit: String) -> Dictionary:
	match unit:
		"ml":
			return booked_ml
		"pcs":
			return booked_pcs
		_:
			return stock

func _hozzaad_unbooked_lista(lista: Array, adat: Dictionary, unit: String) -> void:
	for kulcs in adat.keys():
		var id = String(kulcs).strip_edges()
		if id == "":
			continue
		var entry_any = adat.get(id, {})
		var entry = entry_any if entry_any is Dictionary else {}
		var qty = int(entry.get("qty", 0))
		if qty <= 0:
			continue
		lista.append({
			"id": id,
			"qty": qty,
			"unit": unit
		})

func _osszegyujt_kulcsok(cel: Array, forras: Dictionary) -> void:
	for kulcs in forras.keys():
		var id = String(kulcs).strip_edges()
		if id == "":
			continue
		if not cel.has(id):
			cel.append(id)

func _is_buildable_item(item_id: String) -> bool:
	var kulcsszavak = ["chair", "table", "decor", "bench", "stool", "barrel", "lamp"]
	if item_id.begins_with("build_"):
		return true
	for szo in kulcsszavak:
		if item_id.find(szo) >= 0:
			return true
	return false

func _is_kitchen_ingredient(item_id: String) -> bool:
	if item_id == "":
		return false
	if _cached_kitchen_ingredient_ids.is_empty():
		_build_kitchen_ingredient_cache()
	return _cached_kitchen_ingredient_ids.has(item_id)

func _build_kitchen_ingredient_cache() -> void:
	_cached_kitchen_ingredient_ids.clear()
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen == null:
		return
	var recipes_any = kitchen.get("_recipes")
	var recipes = recipes_any if recipes_any is Dictionary else {}
	if recipes.is_empty():
		return
	for rid in recipes.keys():
		var recipe_any = recipes.get(rid, {})
		var recipe = recipe_any if recipe_any is Dictionary else {}
		_collect_kitchen_ingredient_ids(recipe)

func _collect_kitchen_ingredient_ids(recipe: Dictionary) -> void:
	var ingredients_any = recipe.get("ingredients", [])
	if ingredients_any is Array:
		for ing_any in ingredients_any:
			var ing = ing_any if ing_any is Dictionary else {}
			var id = str(ing.get("item_id", "")).strip_edges().to_lower()
			if id != "":
				_cached_kitchen_ingredient_ids[id] = true
	elif ingredients_any is Dictionary:
		for key in ingredients_any.keys():
			var id2 = str(key).strip_edges().to_lower()
			if id2 != "":
				_cached_kitchen_ingredient_ids[id2] = true

	var inputs_any = recipe.get("inputs", {})
	if inputs_any is Dictionary:
		for key2 in inputs_any.keys():
			var id3 = str(key2).strip_edges().to_lower()
			if id3 != "":
				_cached_kitchen_ingredient_ids[id3] = true

	var costs_any = recipe.get("costs", {})
	if costs_any is Dictionary:
		for key3 in costs_any.keys():
			var id4 = str(key3).strip_edges().to_lower()
			if id4 != "":
				_cached_kitchen_ingredient_ids[id4] = true

func _unit_cimke(unit: String) -> String:
	match unit:
		"pcs":
			return "db"
		_:
			return unit

# =========================================================
# EVENT BUS
# =========================================================

func _connect_bus() -> void:
	var eb: Node = _eb()
	if eb and eb.has_signal("bus_emitted"):
		eb.connect("bus_emitted", Callable(self, "_on_bus"))

func _on_bus(topic: String, payload: Dictionary) -> void:
	match topic:
		"stock.buy": # 👉 BOLT HASZNÁLJA
			add_unbooked(
				payload.get("item",""),
				payload.get("qty",0),
				payload.get("unit_price",0)
			)
		"stock.dump":
			dump_toast()
		_:
			pass

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

# =========================================================
# NAPLÓ
# =========================================================

func _log_journal(kind: String, item: String, qty: int, unit_price: int, total_cost: int) -> void:
	_journal.append({
		"time": TimeSystem1.get_game_time_string(),
		"type": kind,
		"item": item,
		"qty": qty,
		"unit_price": unit_price,
		"total_cost": total_cost
	})

func dump_toast() -> void:
	for k: String in stock.keys():
		_toast("%s = %d" % [k, int(stock.get(k, 0))])

func _toast(t: String) -> void:
	var eb: Node = _eb()
	if eb and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", t)
