# res://scripts/systems/encounters/EncounterDirector.gd
extends Node
class_name EncounterDirector
# Autoload Node Name: EncounterDirector1

@export var debug_toast: bool = true
@export var catalog_autoload_name: String = "EncounterCatalog1"

var _catalog: Node = null

# Fallback adatbázis (akkor is működjön, ha nincs catalog)
var _db: Dictionary = {
	"test_judge": {
		"id": "test_judge",
		"title": "A bíró betér",
		"body": "A bíró egy pálinkát kér. Fizetni később akar. Mit teszel?",
		"choices": [
			{"id":"serve", "text":"Kiszolgálod (jó pont)"},
			{"id":"refuse", "text":"Nem szolgálod ki (kockázat)"}
		]
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_catalog()
	_connect_bus()
	_connect_signal_fallback()
	if debug_toast:
		_toast("EncounterDirector READY")

# -------------------- Public API --------------------

func request(id: String) -> void:
	_open_by_id(id)

func register_encounter(id: String, data: Dictionary) -> void:
	var key = str(id).strip_edges()
	if key != "" and data != null and not data.is_empty():
		_db[key] = data

# -------------------- Catalog (AUTLOAD) --------------------

func _cache_catalog() -> void:
	var root = get_tree().root
	_catalog = root.get_node_or_null(catalog_autoload_name)
	if _catalog == null:
		# opcionális fallback, ha valaki nem 1-es névvel futtatja
		_catalog = root.get_node_or_null("EncounterCatalog")

func _get_catalog() -> Node:
	if _catalog == null or not is_instance_valid(_catalog):
		_cache_catalog()
	return _catalog

func _get_from_catalog(id: String) -> Dictionary:
	var c = _get_catalog()
	if c == null:
		return {}

	# A te catalogod API-ja: has(id), get_data(id)
	if c.has_method("get_data"):
		var d = c.call("get_data", id)
		if typeof(d) == TYPE_DICTIONARY:
			return d

	return {}

# -------------------- Bus --------------------

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null:
		return
	if eb.has_signal("bus_emitted"):
		var cb = Callable(self, "_on_bus")
		if not eb.is_connected("bus_emitted", cb):
			eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"encounter.request":
			_open_by_id(str(payload.get("id","")))
		"encounter.resolved":
			_on_resolved_bus(payload)
		_:
			pass

func _on_resolved_bus(payload: Dictionary) -> void:
	var id = str(payload.get("id",""))
	var choice = str(payload.get("choice",""))
	_toast("ENCOUNTER: %s -> %s" % [id, choice])

	# későbbi milestone: pénz/frakció/hírnév stb.
	_bus("encounter.apply_effects", {"id": id, "choice": choice})

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

# -------------------- Signal fallback (kompatibilitás) --------------------

func _connect_signal_fallback() -> void:
	var eb = _eb()
	if eb == null:
		return

	# régi jel: request_show_encounter(encounter_id)
	if eb.has_signal("request_show_encounter"):
		var cb_show = Callable(self, "_on_request_show_encounter")
		if not eb.is_connected("request_show_encounter", cb_show):
			eb.connect("request_show_encounter", cb_show)

	# régi jel: encounter_resolved(encounter_id, choice_id)
	if eb.has_signal("encounter_resolved"):
		var cb_res = Callable(self, "_on_encounter_resolved_signal")
		if not eb.is_connected("encounter_resolved", cb_res):
			eb.connect("encounter_resolved", cb_res)

func _on_request_show_encounter(encounter_id: String) -> void:
	_open_by_id(str(encounter_id))

func _on_encounter_resolved_signal(a, b = null) -> void:
	var id = str(a)
	var choice = "ok"
	if b != null:
		choice = str(b)

	_toast("ENCOUNTER: %s -> %s" % [id, choice])
	_bus("encounter.apply_effects", {"id": id, "choice": choice})

# -------------------- Open --------------------

func _open_by_id(id: String) -> void:
	var key = str(id).strip_edges()
	if key == "":
		return

	# 1) Catalog (autoload)
	var data: Dictionary = _get_from_catalog(key)

	# 2) Fallback _db (plusz Catalog->Director regisztráció is ide kerül)
	if data.is_empty():
		data = _db.get(key, {})

	# 3) Default
	if data.is_empty():
		data = {
			"id": key,
			"title": "Encounter",
			"body": "Nincs még adat ehhez az encounterhez: %s" % key,
			"choices": [{"id":"ok","text":"OK"}]
		}

	_bus("ui.modal.open", {"kind":"encounter", "data": data})

	if debug_toast:
		_toast("OPEN: %s" % key)

func _toast(t: String) -> void:
	_bus("ui.toast", {"text": str(t)})
