extends Node
class_name StockSystem
# Autoload neve: StockSystem1

@export var debug_toast: bool = true

# =========================================================
# KÉSZLETEK
# =========================================================

# Könyvelt, felhasználható készlet
var stock: Dictionary = {}
# Példa: { "potato": 120 }

# Könyveletlen készlet + ár
# { item_id : { "qty": int, "unit_price": int, "total_cost": int } }
var stock_unbooked: Dictionary = {}

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

func add_unbooked(item_id: String, qty: int, unit_price: int) -> void:
	var id: String = item_id.strip_edges()
	if id == "" or qty <= 0 or unit_price < 0:
		return

	var existing: Dictionary = stock_unbooked.get(id, {
		"qty": 0,
		"unit_price": unit_price,
		"total_cost": 0
	})

	var current_qty: int = int(existing.get("qty", 0))
	existing["qty"] = current_qty + qty
	existing["unit_price"] = unit_price
	existing["total_cost"] = int(existing["qty"]) * unit_price

	stock_unbooked[id] = existing

	_log_journal("UNBOOKED_BUY", id, qty, unit_price, qty * unit_price)

	if debug_toast:
		_toast("🛒 Vásárlás: %s +%d db @ %d Ft/db (össz: %d Ft)"
			% [id, qty, unit_price, qty * unit_price])

# A könyvelési panel EZT használja
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

	var available_qty: int = int(entry.get("qty", 0))
	if available_qty < qty:
		_toast("❌ Nincs elég könyveletlen készlet (%s)" % id)
		return false
	var unit_price: int = int(entry.get("unit_price", 0))
	var total_cost: int = qty * unit_price


	# Könyveletlen csökkentése
	entry["qty"] = available_qty - qty
	entry["total_cost"] = int(entry["qty"]) * unit_price

	if entry["qty"] <= 0:
		stock_unbooked.erase(id)
	else:
		stock_unbooked[id] = entry

	# Könyvelt készlet növelése
	stock[id] = int(stock.get(id, 0)) + qty

	_log_journal("BOOKED", id, qty, unit_price, total_cost)

	# 💰 AUTOMATIKUS KÖLTSÉG KÖNYVELÉS
	if has_node("/root/EconomySystem1"):
		EconomySystem1.add_expense(total_cost, "Áru könyvelés: %s" % id)

	if debug_toast:
		_toast("📘 Könyvelve: %s %d db → %d Ft" % [id, qty, total_cost])

	return true

# =========================================================
# KÖNYVELT KÉSZLET
# =========================================================

func get_qty(item_id: String) -> int:
	return int(stock.get(item_id.strip_edges(), 0))

func remove(item_id: String, qty: int) -> bool:
	var id: String = item_id.strip_edges()
	if get_qty(id) < qty:
		return false
	stock[id] = int(stock.get(id, 0)) - qty
	return true

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
