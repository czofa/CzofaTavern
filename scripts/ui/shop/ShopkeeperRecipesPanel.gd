extends Control

@export var button_buy_gulyas_path: NodePath
@export var button_buy_kolbasz_path: NodePath
@export var button_buy_rantotta_path: NodePath
@export var button_back_path: NodePath

@onready var _btn_gulyas: Button = get_node(button_buy_gulyas_path)
@onready var _btn_kolbasz: Button = get_node(button_buy_kolbasz_path)
@onready var _btn_rantotta: Button = get_node(button_buy_rantotta_path)
@onready var _btn_back: Button = get_node(button_back_path)

func _ready() -> void:
	_btn_gulyas.pressed.connect(func(): _buy_recipe("gulyas", 25))
	_btn_kolbasz.pressed.connect(func(): _buy_recipe("kolbasz", 20))
	_btn_rantotta.pressed.connect(func(): _buy_recipe("rantotta", 15))
	_btn_back.pressed.connect(_on_back)

func _buy_recipe(id: String, price: int) -> void:
	var kitchen = get_node_or_null("/root/KitchenSystem1")
	if kitchen and kitchen.owns_recipe(id):
		_toast("✅ Már birtoklod ezt a receptet.")
	else:
		_bus("economy.buy_recipe", {
			"id": id,
			"price": price
		})
		_toast("📖 Recept megvásárolva: " + id.capitalize())

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
