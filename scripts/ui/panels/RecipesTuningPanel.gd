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
@export var ingredients_list_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/IngredientsList"
@export var popularity_bar_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityBar"
@export var popularity_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityLabel"
@export var popularity_effect_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Content/Right/PopularityBlock/PopularityEffect"
@export var back_button_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/BackButton"

var _title_label: Label
var _panel_container: PanelContainer
var _recipe_list: VBoxContainer
var _popularity_bar: ProgressBar
var _popularity_label: Label
var _popularity_effect: Label
var _back_button: Button

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
	_popularity_bar = get_node_or_null(popularity_bar_path) as ProgressBar
	_popularity_label = get_node_or_null(popularity_label_path) as Label
	_popularity_effect = get_node_or_null(popularity_effect_path) as Label
	_back_button = get_node_or_null(back_button_path) as Button

	var selected_title = get_node_or_null(selected_title_path) as Label
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
	var ingredients_list = get_node_or_null(ingredients_list_path) as VBoxContainer

	if _title_label != null:
		_title_label.text = "🍳 Receptek szabályozása"
	if selected_title != null:
		selected_title.visible = false
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
	if ingredients_list != null:
		ingredients_list.visible = false
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)

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
	root.theme_override_constants.separation = 6
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
	price_row.theme_override_constants.separation = 6
	var price_label = Label.new()
	price_label.text = "Ár: %d Ft" % int(cfg.get("price_ft", 0))
	price_row.add_child(price_label)
	price_row.add_child(_build_price_button(recipe_id, -50, "-50"))
	price_row.add_child(_build_price_button(recipe_id, -10, "-10"))
	price_row.add_child(_build_price_button(recipe_id, 10, "+10"))
	price_row.add_child(_build_price_button(recipe_id, 50, "+50"))
	root.add_child(price_row)

	var portion_row = HBoxContainer.new()
	portion_row.theme_override_constants.separation = 6
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
