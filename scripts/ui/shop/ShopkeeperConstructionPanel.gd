extends Control

@export var button_buy_wood_path: NodePath
@export var button_buy_stone_path: NodePath
@export var button_buy_brick_path: NodePath
@export var button_back_path: NodePath

@onready var _btn_wood: Button = get_node(button_buy_wood_path)
@onready var _btn_stone: Button = get_node(button_buy_stone_path)
@onready var _btn_brick: Button = get_node(button_buy_brick_path)
@onready var _btn_back: Button = get_node(button_back_path)

func _ready() -> void:
	_btn_wood.pressed.connect(func(): _buy("wood", 10))
	_btn_stone.pressed.connect(func(): _buy("stone", 12))
	_btn_brick.pressed.connect(func(): _buy("brick", 15))
	_btn_back.pressed.connect(_on_back)

func _buy(id: String, price: int) -> void:
	_bus("economy.buy_stock", {
		"id": id,
		"amount": 1,
		"price": price
	})
	_toast("✅ Vásárlás: " + id.capitalize())

func _on_back() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

func _toast(msg: String) -> void:
	var eb := _eb()
	if eb != null:
		eb.emit_signal("notification_requested", msg)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _eb() -> Node:
	var root := get_tree().root
	var eb := root.get_node_or_null("EventBus1")
	if eb == null:
		eb = root.get_node_or_null("EventBus")
	return eb
