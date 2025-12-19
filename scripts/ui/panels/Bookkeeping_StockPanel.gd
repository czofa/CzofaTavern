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
var _ui_ready: bool = false

func _calc_portion_size() -> int:
	if _slider == null:
		return 0
	var step: int = int(max(_slider.step, 1.0))
	var snapped_value: int = int(snapped(_slider.value, float(step)))
	var min_value: int = max(step, 1)
	var max_value: int = int(max(_slider.max_value, float(step)))
	var capped_value: int = clampi(snapped_value, min_value, max_value)
	if capped_value <= 0:
		return 0
	return capped_value

func _ready() -> void:
	_item_selector = get_node_or_null(item_selector_path)
	_slider = get_node_or_null(slider_path)
	_result_label = get_node_or_null(result_label_path)
	_btn_submit = get_node_or_null(btn_submit_path)
	_btn_back = get_node_or_null(btn_back_path)

	if _item_selector == null:
		push_warning("❌ Bookkeeping_StockPanel: hiányzik az ItemSelector (%s)." % item_selector_path)
	if _slider == null:
		push_warning("❌ Bookkeeping_StockPanel: hiányzik a csúszka (%s)." % slider_path)
	if _result_label == null:
		push_warning("❌ Bookkeeping_StockPanel: hiányzik az eredmény címke (%s)." % result_label_path)
	if _btn_submit == null:
		push_warning("❌ Bookkeeping_StockPanel: hiányzik a mentés gomb (%s)." % btn_submit_path)
	if _btn_back == null:
		push_warning("❌ Bookkeeping_StockPanel: hiányzik a vissza gomb (%s)." % btn_back_path)

	if _btn_submit != null:
		_btn_submit.pressed.connect(_on_submit_pressed)
	if _btn_back != null:
		_btn_back.pressed.connect(_on_back_pressed)
	if _item_selector != null:
		_item_selector.item_selected.connect(_on_item_selected)
	if _slider != null:
		_slider.value_changed.connect(_on_slider_changed)

	_ui_ready = _item_selector != null and _slider != null and _result_label != null
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
	if not _ui_ready:
		return

	_item_selector.clear()

	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		_result_label.text = "❌ A készlet rendszer nem elérhető."
		if _btn_submit != null:
			_btn_submit.disabled = true
		return

	var items = StockSystem1.get_unbooked_items()

	for item in items:
		var qty: int = StockSystem1.get_unbooked_qty(item)
		var label_text := "%s (%d g)" % [item, qty]
		_item_selector.add_item(label_text)
		_item_selector.set_item_metadata(_item_selector.get_item_count() - 1, item)

	if items.size() > 0:
		if _btn_submit != null:
			_btn_submit.disabled = false
		_item_selector.select(0)
		_on_item_selected(0)
	else:
		_result_label.text = "❌ Nincs be nem könyvelt alapanyag."
		if _btn_submit != null:
			_btn_submit.disabled = true

func _on_item_selected(index: int) -> void:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		_result_label.text = "❌ A készlet rendszer nem elérhető."
		return
	if _item_selector == null or _slider == null:
		return
	var meta = _item_selector.get_item_metadata(index)
	_current_item = meta if typeof(meta) == TYPE_STRING else _item_selector.get_item_text(index)
	_current_qty = StockSystem1.get_unbooked_qty(_current_item)

	var step: float = 10.0
	_slider.step = step

	var max_value: float = float(max(_current_qty, int(step)))
	_slider.min_value = step
	_slider.max_value = max_value
	var start_value: float = clampf(max_value, _slider.min_value, _slider.max_value)
	_slider.value = start_value

	_update_result_label()

func _on_slider_changed(_value: float) -> void:
	_update_result_label()

func _update_result_label() -> void:
	if _slider == null or _result_label == null:
		return
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and _current_item != "":
		_current_qty = StockSystem1.get_unbooked_qty(_current_item)
	if _current_qty <= 0:
		_result_label.text = "❌ Nincs könyvelhető mennyiség."
		return

	var portion_size: int = max(_calc_portion_size(), 0)
	if portion_size <= 0:
		_result_label.text = "⚠️ Túl nagy adagméret."
		return

	var portions: int = int(floor(float(_current_qty) / float(portion_size)))
	if portions <= 0:
		_result_label.text = "⚠️ Túl nagy adagméret."
		return

	var remainder: int = _current_qty % portion_size

	_result_label.text = "🥄 Adagméret: %d g\n🍽️ Könyvelhető adagok: %d\n📦 Maradék: %d g" % [portion_size, portions, remainder]

# ─────────────────────────────
# MENTÉS
# ─────────────────────────────

func _on_submit_pressed() -> void:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		_result_label.text = "❌ A készlet rendszer nem elérhető."
		return
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		_result_label.text = "❌ A konyha rendszer nem elérhető."
		return
	var available_qty: int = StockSystem1.get_unbooked_qty(_current_item)
	if available_qty <= 0:
		_result_label.text = "❌ Ehhez a tételhez nincs könyvelhető mennyiség."
		return
	_current_qty = available_qty

	var portion_size: int = max(_calc_portion_size(), 0)
	if portion_size <= 0:
		_result_label.text = "⚠️ Túl nagy adagméret, nincs könyvelhető adag."
		return

	var portions: int = int(floor(float(available_qty) / float(portion_size)))
	var remainder: int = available_qty % portion_size
	if portions <= 0:
		_result_label.text = "⚠️ Túl nagy adagméret, nincs könyvelhető adag."
		return

	var grams_to_book: int = portions * portion_size

	if not StockSystem1.book_item(_current_item, grams_to_book):
		_result_label.text = "❌ Könyvelés sikertelen, próbáld újra."
		return

	if KitchenSystem1.has_method("set_portion_data"):
		KitchenSystem1.set_portion_data(_current_item, portion_size, portions)
	else:
		push_warning("ℹ️ A konyha rendszer nem támogatja az adagok tárolását.")

	_result_label.text = "✅ Könyvelve: %s – %d adag, %d g maradék." % [_current_item, portions, remainder]
	_back_to_bookkeeping()

func _on_back_pressed() -> void:
	_back_to_bookkeeping()

func _back_to_bookkeeping() -> void:
	hide_panel()
	var panel = get_tree().root.get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
	elif panel:
		panel.show()
	else:
		push_warning("ℹ️ Visszalépés: a könyvelési menü nem található.")
