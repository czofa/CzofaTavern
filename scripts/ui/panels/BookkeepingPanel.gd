extends Control

@export var label_title_path: NodePath = ^"VBoxContainer/TitleLabel"
@export var btn_stock_path: NodePath = ^"VBoxContainer/BtnStock"
@export var btn_price_path: NodePath = ^"VBoxContainer/BtnPrice"
@export var btn_recipe_path: NodePath = ^"VBoxContainer/BtnRecipe"
@export var btn_tax_path: NodePath = ^"VBoxContainer/BtnTax"
@export var btn_employees_path: NodePath = ^"VBoxContainer/BtnEmployees"
@export var btn_log_path: NodePath = ^"VBoxContainer/BtnLog"
@export var btn_dividend_path: NodePath = ^"VBoxContainer/BtnDividend"
@export var btn_back_path: NodePath = ^"VBoxContainer/BtnBack"

var _label_title: Label
var _btn_stock: Button
var _btn_price: Button
var _btn_recipe: Button
var _btn_tax: Button
var _btn_employees: Button
var _btn_log: Button
var _btn_dividend: Button
var _btn_back: Button
var _ui_ready: bool = false

func _ready() -> void:
	print("📕 BookkeepingPanel READY")
	_init_paths()
	hide()

func _init_paths() -> void:
	_label_title = get_node_or_null(label_title_path)
	_btn_stock = get_node_or_null(btn_stock_path)
	_btn_price = get_node_or_null(btn_price_path)
	_btn_recipe = get_node_or_null(btn_recipe_path)
	_btn_tax = get_node_or_null(btn_tax_path)
	_btn_employees = get_node_or_null(btn_employees_path)
	_btn_log = get_node_or_null(btn_log_path)
	_btn_dividend = get_node_or_null(btn_dividend_path)
	_btn_back = get_node_or_null(btn_back_path)

	if _btn_stock == null:
		push_warning("❌ BookkeepingPanel: hiányzik a készlet gomb (%s)." % btn_stock_path)
	if _btn_price == null:
		push_warning("❌ BookkeepingPanel: hiányzik az árkezelés gomb (%s)." % btn_price_path)
	if _btn_recipe == null:
		push_warning("❌ BookkeepingPanel: hiányzik a recept gomb (%s)." % btn_recipe_path)
	if _btn_tax == null:
		push_warning("❌ BookkeepingPanel: hiányzik az adó gomb (%s)." % btn_tax_path)
	if _btn_employees == null:
		push_warning("❌ BookkeepingPanel: hiányzik az alkalmazott gomb (%s)." % btn_employees_path)
	if _btn_log == null:
		push_warning("❌ BookkeepingPanel: hiányzik a napló gomb (%s)." % btn_log_path)
	if _btn_dividend == null:
		push_warning("❌ BookkeepingPanel: hiányzik az osztalék gomb (%s)." % btn_dividend_path)
	if _btn_back == null:
		push_warning("❌ BookkeepingPanel: hiányzik a vissza gomb (%s)." % btn_back_path)

	if _btn_stock != null:
		_btn_stock.pressed.connect(_on_stock_pressed)
	if _btn_price != null:
		_btn_price.pressed.connect(_on_price_pressed)
	if _btn_recipe != null:
		_btn_recipe.pressed.connect(_on_recipe_pressed)
	if _btn_tax != null:
		_btn_tax.pressed.connect(_on_tax_pressed)
	if _btn_employees != null:
		_btn_employees.pressed.connect(_on_employees_pressed)
	if _btn_log != null:
		_btn_log.pressed.connect(_on_log_pressed)
	if _btn_dividend != null:
		_btn_dividend.pressed.connect(_on_dividend_pressed)
	if _btn_back != null:
		_btn_back.pressed.connect(_on_back_pressed)

	if _btn_price != null:
		_btn_price.disabled = true
		_btn_price.visible = false
		_btn_price.tooltip_text = "🔒 Árkezelés kikapcsolva."

	_ui_ready = _btn_stock != null and _btn_back != null

func show_panel() -> void:
	print("📘 Könyvelési menü megnyitva")
	show()

func hide_panel() -> void:
	print("📕 Könyvelési menü elrejtve")
	hide()

# ─────────────────────────────
# Gombkezelők
# ─────────────────────────────

func _on_stock_pressed() -> void:
	if not _ui_ready:
		return
	print("🧾 Árubevezetés megnyitása")
	hide_panel()
	var stock_panel = get_tree().get_root().get_node_or_null(
		"Main/UIRoot/UiRoot/Bookkeeping_StockPanel"
	)
	if stock_panel and stock_panel.has_method("show_panel"):
		stock_panel.show_panel()
	elif stock_panel:
		stock_panel.show()
	else:
		print("❌ HIBA: Bookkeeping_StockPanel nem található!")

func _on_price_pressed() -> void:
	if not _ui_ready:
		return
	print("💰 Árkezelés megnyitása")
	hide_panel()
	var price_panel = get_tree().get_root().get_node_or_null(
		"Main/UIRoot/UiRoot/Bookkeeping_PricePanel"
	)
	if price_panel and price_panel.has_method("show_panel"):
		price_panel.show_panel()
	elif price_panel:
		price_panel.show()
	else:
		print("❌ HIBA: Bookkeeping_PricePanel nem található!")

func _on_recipe_pressed() -> void:
	if not _ui_ready:
		return
	print("🍳 Receptek szabályozása megnyitása")
	hide_panel()
	var main_menu = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/BookMenu")
	if main_menu:
		main_menu.visible = false
	var panel = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/RecipesTuningPanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
	elif panel:
		panel.show()
	else:
		push_warning("❌ Receptek szabályozása panel nem található.")

func _on_tax_pressed() -> void:
	print("💸 Adó kimutatás megnyitása")
	hide_panel()
	var panel = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/TaxReportPanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
	elif panel:
		panel.show()
	else:
		push_warning("❌ Adó riport panel nem található.")

func _on_employees_pressed() -> void:
	if not _ui_ready:
		return
	print("🧑‍💼 Alkalmazottak adminisztráció megnyitása")
	hide_panel()
	var panel = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/Bookkeeping_EmployeesPanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
	elif panel:
		panel.show()
	else:
		push_warning("❌ Alkalmazotti adminisztrációs panel nem található.")

func _on_log_pressed() -> void:
	print("📄 Napló / kimutatások megnyitása (TODO: külön panel betöltés)")

func _on_dividend_pressed() -> void:
	print("🏦 Osztalék kivét indítása (TODO: külön panel betöltés)")

func _on_back_pressed() -> void:
	print("🔙 Visszalépés a főmenübe")
	hide_panel()
	var main_menu = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/BookMenu")
	if main_menu:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")
	else:
		push_warning("ℹ️ A főkönyv menü nem található, a visszalépés sikertelen.")
