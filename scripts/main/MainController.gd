extends Node
class_name MainController
# Node: scenes/main/Main.tscn -> Main (root)

# -----------------------------------------------------------------------------
# MainController – csak vezérlés/indítás (nincs gameplay logika)
# -----------------------------------------------------------------------------

@export var initial_mode: String = "RTS"

func _ready() -> void:
	_bus("ui.toast", {"text":"BOOT OK"})
	_bus("mode.set", {"mode": initial_mode})

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)
