extends Control

const KARTYAK_UTVONAL: NodePath = ^"Panel/VBoxContainer/ScrollContainer/CardsVBox"

@onready var _vbox: Container = _resolve_cards_container()
@onready var _scroll: ScrollContainer = _resolve_scroll_container()
@onready var _back_button: Button = get_node_or_null("Panel/VBoxContainer/BtnBack")

var _my_panel: Control
var _ui_root: Node
var _debug_nyitas_pending := false
var _debug_elso_kartya_kiirva := false

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
	show()

func hide_panel() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		_debug_nyitas_pending = true
		_debug_elso_kartya_kiirva = false
		await _refresh()

func _refresh() -> void:
	if _vbox == null:
		_log_kontener_hiany()
		return
	_ensure_container_layout()
	if _debug_nyitas_pending:
		_log_kontener_info()
	for child in _vbox.get_children():
		_vbox.remove_child(child)
		child.queue_free()
	await get_tree().process_frame
	var rendszer = _get_employee_system()
	var jeloltek: Array = []
	if rendszer != null and rendszer.has_method("get_candidates"):
		jeloltek = rendszer.get_candidates()
	for jelolt_any in jeloltek:
		if jelolt_any is Dictionary:
			_add_card(jelolt_any)
	if jeloltek.is_empty():
		var ures = Label.new()
		ures.text = "Nincs elérhető jelölt."
		_vbox.add_child(ures)
	if _debug_nyitas_pending:
		print("[EMP_UI] container=", _vbox.get_path(), " size=", _vbox.size, " visible=", _vbox.visible, " children_after=", _vbox.get_child_count())
	_debug_nyitas_pending = false

func _add_card(seeker: Dictionary) -> void:
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(0, 96)
	kartya.add_theme_constant_override("margin_left", 8)
	kartya.add_theme_constant_override("margin_right", 8)
	kartya.add_theme_constant_override("margin_top", 4)
	kartya.add_theme_constant_override("margin_bottom", 4)
	kartya.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartya.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kartya.modulate = Color(1, 1, 1, 1)
	kartya.show()

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartya.add_child(vbox)

	var nev = _dict_str(seeker, "name", "")
	if nev == "":
		nev = _dict_str(seeker, "id", "Ismeretlen")
	var lbl_nev = Label.new()
	var ber = _dict_int(seeker, "wage", _dict_int(seeker, "wage_request", 0))
	lbl_nev.text = "%s | bér: %d Ft | speed:%d cook:%d rel:%d" % [
		nev,
		ber,
		_dict_int(seeker, "speed", 0),
		_dict_int(seeker, "cook", 0),
		_dict_int(seeker, "reliability", 0)
	]
	lbl_nev.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(lbl_nev)

	var gombsor = HBoxContainer.new()
	gombsor.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(gombsor)

	var btn_hire = Button.new()
	btn_hire.text = "Felvétel"
	btn_hire.pressed.connect(_on_hire_pressed.bind(_dict_str(seeker, "id", "")))
	gombsor.add_child(btn_hire)

	var btn_reject = Button.new()
	btn_reject.text = "Elutasítás"
	btn_reject.pressed.connect(_on_reject_pressed.bind(_dict_str(seeker, "id", "")))
	gombsor.add_child(btn_reject)

	_vbox.add_child(kartya)
	if _debug_nyitas_pending and not _debug_elso_kartya_kiirva:
		_debug_elso_kartya_kiirva = true
		print("[EMP_UI] elso_kartya_rect=", kartya.get_global_rect())

func _on_back_pressed() -> void:
	var main_menu = _get_book_menu()
	if main_menu != null and main_menu.has_method("show_main_menu"):
		main_menu.call("show_main_menu", "EmployeesHirePanel")
	hide()

func _on_hire_pressed(seeker_id: String) -> void:
	var rendszer = _get_employee_system()
	if rendszer == null:
		_toast("❌ Alkalmazotti rendszer nem érhető el.")
		return
	rendszer.hire(seeker_id)
	_toast("✅ Felvétel rögzítve.")
	await _refresh()
	_refresh_my_panel()

func _on_reject_pressed(seeker_id: String) -> void:
	var rendszer = _get_employee_system()
	if rendszer == null:
		_toast("❌ Alkalmazotti rendszer nem érhető el.")
		return
	rendszer.reject(seeker_id)
	_toast("❌ Jelölt elutasítva.")
	await _refresh()

func _refresh_my_panel() -> void:
	if _my_panel != null and _my_panel.has_method("refresh_list"):
		_my_panel.call("refresh_list")

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

func _resolve_cards_container() -> Container:
	var fixed = get_node_or_null(KARTYAK_UTVONAL)
	if fixed is Container:
		return fixed
	var found = find_child("CardsVBox", true, false)
	if found is Container:
		return found
	found = find_child("Cards", true, false)
	if found is Container:
		return found
	return null

func _resolve_scroll_container() -> ScrollContainer:
	var fixed = get_node_or_null("Panel/VBoxContainer/ScrollContainer")
	if fixed is ScrollContainer:
		return fixed
	var found = find_child("ScrollContainer", true, false)
	if found is ScrollContainer:
		return found
	return null

func _ensure_container_layout() -> void:
	if _scroll != null:
		_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _vbox != null:
		_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _log_kontener_hiany() -> void:
	var panel = get_node_or_null("Panel")
	if panel == null:
		push_error("[EMP_ERR] Hiányzik a Cards konténer, a Panel sem található.")
		return
	var nevek: Array[String] = []
	for child in panel.get_children():
		nevek.append(child.name)
	push_error("[EMP_ERR] Hiányzik a Cards konténer. Panel gyerekek: %s" % ", ".join(nevek))

func _log_kontener_info() -> void:
	if _vbox == null:
		return
	print("[EMP_UI] container=", _vbox.get_path(), " size=", _vbox.size, " global_position=", _vbox.global_position, " visible=", _vbox.visible, " clip_contents=", _vbox.clip_contents)

func _get_book_menu() -> Node:
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	return root.find_child("BookMenu", true, false)
