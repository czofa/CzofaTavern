extends Node
class_name GardenCatalog

# Adattár a kerthez és állatokhoz

const CROPS = {
	"potato": {
		"name": "Burgonya",
		"seed_id": "seed_potato",
		"growth_minutes": 60.0,
		"yield_grams": 1000
	}
}

const ANIMALS = {
	"chicken": {
		"name": "Tyúk",
		"product_id": "egg",
		"interval_minutes": 360.0,
		"yield_grams": 200,
		"product_name": "Tojás"
	}
}

const PRODUCTS = {
	"egg": "Tojás"
}

const INITIAL_SEEDS = {
	"seed_potato": 3
}

static func get_crop(crop_id: String) -> Dictionary:
	var id = str(crop_id).strip_edges()
	if id == "":
		return {}
	return CROPS.get(id, {})

static func get_crop_name(crop_id: String) -> String:
	var data = get_crop(crop_id)
	return str(data.get("name", crop_id))

static func get_animal(animal_id: String) -> Dictionary:
	var id = str(animal_id).strip_edges()
	if id == "":
		return {}
	return ANIMALS.get(id, {})

static func get_animal_name(animal_id: String) -> String:
	var data = get_animal(animal_id)
	return str(data.get("name", animal_id))

static func get_product_name(animal_id: String) -> String:
	var data = get_animal(animal_id)
	var product_id = str(data.get("product_id", animal_id))
	var product_name = PRODUCTS.get(product_id, product_id)
	return str(data.get("product_name", product_name))

static func get_initial_seeds() -> Dictionary:
	return INITIAL_SEEDS
