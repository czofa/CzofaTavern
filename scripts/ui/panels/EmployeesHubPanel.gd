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
	if _hire_button == null:
		push_error("❌ Hiányzó NodePath: %s" % hire_button_path)
		return
	if _my_button == null:
		push_error("❌ Hiányzó NodePath: %s" % my_button_path)
		return
	if _back_button == null:
		push_error("❌ Hiányzó NodePath: %s" % back_button_path)
		return
	_hide_child_panels()
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
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s felvetel_panel_null=%s vilag=%s" % [
		_gomb_nev(_hire_button),
		str(_hire_panel == null),
		kontextus
	])
	if _hire_panel == null:
		push_error("❌ Hiányzó NodePath: %s" % hire_panel_path)
		return
	hide()
	if _hire_panel.has_method("show_panel"):
		_hire_panel.call("show_panel")
	elif _hire_panel is Control:
		_hire_panel.show()
	else:
		push_error("❌ Alkalmazotti felvételi panel nem Control.")
		return

func _on_my_pressed() -> void:
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s sajat_panel_null=%s vilag=%s" % [
		_gomb_nev(_my_button),
		str(_my_panel == null),
		kontextus
	])
	if _my_panel == null:
		push_error("❌ Hiányzó NodePath: %s" % my_panel_path)
		return
	hide()
	if _my_panel.has_method("show_panel"):
		_my_panel.call("show_panel")
	elif _my_panel is Control:
		_my_panel.show()
	else:
		push_error("❌ Saját alkalmazotti panel nem Control.")
		return

func _on_back_pressed() -> void:
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s fomenü_null=%s vilag=%s" % [
		_gomb_nev(_back_button),
		str(_book_menu == null),
		kontextus
	])
	hide()
	_apply_menu_state()

func _hide_child_panels() -> void:
	if _hire_panel != null and _hire_panel.has_method("hide_panel"):
		_hire_panel.call("hide_panel")
	if _my_panel != null and _my_panel.has_method("hide_panel"):
		_my_panel.call("hide_panel")

func _apply_menu_state() -> void:
	if _book_menu == null:
		push_error("❌ Hiányzó NodePath: %s" % book_menu_path)
		return
	if _book_menu.has_method("_apply_state"):
		_book_menu.call_deferred("_apply_state")

func _warn_once(kulcs: String, uzenet: String) -> void:
	if _jelzett_hianyok.has(kulcs):
		return
	_jelzett_hianyok[kulcs] = true
	push_warning(uzenet)

func _gomb_nev(gomb: Button) -> String:
	if gomb == null:
		return "ismeretlen"
	return str(gomb.name)

func _world_kontextus() -> String:
	var vilag = _get_aktiv_vilag()
	if vilag != null:
		var csoport_alap = _vilag_kontextus_csoportbol(vilag)
		if csoport_alap != "":
			return csoport_alap
	return _fallback_vilag_kontextus()

func _get_aktiv_vilag() -> Node:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	var csoportok = ["world_tavern", "world_town", "world_farm", "world_mine"]
	for csoport in csoportok:
		var nodek = tree.get_nodes_in_group(csoport)
		for node_any in nodek:
			if node_any is Node:
				var node = node_any as Node
				if not node.is_inside_tree():
					continue
				if _vilag_lathato(node):
					return node
	return null

func _vilag_lathato(node: Node) -> bool:
	if node is Node3D:
		return (node as Node3D).visible
	if node is CanvasItem:
		return (node as CanvasItem).visible
	return true

func _vilag_kontextus_csoportbol(vilag: Node) -> String:
	if vilag == null:
		return ""
	if vilag.is_in_group("world_tavern"):
		return "tavern"
	if vilag.is_in_group("world_town"):
		return "town"
	if vilag.is_in_group("world_farm"):
		return "farm"
	if vilag.is_in_group("world_mine"):
		return "mine"
	return ""

func _fallback_vilag_kontextus() -> String:
	var tree = get_tree()
	if tree != null and tree.current_scene != null:
		var nev = str(tree.current_scene.name).to_lower()
		if nev != "":
			return nev
		var ut = str(tree.current_scene.scene_file_path).to_lower()
		if ut != "":
			return ut
	return "ismeretlen"
