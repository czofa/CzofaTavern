extends Control

@export var btn_chicken_young_path: NodePath
@export var btn_chicken_adult_path: NodePath
@export var btn_cow_young_path: NodePath
@export var btn_cow_adult_path: NodePath
@export var btn_pig_young_path: NodePath
@export var btn_pig_adult_path: NodePath
@export var btn_back_path: NodePath

@onready var _btn_chicken_young: Button = get_node(btn_chicken_young_path)
@onready var _btn_chicken_adult: Button = get_node(btn_chicken_adult_path)
@onready var _btn_cow_young: Button = get_node(btn_cow_young_path)
@onready var _btn_cow_adult: Button = get_node(btn_cow_adult_path)
@onready var _btn_pig_young: Button = get_node(btn_pig_young_path)
@onready var _btn_pig_adult: Button = get_node(btn_pig_adult_path)
@onready var _btn_back: Button = get_node(btn_back_path)

func _ready() -> void:
	hide()

	_btn_chicken_young.pressed.connect(func(): _buy_animal("chicken", "young", 30))
	_btn_chicken_adult.pressed.connect(func(): _buy_animal("chicken", "adult", 60))

	_btn_cow_young.pressed.connect(func(): _buy_animal("cow", "young", 120))
	_btn_cow_adult.pressed.connect(func(): _buy_animal("cow", "adult", 250))

	_btn_pig_young.pressed.connect(func(): _buy_animal("pig", "young", 90))
	_btn_pig_adult.pressed.connect(func(): _buy_animal("pig", "adult", 180))

	_btn_back.pressed.connect(_on_back)

	print("🐄 ShopkeeperAnimalsPanel READY")

func show_panel() -> void:
	show()
	_toast("🐾 Állatok vásárlása")

func _buy_animal(type: String, age: String, price: int) -> void:
	_bus("animal.buy", {
		"type": type,
		"age": age,
		"price": price
	})

	_toast("✅ Vásároltál: %s (%s)" % [type.capitalize(), age])

func _on_back() -> void:
	hide()
	_toast("🔙 Vissza a boltba")

# ───────── helpers ─────────

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _toast(text: String) -> void:
	var eb = _eb()
	if eb and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)

func _eb() -> Node:
	var root = get_tree().root
	var node = root.get_node_or_null("EventBus1")
	if node == null:
		node = root.get_node_or_null("EventBus")
	return node
