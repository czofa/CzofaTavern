extends Node
class_name MainController
# Node: scenes/main/Main.tscn -> Main (root)

# -----------------------------------------------------------------------------
# MainController – csak vezérlés/indítás (nincs gameplay logika)
# -----------------------------------------------------------------------------

@export var initial_mode: String = "RTS"
@export var game_mode_controller_path: NodePath = ^"CoreRoot/GameModeController"

func _ready() -> void:
	_bus("ui.toast", {"text":"BOOT OK"})
	_bus("mode.set", {"mode": initial_mode})
	call_deferred("_apply_start_mode")

func _apply_start_mode() -> void:
	var controller = get_node_or_null(game_mode_controller_path)
	if controller != null and controller.has_method("apply_current_mode"):
		controller.call("apply_current_mode")

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)
