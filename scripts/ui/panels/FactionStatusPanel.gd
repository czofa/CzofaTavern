extends Control

const FactionConfig = preload("res://scripts/systems/factions/FactionConfig.gd")

@export var list_path: NodePath = ^"VBoxContainer/FactionList"

var _list: VBoxContainer

func _ready() -> void:
	_list = get_node_or_null(list_path) as VBoxContainer
	_connect_bus()
	refresh_panel()

func refresh_panel() -> void:
	if _list == null:
		return
	_clear_list()
	for entry in FactionConfig.FACTIONS:
		var id = str(entry.get("id", "")).strip_edges()
		if id == "":
			continue
		var name = str(entry.get("display_name", id))
		var value = _get_value(id)
		var status_data = FactionConfig.get_status_data(value)
		var status_label = str(status_data.get("label", ""))
		var status_desc = str(status_data.get("description", ""))

		var row = Label.new()
		row.text = "%s: %d (%s)" % [name, value, status_label]
		row.tooltip_text = status_desc
		_list.add_child(row)

func _get_value(id: String) -> int:
	if _has_faction_system() and FactionSystem1.has_method("get_faction_value"):
		return int(FactionSystem1.get_faction_value(id))
	if GameState1 != null and GameState1.has_method("get_value"):
		return int(GameState1.call("get_value", id, FactionConfig.DEFAULT_VALUE))
	return FactionConfig.DEFAULT_VALUE

func _clear_list() -> void:
	for child in _list.get_children():
		child.queue_free()

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, _payload: Dictionary) -> void:
	match str(topic):
		"faction.changed":
			refresh_panel()
		_:
			pass

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _has_faction_system() -> bool:
	return typeof(FactionSystem1) != TYPE_NIL and FactionSystem1 != null
