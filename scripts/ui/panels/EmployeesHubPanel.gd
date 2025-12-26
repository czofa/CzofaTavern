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
var _book_menu: Control
var _jelzett_hianyok: Dictionary = {}

func _ready() -> void:
	_cache_nodes()
	_connect_buttons()
	hide()

func show_panel() -> void:
	_hide_child_panels()
	if _book_menu != null:
		_book_menu.visible = false
		if _book_menu.has_method("_apply_state"):
			_book_menu.call_deferred("_apply_state")
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_hire_button = get_node_or_null(hire_button_path)
	_my_button = get_node_or_null(my_button_path)
	_back_button = get_node_or_null(back_button_path)
	_hire_panel = get_node_or_null(hire_panel_path)
	_my_panel = get_node_or_null(my_panel_path)
	_book_menu = get_node_or_null(book_menu_path)

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
	hide()
	if _book_menu == null:
		_warn_once("book_menu", "❌ Főmenü nem található, visszalépés leállt.")
		return
	_book_menu.visible = true
	_apply_menu_state()

func _hide_child_panels() -> void:
	if _hire_panel != null and _hire_panel.has_method("hide_panel"):
		_hire_panel.call("hide_panel")
	if _my_panel != null and _my_panel.has_method("hide_panel"):
		_my_panel.call("hide_panel")

func _apply_menu_state() -> void:
	if _book_menu == null:
		_warn_once("book_menu", "❌ Főmenü nem található, visszalépés leállt.")
		return
	if _book_menu.has_method("_apply_state"):
		_book_menu.call_deferred("_apply_state")

func _warn_once(kulcs: String, uzenet: String) -> void:
	if _jelzett_hianyok.has(kulcs):
		return
	_jelzett_hianyok[kulcs] = true
	push_warning(uzenet)
