extends Control

@export var employee_selector_path: NodePath = ^"MarginContainer/VBoxContainer/EmployeeSelector"
@export var gross_input_path: NodePath = ^"MarginContainer/VBoxContainer/GrossInput"
@export var preset_selector_path: NodePath = ^"MarginContainer/VBoxContainer/PresetSelector"
@export var cost_label_path: NodePath = ^"MarginContainer/VBoxContainer/CostLabel"
@export var save_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnSave"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"

var _employee_selector: OptionButton
var _gross_input: SpinBox
var _preset_selector: OptionButton
var _cost_label: Label
var _save_button: Button
var _back_button: Button
var _ui_ready: bool = false

func _ready() -> void:
	_employee_selector = get_node_or_null(employee_selector_path)
	_gross_input = get_node_or_null(gross_input_path)
	_preset_selector = get_node_or_null(preset_selector_path)
	_cost_label = get_node_or_null(cost_label_path)
	_save_button = get_node_or_null(save_button_path)
	_back_button = get_node_or_null(back_button_path)

	if _employee_selector != null:
		_employee_selector.item_selected.connect(_on_employee_selected)
	if _gross_input != null:
		_gross_input.value_changed.connect(_on_gross_changed)
	if _preset_selector != null:
		_preset_selector.item_selected.connect(_on_preset_selected)
	if _save_button != null:
		_save_button.pressed.connect(_on_save_pressed)
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)

	_ui_ready = _employee_selector != null and _gross_input != null and _preset_selector != null and _cost_label != null and _save_button != null
	hide()

func show_panel() -> void:
	show()
	_toltes()

func hide_panel() -> void:
	hide()

func _toltes() -> void:
	if not _ui_ready:
		return
	_employee_selector.clear()
	_preset_selector.clear()
	_cost_label.text = "Válassz alkalmazottat."
	_gross_input.value = 0

	var preset_lista = _presetek()
	for preset_id in preset_lista.keys():
		var adat_any = preset_lista.get(preset_id, {})
		var adat = adat_any if adat_any is Dictionary else {}
		var cimke = str(adat.get("label", preset_id))
		_preset_selector.add_item(cimke)
		_preset_selector.set_item_metadata(_preset_selector.get_item_count() - 1, preset_id)

	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		_cost_label.text = "❌ Alkalmazotti rendszer nem elérhető."
		return

	var lista = EmployeeSystem1.get_employees()
	for emp_any in lista:
		var emp = emp_any if emp_any is Dictionary else {}
		var nev = str(emp.get("name", emp.get("id", "Ismeretlen")))
		_employee_selector.add_item(nev)
		_employee_selector.set_item_metadata(_employee_selector.get_item_count() - 1, str(emp.get("id", "")))

	if _employee_selector.get_item_count() > 0:
		_employee_selector.select(0)
		_on_employee_selected(0)

func _presetek() -> Dictionary:
	var katalogus = load("res://scripts/systems/employees/EmployeeCatalog.gd").new()
	return katalogus.payroll_presets

func _on_employee_selected(index: int) -> void:
	var emp_id = _employee_selector.get_item_metadata(index)
	if typeof(emp_id) != TYPE_STRING:
		return
	var emp = _keres_emp(emp_id)
	if emp.is_empty():
		return
	_gross_input.value = int(emp.get("gross", 0))
	_kivalaszt_preset(str(emp.get("payroll_preset", "")))
	_frissit_koltseg(emp_id)

func _kivalaszt_preset(preset_id: String) -> void:
	var keresett = str(preset_id)
	for i in _preset_selector.get_item_count():
		var meta = _preset_selector.get_item_metadata(i)
		if typeof(meta) == TYPE_STRING and meta == keresett:
			_preset_selector.select(i)
			return
	_preset_selector.select(0)

func _on_gross_changed(_value: float) -> void:
	_frissit_koltseg(_akt_emp_id())

func _on_preset_selected(_index: int) -> void:
	_frissit_koltseg(_akt_emp_id())

func _akt_emp_id() -> String:
	if _employee_selector == null:
		return ""
	var meta = _employee_selector.get_item_metadata(_employee_selector.get_selected_id())
	return meta if typeof(meta) == TYPE_STRING else ""

func _frissit_koltseg(emp_id: String) -> void:
	if emp_id == "":
		return
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return
	var gross = int(_gross_input.value)
	var preset = _valasztott_preset()
	EmployeeSystem1.set_payroll(emp_id, gross, preset)
	var total = EmployeeSystem1.get_monthly_total_cost(emp_id)
	_cost_label.text = "Teljes havi munkáltatói költség: %d Ft" % total

func _valasztott_preset() -> String:
	var meta = _preset_selector.get_item_metadata(_preset_selector.get_selected_id())
	return meta if typeof(meta) == TYPE_STRING else "mvp_basic"

func _on_save_pressed() -> void:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return
	var emp_id = _akt_emp_id()
	if emp_id == "":
		return
	var gross = int(_gross_input.value)
	var preset = _valasztott_preset()
	EmployeeSystem1.set_payroll(emp_id, gross, preset)
	_frissit_koltseg(emp_id)
	if typeof(EventBus1) != TYPE_NIL and EventBus1 != null and EventBus1.has_signal("notification_requested"):
		EventBus1.emit_signal("notification_requested", "💾 Bérbeállítás mentve.")

func _on_back_pressed() -> void:
	hide_panel()
	var panel = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/BookkeepingPanel")
	if panel and panel.has_method("show_panel"):
		panel.show_panel()
	elif panel:
		panel.show()

func _keres_emp(emp_id: String) -> Dictionary:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return {}
	var lista = EmployeeSystem1.get_employees()
	for emp_any in lista:
		var emp = emp_any if emp_any is Dictionary else {}
		if str(emp.get("id", "")) == str(emp_id):
			return emp
	return {}
