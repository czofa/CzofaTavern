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
	# 1. Levonás gazdasági rendszerből
	_bus("economy.buy", {
		"item": item,
		"qty": qty,
		"unit_price": unit_price
	})

	# 2. Hozzáadás a könyveletlen készlethez (nem könyvelt!)
	_bus("stock.add_unbooked", {
		"item": item,
		"qty": qty
	})

	# 3. Visszajelzés
	_toast("✅ Vásároltál: %d db %s (könyvelés szükséges)" % [qty, item])

func _toast(msg: String) -> void:
	var eb = _eb()
	if eb:
		eb.emit_signal("notification_requested", msg)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _eb() -> Node:
	var root := get_tree().root
	var eb := root.get_node_or_null("EventBus1")
	if not eb:
		eb = root.get_node_or_null("EventBus")
	return eb
