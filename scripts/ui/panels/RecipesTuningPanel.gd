extends Control

@export var title_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/TitleLabel"
@export var recipe_list_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Left/RecipesScroll/RecipesList"
@export var selected_title_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/SelectedTitle"
@export var toggle_enabled_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/ToggleEnabled"
@export var price_value_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PriceRow/PriceValue"
@export var price_minus_50_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PriceRow/BtnMinus50"
@export var price_minus_10_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PriceRow/BtnMinus10"
@export var price_plus_10_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PriceRow/BtnPlus10"
@export var price_plus_50_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PriceRow/BtnPlus50"
@export var portion_row_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionRow"
@export var portion_value_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionRow/PortionValue"
@export var portion_btn_200_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionRow/Btn200"
@export var portion_btn_300_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionRow/Btn300"
@export var portion_btn_500_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionRow/Btn500"
@export var portion_btn_1000_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionRow/Btn1000"
@export var ingredients_list_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/IngredientsList"
@export var popularity_bar_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityBar"
@export var popularity_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityLabel"
@export var popularity_effect_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityEffect"
@export var back_button_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/BackButton"

var _title_label: Label
var _recipe_list: VBoxContainer
var _selected_title: Label
var _toggle_enabled: CheckButton
var _price_value: Label
var _btn_minus_50: Button
var _btn_minus_10: Button
var _btn_plus_10: Button
var _btn_plus_50: Button
var _portion_row: HBoxContainer
var _portion_value: Label
var _btn_200: Button
var _btn_300: Button
var _btn_500: Button
var _btn_1000: Button
var _ingredients_list: VBoxContainer
var _popularity_bar: ProgressBar
var _popularity_label: Label
var _popularity_effect: Label
var _back_button: Button

var _selected_id: String = ""
var _ignore_ui: bool = false

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	var main_menu = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookMenu")
	if main_menu != null:
		main_menu.visible = false
	var book_panel = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if book_panel != null:
		book_panel.hide()
	_render_recipe_list()
	_select_default()
	var darab = _recipe_list.get_child_count() if _recipe_list != null else 0
	print("[RECIPE_TUNE] panel megnyitva: receptek=%d" % darab)
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_recipe_list = get_node_or_null(recipe_list_path) as VBoxContainer
	_selected_title = get_node_or_null(selected_title_path) as Label
	_toggle_enabled = get_node_or_null(toggle_enabled_path) as CheckButton
	_price_value = get_node_or_null(price_value_path) as Label
	_btn_minus_50 = get_node_or_null(price_minus_50_path) as Button
	_btn_minus_10 = get_node_or_null(price_minus_10_path) as Button
	_btn_plus_10 = get_node_or_null(price_plus_10_path) as Button
	_btn_plus_50 = get_node_or_null(price_plus_50_path) as Button
	_portion_row = get_node_or_null(portion_row_path) as HBoxContainer
	_portion_value = get_node_or_null(portion_value_path) as Label
	_btn_200 = get_node_or_null(portion_btn_200_path) as Button
	_btn_300 = get_node_or_null(portion_btn_300_path) as Button
	_btn_500 = get_node_or_null(portion_btn_500_path) as Button
	_btn_1000 = get_node_or_null(portion_btn_1000_path) as Button
	_ingredients_list = get_node_or_null(ingredients_list_path) as VBoxContainer
	_popularity_bar = get_node_or_null(popularity_bar_path) as ProgressBar
	_popularity_label = get_node_or_null(popularity_label_path) as Label
	_popularity_effect = get_node_or_null(popularity_effect_path) as Label
	_back_button = get_node_or_null(back_button_path) as Button

	if _title_label != null:
		_title_label.text = "🍳 Receptek szabályozása"
	if _toggle_enabled != null:
		_toggle_enabled.toggled.connect(_on_toggle_enabled)
	if _btn_minus_50 != null:
		_btn_minus_50.pressed.connect(func(): _on_price_delta(-50))
	if _btn_minus_10 != null:
		_btn_minus_10.pressed.connect(func(): _on_price_delta(-10))
	if _btn_plus_10 != null:
		_btn_plus_10.pressed.connect(func(): _on_price_delta(10))
	if _btn_plus_50 != null:
		_btn_plus_50.pressed.connect(func(): _on_price_delta(50))
	if _btn_200 != null:
		_btn_200.pressed.connect(func(): _on_portion_set(200))
	if _btn_300 != null:
		_btn_300.pressed.connect(func(): _on_portion_set(300))
	if _btn_500 != null:
		_btn_500.pressed.connect(func(): _on_portion_set(500))
	if _btn_1000 != null:
		_btn_1000.pressed.connect(func(): _on_portion_set(1000))
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)

func _render_recipe_list() -> void:
	if _recipe_list == null:
		return
	for child in _recipe_list.get_children():
		child.queue_free()
	var tuning = _tuning()
	if tuning == null:
		return
	var receptek = tuning.get_owned_recipes() if tuning.has_method("get_owned_recipes") else []
	for rid in receptek:
		var gomb = Button.new()
		gomb.text = _build_card_text(rid)
		gomb.alignment = HorizontalAlignment.LEFT
		gomb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gomb.pressed.connect(func(): _select_recipe(rid))
		_recipe_list.add_child(gomb)
	if receptek.is_empty():
		var ures = Label.new()
		ures.text = "Nincs megvásárolt recept."
		_recipe_list.add_child(ures)

func _build_card_text(recipe_id: String) -> String:
	var tuning = _tuning()
	if tuning == null:
		return str(recipe_id)
	var nev = tuning.get_recipe_label(recipe_id)
	var cfg = tuning.get_recipe_config(recipe_id)
	var enabled = bool(cfg.get("enabled", false))
	var ar = int(cfg.get("price_ft", 0))
	var tipus = tuning.get_recipe_type(recipe_id)
	var adag_szoveg = ""
	if tipus == "drink":
		adag_szoveg = "%d ml" % int(cfg.get("portion_ml", 0))
	else:
		var adagok = tuning.get_recipe_output_portions(recipe_id)
		adag_szoveg = "%d adag" % adagok
	var pont = tuning.get_recipe_popularity(recipe_id)
	var badge = tuning.get_popularity_badge(pont)
	var status = "AKTÍV" if enabled else "KIKAPCS"
	var kijelolt = "➡ " if recipe_id == _selected_id else ""
	return "%s%s\n%s | Ár: %d Ft | %s | Közvélemény: %s" % [kijelolt, nev, status, ar, adag_szoveg, badge]

func _select_default() -> void:
	if _selected_id != "":
		_refresh_details()
		return
	var tuning = _tuning()
	if tuning == null:
		return
	var receptek = tuning.get_owned_recipes() if tuning.has_method("get_owned_recipes") else []
	if not receptek.is_empty():
		_select_recipe(str(receptek[0]))
	else:
		_refresh_details()

func _select_recipe(recipe_id: String) -> void:
	_selected_id = recipe_id
	_refresh_details()
	_render_recipe_list()

func _refresh_details() -> void:
	var tuning = _tuning()
	if tuning == null:
		return
	if _selected_id == "":
		if _selected_title != null:
			_selected_title.text = "Nincs kiválasztott recept."
		return
	var cfg = tuning.get_recipe_config(_selected_id)
	_ignore_ui = true
	if _selected_title != null:
		_selected_title.text = "Recept: %s" % tuning.get_recipe_label(_selected_id)
	if _toggle_enabled != null:
		_toggle_enabled.button_pressed = bool(cfg.get("enabled", false))
	if _price_value != null:
		_price_value.text = "%d Ft" % int(cfg.get("price_ft", 0))
	var tipus = tuning.get_recipe_type(_selected_id)
	if _portion_row != null:
		_portion_row.visible = (tipus == "drink")
	if _portion_value != null:
		if tipus == "drink":
			_portion_value.text = "%d ml" % int(cfg.get("portion_ml", 0))
		else:
			_portion_value.text = "-"
	_render_ingredients(tuning)
	_frissit_kozelem(tuning)
	_ignore_ui = false

func _render_ingredients(tuning: Node) -> void:
	if _ingredients_list == null:
		return
	for child in _ingredients_list.get_children():
		child.queue_free()
	if _selected_id == "":
		return
	var lista = tuning.get_recipe_ingredients(_selected_id)
	if lista.is_empty():
		var ures = Label.new()
		ures.text = "Nincs hozzávaló."
		_ingredients_list.add_child(ures)
		return
	for ing_any in lista:
		var ing = ing_any if ing_any is Dictionary else {}
		_ingredients_list.add_child(_build_ingredient_row(ing))

func _build_ingredient_row(ing: Dictionary) -> Control:
	var sor = HBoxContainer.new()
	var id = str(ing.get("id", ""))
	var unit = str(ing.get("unit", "g"))
	var amount = int(ing.get("amount", 0))
	var cimke = Label.new()
	cimke.text = "%s: %d %s" % [_format_nev(id), amount, unit]
	cimke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cimke.size_flags_vertical = Control.SIZE_FILL
	sor.add_child(cimke)
	if unit == "pcs":
		for preset in [1, 2, 3]:
			var btn = Button.new()
			btn.text = "%d db" % preset
			btn.pressed.connect(func(): _set_ingredient_value(id, preset, unit))
			sor.add_child(btn)
	else:
		for step in [-50, 50, 100]:
			var btn = Button.new()
			btn.text = "%+d%s" % [step, unit]
			btn.pressed.connect(func(): _add_ingredient_delta(id, step, unit))
			sor.add_child(btn)
	return sor

func _frissit_kozelem(tuning: Node) -> void:
	if _selected_id == "":
		return
	var pont = tuning.get_recipe_popularity(_selected_id)
	if _popularity_bar != null:
		_popularity_bar.value = pont
	if _popularity_label != null:
		_popularity_label.text = tuning.get_popularity_label(pont)
	if _popularity_effect != null:
		_popularity_effect.text = tuning.get_popularity_effect_text(pont)

func _on_toggle_enabled(ertek: bool) -> void:
	if _ignore_ui or _selected_id == "":
		return
	var tuning = _tuning()
	if tuning != null:
		tuning.set_recipe_enabled(_selected_id, ertek)
	_refresh_details()
	_render_recipe_list()

func _on_price_delta(delta: int) -> void:
	if _selected_id == "":
		return
	var tuning = _tuning()
	if tuning == null:
		return
	var cfg = tuning.get_recipe_config(_selected_id)
	var uj = int(cfg.get("price_ft", 0)) + delta
	tuning.set_recipe_price(_selected_id, uj)
	_refresh_details()
	_render_recipe_list()

func _on_portion_set(ml: int) -> void:
	if _selected_id == "":
		return
	var tuning = _tuning()
	if tuning == null:
		return
	tuning.set_recipe_portion_ml(_selected_id, ml)
	_refresh_details()
	_render_recipe_list()

func _add_ingredient_delta(ingredient_id: String, delta: int, unit: String) -> void:
	if _selected_id == "":
		return
	var tuning = _tuning()
	if tuning == null:
		return
	var base = tuning.get_recipe_ingredients(_selected_id)
	var aktualis = 0
	for ing_any in base:
		var ing = ing_any if ing_any is Dictionary else {}
		if str(ing.get("id", "")) == ingredient_id:
			aktualis = int(ing.get("amount", 0))
			break
	var uj = max(aktualis + delta, 0)
	tuning.set_recipe_ingredient_amount(_selected_id, ingredient_id, uj, unit)
	_refresh_details()
	_render_recipe_list()

func _set_ingredient_value(ingredient_id: String, value: int, unit: String) -> void:
	if _selected_id == "":
		return
	var tuning = _tuning()
	if tuning == null:
		return
	tuning.set_recipe_ingredient_amount(_selected_id, ingredient_id, value, unit)
	_refresh_details()
	_render_recipe_list()

func _on_back_pressed() -> void:
	hide_panel()
	var book_panel = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if book_panel != null:
		if book_panel.has_method("show_panel"):
			book_panel.call("show_panel")
		else:
			book_panel.show()

func _format_nev(id: String) -> String:
	return id.capitalize().replace("_", " ")

func _tuning() -> Node:
	if typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		return RecipeTuningSystem1
	return get_tree().root.get_node_or_null("RecipeTuningSystem1")
