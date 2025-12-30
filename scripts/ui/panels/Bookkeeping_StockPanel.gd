extends Control

@export var item_selector_path: NodePath = ^"MarginContainer/VBoxContainer/ItemSelector"
@export var slider_path: NodePath = ^"MarginContainer/VBoxContainer/Slider"
@export var result_label_path: NodePath = ^"MarginContainer/VBoxContainer/ResultLabel"
@export var btn_submit_path: NodePath = ^"MarginContainer/VBoxContainer/BtnSubmit"
@export var btn_back_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"
@export var portion_buttons_parent_path: NodePath = ^"MarginContainer/VBoxContainer"

var _item_selector: OptionButton
var _slider: HSlider
var _result_label: Label
var _btn_submit: Button
var _btn_back: Button
var _mennyiseg_parent: Control
var _mennyiseg_buttons: Array = []
var _mennyiseg_row: HBoxContainer
var _valasztott_mennyiseg: int = 0

var _current_item: String = ""
var _current_qty: int = 0
var _current_unit: String = "g"
var _ui_ready: bool = false

func _ready() -> void:
	_item_selector = get_node_or_null(item_selector_path)
	_slider = get_node_or_null(slider_path)
	_result_label = get_node_or_null(result_label_path)
	_btn_submit = get_node_or_null(btn_submit_path)
	_btn_back = get_node_or_null(btn_back_path)
	_mennyiseg_parent = get_node_or_null(portion_buttons_parent_path)

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
		_slider.hide()
		_slider.min_value = 1
		_slider.value_changed.connect(_on_slider_changed)
	_epit_mennyiseg_gombok()

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
	for item_any in items:
		var adat = item_any if item_any is Dictionary else {}
		var id = str(adat.get("id", item_any)).strip_edges()
		if id == "":
			continue
		var qty: int = int(adat.get("qty", StockSystem1.get_unbooked_qty(id)))
		var unit: String = str(adat.get("unit", "g"))
		var label_text = _format_tetel_cimke(id, qty, unit)
		_item_selector.add_item(label_text)
		_item_selector.set_item_metadata(_item_selector.get_item_count() - 1, {
			"id": id,
			"qty": qty,
			"unit": unit
		})

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
	if _item_selector == null:
		return
	var meta = _item_selector.get_item_metadata(index)
	var adat = meta if meta is Dictionary else {}
	_current_item = str(adat.get("id", meta)).strip_edges()
	if _current_item == "":
		_current_item = _item_selector.get_item_text(index)
	_current_qty = int(adat.get("qty", StockSystem1.get_unbooked_qty(_current_item)))
	_current_unit = str(adat.get("unit", "g"))

	_valasztott_mennyiseg = 0
	_frissit_mennyiseg_ui()
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

	var kivalasztott = _kivalasztott_mennyiseg()
	if _current_unit == "g" or _current_unit == "pcs":
		var kivalasztott_szoveg = _format_mennyiseg_szoveg(_current_item, kivalasztott, _current_unit)
		var elerheto_szoveg = _format_mennyiseg_szoveg(_current_item, _current_qty, _current_unit)
		_result_label.text = "Mennyit könyvelsz?\nKiválasztva: %s\nElérhető: %s" % [
			kivalasztott_szoveg, elerheto_szoveg
		]
		return
	if _current_unit == "ml":
		var kivalasztott_szoveg = _format_ml_mennyiseg(kivalasztott)
		var elerheto_szoveg = _format_ml_mennyiseg(_current_qty)
		_result_label.text = "Mennyit könyvelsz?\nKiválasztva: %s\nElérhető: %s" % [
			kivalasztott_szoveg, elerheto_szoveg
		]
	else:
		_result_label.text = "Mennyit könyvelsz?\nKiválasztva: %d db\nElérhető: %d db" % [kivalasztott, _current_qty]

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

	var book_qty = _kivalasztott_mennyiseg()
	if book_qty <= 0:
		_result_label.text = "❌ Válassz legalább 1 egységet."
		return
	if book_qty > available_qty:
		_result_label.text = "⚠️ Nincs elég könyveletlen mennyiség."
		_toast("⚠️ Nincs elég könyveletlen mennyiség.")
		return
	if not StockSystem1.book_item(_current_item, book_qty, _current_unit):
		_result_label.text = "❌ Könyvelés sikertelen, próbáld újra."
		return
	if _current_unit == "ml":
		_result_label.text = "✅ Könyvelve: %s – %s" % [_current_item, _format_ml_mennyiseg(book_qty)]
	else:
		_result_label.text = "✅ Könyvelve: %s – %d db" % [_current_item, book_qty]
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

func _epit_portion_gombok() -> void:
	if _mennyiseg_parent == null:
		push_warning("ℹ️ Mennyiségválasztó konténer nem elérhető, a gombok nem készültek el.")
		return
	var sor = HBoxContainer.new()
	_mennyiseg_row = sor
	_mennyiseg_parent.add_child(sor)
	if _result_label != null:
		_mennyiseg_parent.move_child(sor, _result_label.get_index())

func _epit_mennyiseg_gombok() -> void:
	_epit_portion_gombok()

func _frissit_gombok(ertekek: Array, unit: String) -> void:
	if _mennyiseg_row == null:
		return
	for btn_any in _mennyiseg_buttons:
		if btn_any is Node:
			btn_any.queue_free()
	_mennyiseg_buttons.clear()
	for ertek_any in ertekek:
		var ertek = int(ertek_any)
		var btn = Button.new()
		if ertek <= 0:
			btn.text = "MIND"
		elif unit == "g":
			btn.text = "%.1f kg" % (float(ertek) / 1000.0)
		elif unit == "pcs":
			btn.text = "%d db" % ertek
		else:
			btn.text = "%d" % ertek
		btn.pressed.connect(_on_mennyiseg_button_pressed.bind(ertek))
		_mennyiseg_row.add_child(btn)
		_mennyiseg_buttons.append(btn)

func _on_mennyiseg_button_pressed(menny: int) -> void:
	if menny <= 0:
		_valasztott_mennyiseg = _current_qty
	else:
		_valasztott_mennyiseg = max(int(menny), 0)
	_update_result_label()

func _frissit_mennyiseg_ui() -> void:
	if _slider == null:
		return
	var step = 1
	if _current_unit == "ml":
		step = 50 if _current_qty >= 50 else 1
	if _current_unit == "g" or _current_unit == "pcs":
		_slider.hide()
		if _mennyiseg_row != null:
			_mennyiseg_row.visible = true
		if _current_unit == "g":
			_frissit_gombok([500, 1000, 2000, 0], "g")
			_valasztott_mennyiseg = min(_current_qty, 1000)
		else:
			_frissit_gombok([1, 5, 10, 0], "pcs")
			_valasztott_mennyiseg = min(_current_qty, 1)
	else:
		_slider.show()
		_slider.min_value = 1
		_slider.max_value = max(_current_qty, 1)
		_slider.step = step
		_slider.value = min(_slider.max_value, float(step))
		if _mennyiseg_row != null:
			_mennyiseg_row.visible = false

func _kivalasztott_mennyiseg() -> int:
	if _current_unit == "g" or _current_unit == "pcs":
		return max(_valasztott_mennyiseg, 0)
	if _slider == null:
		return 0
	return int(round(_slider.value))

func _format_tetel_cimke(id: String, qty: int, unit: String) -> String:
	var mennyiseg_szoveg = ""
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and StockSystem1.has_method("format_qty_for_ui"):
		mennyiseg_szoveg = str(StockSystem1.call("format_qty_for_ui", id, qty, unit))
	if mennyiseg_szoveg == "":
		if unit == "ml":
			mennyiseg_szoveg = _format_ml_mennyiseg(qty)
		elif unit == "pcs":
			mennyiseg_szoveg = "%d db" % qty
		else:
			mennyiseg_szoveg = "%d g" % qty
	var cimke = "%s (%s)" % [id, mennyiseg_szoveg]
	print("[UNBOOKED_UI] id=%s qty=%d unit=%s shown=\"%s\"" % [id, qty, unit, cimke])
	return cimke

func _format_mennyiseg_szoveg(id: String, qty: int, unit: String) -> String:
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and StockSystem1.has_method("format_qty_for_ui"):
		return str(StockSystem1.call("format_qty_for_ui", id, qty, unit))
	if unit == "ml":
		return _format_ml_mennyiseg(qty)
	if unit == "pcs":
		return "%d db" % qty
	return "%d g" % qty

func _format_ml_mennyiseg(menny: int) -> String:
	if menny >= 1000:
		return "%d ml (%.1f L)" % [menny, float(menny) / 1000.0]
	return "%d ml" % menny

func _toast(szoveg: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)
