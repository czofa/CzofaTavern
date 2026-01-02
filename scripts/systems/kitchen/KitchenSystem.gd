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
	reload_from_game_data()
	if _recipes.is_empty():
		_load_recipe_catalog()
	var seeded = _seed_alap_receptek()
	print("[RECIPE_OWN] seeded=%d owned=%s" % [seeded, str(get_owned_recipes())])
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
			"id": "gulyas",
			"name": "Gulyás",
			"type": "food",
			"ingredients": [
				{"item_id": "potato", "g": 200},
				{"item_id": "sausage", "g": 150}
			],
			"output_portions": 1,
			"sell_price": 700,
			"serve_direct": false,
			"unlocked": false
		},
		"kolbasz": {
			"id": "kolbasz",
			"name": "Sült kolbász",
			"type": "food",
			"ingredients": [
				{"item_id": "sausage", "g": 200}
			],
			"output_portions": 1,
			"sell_price": 900,
			"serve_direct": false,
			"unlocked": false
		},
		"rantotta": {
			"id": "rantotta",
			"name": "Rántotta",
			"type": "food",
			"ingredients": [
				{"item_id": "bread", "g": 150}
			],
			"output_portions": 1,
			"sell_price": 700,
			"serve_direct": false,
			"unlocked": true
		},
		"beer": {
			"id": "beer",
			"name": "Sör",
			"type": "drink",
			"ingredients": [],
			"output_portions": 1,
			"sell_price": 800,
			"serve_direct": true,
			"unlocked": true
		}
	}
	_init_owned_recipes()
	_cooked.clear()

func owns_recipe(recipe_id: String) -> bool:
	var rid = str(recipe_id).strip_edges()
	return _owned_recipes.has(rid)

func has_recipe(id: String) -> bool:
	return owns_recipe(id)

func get_owned_recipes() -> Array[String]:
	var lista: Array[String] = []
	for rid in _owned_recipes.keys():
		lista.append(str(rid))
	lista.sort()
	return lista

func get_owned_recipe_ids() -> Array[String]:
	return get_owned_recipes()

func get_enabled_recipe_ids() -> Array[String]:
	var owned = get_owned_recipe_ids()
	if owned.is_empty():
		return []
	var tuning = RecipeTuningSystem1 if typeof(RecipeTuningSystem1) != TYPE_NIL else null
	if tuning != null and tuning.has_method("get_active_recipes"):
		var aktiv_any = tuning.call("get_active_recipes")
		var aktiv = aktiv_any if aktiv_any is Array else []
		var enabled: Array[String] = []
		var owned_map: Dictionary = {}
		for rid_any in owned:
			var rid = str(rid_any).strip_edges()
			if rid != "":
				owned_map[rid] = true
		for rid_any in aktiv:
			var rid = str(rid_any).strip_edges()
			if rid != "" and owned_map.has(rid):
				enabled.append(rid)
		return enabled
	if tuning != null and tuning.has_method("is_recipe_enabled"):
		var enabled2: Array[String] = []
		for rid_any in owned:
			var rid = str(rid_any).strip_edges()
			if rid == "":
				continue
			if bool(tuning.call("is_recipe_enabled", rid)):
				enabled2.append(rid)
		return enabled2
	return owned.duplicate()

func get_owned_recipe_source() -> String:
	return "KitchenSystem1.get_owned_recipe_ids"

func get_enabled_recipe_source() -> String:
	var tuning = RecipeTuningSystem1 if typeof(RecipeTuningSystem1) != TYPE_NIL else null
	if tuning != null and tuning.has_method("get_active_recipes"):
		return "KitchenSystem1.get_enabled_recipe_ids+RecipeTuningSystem1.get_active_recipes"
	if tuning != null and tuning.has_method("is_recipe_enabled"):
		return "KitchenSystem1.get_enabled_recipe_ids+RecipeTuningSystem1.is_recipe_enabled"
	return "KitchenSystem1.get_enabled_recipe_ids"

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
	var adat_any = _recipes.get(rid, {})
	var adat = adat_any if adat_any is Dictionary else {}
	adat["unlocked"] = true
	_recipes[rid] = adat
	if typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		if RecipeTuningSystem1.has_method("ensure_seed_for_owned_recipes"):
			RecipeTuningSystem1.call("ensure_seed_for_owned_recipes")
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
	if not _taverna_nyitva():
		return false
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
		_log_kitchen("Nincs elég alapanyag a főzéshez: %s" % rid)
		return false

	_spend_portions(recipe, batch)
	_store_meal(recipe, batch)
	_log_kitchen("Elkészült: %s × %d adag" % [rid, batch])
	return true

func get_cooked_qty(item_id: String) -> int:
	var key = str(item_id).strip_edges()
	return int(_cooked.get(key, 0))

func consume_item(item_id: String) -> bool:
	if not _taverna_nyitva():
		return false
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
	var inputs = _recept_hozzavalok(recipe)
	for ingredient in inputs.keys():
		var per_batch = int(inputs.get(ingredient, 0))
		if per_batch <= 0:
			continue
		var need = per_batch * batches
		if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
			return false
		if not StockSystem1.has_method("get_qty"):
			return false
		var available = int(StockSystem1.call("get_qty", ingredient))
		if available < need:
			return false
	return true

func _spend_portions(recipe: Dictionary, batches: int) -> void:
	var inputs = _recept_hozzavalok(recipe)
	for ingredient in inputs.keys():
		var per_batch = int(inputs.get(ingredient, 0))
		if per_batch <= 0:
			continue
		var need = per_batch * batches
		if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
			continue
		if not StockSystem1.has_method("remove"):
			continue
		StockSystem1.call("remove", ingredient, need)

func _store_meal(recipe: Dictionary, batches: int) -> void:
	var output_id = _kimenet_azonosito(recipe)
	var per_batch = int(recipe.get("output_portions", 1))
	var add_qty = per_batch * batches
	_cooked[output_id] = int(_cooked.get(output_id, 0)) + add_qty

func _find_recipe_for_output(output_id: String) -> String:
	var target = output_id.strip_edges().to_lower()
	for rid in _recipes.keys():
		var recipe_any = _recipes.get(rid, {})
		var recipe = recipe_any if recipe_any is Dictionary else {}
		var out_id = _kimenet_azonosito(recipe).to_lower()
		if out_id == target:
			return rid
	return ""

func _recept_hozzavalok(recipe: Dictionary) -> Dictionary:
	var eredmeny: Dictionary = {}
	var rid = str(recipe.get("id", "")).strip_edges()
	if rid != "" and typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		if RecipeTuningSystem1.has_method("get_effective_ingredients"):
			var eff_any = RecipeTuningSystem1.call("get_effective_ingredients", rid)
			var eff = eff_any if eff_any is Dictionary else {}
			if not eff.is_empty():
				return eff
	var lista_any = recipe.get("ingredients", [])
	if lista_any is Array:
		for ing_any in lista_any:
			var ing = ing_any if ing_any is Dictionary else {}
			var id = str(ing.get("item_id", "")).strip_edges()
			if id == "":
				continue
			var gramm = int(ing.get("g", 0))
			var aktualis = int(eredmeny.get(id, 0))
			eredmeny[id] = aktualis + max(gramm, 0)
	var regi = recipe.get("inputs", {})
	if regi is Dictionary:
		for key in regi.keys():
			eredmeny[key] = int(eredmeny.get(key, 0)) + int(regi.get(key, 0))
	if rid != "" and typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		if RecipeTuningSystem1.has_method("get_recipe_ingredient_amount"):
			for key in eredmeny.keys():
				var alap = int(eredmeny.get(key, 0))
				var uj = int(RecipeTuningSystem1.call("get_recipe_ingredient_amount", rid, str(key), alap, "g"))
				eredmeny[key] = max(uj, 0)
	return eredmeny

func _kimenet_azonosito(recipe: Dictionary) -> String:
	var output_any = recipe.get("output", {})
	var output = output_any if output_any is Dictionary else {}
	var alap = str(output.get("id", recipe.get("id", "unknown")))
	return alap if alap != "" else "unknown"

func _kell_adag(ingredient: String, gramm: int) -> int:
	var portion_data_any = _portions.get(ingredient, {})
	var portion_data = portion_data_any if portion_data_any is Dictionary else {}
	var portion_size = int(portion_data.get("portion_size", 0))
	if portion_size <= 0:
		return gramm
	return int(ceil(float(gramm) / float(portion_size)))

func reload_from_game_data() -> void:
	var gd = _game_data()
	if gd != null and gd.has_method("get_recipes"):
		var adat_any = gd.call("get_recipes")
		var adat = adat_any if adat_any is Dictionary else {}
		if not adat.is_empty():
			_recipes = adat.duplicate(true)
			_init_owned_recipes()
			_cooked.clear()

func _init_owned_recipes() -> void:
	_owned_recipes.clear()
	for rid in _recipes.keys():
		var adat_any = _recipes.get(rid, {})
		var adat = adat_any if adat_any is Dictionary else {}
		if bool(adat.get("unlocked", false)):
			_owned_recipes[rid] = true
	if _owned_recipes.is_empty():
		var alap_receptek: Array = ["rantotta", "beer"]
		for rid in alap_receptek:
			if _recipes.has(rid):
				_owned_recipes[rid] = true

func _seed_alap_receptek() -> int:
	var now_owned = _owned_recipes.size()
	if now_owned >= 2:
		return 0
	var kulcsok: Array[String] = []
	for rid in _recipes.keys():
		kulcsok.append(str(rid))
	kulcsok.sort()
	var seeded = 0
	for rid in kulcsok:
		if _owned_recipes.has(rid):
			continue
		_owned_recipes[rid] = true
		var adat_any = _recipes.get(rid, {})
		var adat = adat_any if adat_any is Dictionary else {}
		adat["unlocked"] = true
		_recipes[rid] = adat
		seeded += 1
		now_owned += 1
		if now_owned >= 2:
			break
	return seeded

func _game_data() -> Node:
	return get_tree().root.get_node_or_null("GameData1")

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

func _taverna_nyitva() -> bool:
	if not Engine.has_singleton("EmployeeSystem1") and typeof(EmployeeSystem1) == TYPE_NIL:
		return true
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return true
	if not EmployeeSystem1.has_method("is_tavern_open"):
		return true
	var perc = int(TimeSystem1.get_game_minutes()) if typeof(TimeSystem1) != TYPE_NIL and TimeSystem1 != null else 0
	var nyitva = EmployeeSystem1.is_tavern_open(perc)
	if not nyitva and EmployeeSystem1.has_method("request_closed_notification"):
		EmployeeSystem1.request_closed_notification()
	return nyitva

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
