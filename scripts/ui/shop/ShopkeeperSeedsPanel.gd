extends Control

@export var button_buy_wheat_path: NodePath
@export var button_buy_potato_path: NodePath
@export var button_buy_onion_path: NodePath
@export var button_back_path: NodePath

@onready var _btn_wheat: Button = get_node(button_buy_wheat_path)
@onready var _btn_potato: Button = get_node(button_buy_potato_path)
@onready var _btn_onion: Button = get_node(button_buy_onion_path)
@onready var _btn_back: Button = get_node(button_back_path)

func _ready() -> void:
	_btn_wheat.pressed.connect(func(): _buy_seed("seed_potato", 5))
	_btn_potato.pressed.connect(func(): _buy_seed("seed_potato", 7))
	_btn_onion.pressed.connect(func(): _buy_seed("seed_potato", 6))
	_btn_back.pressed.connect(_on_back)

func _buy_seed(id: String, price: int) -> void:
	var ar: int = int(price)
	if ar < 0:
		return
	var penz: int = 0
	if EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		penz = EconomySystem1.get_money()
	if penz < ar and ar > 0:
		_toast("❌ Nincs elég pénz.")
		return
	if EconomySystem1 != null:
		EconomySystem1.add_money(-ar, "Vetőmag vásárlás: %s" % id)
	if SeedInventorySystem1 != null:
		SeedInventorySystem1.add_seed(id, 1)
	_toast("🌱 Vásárlás: %s" % id)

func _on_back() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

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
	var forras: Dictionary = {}
	if forras_any is Dictionary:
		forras = forras_any
	var kovetkezo: Dictionary = {}
	kovetkezo["qty"] = int(forras.get("qty", 0))
	kovetkezo["unit_price"] = int(forras.get("unit_price", unit_price))
	kovetkezo["total_cost"] = int(forras.get("total_cost", 0))
	print("[SHOP_FIX_TYPED] item=", kovetkezo, " typeof=", typeof(kovetkezo))
	kitchen.stock_unbooked[item_id] = kovetkezo

func _eb() -> Node:
	var root = get_tree().root
	var node = root.get_node_or_null("EventBus1")
	if node == null:
		node = root.get_node_or_null("EventBus")
	return node
