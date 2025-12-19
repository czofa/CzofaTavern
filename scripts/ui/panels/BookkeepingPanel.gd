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

func _ready() -> void:
	print("📕 BookkeepingPanel READY")
	_init_paths()
	hide()

func _init_paths() -> void:
	_label_title = get_node(label_title_path)
	_btn_stock = get_node(btn_stock_path)
	_btn_price = get_node(btn_price_path)
	_btn_recipe = get_node(btn_recipe_path)
	_btn_tax = get_node(btn_tax_path)
	_btn_employees = get_node(btn_employees_path)
	_btn_log = get_node(btn_log_path)
	_btn_dividend = get_node(btn_dividend_path)
	_btn_back = get_node(btn_back_path)

	_btn_stock.pressed.connect(_on_stock_pressed)
	_btn_price.pressed.connect(_on_price_pressed)
	_btn_recipe.pressed.connect(_on_recipe_pressed)
	_btn_tax.pressed.connect(_on_tax_pressed)
	_btn_employees.pressed.connect(_on_employees_pressed)
	_btn_log.pressed.connect(_on_log_pressed)
	_btn_dividend.pressed.connect(_on_dividend_pressed)
	_btn_back.pressed.connect(_on_back_pressed)

	# ❌ Árkezelés ideiglenesen nem elérhető
	_btn_price.disabled = true
	_btn_price.tooltip_text = "🔒 Elérhető később, ha már termelsz is!"

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
	print("🧾 Árubevezetés megnyitása")
	hide_panel()
	var stock_panel = get_tree().get_root().get_node(
		"Main/UIRoot/UiRoot/Bookkeeping_StockPanel"
	)
	if stock_panel:
		stock_panel.show_panel()
	else:
		print("❌ HIBA: Bookkeeping_StockPanel nem található!")

func _on_price_pressed() -> void:
	print("💰 Árkezelés megnyitása")
	hide_panel()
	var price_panel = get_tree().get_root().get_node(
		"Main/UIRoot/UiRoot/Bookkeeping_PricePanel"
	)
	if price_panel:
		price_panel.show_panel()
	else:
		print("❌ HIBA: Bookkeeping_PricePanel nem található!")

func _on_recipe_pressed() -> void:
	print("🍳 Receptek kezelése (TODO: külön panel betöltés)")

func _on_tax_pressed() -> void:
	print("💸 ÁFA és adózás megnyitása (TODO: külön panel betöltés)")

func _on_employees_pressed() -> void:
	print("🧑‍💼 Alkalmazottak adminisztrációja (TODO: külön panel betöltés)")

func _on_log_pressed() -> void:
	print("📄 Napló / kimutatások megnyitása (TODO: külön panel betöltés)")

func _on_dividend_pressed() -> void:
	print("🏦 Osztalék kivét indítása (TODO: külön panel betöltés)")

func _on_back_pressed() -> void:
	print("🔙 Visszalépés a főmenübe")
	get_parent().visible = false
	var main_menu = get_tree().get_root().get_node(
		"Main/UIRoot/UiRoot/BookMenu"
	)
	if main_menu:
		main_menu.visible = true
