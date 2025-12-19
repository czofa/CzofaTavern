extends Node

# Autoload neve: StockSystem1

@export var debug_toast: bool = true

# =========================================================
# ADATSTRUKTÚRÁK
# =========================================================

# Könyvelt (felhasználható) készlet
# { "potato": 120 }
var stock: Dictionary[String, int] = {}

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

# =========================================================
# READY
# =========================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	if debug_toast:
		_toast("📦 StockSystem READY")

# =========================================================
# VÁSÁRLÁS → KÖNYVELETLEN KÉSZLET
# =========================================================

func add_unbooked(item_id: String, qty: int, unit_price: int) -> void:
	var id: String = item_id.strip_edges()
	if id == "" or qty <= 0 or unit_price < 0:
		return

	var entry: Dictionary[String, int] = stock_unbooked.get(id, {
		"qty": 0,
		"unit_price": unit_price,
		"total_cost": 0
	}) as Dictionary[String, int]

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

	var entry: Dictionary[String, int] = stock_unbooked[id] as Dictionary[String, int]
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
# EVENT BUS
# =========================================================

func _connect_bus() -> void:
	var eb: Node = _eb()
	if eb != null and eb.has_signal("bus_emitted"):
		eb.connect("bus_emitted", Callable(self, "_on_bus"))

func _on_bus(topic: String, payload: Dictionary) -> void:
	match topic:
		"stock.buy":
			add_unbooked(
				str(payload.get("item","")),
				int(payload.get("qty",0)),
				int(payload.get("unit_price",0))
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
	_toast("🍽️ '%s' adag beállítva: %dg × %d adag" % [item_name, portion_size, total_portions])

func get_portion_size(item_name: String) -> int:
	return int(_portions.get(item_name, {}).get("portion_size", 0))

func get_total_portions(item_name: String) -> int:
	return int(_portions.get(item_name, {}).get("total", 0))
