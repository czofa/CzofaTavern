extends Control

@export var category_select_path: NodePath = ^"Panel/VBox/Tabs/ShopTab/ShopMargin/ShopVBox/ShopHeader/CategorySelect"
@export var add_item_button_path: NodePath = ^"Panel/VBox/Tabs/ShopTab/ShopMargin/ShopVBox/ShopHeader/AddItemButton"
@export var shop_items_path: NodePath = ^"Panel/VBox/Tabs/ShopTab/ShopMargin/ShopVBox/ShopScroll/ShopItems"
@export var shop_status_path: NodePath = ^"Panel/VBox/Tabs/ShopTab/ShopMargin/ShopVBox/ShopStatus"

@export var add_recipe_button_path: NodePath = ^"Panel/VBox/Tabs/RecipesTab/RecipesMargin/RecipesVBox/RecipeHeader/AddRecipeButton"
@export var recipes_list_path: NodePath = ^"Panel/VBox/Tabs/RecipesTab/RecipesMargin/RecipesVBox/RecipesScroll/RecipesList"
@export var recipe_status_path: NodePath = ^"Panel/VBox/Tabs/RecipesTab/RecipesMargin/RecipesVBox/RecipeStatus"

@export var money_input_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/MoneyHBox/MoneyInput"
@export var money_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/MoneyHBox/MoneyButton"
@export var stock_item_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/StockHBox/StockItem"
@export var stock_qty_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/StockHBox/StockQty"
@export var stock_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/StockHBox/StockButton"
@export var recipe_unlock_input_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/RecipeHBox/RecipeId"
@export var recipe_unlock_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/RecipeHBox/RecipeButton"
@export var spawn_guest_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/GuestHBox/SpawnGuest"
@export var clear_guests_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/GuestHBox/ClearGuests"
@export var skip_hour_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/TimeHBox/SkipHour"
@export var skip_day_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/TimeHBox/SkipDay"
@export var reset_data_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/ResetData"
@export var dump_debug_button_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/DumpDebug"
@export var tools_status_path: NodePath = ^"Panel/VBox/Tabs/ToolsTab/ToolsMargin/ToolsVBox/ToolsStatus"

@export var save_button_path: NodePath = ^"Panel/VBox/Tabs/SaveTab/SaveMargin/SaveVBox/SaveButton"
@export var load_button_path: NodePath = ^"Panel/VBox/Tabs/SaveTab/SaveMargin/SaveVBox/LoadButton"
@export var export_button_path: NodePath = ^"Panel/VBox/Tabs/SaveTab/SaveMargin/SaveVBox/ExportButton"
@export var import_path_path: NodePath = ^"Panel/VBox/Tabs/SaveTab/SaveMargin/SaveVBox/ImportPath"
@export var import_button_path: NodePath = ^"Panel/VBox/Tabs/SaveTab/SaveMargin/SaveVBox/ImportButton"
@export var save_status_path: NodePath = ^"Panel/VBox/Tabs/SaveTab/SaveMargin/SaveVBox/SaveStatus"

@export var close_button_path: NodePath = ^"Panel/VBox/Header/CloseButton"
@export var reload_button_path: NodePath = ^"Panel/VBox/Header/ReloadButton"

var _category_select: OptionButton
var _add_item_button: Button
var _shop_items_box: VBoxContainer
var _shop_status: Label

var _add_recipe_button: Button
var _recipes_list: VBoxContainer
var _recipe_status: Label

var _money_input: LineEdit
var _money_button: Button
var _stock_item: LineEdit
var _stock_qty: LineEdit
var _stock_button: Button
var _recipe_unlock_input: LineEdit
var _recipe_unlock_button: Button
var _spawn_guest_button: Button
var _clear_guests_button: Button
var _skip_hour_button: Button
var _skip_day_button: Button
var _reset_data_button: Button
var _dump_debug_button: Button
var _tools_status: Label

var _save_button: Button
var _load_button: Button
var _export_button: Button
var _admin_import_path: LineEdit
var _import_button: Button
var _save_status: Label

var _close_button: Button
var _reload_button: Button

var _shop_data: Dictionary = {}
var _recipes_data: Dictionary = {}
var _active_category: String = ""

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	_reload_from_data()

func open_panel() -> void:
	visible = true
	_reload_from_data()

func close_panel() -> void:
	visible = false

func _cache_nodes() -> void:
	_category_select = get_node_or_null(category_select_path)
	_add_item_button = get_node_or_null(add_item_button_path)
	_shop_items_box = get_node_or_null(shop_items_path)
	_shop_status = get_node_or_null(shop_status_path)
	_add_recipe_button = get_node_or_null(add_recipe_button_path)
	_recipes_list = get_node_or_null(recipes_list_path)
	_recipe_status = get_node_or_null(recipe_status_path)
	_money_input = get_node_or_null(money_input_path)
	_money_button = get_node_or_null(money_button_path)
	_stock_item = get_node_or_null(stock_item_path)
	_stock_qty = get_node_or_null(stock_qty_path)
	_stock_button = get_node_or_null(stock_button_path)
	_recipe_unlock_input = get_node_or_null(recipe_unlock_input_path)
	_recipe_unlock_button = get_node_or_null(recipe_unlock_button_path)
	_spawn_guest_button = get_node_or_null(spawn_guest_button_path)
	_clear_guests_button = get_node_or_null(clear_guests_button_path)
	_skip_hour_button = get_node_or_null(skip_hour_button_path)
	_skip_day_button = get_node_or_null(skip_day_button_path)
	_reset_data_button = get_node_or_null(reset_data_button_path)
	_dump_debug_button = get_node_or_null(dump_debug_button_path)
	_tools_status = get_node_or_null(tools_status_path)
	_save_button = get_node_or_null(save_button_path)
	_load_button = get_node_or_null(load_button_path)
	_export_button = get_node_or_null(export_button_path)
	_admin_import_path = get_node_or_null(import_path_path)
	_import_button = get_node_or_null(import_button_path)
	_save_status = get_node_or_null(save_status_path)
	_close_button = get_node_or_null(close_button_path)
	_reload_button = get_node_or_null(reload_button_path)

func _connect_signals() -> void:
	if _close_button != null:
		var cb = Callable(self, "close_panel")
		if not _close_button.pressed.is_connected(cb):
			_close_button.pressed.connect(cb)
	if _reload_button != null:
		var cb_reload = Callable(self, "_reload_from_data")
		if not _reload_button.pressed.is_connected(cb_reload):
			_reload_button.pressed.connect(cb_reload)
	if _add_item_button != null:
		_add_item_button.pressed.connect(_on_add_shop_item)
	if _category_select != null:
		_category_select.item_selected.connect(_on_category_selected)
	if _add_recipe_button != null:
		_add_recipe_button.pressed.connect(_on_add_recipe)
	if _money_button != null:
		_money_button.pressed.connect(_on_money_send)
	if _stock_button != null:
		_stock_button.pressed.connect(_on_stock_add)
	if _recipe_unlock_button != null:
		_recipe_unlock_button.pressed.connect(_on_recipe_unlock)
	if _spawn_guest_button != null:
		_spawn_guest_button.pressed.connect(_on_spawn_guest)
	if _clear_guests_button != null:
		_clear_guests_button.pressed.connect(_on_clear_guests)
	if _skip_hour_button != null:
		_skip_hour_button.pressed.connect(_on_skip_hour)
	if _skip_day_button != null:
		_skip_day_button.pressed.connect(_on_skip_day)
	if _reset_data_button != null:
		_reset_data_button.pressed.connect(_on_reset_override)
	if _dump_debug_button != null:
		_dump_debug_button.pressed.connect(_on_dump_debug)
	if _save_button != null:
		_save_button.pressed.connect(_on_save_pressed)
	if _load_button != null:
		_load_button.pressed.connect(_on_reload_pressed)
	if _export_button != null:
		_export_button.pressed.connect(_on_export_pressed)
	if _import_button != null:
		_import_button.pressed.connect(_on_import_pressed)

func _reload_from_data() -> void:
	_shop_data = _load_shop_from_game()
	_recipes_data = _load_recipes_from_game()
	_build_category_options()
	_render_shop_items(_active_category)
	_render_recipes()
	_status("", _shop_status)
	_status("", _recipe_status)
	_status("", _save_status)

func _load_shop_from_game() -> Dictionary:
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("get_shop_catalog"):
			var adat_any = gd.call("get_shop_catalog")
			var adat = adat_any if adat_any is Dictionary else {}
			if not adat.is_empty():
				return adat
	return {}

func _load_recipes_from_game() -> Dictionary:
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("get_recipes"):
			var adat_any = gd.call("get_recipes")
			var adat = adat_any if adat_any is Dictionary else {}
			if not adat.is_empty():
				return adat
	return {}

func _build_category_options() -> void:
	if _category_select == null:
		return
	_category_select.clear()
	var kulcsok: Array = []
	for k in _shop_data.keys():
		kulcsok.append(k)
	kulcsok.sort()
	if kulcsok.is_empty():
		kulcsok = ["alapanyagok", "receptek", "magvak", "állatok", "eszközök", "kiszolgálóeszközök", "építőanyagok", "eladás"]
	_category_select.clear()
	for i in range(kulcsok.size()):
		var key = str(kulcsok[i])
		_category_select.add_item(_category_label(key), i)
		_category_select.set_item_metadata(i, key)
	if _active_category == "" and kulcsok.size() > 0:
		_active_category = str(kulcsok[0])
	_update_category_selection()

func _update_category_selection() -> void:
	if _category_select == null:
		return
	for i in range(_category_select.item_count):
		var meta = _category_select.get_item_metadata(i)
		if str(meta) == _active_category:
			_category_select.select(i)
			break

func _on_category_selected(index: int) -> void:
	_cache_current_shop_category()
	var meta = _category_select.get_item_metadata(index)
	_active_category = str(meta)
	_render_shop_items(_active_category)

func _cache_current_shop_category() -> void:
	if _active_category == "" or _shop_items_box == null:
		return
	var frissitett: Array = []
	for child in _shop_items_box.get_children():
		var adat = _collect_shop_item(child)
		if adat.is_empty():
			continue
		frissitett.append(adat)
	_shop_data[_active_category] = frissitett

func _render_shop_items(category: String) -> void:
	if _shop_items_box == null:
		return
	for child in _shop_items_box.get_children():
		child.queue_free()
	var lista_any = _shop_data.get(category, [])
	var lista = lista_any if lista_any is Array else []
	if lista.is_empty():
		_status("⚠️ Nincs termék ebben a kategóriában.", _shop_status)
	else:
		_status("", _shop_status)
	var index = 0
	for adat_any in lista:
		var adat = adat_any if adat_any is Dictionary else {}
		_shop_items_box.add_child(_build_shop_item_row(adat, index))
		index += 1

func _build_shop_item_row(adat: Dictionary, index: int) -> VBoxContainer:
	var doboz = VBoxContainer.new()
	doboz.name = "ShopItem_%d" % index
	doboz.add_theme_constant_override("separation", 2)

	var sor1 = HBoxContainer.new()
	var id_label = Label.new()
	id_label.text = "ID"
	sor1.add_child(id_label)
	var id_edit = LineEdit.new()
	id_edit.name = "IdEdit"
	id_edit.text = str(adat.get("id", ""))
	sor1.add_child(id_edit)
	var enable_check = CheckBox.new()
	enable_check.name = "EnabledCheck"
	enable_check.text = "Aktív"
	enable_check.button_pressed = bool(adat.get("enabled", true))
	sor1.add_child(enable_check)
	doboz.add_child(sor1)

	var sor2 = HBoxContainer.new()
	var nev_label = Label.new()
	nev_label.text = "Név"
	sor2.add_child(nev_label)
	var nev_edit = LineEdit.new()
	nev_edit.name = "NameEdit"
	nev_edit.text = str(adat.get("name", ""))
	sor2.add_child(nev_edit)
	doboz.add_child(sor2)

	var sor3 = HBoxContainer.new()
	var ar_label = Label.new()
	ar_label.text = "Ár"
	sor3.add_child(ar_label)
	var ar_edit = LineEdit.new()
	ar_edit.name = "PriceEdit"
	ar_edit.text = str(adat.get("price", 0))
	sor3.add_child(ar_edit)
	var gramm_label = Label.new()
	gramm_label.text = "Csomag (g)"
	sor3.add_child(gramm_label)
	var gramm_edit = LineEdit.new()
	gramm_edit.name = "PackEdit"
	gramm_edit.text = str(adat.get("pack_g", 0))
	sor3.add_child(gramm_edit)
	doboz.add_child(sor3)

	var sor4 = HBoxContainer.new()
	var type_label = Label.new()
	type_label.text = "Típus"
	sor4.add_child(type_label)
	var type_edit = LineEdit.new()
	type_edit.name = "TypeEdit"
	type_edit.text = str(adat.get("type", ""))
	sor4.add_child(type_edit)
	var recipe_label = Label.new()
	recipe_label.text = "Recept ID"
	sor4.add_child(recipe_label)
	var recipe_edit = LineEdit.new()
	recipe_edit.name = "RecipeIdEdit"
	recipe_edit.text = str(adat.get("recipe_id", ""))
	sor4.add_child(recipe_edit)
	doboz.add_child(sor4)

	var torles = Button.new()
	torles.text = "Törlés"
	torles.pressed.connect(_on_remove_shop_item.bind(doboz))
	doboz.add_child(torles)

	var sep = HSeparator.new()
	doboz.add_child(sep)
	return doboz

func _collect_shop_item(container: Node) -> Dictionary:
	var adat: Dictionary = {}
	if container == null:
		return adat
	var id_edit = container.get_node_or_null("IdEdit")
	var nev_edit = container.get_node_or_null("NameEdit")
	var ar_edit = container.get_node_or_null("PriceEdit")
	var pack_edit = container.get_node_or_null("PackEdit")
	var type_edit = container.get_node_or_null("TypeEdit")
	var recipe_edit = container.get_node_or_null("RecipeIdEdit")
	var enabled_check = container.get_node_or_null("EnabledCheck")
	var id = ""
	if id_edit is LineEdit:
		id = str(id_edit.text).strip_edges()
	if id == "":
		return {}
	adat["id"] = id
	adat["name"] = str(nev_edit.text) if nev_edit is LineEdit else id
	adat["price"] = int(str(ar_edit.text)) if ar_edit is LineEdit else 0
	adat["pack_g"] = int(str(pack_edit.text)) if pack_edit is LineEdit else 0
	adat["type"] = str(type_edit.text) if type_edit is LineEdit else ""
	adat["recipe_id"] = str(recipe_edit.text) if recipe_edit is LineEdit else ""
	adat["enabled"] = bool(enabled_check.button_pressed) if enabled_check is CheckBox else true
	return adat

func _on_add_shop_item() -> void:
	_cache_current_shop_category()
	var uj: Dictionary = {
		"id": "uj_termek_%d" % int(Time.get_ticks_msec() % 1000),
		"name": "Új termék",
		"price": 0,
		"pack_g": 0,
		"type": "ingredient",
		"recipe_id": "",
		"enabled": true
	}
	var lista_any = _shop_data.get(_active_category, [])
	var lista = lista_any if lista_any is Array else []
	lista.append(uj)
	_shop_data[_active_category] = lista
	_render_shop_items(_active_category)

func _on_remove_shop_item(container: Node) -> void:
	if container == null or _shop_items_box == null:
		return
	container.queue_free()
	_cache_current_shop_category()
	_render_shop_items(_active_category)

func _category_label(key: String) -> String:
	match key:
		"alapanyagok":
			return "🥕 Alapanyagok"
		"receptek":
			return "📜 Receptek"
		"magvak":
			return "🌱 Magvak"
		"állatok":
			return "🐄 Állatok"
		"eszközök":
			return "🪓 Eszközök"
		"kiszolgálóeszközök":
			return "🍽️ Kiszolgálóeszközök"
		"építőanyagok":
			return "🧱 Építőanyagok"
		"eladás":
			return "💰 Eladás"
		_:
			return key

# -----------------------------------------------------------
# Receptek
# -----------------------------------------------------------

func _render_recipes() -> void:
	if _recipes_list == null:
		return
	for child in _recipes_list.get_children():
		child.queue_free()
	for rid in _recipes_data.keys():
		var adat_any = _recipes_data.get(rid, {})
		var adat = adat_any if adat_any is Dictionary else {}
		_recipes_list.add_child(_build_recipe_entry(adat))
	_status("", _recipe_status)
	if _recipes_data.is_empty():
		_status("⚠️ Nincs recept adat.", _recipe_status)

func _build_recipe_entry(adat: Dictionary) -> VBoxContainer:
	var doboz = VBoxContainer.new()
	doboz.name = "Recipe_%s" % str(adat.get("id", ""))
	doboz.add_theme_constant_override("separation", 2)

	var sor1 = HBoxContainer.new()
	var id_label = Label.new()
	id_label.text = "ID"
	sor1.add_child(id_label)
	var id_edit = LineEdit.new()
	id_edit.name = "IdEdit"
	id_edit.text = str(adat.get("id", ""))
	sor1.add_child(id_edit)
	var nev_label = Label.new()
	nev_label.text = "Név"
	sor1.add_child(nev_label)
	var nev_edit = LineEdit.new()
	nev_edit.name = "NameEdit"
	nev_edit.text = str(adat.get("name", ""))
	sor1.add_child(nev_edit)
	doboz.add_child(sor1)

	var sor2 = HBoxContainer.new()
	var type_label = Label.new()
	type_label.text = "Típus"
	sor2.add_child(type_label)
	var type_edit = LineEdit.new()
	type_edit.name = "TypeEdit"
	type_edit.text = str(adat.get("type", ""))
	sor2.add_child(type_edit)
	var price_label = Label.new()
	price_label.text = "Eladási ár"
	sor2.add_child(price_label)
	var price_edit = LineEdit.new()
	price_edit.name = "SellPriceEdit"
	price_edit.text = str(adat.get("sell_price", 0))
	sor2.add_child(price_edit)
	doboz.add_child(sor2)

	var sor3 = HBoxContainer.new()
	var out_label = Label.new()
	out_label.text = "Adag/forgatás"
	sor3.add_child(out_label)
	var out_edit = LineEdit.new()
	out_edit.name = "OutputEdit"
	out_edit.text = str(adat.get("output_portions", 1))
	sor3.add_child(out_edit)
	var serve_check = CheckBox.new()
	serve_check.name = "ServeCheck"
	serve_check.text = "Azonnal tálalható"
	serve_check.button_pressed = bool(adat.get("serve_direct", false))
	sor3.add_child(serve_check)
	var unlocked_check = CheckBox.new()
	unlocked_check.name = "UnlockedCheck"
	unlocked_check.text = "Feloldva"
	unlocked_check.button_pressed = bool(adat.get("unlocked", false))
	sor3.add_child(unlocked_check)
	doboz.add_child(sor3)

	var hozzavalo_label = Label.new()
	hozzavalo_label.text = "Hozzávalók"
	doboz.add_child(hozzavalo_label)

	var ing_box = VBoxContainer.new()
	ing_box.name = "IngredientsBox"
	var ing_any = adat.get("ingredients", [])
	var ing_list = ing_any if ing_any is Array else []
	for ing in ing_list:
		ing_box.add_child(_build_ingredient_row(ing))
	doboz.add_child(ing_box)

	var add_ing = Button.new()
	add_ing.text = "Hozzávaló +"
	add_ing.pressed.connect(_on_add_ingredient.bind(ing_box))
	doboz.add_child(add_ing)

	var torles = Button.new()
	torles.text = "Recept törlése"
	torles.pressed.connect(_on_remove_recipe.bind(doboz))
	doboz.add_child(torles)

	var sep = HSeparator.new()
	doboz.add_child(sep)
	return doboz

func _build_ingredient_row(adat: Dictionary) -> HBoxContainer:
	var sor = HBoxContainer.new()
	sor.name = "IngredientRow"
	var id_edit = LineEdit.new()
	id_edit.name = "ItemIdEdit"
	id_edit.placeholder_text = "item_id"
	id_edit.text = str(adat.get("item_id", ""))
	sor.add_child(id_edit)
	var gramm_edit = LineEdit.new()
	gramm_edit.name = "GramEdit"
	gramm_edit.placeholder_text = "g"
	gramm_edit.text = str(adat.get("g", 0))
	sor.add_child(gramm_edit)
	var torles = Button.new()
	torles.text = "X"
	torles.pressed.connect(_on_remove_ingredient.bind(sor))
	sor.add_child(torles)
	return sor

func _on_add_recipe() -> void:
	var uj: Dictionary = {
		"id": "uj_recept_%d" % int(Time.get_ticks_msec() % 1000),
		"name": "Új recept",
		"type": "food",
		"ingredients": [],
		"output_portions": 1,
		"sell_price": 0,
		"serve_direct": false,
		"unlocked": false
	}
	_recipes_data[uj.get("id", "")] = uj
	_render_recipes()

func _on_remove_recipe(doboz: Node) -> void:
	if doboz == null or _recipes_list == null:
		return
	var id_edit = doboz.get_node_or_null("IdEdit")
	var rid = ""
	if id_edit is LineEdit:
		rid = str(id_edit.text).strip_edges()
	doboz.queue_free()
	if rid != "" and _recipes_data.has(rid):
		_recipes_data.erase(rid)

func _on_add_ingredient(ing_box: Node) -> void:
	if ing_box == null:
		return
	ing_box.add_child(_build_ingredient_row({"item_id": "", "g": 0}))

func _on_remove_ingredient(sor: Node) -> void:
	if sor != null:
		sor.queue_free()

func _collect_recipes_from_ui() -> Dictionary:
	var uj: Dictionary = {}
	if _recipes_list == null:
		return uj
	for doboz in _recipes_list.get_children():
		var adat = _collect_recipe_entry(doboz)
		if adat.is_empty():
			continue
		uj[adat.get("id", "")] = adat
	return uj

func _collect_recipe_entry(doboz: Node) -> Dictionary:
	var adat: Dictionary = {}
	if doboz == null:
		return adat
	var id_edit = doboz.get_node_or_null("IdEdit")
	var nev_edit = doboz.get_node_or_null("NameEdit")
	var type_edit = doboz.get_node_or_null("TypeEdit")
	var price_edit = doboz.get_node_or_null("SellPriceEdit")
	var out_edit = doboz.get_node_or_null("OutputEdit")
	var serve_check = doboz.get_node_or_null("ServeCheck")
	var unlocked_check = doboz.get_node_or_null("UnlockedCheck")
	var rid = ""
	if id_edit is LineEdit:
		rid = str(id_edit.text).strip_edges()
	if rid == "":
		return {}
	adat["id"] = rid
	adat["name"] = str(nev_edit.text) if nev_edit is LineEdit else rid
	adat["type"] = str(type_edit.text) if type_edit is LineEdit else ""
	adat["sell_price"] = int(str(price_edit.text)) if price_edit is LineEdit else 0
	adat["output_portions"] = int(str(out_edit.text)) if out_edit is LineEdit else 1
	adat["serve_direct"] = bool(serve_check.button_pressed) if serve_check is CheckBox else false
	adat["unlocked"] = bool(unlocked_check.button_pressed) if unlocked_check is CheckBox else false
	var ing_box = doboz.get_node_or_null("IngredientsBox")
	var ing_lista: Array = []
	if ing_box is VBoxContainer:
		for sor in ing_box.get_children():
			var ing = _collect_ingredient_row(sor)
			if ing.is_empty():
				continue
			ing_lista.append(ing)
	adat["ingredients"] = ing_lista
	return adat

func _collect_ingredient_row(sor: Node) -> Dictionary:
	var adat: Dictionary = {}
	if sor == null:
		return adat
	var id_edit = sor.get_node_or_null("ItemIdEdit")
	var g_edit = sor.get_node_or_null("GramEdit")
	var iid = ""
	if id_edit is LineEdit:
		iid = str(id_edit.text).strip_edges()
	if iid == "":
		return {}
	adat["item_id"] = iid
	adat["g"] = int(str(g_edit.text)) if g_edit is LineEdit else 0
	return adat

# -----------------------------------------------------------
# Mentés / import
# -----------------------------------------------------------

func _on_save_pressed() -> void:
	_cache_current_shop_category()
	_recipes_data = _collect_recipes_from_ui()
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("set_shop_catalog"):
			gd.call("set_shop_catalog", _shop_data)
		if gd.has_method("set_recipes"):
			gd.call("set_recipes", _recipes_data)
		var ok = false
		if gd.has_method("save_all"):
			ok = gd.call("save_all")
		if ok:
			_status("✅ Admin adatok mentve.", _save_status)
			_apply_runtime_reload()
		else:
			_status("❌ Mentés sikertelen.", _save_status)

func _on_reload_pressed() -> void:
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("load_all"):
			gd.call("load_all")
	_reload_from_data()
	_apply_runtime_reload()
	_status("🔄 Újratöltve a mentett adatok.", _save_status)

func _on_export_pressed() -> void:
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("export_debug"):
			var ok = gd.call("export_debug")
			if ok:
				_status("📤 Exportálva res://debug_exports/game_data_export.json", _save_status)
			else:
				_status("❌ Export sikertelen.", _save_status)

func _on_import_pressed() -> void:
	if _admin_import_path == null:
		return
	var path = str(_admin_import_path.text).strip_edges()
	if path == "":
		_status("⚠️ Adj meg import útvonalat.", _save_status)
		return
	if not has_node("/root/GameData1"):
		_status("❌ GameData1 nem elérhető.", _save_status)
		return
	var gd = get_node("/root/GameData1")
	if not gd.has_method("import_user_file"):
		_status("❌ Import nem támogatott.", _save_status)
		return
	var ok = gd.call("import_user_file", path)
	if ok:
		gd.call("save_all")
		_reload_from_data()
		_apply_runtime_reload()
		_status("📥 Import sikeres: %s" % path, _save_status)
	else:
		_status("❌ Import sikertelen: %s" % path, _save_status)

func _apply_runtime_reload() -> void:
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen != null and kitchen.has_method("reload_from_game_data"):
		kitchen.call("reload_from_game_data")
	var guest_spawner = _find_guest_spawner()
	if guest_spawner != null and guest_spawner.has_method("_epit_rendeles_lista"):
		guest_spawner.call("_epit_rendeles_lista")

func _status(uzenet: String, label: Label) -> void:
	if label != null:
		label.text = uzenet

# -----------------------------------------------------------
# Tools
# -----------------------------------------------------------

func _on_money_send() -> void:
	var osszeg = int(str(_money_input.text)) if _money_input is LineEdit else 0
	if osszeg == 0:
		_status("⚠️ Adj meg nem nulla összeget.", _tools_status)
		return
	var eco = get_tree().root.get_node_or_null("EconomySystem1")
	if eco != null and eco.has_method("add_money"):
		eco.call("add_money", osszeg, "Admin panel")
		_status("💰 Pénz hozzáadva: %d" % osszeg, _tools_status)
		return
	_status("ℹ️ EconomySystem1 nem elérhető.", _tools_status)

func _on_stock_add() -> void:
	var id = str(_stock_item.text).strip_edges() if _stock_item is LineEdit else ""
	var qty = int(str(_stock_qty.text)) if _stock_qty is LineEdit else 0
	if id == "" or qty == 0:
		_status("⚠️ Adj meg azonosítót és mennyiséget.", _tools_status)
		return
	var stock = get_tree().root.get_node_or_null("StockSystem1")
	if stock != null and stock.has_method("add_unbooked"):
		stock.call("add_unbooked", id, qty, 0)
		_status("📦 Könyveletlen készlet növelve: %s (%d)" % [id, qty], _tools_status)
		return
	_status("ℹ️ StockSystem1 nem elérhető.", _tools_status)

func _on_recipe_unlock() -> void:
	var rid = str(_recipe_unlock_input.text).strip_edges() if _recipe_unlock_input is LineEdit else ""
	if rid == "":
		_status("⚠️ Adj meg recept ID-t.", _tools_status)
		return
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen != null and kitchen.has_method("unlock_recipe"):
		kitchen.call("unlock_recipe", rid)
		_status("📜 Feloldva: %s" % rid, _tools_status)
		return
	_status("ℹ️ KitchenSystem1 nem elérhető.", _tools_status)

func _on_spawn_guest() -> void:
	var spawner = _find_guest_spawner()
	if spawner != null and spawner.has_method("_spawn_guest"):
		spawner.call("_spawn_guest")
		_status("🙋 Vendég spawnolva.", _tools_status)
		return
	_status("ℹ️ GuestSpawner nem található.", _tools_status)

func _on_clear_guests() -> void:
	var spawner = _find_guest_spawner()
	if spawner == null:
		_status("ℹ️ GuestSpawner nem érhető el.", _tools_status)
		return
	var lista_any = spawner.get("_aktiv_vendegek") if spawner.has("_aktiv_vendegek") else []
	var lista = lista_any if lista_any is Array else []
	for g in lista:
		if g is Node:
			g.queue_free()
	_status("🧹 Vendégek törölve (ha voltak).", _tools_status)

func _on_skip_hour() -> void:
	var time = get_tree().root.get_node_or_null("TimeSystem1")
	if time != null and time.has_method("add_minutes"):
		time.call("add_minutes", 60.0)
		_status("⏩ +1 óra", _tools_status)
		return
	_status("ℹ️ Idő rendszer nem elérhető vagy nem támogatja.", _tools_status)

func _on_skip_day() -> void:
	var time = get_tree().root.get_node_or_null("TimeSystem1")
	if time != null:
		if time.has_method("start_next_day"):
			time.call("start_next_day")
			_status("📅 Következő nap", _tools_status)
			return
	_status("ℹ️ Idő rendszer nem érhető el.", _tools_status)

func _on_reset_override() -> void:
	if has_node("/root/GameData1"):
		var gd = get_node("/root/GameData1")
		if gd.has_method("reset_to_defaults"):
			gd.call("reset_to_defaults")
			gd.call("save_all")
			_reload_from_data()
			_apply_runtime_reload()
			_status("🔁 Override törölve, visszaállítva.", _tools_status)
			return
	_status("ℹ️ GameData1 nem érhető el.", _tools_status)

func _on_dump_debug() -> void:
	if not has_node("/root/GameData1"):
		_status("ℹ️ GameData1 nem érhető el.", _tools_status)
		return
	var gd = get_node("/root/GameData1")
	var adat_any = gd.call("get_all_data") if gd.has_method("get_all_data") else {}
	var adat = adat_any if adat_any is Dictionary else {}
	print("[ADMIN DEBUG] Bolt kategóriák: %d, Receptek: %d" % [adat.get("shop_catalog", {}).size() if adat.has("shop_catalog") else 0, adat.get("recipes", {}).size() if adat.has("recipes") else 0])
	_status("📝 Debug dump konzolra írva.", _tools_status)

func _find_guest_spawner() -> Node:
	var jeloltek = [
		"/root/Main/WorldRoot/TavernWorld/GuestSpawner",
		"/root/Main/TavernWorld/GuestSpawner",
		"/root/TavernWorld/GuestSpawner"
	]
	for path in jeloltek:
		var node = get_node_or_null(path)
		if node != null:
			return node
	return get_tree().root.find_child("GuestSpawner", true, false)
