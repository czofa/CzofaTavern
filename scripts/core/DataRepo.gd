extends Node
class_name DataRepo
# Autoload: DataRepo1 -> res://scripts/core/DataRepo.gd

# -----------------------------------------------------------------------------
# DataRepo1 – adatforrás (stub)
# - később JSON-ból tölt, most ad fallback mintákat
# -----------------------------------------------------------------------------

var encounters: Dictionary = {}

func _ready() -> void:
	_load_stub()

func get_encounter(encounter_id: String) -> Dictionary:
	if encounters.has(encounter_id):
		return encounters[encounter_id]
	return encounters.get("fallback", {})

func _load_stub() -> void:
	encounters.clear()

	encounters["test_judge"] = {
		"id":"test_judge",
		"title":"A bíró betér",
		"body":"A bíró egy italra ül be. Baráti áron adod, vagy lehúzod?",
		"choices":[
			{"id":"fair","text":"Baráti ár (jó hírnév, kevesebb pénz)"},
			{"id":"scam","text":"Lehúzod (több pénz, rossz hírnév)"}
		]
	}

	encounters["fallback"] = {
		"id":"fallback",
		"title":"Csendes nap",
		"body":"Semmi különös nem történt.",
		"choices":[ {"id":"ok","text":"Tovább"} ]
	}
