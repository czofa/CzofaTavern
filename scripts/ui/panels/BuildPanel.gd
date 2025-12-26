extends Control

const BuildCatalog = preload("res://scripts/world/BuildCatalog.gd")

@onready var _grid: GridContainer = %CardsGrid
@onready var _status_label: Label = %Status
@onready var _back_button: Button = %BackButton

var _catalog: BuildCatalog
var _build_controller: Node

func _ready() -> void:
	_catalog = BuildCatalog.new()
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	hide()

func show_panel() -> void:
	_rebuild_cards()
	visible = true
	z_as_relative = false
	z_index = 1100
	move_to_front()
	show()

func hide_panel() -> void:
	hide()

func _on_visibility_changed() -> void:
	if visible:
		_rebuild_cards()

func _rebuild_cards() -> void:
	if _grid == null:
		push_error("[BUILD_ERR] Hiányzik a CardsGrid konténer.")
		return
	for child in _grid.get_children():
		child.queue_free()
	var elemek = _get_katalogus_elemek()
	var letrehozott = 0
	for adat in elemek:
		if adat is Dictionary:
			_add_card(adat)
			letrehozott += 1
	if _status_label != null:
		_status_label.text = "Válassz egy elemet az építéshez."
	print("[BUILD_UI_OK] created=", letrehozott, " items=", elemek.size(), " grid_children=", _grid.get_child_count())

func _add_card(adat: Dictionary) -> void:
	var kulcs = str(adat.get("id", "")).strip_edges()
	if kulcs == "":
		return
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(220, 160)
	kartya.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kartya.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kartya.add_child(box)

	var nev = str(adat.get("display_name", "")).strip_edges()
	if nev == "":
		nev = str(adat.get("cimke", kulcs))
	var cim = Label.new()
	cim.text = nev
	box.add_child(cim)

	var koltseg = Label.new()
	koltseg.text = "Költség: %s" % _format_koltseg(adat)
	koltseg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(koltseg)

	var gomb = Button.new()
	gomb.text = "Építés"
	gomb.pressed.connect(_on_build_pressed.bind(kulcs))
	box.add_child(gomb)

	_grid.add_child(kartya)

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
				reszek.append("%s: %dg" % [id, menny])
		reszek.sort()
		if not reszek.is_empty():
			return ", ".join(reszek)
	var alap = str(adat.get("koltseg", "")).strip_edges()
	if alap == "":
		return "nincs megadva"
	return alap

func _get_katalogus_elemek() -> Array:
	var elemek: Array = []
	if _catalog == null:
		_catalog = BuildCatalog.new()
	if _catalog != null and _catalog.has_method("get_items"):
		elemek = _catalog.get_items()
	if elemek.is_empty():
		elemek = _fallback_elemek()
	return elemek

func _fallback_elemek() -> Array:
	return [
		{
			"id": "chair",
			"display_name": "Szék",
			"cimke": "Szék",
			"cost_map": {"wood": 8, "nails": 4}
		},
		{
			"id": "table",
			"display_name": "Asztal",
			"cimke": "Asztal",
			"cost_map": {"wood": 12, "nails": 6, "stone": 2}
		},
		{
			"id": "decor",
			"display_name": "Dekor",
			"cimke": "Dekor",
			"cost_map": {"wood": 4, "stone": 1}
		}
	]

func _on_build_pressed(kulcs: String) -> void:
	var build = _get_build_controller()
	if build == null:
		push_error("[BUILD_ERR] Hiányzik az építési vezérlő.")
		return
	if build.has_method("start_build_mode_with_key"):
		build.call("start_build_mode_with_key", kulcs)
	elif build.has_method("start_build"):
		build.call("start_build", kulcs)
	else:
		push_error("[BUILD_ERR] Hiányzó építési indítási metódus.")
		return
	hide_panel()
	_close_menu_after_build()

func _close_menu_after_build() -> void:
	var main_menu = _get_book_menu()
	if main_menu != null and main_menu.has_method("close_menu"):
		main_menu.call("close_menu")
		return
	if main_menu is Control:
		main_menu.visible = false
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _on_back_pressed() -> void:
	hide_panel()
	var ui_root = _get_ui_root()
	if ui_root != null and ui_root.has_method("open_main_menu"):
		ui_root.call("open_main_menu")
		return
	var main_menu = _get_book_menu()
	if main_menu is Control:
		main_menu.visible = true
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
	_build_controller = root.find_child("BuildController", true, false)
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

func _get_book_menu() -> Node:
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	return root.find_child("BookMenu", true, false)
