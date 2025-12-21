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
	},
	"farm_plot": {
		"cimke": "Kert parcella",
		"scene": "res://scenes/world/buildables/FarmPlot.tscn",
		"grid": 1.0,
		"seat": false,
		"build_key": "farm_plot"
	},
	"chicken_coop": {
		"cimke": "Tyúkól",
		"scene": "res://scenes/world/buildables/ChickenCoop.tscn",
		"grid": 1.5,
		"seat": false,
		"build_key": "chicken_coop"
	}
}

func list_keys() -> Array:
	return BUILDABLES.keys()

func get_data(key: String) -> Dictionary:
	var adat = BUILDABLES.get(key, {})
	if not adat.has("id"):
		adat["id"] = key
	return adat
