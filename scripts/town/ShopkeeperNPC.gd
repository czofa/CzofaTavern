extends Node3D

@export var shopkeeper_panel_path: NodePath = ^"/root/Main/UIRoot/ShopkeeperIngredientsPanel"

var _panel: Control

func _ready() -> void:
	_load_panel()

func _exit_tree() -> void:
	# nincs mit lecsatlakoztatni most
	pass

# -------------------------------------------------
# INTERACT
# -------------------------------------------------

func interact() -> void:
	if _panel == null:
		_toast("Bolt: hiba történt (panel nincs betöltve)")
		return

	_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # 👉 egérmutató bekapcsolása
	_toast("Bolt: válassz a kínálatból.")


# -------------------------------------------------
# PANEL INIT
# -------------------------------------------------

func _load_panel() -> void:
	var panel_node := get_node_or_null(shopkeeper_panel_path)
	if panel_node == null:
		printerr("❌ ShopkeeperNPC: nem található panel a megadott úton: %s" % shopkeeper_panel_path)
		return

	_panel = panel_node
	_panel.visible = false

# -------------------------------------------------
# HELPERS
# -------------------------------------------------

func _toast(text: String) -> void:
	var eb := _eb()
	if eb == null:
		return

	if eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(text))
	elif eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text": str(text)})

func _eb() -> Node:
	var root := get_tree().root
	var eb := root.get_node_or_null("EventBus1")
	if eb == null:
		eb = root.get_node_or_null("EventBus")
	return eb
