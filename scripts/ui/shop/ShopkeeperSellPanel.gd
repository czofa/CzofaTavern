extends Control

@export var button_sell_wood_path: NodePath
@export var button_sell_stone_path: NodePath
@export var button_sell_clay_path: NodePath
@export var button_sell_ore_path: NodePath

@export var button_sell_kolbasz_path: NodePath
@export var button_sell_szalonna_path: NodePath
@export var button_sell_palinka_path: NodePath
@export var button_sell_sor_path: NodePath

@export var button_back_path: NodePath

@onready var _btn_wood: Button = get_node(button_sell_wood_path)
@onready var _btn_stone: Button = get_node(button_sell_stone_path)
@onready var _btn_clay: Button = get_node(button_sell_clay_path)
@onready var _btn_ore: Button = get_node(button_sell_ore_path)

@onready var _btn_kolbasz: Button = get_node(button_sell_kolbasz_path)
@onready var _btn_szalonna: Button = get_node(button_sell_szalonna_path)
@onready var _btn_palinka: Button = get_node(button_sell_palinka_path)
@onready var _btn_sor: Button = get_node(button_sell_sor_path)

@onready var _btn_back: Button = get_node(button_back_path)

func _ready() -> void:
	_btn_wood.pressed.connect(func(): _sell("wood", 20))
	_btn_stone.pressed.connect(func(): _sell("stone", 25))
	_btn_clay.pressed.connect(func(): _sell("clay", 30))
	_btn_ore.pressed.connect(func(): _sell("ore", 50))

	_btn_kolbasz.pressed.connect(func(): _sell("kolbasz", 50))
	_btn_szalonna.pressed.connect(func(): _sell("szalonna", 45))
	_btn_palinka.pressed.connect(func(): _sell("palinka", 60))
	_btn_sor.pressed.connect(func(): _sell("sor", 40))

	_btn_back.pressed.connect(_on_back)

func _sell(id: String, price: int) -> void:
	_bus("economy.sell_stock", {
		"id": id,
		"amount": 1,
		"price": price
	})
	_toast("✅ Eladás: " + id.capitalize())

func _on_back() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

func _toast(msg: String) -> void:
	var eb = _eb()
	if eb != null:
		eb.emit_signal("notification_requested", msg)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb == null:
		eb = root.get_node_or_null("EventBus")
	return eb
