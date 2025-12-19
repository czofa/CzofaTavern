extends Node
class_name EncounterOutcomeSystem
# Autoload Node Name: EncounterOutcomeSystem1

# -------------------------------------------------------------------
# EncounterOutcomeSystem (CLEAN VERSION)
# - kizárólag encounter.resolved eseményt figyel
# - NEM tartalmaz hardcoded outcome-okat
# - a feldolgozást az EncounterEffectsApplier végzi
# - ez a rendszer csak logol + forwardol (fail-safe)
# -------------------------------------------------------------------

@export var debug_toast: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	if debug_toast:
		_toast("EncounterOutcomeSystem READY (catalog-driven)")

func _exit_tree() -> void:
	_disconnect_bus()

# -------------------------------------------------------------------
# Bus wiring
# -------------------------------------------------------------------

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb := _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return

	var cb := Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _disconnect_bus() -> void:
	var eb := _eb()
	if eb == null:
		return

	var cb := Callable(self, "_on_bus")
	if eb.has_signal("bus_emitted") and eb.is_connected("bus_emitted", cb):
		eb.disconnect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	if str(topic) != "encounter.resolved":
		return

	var encounter_id := str(payload.get("id", "")).strip_edges()
	var choice_id := str(payload.get("choice", "")).strip_edges()

	if encounter_id == "" or choice_id == "":
		return

	if debug_toast:
		_toast("Outcome received: %s / %s" % [encounter_id, choice_id])

	# 👉 NINCS további logika itt
	# Az EncounterEffectsApplier már figyeli és alkalmazza az effekteket

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func _toast(t: String) -> void:
	var eb := _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
