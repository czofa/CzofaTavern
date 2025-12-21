extends Node3D

@export var item_id: String = ""
@export var qty: int = 1
@export var value_each: int = 0
@export var pickup_area_path: NodePath = ^"Area3D"

var _area: Area3D = null
var _picked: bool = false

func _ready() -> void:
	_cache_area()
	_connect_area()

func set_loot_data(id: String, amount: int, value: int) -> void:
	item_id = str(id)
	qty = int(amount)
	value_each = int(value)

func _cache_area() -> void:
	if pickup_area_path != NodePath("") and has_node(pickup_area_path):
		_area = get_node(pickup_area_path) as Area3D

func _connect_area() -> void:
	if _area == null:
		return
	var cb = Callable(self, "_on_area_body_entered")
	if not _area.is_connected("body_entered", cb):
		_area.connect("body_entered", cb)

func _on_area_body_entered(body: Node) -> void:
	if _picked:
		return
	if body == null:
		return
	if not (body is CharacterBody3D):
		return
	if (body as CharacterBody3D).name != "Player":
		return
	_pickup()

func _pickup() -> void:
	if _picked:
		return
	_picked = true
	if typeof(LootInventorySystem1) != TYPE_NIL and LootInventorySystem1 != null:
		LootInventorySystem1.add_loot(item_id, qty)
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		var text = "💎 Loot felvéve: %s x%d (%d Ft/db)" % [
			MineLootTable.get_display_name(item_id),
			qty,
			value_each
		]
		eb.emit_signal("notification_requested", text)
	queue_free()

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")
