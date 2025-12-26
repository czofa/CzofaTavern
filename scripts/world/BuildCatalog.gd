extends Node

# Egyszerű katalógus az építhető elemekhez.
const BUILDABLES = {
	"chair_basic": {
		"cimke": "Alap szék",
		"display_name": "Alap szék",
		"scene": "res://scenes/world/buildables/Chair.tscn",
		"grid": 1.0,
		"seat": true,
		"koltseg": "fa: 500 g",
		"cost_map": {
			"wood_plank": 500
		},
		"koltseg_map": {
			"wood_plank": 500
		}
	},
	"table_basic": {
		"cimke": "Alap asztal",
		"display_name": "Alap asztal",
		"scene": "res://scenes/world/buildables/Table.tscn",
		"grid": 1.0,
		"seat": false,
		"koltseg": "fa: 800 g",
		"cost_map": {
			"wood_plank": 800
		},
		"koltseg_map": {
			"wood_plank": 800
		}
	},
	"decor_basic": {
		"cimke": "Alap dekor",
		"display_name": "Alap dekor",
		"scene": "res://scenes/world/buildables/Decor.tscn",
		"grid": 1.0,
		"seat": false,
		"koltseg": "festék: 200 g",
		"cost_map": {
			"paint": 200
		},
		"koltseg_map": {
			"paint": 200
		}
	},
	"chair": {
		"cimke": "Szék",
		"display_name": "Szék",
		"scene": "res://scenes/world/buildables/Chair.tscn",
		"grid": 1.0,
		"seat": true,
		"koltseg": "fa: 8 g, szög: 4 g",
		"cost_map": {
			"fa": 8,
			"szög": 4
		},
		"koltseg_map": {
			"fa": 8,
			"szög": 4
		}
	},
	"table": {
		"cimke": "Asztal",
		"display_name": "Asztal",
		"scene": "res://scenes/world/buildables/Table.tscn",
		"grid": 1.0,
		"seat": false,
		"koltseg": "fa: 12 g, szög: 6 g",
		"cost_map": {
			"fa": 12,
			"szög": 6
		},
		"koltseg_map": {
			"fa": 12,
			"szög": 6
		}
	},
	"decor": {
		"cimke": "Dekor",
		"display_name": "Dekor",
		"scene": "res://scenes/world/buildables/Decor.tscn",
		"grid": 1.0,
		"seat": false,
		"koltseg": "fa: 4 g, festék: 2 g",
		"cost_map": {
			"fa": 4,
			"festék": 2
		},
		"koltseg_map": {
			"fa": 4,
			"festék": 2
		}
	},
	"farm_plot": {
		"cimke": "Kert parcella",
		"display_name": "Kert parcella",
		"scene": "res://scenes/world/buildables/FarmPlot.tscn",
		"grid": 1.0,
		"seat": false,
		"koltseg": "költség: nincs",
		"cost_map": {},
		"koltseg_map": {},
		"build_key": "farm_plot"
	},
	"chicken_coop": {
		"cimke": "Tyúkól",
		"display_name": "Tyúkól",
		"scene": "res://scenes/world/buildables/ChickenCoop.tscn",
		"grid": 1.5,
		"seat": false,
		"koltseg": "költség: nincs",
		"cost_map": {},
		"koltseg_map": {},
		"build_key": "chicken_coop"
	}
}

func list_keys() -> Array:
	return BUILDABLES.keys()

func get_data(key: String) -> Dictionary:
	var alap = BUILDABLES.get(key, {})
	var adat = {}
	if alap is Dictionary:
		adat = alap.duplicate(true)
	if not adat.has("id"):
		adat["id"] = key
	if not adat.has("display_name") and adat.has("cimke"):
		adat["display_name"] = adat["cimke"]
	if not adat.has("cost_map") and adat.has("koltseg_map"):
		adat["cost_map"] = adat["koltseg_map"]
	return adat

func get_items() -> Array:
	var lista: Array = []
	var alap_kulcsok = ["chair_basic", "table_basic", "decor_basic"]
	for kulcs in alap_kulcsok:
		if BUILDABLES.has(kulcs):
			lista.append(get_data(kulcs))
	return lista
