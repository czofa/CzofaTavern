extends Node

# Egyszerű katalógus az építhető elemekhez.
const BUILDABLES = {
	"chair": {
		"cimke": "Szék",
		"scene": "res://scenes/world/buildables/Chair.tscn",
		"grid": 1.0,
		"seat": true
	},
	"table": {
		"cimke": "Asztal",
		"scene": "res://scenes/world/buildables/Table.tscn",
		"grid": 1.0,
		"seat": false
	},
	"decor": {
		"cimke": "Dekor",
		"scene": "res://scenes/world/buildables/Decor.tscn",
		"grid": 1.0,
		"seat": false
	}
}

func list_keys() -> Array:
	return BUILDABLES.keys()

func get_data(key: String) -> Dictionary:
	return BUILDABLES.get(key, {})
