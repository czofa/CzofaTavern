extends Control

@export var item_selector_path: NodePath = ^"MarginContainer/VBoxContainer/ItemSelector"
@export var slider_path: NodePath = ^"MarginContainer/VBoxContainer/Slider"
@export var result_label_path: NodePath = ^"MarginContainer/VBoxContainer/ResultLabel"
@export var btn_submit_path: NodePath = ^"MarginContainer/VBoxContainer/BtnSubmit"
@export var btn_back_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"

var _item_selector: OptionButton
var _slider: HSlider
var _result_label: Label
var _btn_submit: Button
var _btn_back: Button

var _current_item: String = ""
var _current_qty: int = 0

func _ready() -> void:
	_item_selector = get_node(item_selector_path)
	_slider = get_node(slider_path)
	_result_label = get_node(result_label_path)
	_btn_submit = get_node(btn_submit_path)
	_btn_back = get_node(btn_back_path)

	_btn_submit.pressed.connect(_on_submit_pressed)
	_btn_back.pressed.connect(_on_back_pressed)
	_item_selector.item_selected.connect(_on_item_selected)
	_slider.value_changed.connect(_on_slider_changed)

	hide()

# ─────────────────────────────
# PANEL VEZÉRLÉS (STRUKTURÁLT)
# ─────────────────────────────

func show_panel() -> void:
	show()
	_load_unbooked_items()

func hide_panel() -> void:
	hide()

# ─────────────────────────────
# ADATBETÖLTÉS
# ─────────────────────────────

func _load_unbooked_items() -> void:
	_item_selector.clear()
	var items = StockSystem1.get_unbooked_items()

	for item in items:
		_item_selector.add_item(item)

	if items.size() > 0:
		_item_selector.select(0)
		_on_item_selected(0)
	else:
		_result_label.text = "❌ Nincs be nem könyvelt alapanyag."

func _on_item_selected(index: int) -> void:
	_current_item = _item_selector.get_item_text(index)
	_current_qty = StockSystem1.get_unbooked_qty(_current_item)

	_slider.min_value = 10
	_slider.step = 10
	_slider.max_value = _current_qty
	_slider.value = min(100, _current_qty)

	_update_result_label()

func _on_slider_changed(_value: float) -> void:
	_update_result_label()

func _update_result_label() -> void:
	var portion_size := int(_slider.value)
	if portion_size <= 0:
		_result_label.text = "⚠️ Válassz nagyobb adagot!"
		return

	var portions := _current_qty / portion_size
	var remainder := _current_qty % portion_size

	_result_label.text = "🍽️ Adagok: %d\n📦 Maradék: %d g" % [portions, remainder]

# ─────────────────────────────
# MENTÉS
# ─────────────────────────────

func _on_submit_pressed() -> void:
	var portion_size := int(_slider.value)
	if portion_size <= 0:
		return

	var portions := _current_qty / portion_size
	var remainder := _current_qty % portion_size

	# Teljes mennyiség könyvelése
	StockSystem1.book_item(_current_item, _current_qty)

	# Konyhai adag aktiválás
	if KitchenSystem1.has_ingredient(_current_item):
		KitchenSystem1.set_portion_data(_current_item, portion_size, portions)

	# Maradék vissza
	if remainder > 0:
		StockSystem1.add_unbooked(_current_item, remainder, 0)

	_back_to_bookkeeping()

func _on_back_pressed() -> void:
	_back_to_bookkeeping()

func _back_to_bookkeeping() -> void:
	hide_panel()
	var panel = get_tree().root.get_node("Main/UIRoot/UiRoot/BookkeepingPanel")
	if panel:
		panel.show_panel()
