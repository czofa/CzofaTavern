extends Control

@export var company_label_path: NodePath = ^"MarginContainer/VBoxContainer/CompanyMoney"
@export var personal_label_path: NodePath = ^"MarginContainer/VBoxContainer/PersonalMoney"
@export var period_label_path: NodePath = ^"MarginContainer/VBoxContainer/PeriodInfo"
@export var input_vat_label_path: NodePath = ^"MarginContainer/VBoxContainer/InputVat"
@export var output_vat_label_path: NodePath = ^"MarginContainer/VBoxContainer/OutputVat"
@export var payable_label_path: NodePath = ^"MarginContainer/VBoxContainer/Payable"
@export var status_label_path: NodePath = ^"MarginContainer/VBoxContainer/Status"
@export var pay_button_path: NodePath = ^"MarginContainer/VBoxContainer/PayButton"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"

var _company_label: Label
var _personal_label: Label
var _period_label: Label
var _input_vat_label: Label
var _output_vat_label: Label
var _payable_label: Label
var _status_label: Label
var _pay_button: Button
var _back_button: Button

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	_connect_bus()
	hide()

func show_panel() -> void:
	show()
	_frissit()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_company_label = get_node_or_null(company_label_path) as Label
	_personal_label = get_node_or_null(personal_label_path) as Label
	_period_label = get_node_or_null(period_label_path) as Label
	_input_vat_label = get_node_or_null(input_vat_label_path) as Label
	_output_vat_label = get_node_or_null(output_vat_label_path) as Label
	_payable_label = get_node_or_null(payable_label_path) as Label
	_status_label = get_node_or_null(status_label_path) as Label
	_pay_button = get_node_or_null(pay_button_path) as Button
	_back_button = get_node_or_null(back_button_path) as Button

	if _company_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik a cégpénz címke.")
	if _personal_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik a magánpénz címke.")
	if _period_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik az időszak címke.")
	if _input_vat_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik a levonható ÁFA sor.")
	if _output_vat_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik a fizetendő ÁFA sor.")
	if _payable_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik az összeg sor.")
	if _status_label == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik az állapot sor.")
	if _pay_button == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik az Adófizetés gomb.")
	if _back_button == null:
		push_warning("ℹ️ TaxReportPanel: hiányzik a Vissza gomb.")

func _connect_signals() -> void:
	if _pay_button != null and not _pay_button.pressed.is_connected(Callable(self, "_on_pay_pressed")):
		_pay_button.pressed.connect(Callable(self, "_on_pay_pressed"))
	if _back_button != null and not _back_button.pressed.is_connected(Callable(self, "_on_back_pressed")):
		_back_button.pressed.connect(Callable(self, "_on_back_pressed"))

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"tax.updated":
			if visible:
				_frissit()
		"state.add":
			if visible and str(payload.get("key","")) in ["company_money_ft", "personal_money_ft", "money"]:
				_frissit()
		_:
			pass

func _frissit() -> void:
	if typeof(TaxSystem1) == TYPE_NIL or TaxSystem1 == null or not TaxSystem1.has_method("get_summary"):
		_set_status("❌ Az adó modul nem érhető el.")
		if _pay_button != null:
			_pay_button.disabled = true
		return

	var osszegzes: Dictionary = TaxSystem1.get_summary()
	var cegpenz: int = int(osszegzes.get("company_money_ft", _get_company_money()))
	var magan: int = int(osszegzes.get("personal_money_ft", _get_personal_money()))
	var napok: int = int(osszegzes.get("days_elapsed", 0))
	var hatralevo: int = int(osszegzes.get("days_left", 0))
	var input_vat: int = int(osszegzes.get("input_vat_total", 0))
	var output_vat: int = int(osszegzes.get("output_vat_total", 0))
	var fizetendo: int = int(osszegzes.get("vat_payable", 0))
	var visszaigenyelheto: int = int(osszegzes.get("vat_refund", 0))

	if _company_label != null:
		_company_label.text = "Cégpénz: %d Ft" % cegpenz
	if _personal_label != null:
		_personal_label.text = "Magánpénz: %d Ft" % magan
	if _period_label != null:
		_period_label.text = "Időszak: %d/7 nap (hátra: %d)" % [napok, hatralevo]
	if _input_vat_label != null:
		_input_vat_label.text = "Levonható ÁFA: %d Ft" % input_vat
	if _output_vat_label != null:
		_output_vat_label.text = "Fizetendő ÁFA: %d Ft" % output_vat
	if _payable_label != null:
		_payable_label.text = "Fizetendő most: %d Ft" % fizetendo

	if _pay_button != null:
		_pay_button.disabled = false

	if _status_label != null:
		if visszaigenyelheto > 0 and fizetendo == 0:
			_status_label.text = "ℹ️ Visszaigényelhető ÁFA: %d Ft" % visszaigenyelheto
		else:
			_status_label.text = "Ledger frissítve."

func _on_pay_pressed() -> void:
	if typeof(TaxSystem1) == TYPE_NIL or TaxSystem1 == null:
		_set_status("❌ Az adó modul nem érhető el.")
		return
	if not TaxSystem1.has_method("pay_due_vat"):
		_set_status("❌ Az adófizetés nem támogatott.")
		return
	var eredmeny: Dictionary = TaxSystem1.pay_due_vat()
	var uzenet: String = str(eredmeny.get("message", ""))
	if uzenet.strip_edges() == "":
		uzenet = "ÁFA folyamat frissítve."
	_set_status(uzenet)
	_frissit()

func _on_back_pressed() -> void:
	hide_panel()
	var panel = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
	elif panel:
		panel.show()

func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text

func _get_company_money() -> int:
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		return int(EconomySystem1.get_money())
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", "company_money_ft", 0))
	return 0

func _get_personal_money() -> int:
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", "personal_money_ft", 0))
	return 0

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")
