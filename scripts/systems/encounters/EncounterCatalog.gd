# res://scripts/systems/encounters/EncounterCatalog.gd
extends Node
class_name EncounterCatalog
# Autoload Node Name: EncounterCatalog1

const RETRY_MAX: int = 12
const RETRY_DELAY_SEC: float = 0.20

var _catalog: Dictionary = {
	"test_judge": {
		"id": "test_judge",
		"title": "A bíró betér",
		"body": "A bíró egy pálinkát kér. Fizetni később akar. Mit teszel?",
		"choices": [
			{
				"id":"serve",
				"text":"Kiszolgálod (jó pont)",
				"effects": {"reputation": 1, "authority": 1, "money": 2}
			},
			{
				"id":"refuse",
				"text":"Nem szolgálod ki (kockázat)",
				"effects": {"reputation": -1, "risk": 1}
			}
		]
	},

	"test_taxman": {
		"id": "test_taxman",
		"title": "NAV ellenőrzés",
		"body": "Megjelenik egy ellenőr. Könyvelést kér. Mit csinálsz?",
		"choices": [
			{
				"id":"cooperate",
				"text":"Együttműködsz (biztonság)",
				"effects": {"safety": 1, "authority": 1}
			},
			{
				"id":"stall",
				"text":"Húzod az időt (kockázat)",
				"effects": {"risk": 2, "reputation": -1}
			}
		]
	},

	"test_underworld": {
		"id": "test_underworld",
		"title": "Alvilági ajánlat",
		"body": "Egy idegen pénzt ajánl \"védelemért\". Elfogadod?",
		"choices": [
			{
				"id":"accept",
				"text":"Elfogadod (gyors pénz)",
				"effects": {"money": 10, "underworld": 2, "risk": 1}
			},
			{
				"id":"reject",
				"text":"Elutasítod (veszély?)",
				"effects": {"safety": 1, "risk": 2}
			}
		]
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_try_register_all", 0)

func has(id: String) -> bool:
	var key := str(id).strip_edges()
	return key != "" and _catalog.has(key)

func get_data(id: String) -> Dictionary:
	var key := str(id).strip_edges()
	if key == "" or not _catalog.has(key):
		return {}
	return _catalog[key]

func all_ids() -> Array:
	return _catalog.keys()

func register_or_replace(id: String, data: Dictionary) -> void:
	var key := str(id).strip_edges()
	if key == "" or data == null:
		return
	_catalog[key] = data

func _try_register_all(attempt: int) -> void:
	var director := _get_director()
	if director == null:
		if attempt < RETRY_MAX:
			await get_tree().create_timer(RETRY_DELAY_SEC).timeout
			_try_register_all(attempt + 1)
		else:
			_toast("EncounterCatalog: Director not found (gave up).")
		return

	if not director.has_method("register_encounter"):
		_toast("EncounterCatalog: Director has no register_encounter().")
		return

	var count := 0
	for id in _catalog.keys():
		director.call("register_encounter", str(id), _catalog[id])
		count += 1

	_toast("EncounterCatalog: registered %d encounters." % count)

func _get_director() -> Node:
	var root := get_tree().root
	var d := root.get_node_or_null("EncounterDirector1")
	if d != null:
		return d
	d = root.get_node_or_null("EncounterDirector")
	if d != null:
		return d
	return null

func _toast(t: String) -> void:
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(t))
		return
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text": str(t)})
