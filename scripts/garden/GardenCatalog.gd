extends Node
class_name GardenCatalog

# Adattár a kerthez és állatokhoz

var crops: Dictionary = {
	"potato": {
		"name": "Burgonya",
		"seed_id": "seed_potato",
		"growth_minutes": 60.0,
		"yield_grams": 1000
	}
}

var animals: Dictionary = {
	"chicken": {
		"name": "Tyúk",
		"product_id": "egg",
		"interval_minutes": 360.0,
		"yield_grams": 200,
		"product_name": "Tojás"
	}
}

var initial_seeds: Dictionary = {
	"seed_potato": 3
}

func get_crop(crop_id: String) -> Dictionary:
	var id = str(crop_id).strip_edges()
	if id == "":
		return {}
	return crops.get(id, {})

func get_crop_name(crop_id: String) -> String:
	var data = get_crop(crop_id)
	return str(data.get("name", crop_id))

func get_animal(animal_id: String) -> Dictionary:
	var id = str(animal_id).strip_edges()
	if id == "":
		return {}
	return animals.get(id, {})

func get_animal_name(animal_id: String) -> String:
	var data = get_animal(animal_id)
	return str(data.get("name", animal_id))

func get_product_name(animal_id: String) -> String:
	var data = get_animal(animal_id)
	return str(data.get("product_name", data.get("product_id", animal_id)))
