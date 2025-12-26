extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var status_label_path: NodePath = ^"MarginContainer/VBoxContainer/Status"
@export var scroll_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll"
@export var card_grid_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll/Grid"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"
@export var build_controller_path: NodePath = ^"../../../WorldRoot/TavernWorld/BuildController"
@export var book_menu_path: NodePath = ^"../BookMenu"

const BuildCatalog = preload("res://scripts/world/BuildCatalog.gd")
const _MVP_ELEMEK := ["chair_basic", "table_basic", "decor_basic"]

var _title_label: Label
var _status_label: Label
var _card_grid: GridContainer
var _back_button: Button
var _build_controller: Node
var _catalog: BuildCatalog
var _ui_root: Node

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	_cache_nodes()
	_frissit_kartyak()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_status_label = get_node_or_null(status_label_path) as Label
	_card_grid = get_node_or_null(card_grid_path) as GridContainer
	_back_button = get_node_or_null(back_button_path) as Button
	_build_controller = get_node_or_null(build_controller_path)
	_ui_root = _get_ui_root()

	if _title_label != null:
		_title_label.text = "🏗️ Építés"
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

func _on_back_pressed() -> void:
	_hide_panel_to_menu()

func _hide_panel_to_menu() -> void:
	hide_panel()
	if _ui_root != null and _ui_root.has_method("open_main_menu"):
		_ui_root.call("open_main_menu")
		return
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu is Control:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _frissit_status(uzenet: String = "") -> void:
	if _status_label == null:
		return
	if uzenet != "":
		_status_label.text = uzenet
		return
	_status_label.text = "Válassz egy elemet az építéshez."

func _frissit_kartyak() -> void:
	if _card_grid == null:
		return
	for child in _card_grid.get_children():
		child.queue_free()
	if _catalog == null:
		_catalog = BuildCatalog.new()
	var elemek = _catalog.get_items()
	if elemek.is_empty():
		_frissit_status("Nincs build elem (hiba).")
		elemek = _fallback_elemei()
	else:
		_frissit_status()
	var epitheto = 0
	for adat in elemek:
		if adat is Dictionary:
			_hozzaad_kartya(adat)
			epitheto += 1
	if epitheto == 0:
		_add_info("Nincs építhető elem.")

func _hozzaad_kartya(adat: Dictionary) -> void:
	var kulcs = str(adat.get("id", "")).strip_edges()
	if kulcs == "":
		return
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(220, 160)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kartya.add_child(box)

	var kep = TextureRect.new()
	kep.custom_minimum_size = Vector2(64, 64)
	kep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://icon.svg"):
		kep.texture = load("res://icon.svg")
	box.add_child(kep)

	var cim = Label.new()
	var nev = str(adat.get("display_name", ""))
	if nev == "":
		nev = str(adat.get("cimke", kulcs))
	cim.text = nev
	box.add_child(cim)

	var koltseg_szoveg = _format_koltseg(adat)
	var koltseg = Label.new()
	koltseg.text = "Költség: %s" % koltseg_szoveg
	box.add_child(koltseg)

	var gomb = Button.new()
	gomb.text = "Építés"
	gomb.pressed.connect(_on_kartya_valaszt.bind(kulcs))
	box.add_child(gomb)

	_card_grid.add_child(kartya)

func _add_info(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_grid.add_child(lbl)

func _format_koltseg(adat: Dictionary) -> String:
	var map = {}
	if adat.has("cost_map") and adat["cost_map"] is Dictionary:
		map = adat["cost_map"]
	elif adat.has("koltseg_map") and adat["koltseg_map"] is Dictionary:
		map = adat["koltseg_map"]
	if map is Dictionary:
		var reszek: Array = []
		for kulcs in map.keys():
			var id = String(kulcs).strip_edges()
			var menny = int(map.get(kulcs, 0))
			if id != "" and menny > 0:
				reszek.append("%s: %d g" % [id, menny])
		reszek.sort()
		if not reszek.is_empty():
			return ", ".join(reszek)
	var alap = str(adat.get("koltseg", "")).strip_edges()
	if alap == "":
		return "nincs megadva"
	return alap

func _fallback_elemei() -> Array:
	var lista: Array = []
	for kulcs in _MVP_ELEMEK:
		var adat = _catalog.get_data(kulcs)
		if adat.is_empty():
			continue
		lista.append(adat)
	return lista

func _on_kartya_valaszt(kulcs: String) -> void:
	var build = _get_build_controller()
	if build == null:
		_frissit_status("❌ Építési vezérlő nem érhető el.")
		return
	if build.has_method("start_build_mode_with_key"):
		build.call("start_build_mode_with_key", kulcs)
	elif build.has_method("toggle_build_mode_from_ui"):
		build.call("toggle_build_mode_from_ui")
	hide_panel()
	_close_menu_after_build()

func _close_menu_after_build() -> void:
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu != null and main_menu.has_method("close_menu"):
		main_menu.call("close_menu")
		return
	if main_menu is Control:
		main_menu.visible = false
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _get_build_controller() -> Node:
	if _build_controller != null:
		return _build_controller
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	var found = root.find_child("BuildController", true, false)
	if found != null:
		_build_controller = found
	return _build_controller

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
