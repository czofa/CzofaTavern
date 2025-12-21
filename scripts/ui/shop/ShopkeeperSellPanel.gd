extends Control

@export var items_container_path: NodePath
@export var empty_label_path: NodePath
@export var button_back_path: NodePath

@onready var _items_container: VBoxContainer = get_node(items_container_path)
@onready var _label_empty: Label = get_node(empty_label_path)
@onready var _btn_back: Button = get_node(button_back_path)

func _ready() -> void:
	_btn_back.pressed.connect(_on_back)
	_refresh_items()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh_items()

func _refresh_items() -> void:
	for child in _items_container.get_children():
		_items_container.remove_child(child)
		child.queue_free()
	var loot: Dictionary = {}
	if typeof(LootInventorySystem1) != TYPE_NIL and LootInventorySystem1 != null:
		loot = LootInventorySystem1.get_all_loot()
	var ids: Array = loot.keys()
	ids.sort()
	if ids.is_empty():
		_label_empty.visible = true
		return
	_label_empty.visible = false
	for id in ids:
		var qty: int = int(loot.get(id, 0))
		if qty <= 0:
			continue
		_add_item_row(str(id), qty)

func _add_item_row(id: String, qty: int) -> void:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nev = MineLootTable.get_display_name(id)
	var value_each: int = MineLootTable.get_value(id)
	if value_each <= 0:
		value_each = 10
	var lbl = Label.new()
	lbl.text = "%s – %d db" % [nev, qty]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_lbl = Label.new()
	value_lbl.text = "%d Ft/db" % value_each
	var btn_one = Button.new()
	btn_one.text = "Eladás (1)"
	btn_one.pressed.connect(func(): _sell(id, 1, value_each))
	var btn_all = Button.new()
	btn_all.text = "Eladás mind (%d)" % qty
	btn_all.pressed.connect(func(): _sell(id, qty, value_each))

	row.add_child(lbl)
	row.add_child(value_lbl)
	row.add_child(btn_one)
	row.add_child(btn_all)
	_items_container.add_child(row)

func _on_back() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

func _sell(id: String, qty: int, value_each: int) -> void:
	var mennyiseg: int = int(qty)
	var ar: int = int(value_each)
	if mennyiseg <= 0 or ar < 0:
		return
	if typeof(LootInventorySystem1) == TYPE_NIL or LootInventorySystem1 == null:
		_toast("❌ Loot rendszer nem elérhető.")
		return
	if not LootInventorySystem1.remove_loot(id, mennyiseg):
		_toast("❌ Nincs elég mennyiség: %s" % id)
		_refresh_items()
		return
	var total: int = mennyiseg * ar
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("add_money"):
		EconomySystem1.add_money(total, "Bánya loot eladás: %s" % id)
	else:
		_bus("state.add", {
			"key": "money",
			"delta": total,
			"reason": "Bánya loot eladás: %s" % id
		})
	_toast("💰 Eladva: %s x%d (+%d Ft)" % [MineLootTable.get_display_name(id), mennyiseg, total])
	_refresh_items()

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
