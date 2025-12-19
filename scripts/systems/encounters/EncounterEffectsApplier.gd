# res://scripts/systems/encounters/EncounterEffectsApplier.gd
extends Node
class_name EncounterEffectsApplier
# Autoload: EncounterEffectsApplier1

@export var debug_toast: bool = true

var _catalog: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_catalog = _find_catalog_autoload()
	_connect_bus()
	if debug_toast:
		_toast("EncounterEffectsApplier READY")

# -------------------------------------------------------------------
# Catalog lookup (AUTOLOAD-ot keressük, nem new())
# -------------------------------------------------------------------

func _find_catalog_autoload() -> Node:
	var root := get_tree().root
	var c := root.get_node_or_null("EncounterCatalog1")
	if c != null:
		return c
	c = root.get_node_or_null("EncounterCatalog")
	if c != null:
		return c
	if debug_toast:
		_toast("EncounterEffectsApplier: EncounterCatalog(1) not found (effects will not apply).")
	return null

func _get_encounter(id: String) -> Dictionary:
	if _catalog == null:
		return {}

	# ✅ a te Catalogod: get_data(id)
	if _catalog.has_method("get_data"):
		var d = _catalog.call("get_data", id)
		return d if typeof(d) == TYPE_DICTIONARY else {}

	# kompat: ha valahol régebbi név van
	if _catalog.has_method("get_encounter"):
		var d2 = _catalog.call("get_encounter", id)
		return d2 if typeof(d2) == TYPE_DICTIONARY else {}

	return {}

# -------------------------------------------------------------------
# Bus wiring
# -------------------------------------------------------------------

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb := _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		if debug_toast:
			_toast("EncounterEffectsApplier: EventBus1/bus_emitted not found.")
		return
	var cb := Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"encounter.apply_effects":
			_apply(payload)
		_:
			pass

# -------------------------------------------------------------------
# Apply effects
# -------------------------------------------------------------------

func _apply(payload: Dictionary) -> void:
	var encounter_id := str(payload.get("id", "")).strip_edges()
	var choice_id := str(payload.get("choice", "")).strip_edges()
	if encounter_id == "" or choice_id == "":
		return

	var data := _get_encounter(encounter_id)
	if data.is_empty():
		if debug_toast:
			_toast("EFFECTS: no encounter data for %s" % encounter_id)
		return

	var effects := _extract_effects(data, choice_id)
	if effects.is_empty():
		if debug_toast:
			_toast("EFFECTS: none for %s/%s" % [encounter_id, choice_id])
		return

	for k in effects.keys():
		var key := str(k).strip_edges()
		if key == "":
			continue
		var v = effects[k]
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			_bus("state.add", {
				"key": key,
				"delta": int(v),
				"reason": "%s/%s" % [encounter_id, choice_id]
			})

	if debug_toast:
		_toast("EFFECTS APPLIED: %s/%s" % [encounter_id, choice_id])

func _extract_effects(encounter_data: Dictionary, choice_id: String) -> Dictionary:
	var choices: Array = encounter_data.get("choices", [])
	for c in choices:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var cd := c as Dictionary
		if str(cd.get("id", "")).strip_edges() == choice_id:
			var e = cd.get("effects", {})
			return e if typeof(e) == TYPE_DICTIONARY else {}
	return {}

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", str(topic), payload if payload != null else {})

func _toast(t: String) -> void:
	var eb := _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
		return
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text": str(t)})
