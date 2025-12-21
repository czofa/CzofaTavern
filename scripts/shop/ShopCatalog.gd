extends Node
class_name ShopCatalog

# Adatvezérelt bolt katalógus (kategóriák + termékek)

const SHOP_SHOPKEEPER_ID = "shop_shopkeeper"
const SHOP_TERRITORY_MANAGER_ID = "shop_territory_manager"

const CATEGORIES_SHOPKEEPER = [
	{"id": "ingredients", "display_name": "🥕 Alapanyagok"},
	{"id": "recipes", "display_name": "📜 Receptek"},
	{"id": "seeds", "display_name": "🌱 Magvak"},
	{"id": "animals", "display_name": "🐄 Állatok"},
	{"id": "tools", "display_name": "🪓 Eszközök"},
	{"id": "serveware", "display_name": "🍽️ Kiszolgálóeszközök"},
	{"id": "terület", "display_name": "🗺️ Terület"},
	{"id": "construction", "display_name": "🧱 Építőanyagok"},
	{"id": "sell", "display_name": "💰 Eladás"}
]

const ITEMS_SHOPKEEPER = [
	# Alapanyagok
	{"id": "bread", "category": "ingredients", "display": "Kenyér", "type": "ingredient", "qty_g": 1000, "price": 1200},
	{"id": "potato", "category": "ingredients", "display": "Krumpli", "type": "ingredient", "qty_g": 1000, "price": 600},
	{"id": "sausage", "category": "ingredients", "display": "Kolbász", "type": "ingredient", "qty_g": 1000, "price": 4500},
	{"id": "beer", "category": "ingredients", "display": "Sör", "type": "ingredient", "qty_g": 1000, "price": 2000},

	# Receptek
	{"id": "gulyas", "category": "recipes", "display": "Gulyás recept", "type": "recipe", "price": 25, "recipe_id": "gulyas"},
	{"id": "kolbasz", "category": "recipes", "display": "Sült kolbász recept", "type": "recipe", "price": 20, "recipe_id": "kolbasz"},
	{"id": "rantotta", "category": "recipes", "display": "Rántotta recept", "type": "recipe", "price": 15, "recipe_id": "rantotta"},

	# Magvak
	{"id": "wheat_seed", "category": "seeds", "display": "Búza vetőmag", "type": "seed", "price": 5},
	{"id": "potato_seed", "category": "seeds", "display": "Burgonya vetőmag", "type": "seed", "price": 7},
	{"id": "onion_seed", "category": "seeds", "display": "Vöröshagyma vetőmag", "type": "seed", "price": 6},

	# Állatok
	{"id": "chicken_young", "category": "animals", "display": "Csirke (fiatal)", "type": "animal", "price": 30},
	{"id": "chicken_adult", "category": "animals", "display": "Csirke (felnőtt)", "type": "animal", "price": 60},
	{"id": "cow_young", "category": "animals", "display": "Tehén (borjú)", "type": "animal", "price": 120},
	{"id": "cow_adult", "category": "animals", "display": "Tehén (felnőtt)", "type": "animal", "price": 250},
	{"id": "pig_young", "category": "animals", "display": "Malac (fiatal)", "type": "animal", "price": 90},
	{"id": "pig_adult", "category": "animals", "display": "Malac (felnőtt)", "type": "animal", "price": 180},

	# Eszközök
	{"id": "bucket", "category": "tools", "display": "Vödör", "type": "tool", "price": 20},
	{"id": "eggbasket", "category": "tools", "display": "Tojáskosár", "type": "tool", "price": 15},
	{"id": "knife", "category": "tools", "display": "Kés", "type": "tool", "price": 35},
	{"id": "axe", "category": "tools", "display": "Fejsze", "type": "tool", "price": 50},
	{"id": "pickaxe", "category": "tools", "display": "Csákány", "type": "tool", "price": 70},
	{"id": "sickle", "category": "tools", "display": "Sarló", "type": "tool", "price": 40},
	{"id": "storage_box", "category": "tools", "display": "Raktárláda", "type": "tool", "price": 60},

	# Kiszolgáló eszközök
	{"id": "plate", "category": "serveware", "display": "Tányér", "type": "serving_tool", "price": 3},
	{"id": "glass", "category": "serveware", "display": "Pohár", "type": "serving_tool", "price": 2},

	# Terület
	{"id": "farm_terulet", "category": "terület", "display": "Farm terület megvásárlása", "type": "territory", "price": 15000},

	# Építőanyagok
	{"id": "wood", "category": "construction", "display": "Fa", "type": "building", "price": 10},
	{"id": "stone", "category": "construction", "display": "Kő", "type": "building", "price": 12},
	{"id": "brick", "category": "construction", "display": "Tégla", "type": "building", "price": 15}
]

const SHOP_DEFINITIONS = {
	SHOP_SHOPKEEPER_ID: {
		"categories": CATEGORIES_SHOPKEEPER,
		"items": ITEMS_SHOPKEEPER
	},
	SHOP_TERRITORY_MANAGER_ID: {
		"categories": [
			{"id": "terület", "display_name": "🗺️ Terület"}
		],
		"items": [
			{"id": "farm_terulet_fejlesztes", "category": "terület", "display": "Farm megvásárlása / bővítés", "type": "territory", "price": 0}
		]
	}
}

static func get_categories(shop_id: String = SHOP_SHOPKEEPER_ID) -> Array:
	var adat = _shop_def(shop_id)
	var lista: Array = []
	for elem in adat.get("categories", []):
		lista.append(elem)
	return lista

static func get_items_for_category(category_id: String, shop_id: String = SHOP_SHOPKEEPER_ID) -> Array:
	var cid = str(category_id).strip_edges()
	var adat = _shop_def(shop_id)
	var lista: Array = []
	for elem in adat.get("items", []):
		var kat = str(elem.get("category", ""))
		if kat == cid:
			lista.append(elem)
	return lista

static func _shop_def(shop_id: String) -> Dictionary:
	var sid = str(shop_id).strip_edges()
	if sid == "":
		sid = SHOP_SHOPKEEPER_ID
	var adat_any = SHOP_DEFINITIONS.get(sid, SHOP_DEFINITIONS.get(SHOP_SHOPKEEPER_ID, {}))
	if adat_any is Dictionary:
		return (adat_any as Dictionary)
	return {}
