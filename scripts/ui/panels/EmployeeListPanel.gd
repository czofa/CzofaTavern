extends Control

@export var list_container_path: NodePath = ^"MarginContainer/VBoxContainer/List"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"

var _list_container: VBoxContainer
var _back_button: Button
var _ui_ready: bool = false

func _ready() -> void:
	_list_container = get_node_or_null(list_container_path)
	_back_button = get_node_or_null(back_button_path)

	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)

	if _list_container == null:
		push_warning("ℹ️ Alkalmazott lista konténer hiányzik.")
	else:
		_ui_ready = true

	hide()

func show_panel() -> void:
	show()
	_frissit_lista()

func hide_panel() -> void:
	hide()

func _frissit_lista() -> void:
	if not _ui_ready:
		return
	for child in _list_container.get_children():
		child.queue_free()

	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		_add_sor("❌ Alkalmazotti rendszer nem elérhető.", "", false, "")
		return

	var most = TimeSystem1.get_game_minutes() if typeof(TimeSystem1) != TYPE_NIL and TimeSystem1 != null else 0
	var lista = EmployeeSystem1.get_employees()
	if lista.is_empty():
		_add_sor("Nincs alkalmazott.", "", false, "")
		return

	for emp_any in lista:
		var emp = emp_any if emp_any is Dictionary else {}
		var nev = str(emp.get("name", emp.get("id", "Ismeretlen")))
		var statok = "Sebesség: %d | Főzés: %d | Megbízhatóság: %d" % [
			int(emp.get("speed", 0)),
			int(emp.get("cook", 0)),
			int(emp.get("reliability", 0))
		]
		var aktiv = _taverna_nyitva(int(most)) and _alkalmazott_aktiv(emp, int(most))
		var statusz = "Aktív műszakban" if aktiv else "Pihen"
		_add_sor(nev, "%s | %s" % [statok, statusz], true, str(emp.get("id", "")))

func _taverna_nyitva(minutes: int) -> bool:
	if not Engine.has_singleton("EmployeeSystem1") and typeof(EmployeeSystem1) == TYPE_NIL:
		return true
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return true
	if not EmployeeSystem1.has_method("is_tavern_open"):
		return true
	return EmployeeSystem1.is_tavern_open(minutes)

func _alkalmazott_aktiv(emp: Dictionary, minutes: int) -> bool:
	var start = int(emp.get("shift_start", 0))
	var end = int(emp.get("shift_end", 0))
	if start == 0 and end == 0:
		return true
	return minutes >= start and minutes <= end

func _add_sor(cim: String, al_cim: String, kirugas_gomb: bool, emp_id: String) -> void:
	var sor = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "%s\n%s" % [cim, al_cim]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sor.add_child(lbl)

	if kirugas_gomb and emp_id != "":
		var btn = Button.new()
		btn.text = "Kirúgás"
		btn.pressed.connect(_on_fire_pressed.bind(emp_id))
		sor.add_child(btn)

	_list_container.add_child(sor)

func _on_fire_pressed(emp_id: String) -> void:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return
	if EmployeeSystem1.fire_employee(emp_id):
		_frissit_lista()

func _on_back_pressed() -> void:
	hide_panel()
	var main_menu = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/BookMenu")
	if main_menu and main_menu.has_method("_apply_state"):
		main_menu.call_deferred("_apply_state")
