extends Control

@export var list_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll/List"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"
@export var hub_panel_path: NodePath = ^"../EmployeesHubPanel"
@export var book_menu_path: NodePath = ^"../BookMenu"

var _list_container: VBoxContainer
var _back_button: Button
var _hub_panel: Control
var _ui_root: Node
var _jelzett_hianyok: Dictionary = {}

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	hide()

func show_panel() -> void:
	_cache_nodes()
	_close_main_menu()
	refresh_list()
	show()

func hide_panel() -> void:
	hide()

func refresh_list() -> void:
	if _list_container == null:
		_warn_once("lista", "❌ Alkalmazott lista konténer hiányzik.")
		return
	for child in _list_container.get_children():
		child.queue_free()
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		_add_info("❌ Alkalmazotti rendszer nem érhető el.")
		return
	var lista: Array = []
	if EmployeeSystem1.has_method("get_hired"):
		lista = EmployeeSystem1.get_hired()
	else:
		lista = EmployeeSystem1.get_employees()
	if lista.is_empty():
		_add_info("Nincs alkalmazott.")
		return
	for emp_any in lista:
		var emp = emp_any if emp_any is Dictionary else {}
		_add_card(emp)

func _cache_nodes() -> void:
	_list_container = get_node_or_null(list_container_path)
	_back_button = get_node_or_null(back_button_path)
	_hub_panel = get_node_or_null(hub_panel_path)
	_ui_root = _get_ui_root()

func _connect_signals() -> void:
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

func _add_info(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _list_container != null:
		_list_container.add_child(lbl)

func _add_card(emp: Dictionary) -> void:
	var kartya = PanelContainer.new()
	kartya.add_theme_constant_override("margin_left", 8)
	kartya.add_theme_constant_override("margin_right", 8)
	kartya.add_theme_constant_override("margin_top", 4)
	kartya.add_theme_constant_override("margin_bottom", 4)

	var hbox = HBoxContainer.new()
	kartya.add_child(hbox)

	var kep = TextureRect.new()
	kep.custom_minimum_size = Vector2(64, 64)
	kep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path = str(emp.get("portrait_path", ""))
	var tex = null
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		tex = load(portrait_path)
	elif ResourceLoader.exists("res://icon.svg"):
		tex = load("res://icon.svg")
	kep.texture = tex
	hbox.add_child(kep)

	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)

	var nev = str(emp.get("name", emp.get("id", "Ismeretlen")))
	var lbl_nev = Label.new()
	lbl_nev.text = nev
	vbox.add_child(lbl_nev)

	var statok = "Sebesség: %d | Főzés: %d | Megbízhatóság: %d" % [
		int(emp.get("speed", 0)),
		int(emp.get("cook", 0)),
		int(emp.get("reliability", 0))
	]
	var lbl_stat = Label.new()
	lbl_stat.text = statok
	vbox.add_child(lbl_stat)

	var igeny = int(emp.get("wage_request", 0))
	var lbl_ber = Label.new()
	lbl_ber.text = "Bérigény: %d Ft/nap" % igeny
	vbox.add_child(lbl_ber)

	var gomb_sor = HBoxContainer.new()
	vbox.add_child(gomb_sor)

	var btn_fire = Button.new()
	btn_fire.text = "Kirúgás"
	btn_fire.pressed.connect(_on_fire_pressed.bind(str(emp.get("id", ""))))
	gomb_sor.add_child(btn_fire)

	_list_container.add_child(kartya)

func _on_back_pressed() -> void:
	hide()
	if _ui_root != null and _ui_root.has_method("open_main_menu"):
		_ui_root.call("open_main_menu")
		return
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu is Control:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _close_main_menu() -> void:
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu != null and main_menu.has_method("close_menu"):
		main_menu.call("close_menu")

func _on_fire_pressed(emp_id: String) -> void:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return
	if EmployeeSystem1.has_method("fire"):
		EmployeeSystem1.fire(emp_id)
	else:
		EmployeeSystem1.fire_employee(emp_id)
	refresh_list()

func _warn_once(kulcs: String, uzenet: String) -> void:
	if _jelzett_hianyok.has(kulcs):
		return
	_jelzett_hianyok[kulcs] = true
	push_warning(uzenet)

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
