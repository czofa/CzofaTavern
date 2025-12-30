extends Node
class_name GameData
# Autoload neve: GameData1

const DEFAULT_SHOP_PATH = "res://data/default_shop.json"
const DEFAULT_RECIPES_PATH = "res://data/default_recipes.json"
const USER_DATA_PATH = "user://game_data.json"
const DEBUG_EXPORT_PATH = "res://debug_exports/game_data_export.json"
const ALAP_SHOP_ID = "shop_shopkeeper"

var _shop_catalog: Dictionary = {}
var _recipes: Dictionary = {}
var _defaults_shop: Dictionary = {}
var _defaults_recipes: Dictionary = {}
var _recipe_tuning: Dictionary = {}
var _public_opinion: float = 0.0

func _ready() -> void:
	load_all()

func get_shop_catalog(shop_id: String = ALAP_SHOP_ID) -> Dictionary:
	var sid = _norm_shop_id(shop_id)
	var bolt = _shop_catalog.get(sid, null)
	if bolt is Dictionary:
		return (bolt as Dictionary).duplicate(true)
	if _shop_catalog.has(ALAP_SHOP_ID):
		var alap = _shop_catalog.get(ALAP_SHOP_ID)
		if alap is Dictionary:
			return (alap as Dictionary).duplicate(true)
	for key in _shop_catalog.keys():
		var adat = _shop_catalog.get(key)
		if adat is Dictionary:
			return (adat as Dictionary).duplicate(true)
	return {}

func get_all_shop_catalogs() -> Dictionary:
	return _shop_catalog.duplicate(true)

func get_recipes() -> Dictionary:
	return _recipes.duplicate(true)

func get_recipe_tuning() -> Dictionary:
	return _recipe_tuning.duplicate(true)

func get_public_opinion() -> float:
	return _public_opinion

func set_shop_catalog(cat: Dictionary, shop_id: String = ALAP_SHOP_ID) -> void:
	var sid = _norm_shop_id(shop_id)
	var user_shop: Dictionary = {}
	if cat is Dictionary and _is_kategoria_map(cat):
		user_shop[sid] = cat.duplicate(true)
	else:
		user_shop = _ensure_shop_map(cat)
	_shop_catalog = _merge_shop_catalogs(_defaults_shop, user_shop)

func set_recipes(rec: Dictionary) -> void:
	_recipes = _ensure_dict(rec, _defaults_recipes)

func set_recipe_tuning(tuning: Dictionary) -> void:
	_recipe_tuning = _ensure_dict(tuning, {})

func set_public_opinion(value: float) -> void:
	_public_opinion = clamp(float(value), -100.0, 100.0)

func load_all() -> void:
	_defaults_shop = _ensure_shop_map(_load_json(DEFAULT_SHOP_PATH))
	_defaults_recipes = _load_json(DEFAULT_RECIPES_PATH)
	_shop_catalog = _defaults_shop.duplicate(true)
	_recipes = _defaults_recipes.duplicate(true)
	_recipe_tuning = {}
	_public_opinion = 0.0
	var override_any = _load_json(USER_DATA_PATH)
	if override_any.is_empty():
		var base_count = _count_shop_items(_defaults_shop, ALAP_SHOP_ID)
		print("[SHOP_LOAD] base=%d user=0 final=%d source=%s:shop_catalog" % [base_count, base_count, USER_DATA_PATH])
		return
	var override_shop_any = override_any.get("shop_catalog", {})
	var override_rec_any = override_any.get("recipes", {})
	var override_tune_any = override_any.get("recipe_tuning", {})
	var override_opinion_any = override_any.get("public_opinion", 0.0)
	var override_shop = _ensure_shop_map(override_shop_any)
	var override_recipes = _ensure_dict(override_rec_any, _defaults_recipes)
	if not override_shop.is_empty():
		_shop_catalog = _merge_shop_catalogs(_defaults_shop, override_shop)
	if not override_recipes.is_empty():
		_recipes = override_recipes.duplicate(true)
	_recipe_tuning = _ensure_dict(override_tune_any, {})
	_public_opinion = clamp(float(override_opinion_any), -100.0, 100.0)
	var base_count = _count_shop_items(_defaults_shop, ALAP_SHOP_ID)
	var user_count = _count_shop_items(override_shop, ALAP_SHOP_ID)
	var final_count = _count_shop_items(_shop_catalog, ALAP_SHOP_ID)
	print("[SHOP_LOAD] base=%d user=%d final=%d source=%s:shop_catalog" % [base_count, user_count, final_count, USER_DATA_PATH])

func save_all() -> bool:
	var mentes: Dictionary = {
		"shop_catalog": _shop_catalog,
		"recipes": _recipes,
		"recipe_tuning": _recipe_tuning,
		"public_opinion": _public_opinion
	}
	var json_szoveg = JSON.stringify(mentes, "  ")
	var file = FileAccess.open(USER_DATA_PATH, FileAccess.WRITE)
	if file == null:
		print("[GameData] ❌ Nem sikerült megnyitni a mentési fájlt: %s" % USER_DATA_PATH)
		return false
	file.store_string(json_szoveg)
	file.close()
	print("[GameData] ✅ Mentve: %s" % USER_DATA_PATH)
	return true

func reset_to_defaults() -> void:
	_shop_catalog = _defaults_shop.duplicate(true)
	_recipes = _defaults_recipes.duplicate(true)
	_recipe_tuning = {}
	_public_opinion = 0.0
	if FileAccess.file_exists(USER_DATA_PATH):
		DirAccess.remove_absolute(USER_DATA_PATH)
	print("[GameData] 🔄 Visszaállítva az alapértelmezett adatokra.")

func export_debug() -> bool:
	return _save_to_path(DEBUG_EXPORT_PATH)

func import_user_file(path: String) -> bool:
	var cel = path.strip_edges()
	if cel == "":
		return false
	var adat = _load_json(cel)
	if adat.is_empty():
		return false
	var shop_any = adat.get("shop_catalog", {})
	var rec_any = adat.get("recipes", {})
	var tuning_any = adat.get("recipe_tuning", {})
	var opinion_any = adat.get("public_opinion", 0.0)
	var shop = _ensure_shop_map(shop_any)
	var rec = _ensure_dict(rec_any, _defaults_recipes)
	_shop_catalog = shop.duplicate(true)
	_recipes = rec.duplicate(true)
	_recipe_tuning = _ensure_dict(tuning_any, {})
	_public_opinion = clamp(float(opinion_any), -100.0, 100.0)
	print("[GameData] ✅ Importálva: %s" % cel)
	return true

func get_all_data() -> Dictionary:
	return {
		"shop_catalog": _shop_catalog.duplicate(true),
		"recipes": _recipes.duplicate(true),
		"recipe_tuning": _recipe_tuning.duplicate(true),
		"public_opinion": _public_opinion
	}

func _save_to_path(path: String) -> bool:
	var cel = path.strip_edges()
	if cel == "":
		return false
	var dir_path = cel.get_base_dir()
	var mk_err = DirAccess.make_dir_recursive_absolute(dir_path)
	if mk_err != OK and mk_err != ERR_ALREADY_EXISTS:
		print("[GameData] ❌ Könyvtár létrehozási hiba: %s (%d)" % [dir_path, mk_err])
		return false
	var file = FileAccess.open(cel, FileAccess.WRITE)
	if file == null:
		print("[GameData] ❌ Nem írható: %s" % cel)
		return false
	file.store_string(JSON.stringify(get_all_data(), "  "))
	file.close()
	print("[GameData] 📤 Exportálva: %s" % cel)
	return true

func _ensure_dict(value: Variant, fallback: Dictionary) -> Dictionary:
	if value is Dictionary:
		return value
	if fallback is Dictionary:
		return fallback.duplicate(true)
	return {}

func _ensure_shop_map(value: Variant) -> Dictionary:
	if value is Dictionary:
		var map = value as Dictionary
		var minden_array = true
		for v in map.values():
			if not (v is Array):
				minden_array = false
				break
		if minden_array:
			var becsomagolt: Dictionary = {}
			becsomagolt[_norm_shop_id(ALAP_SHOP_ID)] = map.duplicate(true)
			return becsomagolt
		var eredmeny: Dictionary = {}
		for key in map.keys():
			var adat = map.get(key, {})
			if adat is Dictionary:
				eredmeny[str(key)] = (adat as Dictionary).duplicate(true)
		return eredmeny
	if _defaults_shop is Dictionary and not _defaults_shop.is_empty():
		return _defaults_shop.duplicate(true)
	return {}

func _merge_shop_catalogs(base: Dictionary, user: Dictionary) -> Dictionary:
	var eredmeny: Dictionary = {}
	var base_map = _ensure_shop_map(base)
	for key in base_map.keys():
		var adat_any = base_map.get(key, {})
		if adat_any is Dictionary:
			eredmeny[str(key)] = (adat_any as Dictionary).duplicate(true)
	var user_map = _ensure_shop_map(user)
	for shop_id in user_map.keys():
		var user_shop_any = user_map.get(shop_id, {})
		if user_shop_any is Dictionary:
			var base_shop_any = eredmeny.get(shop_id, {})
			var base_shop = base_shop_any if base_shop_any is Dictionary else {}
			eredmeny[str(shop_id)] = _merge_shop_categories(base_shop, user_shop_any)
	return eredmeny

func _merge_shop_categories(base_shop: Dictionary, user_shop: Dictionary) -> Dictionary:
	var merged: Dictionary = base_shop.duplicate(true)
	for category_id in user_shop.keys():
		var user_list_any = user_shop.get(category_id, [])
		var user_list = user_list_any if user_list_any is Array else []
		if user_list.is_empty():
			if not merged.has(category_id):
				merged[category_id] = []
			continue
		var base_list_any = merged.get(category_id, [])
		var base_list = base_list_any if base_list_any is Array else []
		var uj_lista: Array = []
		var index_map: Dictionary = {}
		for elem_any in base_list:
			var elem = elem_any if elem_any is Dictionary else {}
			uj_lista.append(elem)
			var id = str(elem.get("id", "")).strip_edges()
			if id != "":
				index_map[id] = uj_lista.size() - 1
		for user_any in user_list:
			var user_elem = user_any if user_any is Dictionary else {}
			var user_id = str(user_elem.get("id", "")).strip_edges()
			if user_id == "":
				continue
			if index_map.has(user_id):
				var idx = int(index_map.get(user_id))
				uj_lista[idx] = user_elem
			else:
				uj_lista.append(user_elem)
		merged[category_id] = uj_lista
	return merged

func _load_json(path: String) -> Dictionary:
	var fajl = path.strip_edges()
	if fajl == "":
		return {}
	var file = FileAccess.open(fajl, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

func _norm_shop_id(shop_id: String) -> String:
	var sid = str(shop_id).strip_edges()
	if sid == "":
		return ALAP_SHOP_ID
	return sid

func _is_kategoria_map(value: Dictionary) -> bool:
	if value.is_empty():
		return true
	for v in value.values():
		if not (v is Array):
			return false
	return true

func _count_shop_items(shop_map: Dictionary, shop_id: String) -> int:
	var sid = _norm_shop_id(shop_id)
	if not shop_map.has(sid):
		return 0
	var bolt_any = shop_map.get(sid, {})
	var bolt = bolt_any if bolt_any is Dictionary else {}
	var osszeg = 0
	for lista_any in bolt.values():
		if lista_any is Array:
			osszeg += (lista_any as Array).size()
	return osszeg
