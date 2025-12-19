extends Node

# Autoload neve: GuestServingSystem1

@export var serve_interval: float = 4.0

var _timer = 0.0

func _ready() -> void:
	print("🟢 GuestServingSystem READY")
	set_process(true)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= serve_interval:
		_timer = 0.0
		serve_all_guests()

func serve_all_guests() -> void:
	var guest_spawner = get_node_or_null("/root/Main/WorldRoot/TavernWorld/GuestSpawner")
	if guest_spawner == null:
		guest_spawner = get_node_or_null("/root/Main/TavernWorld/GuestSpawner")
		if guest_spawner == null:
			push_error("[GUEST_SERVE] ❌ GuestSpawner nem található.")
			return

	if not guest_spawner.has_method("get_active_guests"):
		push_error("[GUEST_SERVE] ❌ GuestSpawner nem tartalmaz get_active_guests metódust.")
		return

	var guests: Array = guest_spawner.get_active_guests()
	if guests.is_empty():
		return

	var kitchen = get_node_or_null("/root/KitchenSystem1")
	if kitchen == null:
		push_error("[GUEST_SERVE] ❌ KitchenSystem1 nem található.")
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

		if not guest.has_variable("order"):
			continue

		var rendeles_any = guest.order
		print("[FIX_EQ] order_type=", typeof(rendeles_any), " order=", rendeles_any)

		var item = ""
		var tipus = ""
		if typeof(rendeles_any) == TYPE_DICTIONARY:
			item = String(rendeles_any.get("id", "")).strip_edges()
			tipus = String(rendeles_any.get("tipus", rendeles_any.get("type", ""))).to_lower()
		elif typeof(rendeles_any) == TYPE_STRING:
			item = String(rendeles_any).strip_edges()
		else:
			continue

		if item == "":
			continue

		if tipus == "ital":
			guest.mark_as_consumed()
			print("[GUEST_SERVE] Ital automatikusan felszolgálva: %s → %s" % [guest.name, item])
			continue

		if kitchen.has_method("consume_item") and kitchen.consume_item(item):
			guest.mark_as_consumed()
			print("[GUEST_SERVE] Vendég kiszolgálva: %s → %s" % [guest.name, item])
		else:
			print("[GUEST_SERVE] 🚫 Nincs készleten: %s – %s" % [item, guest.name])
