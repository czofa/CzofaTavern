extends Node
class_name EncounterSystem
# Autoload: EncounterSystem1 -> res://scripts/systems/encounters/EncounterSystem.gd

# -----------------------------------------------------------------------------
# EncounterSystem1 – kártya flow (stub)
# - request -> UI modal open
# - resolved -> toast
# -----------------------------------------------------------------------------

func _ready() -> void:
	_connect_bus()

func _connect_bus() -> void:
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb == null: return
	if eb.has_signal("bus_emitted"):
		var cb := Callable(self, "_on_bus")
		if not eb.is_connected("bus_emitted", cb):
			eb.connect("bus_emitted", cb)
	if eb.has_signal("encounter_resolved"):
		var cb2 := Callable(self, "_on_resolved")
		if not eb.is_connected("encounter_resolved", cb2):
			eb.connect("encounter_resolved", cb2)

func _on_bus(topic: String, payload: Dictionary) -> void:
	if str(topic) != "encounter.request":
		return
	var id := str(payload.get("id","fallback"))

	var repo := get_tree().root.get_node_or_null("DataRepo1")
	var data := {}
	if repo != null and repo.has_method("get_encounter"):
		data = repo.call("get_encounter", id)

	_bus("ui.modal.open", {"kind":"encounter", "data": data})

func _on_resolved(encounter_id: String, choice_id: String) -> void:
	_bus("ui.toast", {"text":"ENCOUNTER RESOLVED %s -> %s" % [encounter_id, choice_id]})

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)
