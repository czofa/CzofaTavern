# res://scripts/tools/DebugHotkeys.gd
extends Node
class_name DebugHotkeys
# Autoload: DebugHotkeys1

# F7-et NE használd: Godot Debugger (Step Into) elviszi Editorból futtatva.
const KEY_BUY_PACK_PRIMARY := KEY_F11
const KEY_DUMP := KEY_F12

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_toast("DebugHotkeys READY (F11 buy pack, F12 dump)")

func _input(event: InputEvent) -> void:
	if event == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k = event as InputEventKey

		# Ha véletlen F7-et nyomsz: jelezzük miért nem jó
		if k.keycode == KEY_F7:
			_toast("F7 = Debugger STEP INTO (Editor elviszi). Használd: F11")
			return

		if k.keycode == KEY_BUY_PACK_PRIMARY or k.keycode == KEY_7 or k.keycode == KEY_KP_7:
			_buy_pack()
			return

		if k.keycode == KEY_DUMP:
			_dump()
			return

func _buy_pack() -> void:
	_toast("BUY PACK TRIGGER")
	_bus("economy.buy", {"item":"bread", "qty":5, "unit_price":2})
	_bus("economy.buy", {"item":"sausage", "qty":3, "unit_price":5})
	_bus("economy.buy", {"item":"beer", "qty":6, "unit_price":3})

func _dump() -> void:
	_bus("stock.dump", {})
	var money = 0
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		money = int(gs.call("get_value", "money", 0))
	_toast("MONEY = %d" % money)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _toast(t: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
