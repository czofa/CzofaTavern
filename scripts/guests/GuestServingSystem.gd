extends Node

# Autoload neve: GuestServingSystem1

@export var serve_interval: float = 4.0

var _timer := 0.0

func _ready() -> void:
	print("🟢 GuestServingSystem READY")
	set_process(true)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= serve_interval:
		_timer = 0.0
		serve_all_guests()

func serve_all_guests() -> void:
	var guest_spawner = get_node_or_null("/root/Main/TavernWorld/GuestSpawner")
	if guest_spawner == null:
		push_error("❌ GuestServingSystem: GuestSpawner nem található.")
		return

	if not guest_spawner.has_method("get_active_guests"):
		push_error("❌ GuestSpawner nem tartalmaz get_active_guests metódust.")
		return

	var guests: Array = guest_spawner.get_active_guests()
	if guests.is_empty():
		return

	var kitchen := get_node_or_null("/root/KitchenSystem1")
	if kitchen == null:
		push_error("❌ KitchenSystem1 nem található.")
		return

	for guest in guests:
		if not is_instance_valid(guest):
			continue

		if not guest.has_method("has_consumed") or not guest.has_method("mark_as_consumed"):
			continue

		if guest.has_consumed():
			continue

		if not guest.has_variable("reached_seat") or not guest.reached_seat:
			continue

		if not guest.has_variable("order") or guest.order == "":
			continue

		var item = guest.order

		if kitchen.has_method("consume_item") and kitchen.consume_item(item):
			guest.mark_as_consumed()
			print("✅ Vendég kiszolgálva:", guest.name, "→", item)
		else:
			print("🚫 Nincs készleten:", item, "–", guest.name)
