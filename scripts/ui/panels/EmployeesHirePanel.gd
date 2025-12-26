extends Control

@onready var _vbox: VBoxContainer = %CardsVBox
@onready var _back_button: Button = %BtnBack

var _my_panel: Control
var _ui_root: Node

func _ready() -> void:
	_my_panel = _find_my_panel()
	_ui_root = _get_ui_root()
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	hide()

func show_panel() -> void:
	_refresh()
	show()

func hide_panel() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		_refresh()

func _refresh() -> void:
	if _vbox == null:
		push_error("[EMP_ERR] Hiányzik a CardsVBox konténer.")
		return
	for child in _vbox.get_children():
		child.queue_free()
	var jeloltek = _leker_jeloltek()
	var letrehozott = 0
	for jelolt_any in jeloltek:
		if jelolt_any is Dictionary:
			_add_card(jelolt_any)
			letrehozott += 1
	print("[EMP_UI_OK] created=", letrehozott, " candidates=", jeloltek.size())

func _add_card(seeker: Dictionary) -> void:
	var kartya = PanelContainer.new()
	kartya.add_theme_constant_override("margin_left", 8)
	kartya.add_theme_constant_override("margin_right", 8)
	kartya.add_theme_constant_override("margin_top", 4)
	kartya.add_theme_constant_override("margin_bottom", 4)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartya.add_child(vbox)

	var nev = _dict_str(seeker, "name", "")
	if nev == "":
		nev = _dict_str(seeker, "id", "Ismeretlen")
	var lbl_nev = Label.new()
	lbl_nev.text = nev
	vbox.add_child(lbl_nev)

	var statok = "Sebesség: %d | Főzés: %d | Megbízhatóság: %d" % [
		_dict_int(seeker, "speed", 0),
		_dict_int(seeker, "cook", 0),
		_dict_int(seeker, "reliability", 0)
	]
	var lbl_stat = Label.new()
	lbl_stat.text = statok
	vbox.add_child(lbl_stat)

	var igeny = _dict_int(seeker, "wage_request", 0)
	var lbl_wage = Label.new()
	lbl_wage.text = "Bérigény: %d Ft/nap" % igeny
	vbox.add_child(lbl_wage)

	var gombsor = HBoxContainer.new()
	gombsor.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(gombsor)

	var btn_hire = Button.new()
	btn_hire.text = "Felvétel"
	btn_hire.pressed.connect(_on_hire_pressed.bind(_dict_str(seeker, "id", "")))
	gombsor.add_child(btn_hire)

	var btn_reject = Button.new()
	btn_reject.text = "Elutasít"
	btn_reject.pressed.connect(_on_reject_pressed.bind(_dict_str(seeker, "id", "")))
	gombsor.add_child(btn_reject)

	_vbox.add_child(kartya)

func _on_back_pressed() -> void:
	hide()
	if _ui_root != null and _ui_root.has_method("open_main_menu"):
		_ui_root.call("open_main_menu")
		return
	var main_menu = _get_book_menu()
	if main_menu is Control:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _on_hire_pressed(seeker_id: String) -> void:
	var rendszer = _get_employee_system()
	if rendszer == null:
		_toast("❌ Alkalmazotti rendszer nem érhető el.")
		return
	if rendszer.has_method("hire"):
		rendszer.hire(seeker_id)
	else:
		rendszer.hire_employee(seeker_id)
	_toast("✅ Felvétel rögzítve.")
	_refresh()
	_refresh_my_panel()

func _on_reject_pressed(seeker_id: String) -> void:
	var rendszer = _get_employee_system()
	if rendszer == null:
		_toast("❌ Alkalmazotti rendszer nem érhető el.")
		return
	if rendszer.has_method("reject"):
		rendszer.reject(seeker_id)
	else:
		rendszer.reject_seeker(seeker_id)
	_toast("❌ Jelölt elutasítva.")
	_refresh()

func _refresh_my_panel() -> void:
	if _my_panel != null and _my_panel.has_method("refresh_list"):
		_my_panel.call("refresh_list")

func _leker_jeloltek() -> Array:
	var rendszer = _get_employee_system()
	if rendszer == null:
		push_error("[EMP_ERR] Alkalmazotti rendszer nem elérhető, helyi jelölt lista töltődik.")
		return _lokalis_fallback_jeloltek()
	if rendszer.has_method("ensure_seed_candidates"):
		rendszer.ensure_seed_candidates()
	var seekers: Array = []
	if rendszer.has_method("get_candidates"):
		seekers = rendszer.get_candidates()
	else:
		seekers = rendszer.get_job_seekers()
	if seekers.is_empty():
		return _lokalis_fallback_jeloltek()
	return seekers

func _lokalis_fallback_jeloltek() -> Array:
	return [
		{
			"id": "local_jelolt_1",
			"name": "Tomi",
			"speed": 4,
			"cook": 3,
			"reliability": 4,
			"wage_request": 1100
		},
		{
			"id": "local_jelolt_2",
			"name": "Lili",
			"speed": 3,
			"cook": 5,
			"reliability": 5,
			"wage_request": 1400
		},
		{
			"id": "local_jelolt_3",
			"name": "Áron",
			"speed": 5,
			"cook": 2,
			"reliability": 3,
			"wage_request": 1250
		}
	]

func _get_employee_system() -> Node:
	if typeof(EmployeeSystem1) != TYPE_NIL and EmployeeSystem1 != null:
		return EmployeeSystem1
	return get_node_or_null("/root/EmployeeSystem1")

func _dict_str(adat: Dictionary, kulcs: String, alap: String) -> String:
	if adat.has(kulcs):
		return str(adat[kulcs])
	return alap

func _dict_int(adat: Dictionary, kulcs: String, alap: int) -> int:
	if adat.has(kulcs):
		return int(adat[kulcs])
	return alap

func _toast(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)

func _find_my_panel() -> Control:
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	var found = root.find_child("EmployeesMyPanel", true, false)
	if found is Control:
		return found
	return null

func _get_ui_root() -> Node:
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	var found = root.find_child("UiRoot", true, false)
	if found == null:
		found = root.find_child("UIRoot", true, false)
	return found

func _get_book_menu() -> Node:
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	return root.find_child("BookMenu", true, false)
