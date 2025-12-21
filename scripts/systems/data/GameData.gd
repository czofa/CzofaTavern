extends Node
class_name GameData
# Autoload neve: GameData1

const DEFAULT_SHOP_PATH = "res://data/default_shop.json"
const DEFAULT_RECIPES_PATH = "res://data/default_recipes.json"
const USER_DATA_PATH = "user://game_data.json"
const DEBUG_EXPORT_PATH = "res://debug_exports/game_data_export.json"

var _shop_catalog: Dictionary = {}
var _recipes: Dictionary = {}
var _defaults_shop: Dictionary = {}
var _defaults_recipes: Dictionary = {}

func _ready() -> void:
	load_all()

func get_shop_catalog() -> Dictionary:
	return _shop_catalog.duplicate(true)

func get_recipes() -> Dictionary:
	return _recipes.duplicate(true)

func set_shop_catalog(cat: Dictionary) -> void:
	_shop_catalog = _ensure_dict(cat, _defaults_shop)

func set_recipes(rec: Dictionary) -> void:
	_recipes = _ensure_dict(rec, _defaults_recipes)

func load_all() -> void:
	_defaults_shop = _load_json(DEFAULT_SHOP_PATH)
	_defaults_recipes = _load_json(DEFAULT_RECIPES_PATH)
	_shop_catalog = _defaults_shop.duplicate(true)
	_recipes = _defaults_recipes.duplicate(true)
	var override_any = _load_json(USER_DATA_PATH)
	if override_any.is_empty():
		return
	var override_shop_any = override_any.get("shop_catalog", {})
	var override_rec_any = override_any.get("recipes", {})
	var override_shop = _ensure_dict(override_shop_any, _defaults_shop)
	var override_recipes = _ensure_dict(override_rec_any, _defaults_recipes)
	if not override_shop.is_empty():
		_shop_catalog = override_shop.duplicate(true)
	if not override_recipes.is_empty():
		_recipes = override_recipes.duplicate(true)

func save_all() -> bool:
	var mentes: Dictionary = {
		"shop_catalog": _shop_catalog,
		"recipes": _recipes
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
	var shop = _ensure_dict(shop_any, _defaults_shop)
	var rec = _ensure_dict(rec_any, _defaults_recipes)
	_shop_catalog = shop.duplicate(true)
	_recipes = rec.duplicate(true)
	print("[GameData] ✅ Importálva: %s" % cel)
	return true

func get_all_data() -> Dictionary:
	return {
		"shop_catalog": _shop_catalog.duplicate(true),
		"recipes": _recipes.duplicate(true)
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
