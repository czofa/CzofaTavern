extends Control

@export var title_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/TitleLabel"
@export var panel_container_path: NodePath = ^"PanelContainer"
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
@export var portions_info_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PortionsInfo"
@export var ingredients_list_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/IngredientsList"
@export var save_button_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/SaveButton"
@export var popularity_bar_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityBar"
@export var popularity_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityLabel"
@export var popularity_effect_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityEffect"
@export var back_button_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/BackButton"

var _title_label: Label
var _panel_container: PanelContainer
var _recipe_list: VBoxContainer
var _selected_title: Label
var _ingredients_list: VBoxContainer
var _portion_info_label: Label
var _popularity_bar: ProgressBar
var _popularity_label: Label
var _popularity_effect: Label
var _back_button: Button
var _save_button: Button

var _selected_recipe_id: String = ""
var _pending_ingredients: Dictionary = {}
var _selected_type: String = ""

var _layout_logolva: bool = false

func _ready() -> void:
	_cache_nodes()
	_relayout()
	var viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)
	hide()

func show_panel() -> void:
	var main_menu = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookMenu")
	if main_menu != null:
		main_menu.visible = false
	var book_panel = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if book_panel != null:
		book_panel.hide()
	_render_recipe_list()
	_frissit_kozelem()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_panel_container = get_node_or_null(panel_container_path) as PanelContainer
	_recipe_list = get_node_or_null(recipe_list_path) as VBoxContainer
	_selected_title = get_node_or_null(selected_title_path) as Label
	_ingredients_list = get_node_or_null(ingredients_list_path) as VBoxContainer
	_portion_info_label = get_node_or_null(portions_info_path) as Label
	_popularity_bar = get_node_or_null(popularity_bar_path) as ProgressBar
	_popularity_label = get_node_or_null(popularity_label_path) as Label
	_popularity_effect = get_node_or_null(popularity_effect_path) as Label
	_back_button = get_node_or_null(back_button_path) as Button
	_save_button = get_node_or_null(save_button_path) as Button

	var toggle_enabled = get_node_or_null(toggle_enabled_path) as CheckButton
	var price_value = get_node_or_null(price_value_path) as Label
	var btn_minus_50 = get_node_or_null(price_minus_50_path) as Button
	var btn_minus_10 = get_node_or_null(price_minus_10_path) as Button
	var btn_plus_10 = get_node_or_null(price_plus_10_path) as Button
	var btn_plus_50 = get_node_or_null(price_plus_50_path) as Button
	var portion_row = get_node_or_null(portion_row_path) as HBoxContainer
	var portion_value = get_node_or_null(portion_value_path) as Label
	var btn_200 = get_node_or_null(portion_btn_200_path) as Button
	var btn_300 = get_node_or_null(portion_btn_300_path) as Button
	var btn_500 = get_node_or_null(portion_btn_500_path) as Button
	var btn_1000 = get_node_or_null(portion_btn_1000_path) as Button

	if _title_label != null:
		_title_label.text = "🍳 Receptek szabályozása"
	if _selected_title != null:
		_selected_title.visible = true
		_selected_title.text = "Recept: -"
	if toggle_enabled != null:
		toggle_enabled.visible = false
	if price_value != null:
		price_value.visible = false
	if btn_minus_50 != null:
		btn_minus_50.visible = false
	if btn_minus_10 != null:
		btn_minus_10.visible = false
	if btn_plus_10 != null:
		btn_plus_10.visible = false
	if btn_plus_50 != null:
		btn_plus_50.visible = false
	if portion_row != null:
		portion_row.visible = false
	if portion_value != null:
		portion_value.visible = false
	if btn_200 != null:
		btn_200.visible = false
	if btn_300 != null:
		btn_300.visible = false
	if btn_500 != null:
		btn_500.visible = false
	if btn_1000 != null:
		btn_1000.visible = false
	if _ingredients_list != null:
		_ingredients_list.visible = true
	if _portion_info_label != null:
		_portion_info_label.text = "Készletből: 0 adag"
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)
	if _save_button != null:
		_save_button.pressed.connect(_on_save_pressed)

func _relayout() -> void:
	if _panel_container == null:
		return
	var viewport_size = get_viewport_rect().size
	var panel_size = Vector2(
		min(1100.0, max(0.0, viewport_size.x - 40.0)),
		min(650.0, max(0.0, viewport_size.y - 40.0))
	)
	var panel_pos = (viewport_size - panel_size) / 2.0
	_panel_container.position = panel_pos
	_panel_container.size = panel_size
	if not _layout_logolva:
		print("[RECIPE_UI] viewport=%s, panel_size=%s, panel_pos=%s" % [viewport_size, panel_size, panel_pos])
		_layout_logolva = true

func _on_viewport_size_changed() -> void:
	_relayout()

func _render_recipe_list() -> void:
	if _recipe_list == null:
		return
	for child in _recipe_list.get_children():
		child.queue_free()
	var tuning = _tuning()
	var receptek = _owned_recipes()
	for rid in receptek:
		_recipe_list.add_child(_build_recipe_card(rid, tuning))
	if receptek.is_empty():
		var ures = Label.new()
		ures.text = "Nincs megvásárolt recept."
		_recipe_list.add_child(ures)
	if _selected_recipe_id != "" and receptek.has(_selected_recipe_id):
		_render_selected_recipe()
	elif _selected_recipe_id != "" and not receptek.has(_selected_recipe_id):
		_selected_recipe_id = ""
		_pending_ingredients.clear()
		_render_selected_recipe()

func _build_recipe_card(recipe_id: String, tuning: Node) -> Control:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 140)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var root = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	var nev = recipe_id
	var tipus = "food"
	var cfg: Dictionary = {}
	if tuning != null:
		nev = tuning.get_recipe_label(recipe_id)
		tipus = tuning.get_recipe_type(recipe_id)
		cfg = tuning.get_recipe_config(recipe_id)

	var cimke = Label.new()
	cimke.text = "🍽️ %s" % nev
	root.add_child(cimke)

	var status = Label.new()
	var aktiv = bool(cfg.get("enabled", false))
	status.text = "Állapot: %s" % ("Aktív" if aktiv else "Kikapcsolva")
	root.add_child(status)

	var toggle = CheckButton.new()
	toggle.text = "Árulom ezt"
	toggle.button_pressed = aktiv
	toggle.toggled.connect(func(ertek: bool): _on_toggle_enabled(recipe_id, ertek))
	root.add_child(toggle)

	var price_row = HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 6)
	var price_label = Label.new()
	price_label.text = "Ár: %d Ft" % int(cfg.get("price_ft", 0))
	price_row.add_child(price_label)
	price_row.add_child(_build_price_button(recipe_id, -50, "-50"))
	price_row.add_child(_build_price_button(recipe_id, -10, "-10"))
	price_row.add_child(_build_price_button(recipe_id, 10, "+10"))
	price_row.add_child(_build_price_button(recipe_id, 50, "+50"))
	root.add_child(price_row)

	var portion_row = HBoxContainer.new()
	portion_row.add_theme_constant_override("separation", 6)
	var portion_label = Label.new()
	if tipus == "drink":
		var ml = int(cfg.get("portion_ml", 0))
		portion_label.text = "Adag: %d ml" % ml
		portion_row.add_child(portion_label)
		portion_row.add_child(_build_portion_ml_button(recipe_id, 200, "200 ml"))
		portion_row.add_child(_build_portion_ml_button(recipe_id, 300, "300 ml"))
		portion_row.add_child(_build_portion_ml_button(recipe_id, 500, "500 ml"))
		portion_row.add_child(_build_portion_ml_button(recipe_id, 1000, "1000 ml"))
	else:
		var g = int(cfg.get("portion_g", 0))
		portion_label.text = "Adag: %d g" % g
		portion_row.add_child(portion_label)
		portion_row.add_child(_build_portion_g_button(recipe_id, -50, "-50 g"))
		portion_row.add_child(_build_portion_g_button(recipe_id, 50, "+50 g"))
		portion_row.add_child(_build_portion_g_button(recipe_id, 100, "+100 g"))
	root.add_child(portion_row)

	var ingredients_label = Label.new()
	var lines: Array = []
	if tuning != null and tuning.has_method("get_recipe_display_lines"):
		var lines_any = tuning.call("get_recipe_display_lines", recipe_id)
		lines = lines_any if lines_any is Array else []
	if lines.is_empty():
		lines.append("Hiányzó recept adat")
	var rovid: Array = []
	for i in range(min(2, lines.size())):
		rovid.append(str(lines[i]))
	ingredients_label.text = "Hozzávalók: %s" % " | ".join(rovid)
	ingredients_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(ingredients_label)

	var reszletek_sor = HBoxContainer.new()
	reszletek_sor.add_theme_constant_override("separation", 6)
	var reszletek = Button.new()
	reszletek.text = "Részletek"
	reszletek.pressed.connect(func(): _select_recipe(recipe_id))
	reszletek_sor.add_child(reszletek)
	root.add_child(reszletek_sor)

	return card

func _build_price_button(recipe_id: String, delta: int, label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.pressed.connect(func(): _on_price_delta(recipe_id, delta))
	return btn

func _build_portion_ml_button(recipe_id: String, ml: int, label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.pressed.connect(func(): _on_portion_set_ml(recipe_id, ml))
	return btn

func _build_portion_g_button(recipe_id: String, delta: int, label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.pressed.connect(func(): _on_portion_delta_g(recipe_id, delta))
	return btn

func _frissit_kozelem() -> void:
	var tuning = _tuning()
	if tuning == null:
		return
	var opinio = float(tuning.get_public_opinion())
	if _popularity_bar != null:
		_popularity_bar.min_value = -100.0
		_popularity_bar.max_value = 100.0
		_popularity_bar.value = opinio
	if _popularity_label != null:
		_popularity_label.text = "Közvélemény: %d (%s)" % [int(opinio), tuning.get_public_opinion_label()]
	if _popularity_effect != null:
		_popularity_effect.text = tuning.get_public_opinion_effect_text()

func _on_toggle_enabled(recipe_id: String, ertek: bool) -> void:
	var tuning = _tuning()
	if tuning != null:
		tuning.set_recipe_enabled(recipe_id, ertek)
	_render_recipe_list()
	_frissit_kozelem()

func _on_price_delta(recipe_id: String, delta: int) -> void:
	var tuning = _tuning()
	if tuning == null:
		return
	var cfg = tuning.get_recipe_config(recipe_id)
	var uj = int(cfg.get("price_ft", 0)) + delta
	tuning.set_recipe_price(recipe_id, uj)
	_render_recipe_list()
	_frissit_kozelem()

func _on_portion_set_ml(recipe_id: String, ml: int) -> void:
	var tuning = _tuning()
	if tuning == null:
		return
	tuning.set_recipe_portion_ml(recipe_id, ml)
	_render_recipe_list()
	_frissit_kozelem()

func _on_portion_delta_g(recipe_id: String, delta: int) -> void:
	var tuning = _tuning()
	if tuning == null:
		return
	var cfg = tuning.get_recipe_config(recipe_id)
	var aktualis = int(cfg.get("portion_g", 0))
	var uj = max(aktualis + delta, 10)
	tuning.set_recipe_portion_g(recipe_id, uj)
	_render_recipe_list()
	_frissit_kozelem()

func _select_recipe(recipe_id: String) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	_selected_recipe_id = rid
	var tuning = _tuning()
	if tuning == null:
		return
	_selected_type = str(tuning.get_recipe_type(rid))
	_pending_ingredients.clear()
	if tuning.has_method("get_effective_ingredients"):
		var eff_any = tuning.call("get_effective_ingredients", rid)
		var eff = eff_any if eff_any is Dictionary else {}
		_pending_ingredients = eff.duplicate(true)
	elif tuning.has_method("get_recipe_ingredients"):
		var lista_any = tuning.call("get_recipe_ingredients", rid)
		var lista = lista_any if lista_any is Array else []
		for entry_any in lista:
			var entry = entry_any if entry_any is Dictionary else {}
			var id = str(entry.get("id", "")).strip_edges()
			if id == "":
				continue
			_pending_ingredients[id] = int(entry.get("amount", entry.get("base", 0)))
	_render_selected_recipe()

func _render_selected_recipe() -> void:
	if _selected_title == null or _ingredients_list == null:
		return
	var tuning = _tuning()
	if tuning == null or _selected_recipe_id == "":
		_selected_title.text = "Recept: -"
		_clear_ingredients_list()
		return
	var nev = tuning.get_recipe_label(_selected_recipe_id)
	_selected_title.text = "Recept: %s" % nev
	_selected_type = str(tuning.get_recipe_type(_selected_recipe_id))
	if _portion_info_label != null:
		_portion_info_label.text = "Készletből: %d adag" % _szamol_portions_pending()
	_clear_ingredients_list()
	var lines_any = tuning.call("get_recipe_display_lines", _selected_recipe_id) if tuning.has_method("get_recipe_display_lines") else []
	var lines = lines_any if lines_any is Array else []
	if lines.size() == 1 and str(lines[0]).strip_edges() == "Hiányzó recept adat":
		var hiany = Label.new()
		hiany.text = "Hiányzó recept adat"
		_ingredients_list.add_child(hiany)
		return
	if _pending_ingredients.is_empty():
		var ures = Label.new()
		ures.text = "Nincs hozzávaló."
		_ingredients_list.add_child(ures)
		return
	var kulcsok: Array = []
	for key_any in _pending_ingredients.keys():
		var key = str(key_any).strip_edges()
		if key != "":
			kulcsok.append(key)
	kulcsok.sort()
	for id in kulcsok:
		_ingredients_list.add_child(_build_ingredient_row(id))

func _build_ingredient_row(ingredient_id: String) -> Control:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	var label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var unit = _ingredient_unit(ingredient_id)
	_frissit_ingredient_label(label, ingredient_id, unit)
	var steps = [-50, -10, 10, 50]
	for delta in steps:
		var btn = Button.new()
		var cimke = "%+d %s" % [delta, unit]
		btn.text = cimke
		btn.pressed.connect(func(): _on_ingredient_delta(ingredient_id, delta, unit, label))
		row.add_child(btn)
	return row

func _frissit_ingredient_label(label: Label, ingredient_id: String, unit: String) -> void:
	var nev = _ingredient_display_name(ingredient_id)
	var amount = int(_pending_ingredients.get(ingredient_id, 0))
	var keszlet = _ingredient_keszlet(ingredient_id)
	label.text = "%s → %s %d %s | Készlet: %d %s" % [ingredient_id, nev, amount, unit, keszlet, unit]

func _on_ingredient_delta(ingredient_id: String, delta: int, unit: String, label: Label) -> void:
	var jelenlegi = int(_pending_ingredients.get(ingredient_id, 0))
	var uj = max(jelenlegi + delta, 0)
	_pending_ingredients[ingredient_id] = uj
	_frissit_ingredient_label(label, ingredient_id, unit)
	_frissit_portions_info()

func _on_save_pressed() -> void:
	if _selected_recipe_id == "":
		return
	var tuning = _tuning()
	if tuning == null:
		return
	var overrides: Dictionary = {}
	for key_any in _pending_ingredients.keys():
		var id = str(key_any).strip_edges()
		if id == "":
			continue
		var amount = int(_pending_ingredients.get(id, 0))
		if amount <= 0:
			continue
		overrides[id] = {
			"amount": amount,
			"unit": _ingredient_unit(id)
		}
	if tuning.has_method("set_recipe_ingredient_overrides"):
		tuning.call("set_recipe_ingredient_overrides", _selected_recipe_id, overrides)
	_render_recipe_list()
	_select_recipe(_selected_recipe_id)

func _ingredient_unit(ingredient_id: String) -> String:
	if _selected_type == "drink":
		return "ml"
	return "g"

func _ingredient_keszlet(ingredient_id: String) -> int:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return 0
	if not StockSystem1.has_method("get_qty"):
		return 0
	return int(StockSystem1.call("get_qty", ingredient_id))

func _frissit_portions_info() -> void:
	if _portion_info_label == null:
		return
	var portions = _szamol_portions_pending()
	_portion_info_label.text = "Készletből: %d adag" % portions

func _szamol_portions_pending() -> int:
	if _selected_recipe_id == "":
		return 0
	if _selected_type == "drink":
		var adag = 0
		var tuning = _tuning()
		if tuning != null and tuning.has_method("get_recipe_portion_ml"):
			adag = int(tuning.call("get_recipe_portion_ml", _selected_recipe_id))
		if adag <= 0:
			return 0
		var elerheto = _ingredient_keszlet(_selected_recipe_id)
		return int(floor(float(elerheto) / float(adag)))
	if _pending_ingredients.is_empty():
		return 0
	var min_adagok = 999999
	for key_any in _pending_ingredients.keys():
		var id = str(key_any).strip_edges()
		if id == "":
			continue
		var amount = int(_pending_ingredients.get(id, 0))
		if amount <= 0:
			continue
		var available = _ingredient_keszlet(id)
		min_adagok = min(min_adagok, int(floor(float(available) / float(amount))))
	if min_adagok == 999999:
		return 0
	return max(min_adagok, 0)

func _ingredient_display_name(ingredient_id: String) -> String:
	var tuning = _tuning()
	if tuning != null and tuning.has_method("get_ingredient_display_name"):
		return str(tuning.call("get_ingredient_display_name", ingredient_id))
	return ingredient_id

func _clear_ingredients_list() -> void:
	if _ingredients_list == null:
		return
	for child in _ingredients_list.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	hide_panel()
	var book_panel = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if book_panel != null:
		if book_panel.has_method("show_panel"):
			book_panel.call("show_panel")
		else:
			book_panel.show()

func _tuning() -> Node:
	if typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		return RecipeTuningSystem1
	return get_tree().root.get_node_or_null("RecipeTuningSystem1")

func _owned_recipes() -> Array:
	var kitchen: Node = null
	if typeof(KitchenSystem1) != TYPE_NIL and KitchenSystem1 != null:
		kitchen = KitchenSystem1
	else:
		kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen == null:
		push_error("[RECIPE_UI] ERROR: KitchenSystem1 nem található.")
		return []
	if kitchen.has_method("get_owned_recipes"):
		return kitchen.call("get_owned_recipes")
	return []
