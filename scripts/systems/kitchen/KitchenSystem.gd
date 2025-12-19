extends Node

# Autoload neve: StockSystem1

@export var debug_toast: bool = true

# =========================================================
# ADATSTRUKTÚRÁK
# =========================================================

# Könyvelt (felhasználható) készlet
# { "potato": 120 }
var stock: Dictionary = {}

# Könyveletlen készlet + ár
# {
#   "potato": {
#       "qty": 300,
#       "unit_price": 4,
#       "total_cost": 1200
#   }
# }
var stock_unbooked: Dictionary = {}

# Könyvelési napló
var _journal: Array = []
var _recipes: Dictionary = {}
var _owned_recipes: Dictionary = {}
var _cooked: Dictionary = {}

# Biztonsági wrapper a korábbi has() hívásokhoz, hogy ne dobjon hibát.
func has(id: String) -> bool:
	if id == "stock_unbooked":
		return stock_unbooked is Dictionary
	if id == "stock":
		return stock is Dictionary
	return false

# =========================================================
# READY
# =========================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	_load_recipe_catalog()
	if debug_toast:
		_toast("📦 StockSystem READY")

# =========================================================
# VÁSÁRLÁS → KÖNYVELETLEN KÉSZLET
# =========================================================

func add_unbooked(item_id: String, qty: int, unit_price: int) -> void:
	var id: String = item_id.strip_edges()
	if id == "" or qty <= 0 or unit_price < 0:
		return

	var entry: Dictionary = stock_unbooked.get(id, {
		"qty": 0,
		"unit_price": unit_price,
		"total_cost": 0
	}) as Dictionary

	entry["qty"] = int(entry.get("qty", 0)) + qty
	entry["unit_price"] = unit_price
	entry["total_cost"] = int(entry["qty"]) * unit_price

	stock_unbooked[id] = entry

	_log_journal("UNBOOKED_BUY", id, qty, unit_price, qty * unit_price)

	if debug_toast:
		_toast("🛒 Vásárlás: %s +%d db @ %d Ft/db"
			% [id, qty, unit_price])

# =========================================================
# LEKÉRDEZÉSEK (UI-NAK)
# =========================================================

func get_unbooked_items() -> Array[String]:
	var result: Array[String] = []
	for k: String in stock_unbooked.keys():
		result.append(k)
	return result

func get_unbooked_qty(item_id: String) -> int:
	if not stock_unbooked.has(item_id):
		return 0
	return int(stock_unbooked[item_id].get("qty", 0))

func get_unbooked_total_cost(item_id: String) -> int:
	if not stock_unbooked.has(item_id):
		return 0
	return int(stock_unbooked[item_id].get("total_cost", 0))

# =========================================================
# KÖNYVELÉS
# =========================================================

func book_item(item_id: String, qty: int) -> bool:
	var id: String = item_id.strip_edges()
	if not stock_unbooked.has(id) or qty <= 0:
		return false

	var entry: Dictionary = stock_unbooked[id] as Dictionary
	var available: int = int(entry.get("qty", 0))

	if available < qty:
		_toast("❌ Nincs elég könyveletlen készlet: %s" % id)
		return false

	var unit_price: int = int(entry.get("unit_price", 0))
	var total_cost: int = qty * unit_price

	# Könyveletlen csökkentése
	entry["qty"] = available - qty
	entry["total_cost"] = int(entry["qty"]) * unit_price

	if entry["qty"] <= 0:
		stock_unbooked.erase(id)
	else:
		stock_unbooked[id] = entry

	# Könyvelt készlet növelése
	if not stock.has(id):
		stock[id] = 0
	stock[id] = int(stock.get(id, 0)) + qty

	_log_journal("BOOKED", id, qty, unit_price, total_cost)

	# 💰 AUTOMATIKUS KÖLTSÉG
	if has_node("/root/EconomySystem1"):
		EconomySystem1.add_expense(total_cost, "Áru könyvelés: %s" % id)

	if debug_toast:
		_toast("📘 Könyvelve: %s %d db → %d Ft"
			% [id, qty, total_cost])

	return true

# =========================================================
# KÖNYVELT KÉSZLET KEZELÉS
# =========================================================

func get_qty(item_id: String) -> int:
	var id: String = item_id.strip_edges()
	return int(stock.get(id, 0))

func remove(item_id: String, qty: int) -> bool:
	var id: String = item_id.strip_edges()
	if not stock.has(id):
		return false
	if int(stock[id]) < qty:
		return false
	stock[id] = int(stock[id]) - qty
	return true

# =========================================================
# RECEPTEK ÉS FŐZÉS
# =========================================================

func _load_recipe_catalog() -> void:
	_recipes = {
		"gulyas": {
			"nev": "Gulyás",
			"inputs": {
				"potato": 1,
				"sausage": 1
			},
			"output": {
				"id": "Gulyás",
				"qty": 1
			}
		},
		"kolbasz": {
			"nev": "Sült kolbász",
			"inputs": {
				"sausage": 1
			},
			"output": {
				"id": "Sült kolbász",
				"qty": 1
			}
		},
		"rantotta": {
			"nev": "Rántotta",
			"inputs": {
				"bread": 1
			},
			"output": {
				"id": "Rántotta",
				"qty": 1
			}
		}
	}
	_owned_recipes.clear()
	var alap_receptek: Array = ["rantotta"]
	for rid in alap_receptek:
		if _recipes.has(rid):
			_owned_recipes[rid] = true
	_cooked.clear()

func owns_recipe(recipe_id: String) -> bool:
	var rid = str(recipe_id).strip_edges()
	return _owned_recipes.has(rid)

func unlock_recipe(recipe_id: String) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	if not _recipes.has(rid):
		_log_kitchen("Ismeretlen recept: %s" % rid)
		return
	if _owned_recipes.has(rid):
		return
	_owned_recipes[rid] = true
	_log_kitchen("Recept feloldva: %s" % rid)

func _unlock_recipe_from_purchase(recipe_id: String) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	if not _recipes.has(rid):
		_log_kitchen("Vétel sikertelen, ismeretlen recept: %s" % rid)
		return
	if owns_recipe(rid):
		_log_kitchen("Recept már megvan, nem szükséges újra megvenni: %s" % rid)
		return
	unlock_recipe(rid)

func cook(recipe_id: String, adagok: int = 1) -> bool:
	var rid = str(recipe_id).strip_edges()
	var batch = max(int(adagok), 1)
	if rid == "" or not _recipes.has(rid):
		_log_kitchen("Ismeretlen recept, nem főzhető: %s" % rid)
		return false
	if not owns_recipe(rid):
		_log_kitchen("Nincs meg a recept: %s" % rid)
		return false
	var recipe_any = _recipes.get(rid, {})
	var recipe = recipe_any if recipe_any is Dictionary else {}
	if not _has_enough_portions(recipe, batch):
		_log_kitchen("Nincs elég adag a főzéshez: %s" % rid)
		return false

	_spend_portions(recipe, batch)
	_store_meal(recipe, batch)
	_log_kitchen("Elkészült: %s × %d adag" % [rid, batch])
	return true

func get_cooked_qty(item_id: String) -> int:
	var key = str(item_id).strip_edges()
	return int(_cooked.get(key, 0))

func consume_item(item_id: String) -> bool:
	var key = str(item_id).strip_edges()
	if key == "":
		return false
	if _cooked.has(key) and int(_cooked.get(key, 0)) > 0:
		_cooked[key] = int(_cooked.get(key, 0)) - 1
		_log_kitchen("Kiadva: %s (maradék: %d)" % [key, int(_cooked.get(key, 0))])
		return true
	var recipe_id = _find_recipe_for_output(key)
	if recipe_id != "" and cook(recipe_id, 1):
		return consume_item(key)
	_log_kitchen("Hiányzó késztermék: %s" % key)
	return false

func _has_enough_portions(recipe: Dictionary, batches: int) -> bool:
	var inputs_any = recipe.get("inputs", {})
	if not (inputs_any is Dictionary):
		return false
	for ingredient in inputs_any.keys():
		var per_batch = int(inputs_any.get(ingredient, 0))
		if per_batch <= 0:
			continue
		var need = per_batch * batches
		var available = get_total_portions(ingredient)
		if available < need:
			return false
	return true

func _spend_portions(recipe: Dictionary, batches: int) -> void:
	var inputs_any = recipe.get("inputs", {})
	if not (inputs_any is Dictionary):
		return
	for ingredient in inputs_any.keys():
		var per_batch = int(inputs_any.get(ingredient, 0))
		if per_batch <= 0:
			continue
		var need = per_batch * batches
		var portion_data_any = _portions.get(ingredient, {})
		var portion_data = portion_data_any if portion_data_any is Dictionary else {}
		var available = int(portion_data.get("total", 0))
		portion_data["total"] = max(available - need, 0)
		_portions[ingredient] = portion_data

func _store_meal(recipe: Dictionary, batches: int) -> void:
	var output_any = recipe.get("output", {})
	var output = output_any if output_any is Dictionary else {}
	var output_id = str(output.get("id", "unknown"))
	var per_batch = int(output.get("qty", 1))
	var add_qty = per_batch * batches
	_cooked[output_id] = int(_cooked.get(output_id, 0)) + add_qty

func _find_recipe_for_output(output_id: String) -> String:
	var target = output_id.strip_edges().to_lower()
	for rid in _recipes.keys():
		var recipe_any = _recipes.get(rid, {})
		var recipe = recipe_any if recipe_any is Dictionary else {}
		var output_any = recipe.get("output", {})
		var output = output_any if output_any is Dictionary else {}
		var out_id = str(output.get("id", rid)).to_lower()
		if out_id == target:
			return rid
	return ""

# =========================================================
# EVENT BUS
# =========================================================
# EVENT BUS
# =========================================================

func _connect_bus() -> void:
	var eb: Node = _eb()
	if eb != null and eb.has_signal("bus_emitted"):
		eb.connect("bus_emitted", Callable(self, "_on_bus"))

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"stock.buy":
			add_unbooked(
				str(payload.get("item","")),
				int(payload.get("qty",0)),
				int(payload.get("unit_price",0))
			)
		"stock.dump":
			dump_toast()
		"kitchen.cook":
			cook(
				str(payload.get("id", payload.get("recipe", ""))),
				int(payload.get("portions", 1))
			)
		"kitchen.unlock_recipe":
			unlock_recipe(str(payload.get("id", "")))
		"economy.buy_recipe":
			_unlock_recipe_from_purchase(str(payload.get("id", "")))
		_:
			pass

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

# =========================================================
# NAPLÓ
# =========================================================

func _log_kitchen(text: String) -> void:
	var msg = "[KITCHEN] %s" % text
	if debug_toast:
		_toast(msg)
	else:
		print(msg)

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

func _toast(text: String) -> void:
	var eb: Node = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)

# --- Adat: porció mérete és adagok száma ---
var _portions: Dictionary = {}

func set_portion_data(item_name: String, portion_size: int, total_portions: int) -> void:
	_portions[item_name] = {
		"portion_size": portion_size,
		"total": total_portions
	}
	_log_kitchen("🍽️ '%s' adag beállítva: %dg × %d adag" % [item_name, portion_size, total_portions])

func get_portion_size(item_name: String) -> int:
	return int(_portions.get(item_name, {}).get("portion_size", 0))

func get_total_portions(item_name: String) -> int:
	return int(_portions.get(item_name, {}).get("total", 0))
