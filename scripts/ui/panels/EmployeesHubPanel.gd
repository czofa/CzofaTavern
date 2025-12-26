extends Control

@export var hire_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnHire"
@export var my_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnMy"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"
@export var hire_panel_path: NodePath = ^"../EmployeesHirePanel"
@export var my_panel_path: NodePath = ^"../EmployeesMyPanel"
@export var book_menu_path: NodePath = ^"../BookMenu"

var _hire_button: Button
var _my_button: Button
var _back_button: Button
var _hire_panel: Control
var _my_panel: Control
var _ui_root: Node
var _jelzett_hianyok: Dictionary = {}

func _ready() -> void:
	_cache_nodes()
	_connect_buttons()
	hide()

func show_panel() -> void:
	_cache_nodes()
	_hide_child_panels()
	_close_main_menu()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_hire_button = get_node_or_null(hire_button_path)
	_my_button = get_node_or_null(my_button_path)
	_back_button = get_node_or_null(back_button_path)
	_hire_panel = get_node_or_null(hire_panel_path)
	_my_panel = get_node_or_null(my_panel_path)
	_ui_root = _get_ui_root()

func _connect_buttons() -> void:
	if _hire_button != null:
		var cb_hire = Callable(self, "_on_hire_pressed")
		if _hire_button.has_signal("pressed") and not _hire_button.pressed.is_connected(cb_hire):
			_hire_button.pressed.connect(cb_hire)
	if _my_button != null:
		var cb_my = Callable(self, "_on_my_pressed")
		if _my_button.has_signal("pressed") and not _my_button.pressed.is_connected(cb_my):
			_my_button.pressed.connect(cb_my)
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

func _on_hire_pressed() -> void:
	if _hire_panel == null:
		_warn_once("hire_panel", "❌ Alkalmazotti felvételi panel hiányzik.")
		return
	hide()
	if _hire_panel.has_method("show_panel"):
		_hire_panel.call("show_panel")

func _on_my_pressed() -> void:
	if _my_panel == null:
		_warn_once("my_panel", "❌ Saját alkalmazotti panel hiányzik.")
		return
	hide()
	if _my_panel.has_method("show_panel"):
		_my_panel.call("show_panel")

func _on_back_pressed() -> void:
	hide_panel()
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

func _hide_child_panels() -> void:
	if _hire_panel != null and _hire_panel.has_method("hide_panel"):
		_hire_panel.call("hide_panel")
	if _my_panel != null and _my_panel.has_method("hide_panel"):
		_my_panel.call("hide_panel")

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
