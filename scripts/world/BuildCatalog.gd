extends Node

# Egyszerű katalógus az építhető elemekhez.
const BUILDABLES = {
	"chair": {
		"display_name": "Szék",
		"cimke": "Szék",
		"scene": "res://scenes/world/buildables/Chair.tscn",
		"scene_path": "res://scenes/world/buildables/Chair.tscn",
		"grid": 1.0,
		"seat": true,
		"icon_path": "res://icon.svg",
		"cost_map": {
			"wood": 8,
			"nails": 4
		}
	},
	"table": {
		"display_name": "Asztal",
		"cimke": "Asztal",
		"scene": "res://scenes/world/buildables/Table.tscn",
		"scene_path": "res://scenes/world/buildables/Table.tscn",
		"grid": 1.0,
		"seat": false,
		"icon_path": "res://icon.svg",
		"cost_map": {
			"wood": 12,
			"nails": 6,
			"stone": 2
		}
	},
	"decor": {
		"display_name": "Dekor",
		"cimke": "Dekor",
		"scene": "res://scenes/world/buildables/Decor.tscn",
		"scene_path": "res://scenes/world/buildables/Decor.tscn",
		"grid": 1.0,
		"seat": false,
		"icon_path": "res://icon.svg",
		"cost_map": {
			"wood": 4,
			"stone": 1
		}
	},
	"farm_plot": {
		"cimke": "Kert parcella",
		"display_name": "Kert parcella",
		"scene": "res://scenes/world/buildables/FarmPlot.tscn",
		"scene_path": "res://scenes/world/buildables/FarmPlot.tscn",
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
		"scene_path": "res://scenes/world/buildables/ChickenCoop.tscn",
		"grid": 1.5,
		"seat": false,
		"koltseg": "költség: nincs",
		"cost_map": {},
		"koltseg_map": {},
		"build_key": "chicken_coop"
	}
}

func list_keys() -> Array:
	var kulcsok: Array = BUILDABLES.keys()
	kulcsok.sort()
	return kulcsok

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
	if not adat.has("scene_path") and adat.has("scene"):
		adat["scene_path"] = adat["scene"]
	return adat

func get_items() -> Array:
	var lista: Array = []
	var alap_kulcsok = ["chair", "table", "decor"]
	for kulcs in alap_kulcsok:
		if BUILDABLES.has(kulcs):
			lista.append(get_data(kulcs))
		else:
			lista.append(_alap_elem(kulcs))
	return lista

func _alap_elem(kulcs: String) -> Dictionary:
	var cimke = "Elem"
	if kulcs == "chair":
		cimke = "Szék"
	elif kulcs == "table":
		cimke = "Asztal"
	elif kulcs == "decor":
		cimke = "Dekor"
	var adat = {
		"id": kulcs,
		"display_name": cimke,
		"cimke": cimke,
		"grid": 1.0,
		"seat": kulcs == "chair",
		"icon_path": "res://icon.svg",
		"cost_map": {
			"wood": 4,
			"nails": 2,
			"stone": 1
		}
	}
	return adat
