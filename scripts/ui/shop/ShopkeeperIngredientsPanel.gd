extends Control

@export var button_buy_bread_path: NodePath
@export var button_buy_potato_path: NodePath
@export var button_buy_sausage_path: NodePath
@export var button_back_path: NodePath

@onready var _btn_bread: Button = get_node(button_buy_bread_path)
@onready var _btn_potato: Button = get_node(button_buy_potato_path)
@onready var _btn_sausage: Button = get_node(button_buy_sausage_path)
@onready var _btn_back: Button = get_node(button_back_path)

func _ready() -> void:
	_btn_bread.pressed.connect(_on_bread_pressed)
	_btn_potato.pressed.connect(_on_potato_pressed)
	_btn_sausage.pressed.connect(_on_sausage_pressed)
	_btn_back.pressed.connect(_on_back_pressed)

func _on_bread_pressed() -> void:
	_buy_ingredient("bread", 1000, 1200)

func _on_potato_pressed() -> void:
	_buy_ingredient("potato", 1000, 600)

func _on_sausage_pressed() -> void:
	_buy_ingredient("sausage", 1000, 4500)

func _on_back_pressed() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

func _buy_ingredient(item: String, qty_grams: int, package_price: int) -> void:
	var safe_item = str(item).strip_edges()
	var safe_qty_grams = int(qty_grams)
	var safe_package_price = max(int(package_price), 0)
	var unit_price = _egysegar_gramonkent(safe_package_price, safe_qty_grams)
	var payload: Dictionary = {
		"item": safe_item,
		"qty": safe_qty_grams if safe_qty_grams > 0 else 0,
		"unit_price": unit_price,
		"total_price": safe_package_price
	}
	if payload["item"] == "" or payload["qty"] <= 0:
		print("[SHOP_FIX] Hiányzó vagy hibás termékadat: %s" % safe_item)
		return
	print("[SHOP_QTY] termék: %s, gramm: %d, csomagár: %d Ft" % [safe_item, payload["qty"], safe_package_price])
	_elokeszit_konyhai_buffer(safe_item, unit_price)
	# 1. Levonás gazdasági rendszerből
	_bus("economy.buy", payload)

	# 2. Visszajelzés
	_toast("✅ Vásároltál: %d g %s (könyvelés szükséges)" % [safe_qty_grams, item])

func _toast(msg: String) -> void:
	var eb = _eb()
	if eb:
		eb.emit_signal("notification_requested", msg)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _elokeszit_konyhai_buffer(item_id: String, unit_price: int) -> void:
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen == null:
		return
	if not kitchen.has("stock_unbooked"):
		return
	var forras_any = kitchen.stock_unbooked.get(item_id, {})
	var forras: Dictionary = forras_any if forras_any is Dictionary else {}
	var typed: Dictionary[String, int] = {}
	typed["qty"] = int(forras.get("qty", 0))
	typed["unit_price"] = int(forras.get("unit_price", unit_price))
	typed["total_cost"] = int(forras.get("total_cost", 0))
	kitchen.stock_unbooked[item_id] = typed

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if not eb:
		eb = root.get_node_or_null("EventBus")
	return eb

func _egysegar_gramonkent(csomag_ar: int, mennyiseg_gramm: int) -> int:
	var gramm = max(int(mennyiseg_gramm), 1)
	var osszeg = max(int(csomag_ar), 0)
	var ar = float(osszeg) / float(gramm)
	var kerekitett = int(round(ar))
	if kerekitett < 1:
		return 1
	return kerekitett
