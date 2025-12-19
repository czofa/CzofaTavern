# res://scripts/systems/encounters/EncounterEffectsApplier.gd
extends Node
class_name EncounterEffectsApplier
# Autoload: EncounterEffectsApplier1

const FactionConfig = preload("res://scripts/systems/factions/FactionConfig.gd")

@export var debug_toast: bool = true

var _catalog: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_catalog = _find_catalog_autoload()
	_connect_bus()
	if debug_toast:
		_toast("EncounterEffectsApplier kész")

# -------------------------------------------------------------------
# Catalog lookup (AUTOLOAD-ot keressük, nem new())
# -------------------------------------------------------------------

func _find_catalog_autoload() -> Node:
	var root = get_tree().root
	var c = root.get_node_or_null("EncounterCatalog1")
	if c != null:
		return c
	c = root.get_node_or_null("EncounterCatalog")
	if c != null:
		return c
	if debug_toast:
		_toast("EncounterEffectsApplier: EncounterCatalog(1) nem található (effektek nem futnak).")
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
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		if debug_toast:
			_toast("EncounterEffectsApplier: EventBus1/bus_emitted hiányzik.")
		return
	var cb = Callable(self, "_on_bus")
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
	var encounter_id = str(payload.get("id", "")).strip_edges()
	var choice_id = str(payload.get("choice", "")).strip_edges()
	if encounter_id == "" or choice_id == "":
		return
	var reason = "Encounter: %s/%s" % [encounter_id, choice_id]

	var data = _get_encounter(encounter_id)
	if data.is_empty():
		if debug_toast:
			_toast("Nincs encounter adat: %s" % encounter_id)
		return

	var effects = _extract_effects(data, choice_id)
	if effects.is_empty():
		if debug_toast:
			_toast("Nincs effect ehhez: %s/%s" % [encounter_id, choice_id])
		return

	var summary: Array = []
	var applied_any: bool = false

	applied_any = _apply_money_effect(effects, reason, summary) or applied_any
	applied_any = _apply_state_effect(effects, "reputation", "Reputáció", reason, summary) or applied_any
	applied_any = _apply_state_effect(effects, "risk", "Kockázat", reason, summary) or applied_any
	applied_any = _apply_direct_faction_keys(effects, reason, summary) or applied_any
	applied_any = _apply_faction_effect(effects, reason, summary) or applied_any

	var other_applied: bool = _apply_remaining_effects(effects, reason)

	if summary.size() > 0:
		_notify_summary(summary)
	elif applied_any or other_applied:
		if debug_toast:
			_toast("Encounter hatás alkalmazva: %s/%s" % [encounter_id, choice_id])
	elif debug_toast:
		_toast("Nem volt alkalmazható encounter hatás: %s/%s" % [encounter_id, choice_id])

func _extract_effects(encounter_data: Dictionary, choice_id: String) -> Dictionary:
	var choices: Array = encounter_data.get("choices", [])
	for c in choices:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var cd = c as Dictionary
		if str(cd.get("id", "")).strip_edges() == choice_id:
			var e = cd.get("effects", {})
			return e if typeof(e) == TYPE_DICTIONARY else {}
	return {}

# -------------------------------------------------------------------
# Effect helpers
# -------------------------------------------------------------------

func _apply_money_effect(effects: Dictionary, reason: String, summary: Array) -> bool:
	if not _has_numeric_effect(effects, "money"):
		return false
	var delta = int(effects.get("money", 0))
	var ok = _apply_money(delta, reason)
	if ok:
		summary.append(_format_money(delta))
	else:
		_toast("⚠️ Encounter hatás kihagyva: pénz (GameState/EconomySystem nem elérhető).")
	return ok

func _apply_state_effect(effects: Dictionary, key: String, label: String, reason: String, summary: Array) -> bool:
	if not _has_numeric_effect(effects, key):
		return false
	var delta = int(effects.get(key, 0))
	var ok = _apply_state_delta(key, delta, reason)
	if ok:
		summary.append(_format_stat(label, delta))
	else:
		_toast("⚠️ Encounter hatás kihagyva: %s (GameState nem elérhető)." % label)
	return ok

func _apply_direct_faction_keys(effects: Dictionary, reason: String, summary: Array) -> bool:
	var applied: bool = false
	for entry in FactionConfig.FACTIONS:
		var key = str(entry.get("id", "")).strip_edges()
		if key == "" or not _has_numeric_effect(effects, key):
			continue
		var delta = int(effects.get(key, 0))
		if delta == 0:
			continue
		var ok = _apply_faction_delta(key, delta, reason)
		if ok:
			summary.append(_format_faction(key, delta))
		else:
			_toast("⚠️ Encounter hatás kihagyva: frakció (%s)." % key)
		applied = applied or ok
	return applied

func _apply_faction_effect(effects: Dictionary, reason: String, summary: Array) -> bool:
	if not effects.has("faction"):
		return false
	var entry = effects.get("faction")
	var target = ""
	var delta = 0

	if typeof(entry) == TYPE_DICTIONARY:
		target = str(entry.get("id", entry.get("faction", ""))).strip_edges()
		delta = int(entry.get("delta", 0))
	elif typeof(entry) == TYPE_STRING:
		target = str(entry).strip_edges()
		delta = int(effects.get("delta", 0))

	if target == "" or delta == 0:
		return false

	var ok = _apply_faction_delta(target, delta, reason)
	if ok:
		var label = _format_faction(target, delta)
		if label != "":
			summary.append(label)
	else:
		_toast("⚠️ Encounter hatás kihagyva: frakció (%s)." % target)
	return ok

func _apply_remaining_effects(effects: Dictionary, reason: String) -> bool:
	var skip: Array = ["money", "reputation", "risk", "faction"]
	var applied: bool = false
	for k in effects.keys():
		var key = str(k).strip_edges()
		if key == "" or skip.has(key):
			continue
		if _is_faction_key(key):
			continue
		var v = effects[k]
		if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
			_bus("state.add", {
				"key": key,
				"delta": int(v),
				"reason": reason
			})
			applied = true
	return applied

func _has_numeric_effect(effects: Dictionary, key: String) -> bool:
	if effects.is_empty() or not effects.has(key):
		return false
	var v = effects.get(key, null)
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT

func _apply_money(delta: int, reason: String) -> bool:
	var eco = get_tree().root.get_node_or_null("EconomySystem1")
	if eco != null and eco.has_method("add_money"):
		eco.call("add_money", int(delta), str(reason))
		return true
	return _apply_state_delta("money", delta, reason)

func _apply_state_delta(key: String, delta: int, reason: String) -> bool:
	var gs = _get_state()
	if gs == null or not gs.has_method("add_value"):
		return false
	gs.call("add_value", str(key), int(delta), str(reason))
	return true

func _apply_faction_delta(id: String, delta: int, reason: String) -> bool:
	if _has_faction_system() and FactionSystem1.has_method("add_faction_value"):
		FactionSystem1.add_faction_value(id, delta, reason)
		return true
	return _apply_state_delta(id, delta, reason)

func _get_state() -> Node:
	var root = get_tree().root
	var gs = root.get_node_or_null("GameState1")
	if gs != null:
		return gs
	return root.get_node_or_null("GameState")

func _has_faction_system() -> bool:
	return typeof(FactionSystem1) != TYPE_NIL and FactionSystem1 != null

func _notify_summary(summary: Array) -> void:
	if summary.is_empty():
		return
	var parts = ""
	for i in summary.size():
		if i > 0:
			parts += ", "
		parts += str(summary[i])
	_toast("📌 Encounter következmény: %s" % parts)

func _format_money(delta: int) -> String:
	var sign = "+" if delta >= 0 else ""
	return "%s%d Ft" % [sign, delta]

func _format_stat(label: String, delta: int) -> String:
	var sign = "+" if delta >= 0 else ""
	return "%s %s%d" % [label, sign, delta]

func _format_faction(id: String, delta: int) -> String:
	var label = _find_faction_label(id)
	if label == "":
		label = id
	var sign = "+" if delta >= 0 else ""
	return "%s %s%d" % [label, sign, delta]

func _find_faction_label(id: String) -> String:
	var key = str(id).strip_edges().to_lower()
	for entry in FactionConfig.FACTIONS:
		if str(entry.get("id", "")).strip_edges().to_lower() == key:
			return str(entry.get("display_name", ""))
	return ""

func _is_faction_key(key: String) -> bool:
	var k = str(key).strip_edges().to_lower()
	for entry in FactionConfig.FACTIONS:
		if str(entry.get("id", "")).strip_edges().to_lower() == k:
			return true
	return false

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", str(topic), payload if payload != null else {})

func _toast(t: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
		return
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text": str(t)})
