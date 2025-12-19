extends Node
class_name EconomySystem
# Autoload név: EconomySystem1

@export var debug_toast: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	if debug_toast:
		_toast("EconomySystem READY")

# -------------------------------------------------
# PUBLIC API
# -------------------------------------------------

func buy(item_id: String, qty: int, unit_price: int) -> bool:
	var item := str(item_id).strip_edges()
	var q := int(qty)
	var price := int(unit_price)

	if item == "" or q <= 0 or price < 0:
		return false

	var total := q * price
	var money := _get_money()

	if money < total:
		_toast("❌ Nincs elég pénz: %d < %d Ft" % [money, total])
		return false

	_add_money(-total, "Vásárlás: %s" % item)
	_stock_add(item, q, price)
	_log_transaction("buy", item, q, total)

	_toast("✅ Vásárlás: %s x%d (%d Ft)" % [item, q, total])
	return true


func sell(item_id: String, qty: int, unit_price: int) -> bool:
	var item := str(item_id).strip_edges()
	var q := int(qty)
	var price := int(unit_price)

	if item == "" or q <= 0 or price < 0:
		return false

	if not _stock_remove(item, q, "Eladás: %s" % item):
		_toast("❌ Nincs elég %s a raktárban!" % item)
		return false

	var total := q * price
	_add_money(total, "Eladás: %s" % item)
	_log_transaction("sell", item, q, total)

	_toast("✅ Eladás: %s x%d (%d Ft)" % [item, q, total])
	return true

# -------------------------------------------------
# BUS
# -------------------------------------------------

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb := _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return

	var cb := Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"economy.buy":
			buy(
				str(payload.get("item", "")),
				int(payload.get("qty", 1)),
				int(payload.get("unit_price", 0))
			)
		"economy.sell":
			sell(
				str(payload.get("item", "")),
				int(payload.get("qty", 1)),
				int(payload.get("unit_price", 0))
			)
		_:
			pass

# -------------------------------------------------
# INTERNAL
# -------------------------------------------------

func _get_money() -> int:
	var gs := get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", "money", 0))
	return 0

func _add_money(delta: int, reason: String) -> void:
	var eb := _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "state.add", {
			"key": "money",
			"delta": int(delta),
			"reason": str(reason)
		})

func _stock_add(item: String, qty: int, unit_price: int) -> void:
	var eb := _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "stock.buy", {
			"item": item,
			"qty": int(qty),
			"unit_price": int(unit_price)
		})

func _stock_remove(item: String, qty: int, reason: String) -> bool:
	var ss := get_tree().root.get_node_or_null("StockSystem1")
	if ss != null and ss.has_method("remove"):
		return bool(ss.call("remove", item, int(qty), str(reason)))
	return false

func _log_transaction(kind: String, item: String, qty: int, total_price: int) -> void:
	var eb := _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "book.log", {
			"kind": str(kind),
			"item": str(item),
			"qty": int(qty),
			"total": int(total_price),
			"time": Time.get_datetime_string_from_system()
		})

func _toast(t: String) -> void:
	if not debug_toast:
		return

	var eb := _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
