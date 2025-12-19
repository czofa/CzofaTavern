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
	_buy_ingredient("bread", 1, 3)

func _on_potato_pressed() -> void:
	_buy_ingredient("potato", 1, 2)

func _on_sausage_pressed() -> void:
	_buy_ingredient("sausage", 1, 5)

func _on_back_pressed() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

func _buy_ingredient(item: String, qty: int, unit_price: int) -> void:
	var safe_item = str(item).strip_edges()
	var safe_qty = int(qty)
	var safe_price = max(int(unit_price), 0)
	var payload: Dictionary = {
		"item": safe_item,
		"qty": safe_qty if safe_qty > 0 else 0,
		"unit_price": safe_price
	}
	if payload["item"] == "" or payload["qty"] <= 0:
		print("[SHOP_FIX] Hiányzó vagy hibás termékadat: %s" % safe_item)
		return
	_elokeszit_konyhai_buffer(safe_item, safe_price)
	# 1. Levonás gazdasági rendszerből
	_bus("economy.buy", payload)

	# 2. Visszajelzés
	_toast("✅ Vásároltál: %d db %s (könyvelés szükséges)" % [qty, item])

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
