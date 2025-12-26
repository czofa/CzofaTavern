extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var status_label_path: NodePath = ^"MarginContainer/VBoxContainer/Status"
@export var scroll_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll"
@export var cards_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll/Grid"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"
@export var build_controller_path: NodePath = ^"../../../WorldRoot/TavernWorld/BuildController"
@export var book_menu_path: NodePath = ^"../BookMenu"
@export var debug_enabled: bool = false

const BuildCatalog = preload("res://scripts/world/BuildCatalog.gd")

var _title_label: Label
var _status_label: Label
var _diag_label: Label
var _scroll_container: ScrollContainer
var _cards_parent: GridContainer
var _back_button: Button
var _build_controller: Node
var _catalog: BuildCatalog
var _ui_root: Node
var _rendered_cards_count: int = 0
var _last_items_count: int = 0

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	_cache_nodes()
	_frissit_kartyak()
	_log_panel_megnyitas()
	visible = true
	z_as_relative = false
	z_index = 1100
	move_to_front()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_status_label = get_node_or_null(status_label_path) as Label
	_scroll_container = get_node_or_null(scroll_container_path) as ScrollContainer
	_cards_parent = get_node_or_null(cards_container_path) as GridContainer
	_back_button = get_node_or_null(back_button_path) as Button
	_build_controller = get_node_or_null(build_controller_path)
	_ui_root = _get_ui_root()

	_sync_diag_label()
	_ensure_cards_container()

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
	_ensure_cards_container()
	_last_items_count = 0
	_clear_hiba_label()
	if _catalog == null:
		_catalog = BuildCatalog.new()
	var elemek = _catalog.get_items()
	_last_items_count = elemek.size()
	if _cards_parent == null:
		_jelolj_hiba("BUILD_UI CONTAINER/PATH HIBA")
		var hiba_path = str(cards_container_path)
		push_error("[BUILD_ERR] BuildPanel: nem található a kártya konténer: %s" % hiba_path)
		_frissit_diag()
		return
	if debug_enabled:
		print("[BUILD_UI] cards_parent=", _cards_parent, " child_count=", _cards_parent.get_child_count())
	for child in _cards_parent.get_children():
		child.queue_free()
	_rendered_cards_count = 0
	if elemek.is_empty():
		push_error("[BUILD_ERR] BUILD_CATALOG ÜRES – WIRING/LOAD HIBA")
		_frissit_status("BUILD_CATALOG ÜRES – WIRING/LOAD HIBA")
		_jelolj_hiba("BUILD_CATALOG ÜRES – WIRING/LOAD HIBA")
		_frissit_diag()
		return
	else:
		_frissit_status()
	var epitheto = 0
	for adat in elemek:
		if adat is Dictionary:
			_hozzaad_kartya(adat)
			epitheto += 1
	if epitheto == 0:
		_add_info("Nincs építhető elem.")
	if _rendered_cards_count > 0 and _rendered_cards_count < 3:
		var hianyzo = 3 - _rendered_cards_count
		for _i in range(hianyzo):
			_add_placeholder_kartya()
	if _last_items_count > 0 and _rendered_cards_count == 0:
		push_error("[BUILD_ERR] BUILD_UI CONTAINER/PATH HIBA")
		_jelolj_hiba("BUILD_UI CONTAINER/PATH HIBA")
	_frissit_diag()

func _hozzaad_kartya(adat: Dictionary) -> void:
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

	var cim = Label.new()
	var nev = str(adat.get("display_name", ""))
	if nev == "":
		nev = str(adat.get("cimke", kulcs))
	cim.text = nev
	box.add_child(cim)

	var koltseg_szoveg = _format_koltseg(adat)
	var koltseg = Label.new()
	koltseg.text = "Költség: %s" % koltseg_szoveg
	koltseg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(koltseg)

	var gomb = Button.new()
	gomb.text = "Kiválaszt"
	gomb.pressed.connect(_on_kartya_valaszt.bind(kulcs))
	box.add_child(gomb)

	_cards_parent.add_child(kartya)
	_rendered_cards_count += 1

func _add_info(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cards_parent.add_child(lbl)

func _add_placeholder_kartya() -> void:
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(220, 160)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kartya.add_child(box)

	var cim = Label.new()
	cim.text = "Üres hely"
	cim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cim)

	var info = Label.new()
	info.text = "Nincs több építhető elem."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)

	_cards_parent.add_child(kartya)
	_rendered_cards_count += 1

func _jelolj_hiba(text: String) -> void:
	var vbox = _get_vbox_container()
	if vbox == null:
		push_error("[BUILD_ERR] BuildPanel: nem található a VBoxContainer a hiba kijelzéshez.")
		return
	_clear_hiba_label()
	var lbl = Label.new()
	lbl.name = "BuildErrorLabel"
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.set("theme_override_colors/font_color", Color(1, 0.25, 0.25))
	vbox.add_child(lbl)
	vbox.move_child(lbl, vbox.get_child_count() - 1)

func _clear_hiba_label() -> void:
	var vbox = _get_vbox_container()
	if vbox == null:
		return
	for child in vbox.get_children():
		if child is Label and child.name == "BuildErrorLabel":
			child.queue_free()

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

func _get_vbox_container() -> VBoxContainer:
	if _title_label != null and _title_label.get_parent() is VBoxContainer:
		return _title_label.get_parent() as VBoxContainer
	if _status_label != null and _status_label.get_parent() is VBoxContainer:
		return _status_label.get_parent() as VBoxContainer
	var found = get_node_or_null("MarginContainer/VBoxContainer")
	if found is VBoxContainer:
		return found
	return null

func _sync_diag_label() -> void:
	if not debug_enabled:
		if _diag_label != null and is_instance_valid(_diag_label):
			_diag_label.queue_free()
		_diag_label = null
		return
	var existing = get_node_or_null("BuildDiagLabel")
	if existing is Label:
		_diag_label = existing
	else:
		_diag_label = Label.new()
		_diag_label.name = "BuildDiagLabel"
		_diag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_diag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_diag_label.set("theme_override_font_sizes/font_size", 10)
		_diag_label.set("theme_override_colors/font_color", Color(1, 0.85, 0.2))
		add_child(_diag_label)
		_diag_label.anchor_left = 0.0
		_diag_label.anchor_top = 0.0
		_diag_label.anchor_right = 0.0
		_diag_label.anchor_bottom = 0.0
		_diag_label.offset_left = 6.0
		_diag_label.offset_top = 6.0
	_frissit_diag()

func _ensure_cards_container() -> void:
	var vbox = _get_vbox_container()
	if vbox == null:
		return
	if _scroll_container == null:
		var found_scroll = vbox.get_node_or_null("Scroll")
		if found_scroll is ScrollContainer:
			_scroll_container = found_scroll as ScrollContainer
	if _cards_parent == null and _scroll_container != null:
		var found_grid = _scroll_container.get_node_or_null("Grid")
		if found_grid is GridContainer:
			_cards_parent = found_grid as GridContainer
	if _scroll_container == null:
		_scroll_container = ScrollContainer.new()
		_scroll_container.name = "Scroll"
		_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		vbox.add_child(_scroll_container)
	if _scroll_container != null:
		_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _cards_parent == null and _scroll_container != null:
		_cards_parent = GridContainer.new()
		_cards_parent.name = "Grid"
		_cards_parent.columns = 2
		_cards_parent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cards_parent.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_cards_parent.set("theme_override_constants/h_separation", 12)
		_cards_parent.set("theme_override_constants/v_separation", 12)
		_scroll_container.add_child(_cards_parent)
	if _cards_parent != null:
		_cards_parent.columns = 2
		_cards_parent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cards_parent.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _frissit_diag() -> void:
	if _diag_label == null or not debug_enabled:
		return
	var node_path = "n/a"
	if is_inside_tree():
		node_path = str(get_path())
	var script_path = "ismeretlen"
	var script_res = get_script()
	if script_res != null:
		script_path = script_res.resource_path
	var world_name = _get_world_root_name()
	_diag_label.text = "[BUILD_UI] node=%s script=%s world=%s items=%d cards=%d" % [
		node_path,
		script_path,
		world_name,
		_last_items_count,
		_rendered_cards_count
	]

func _get_world_root_name() -> String:
	var build = _get_build_controller()
	if build != null and build.has_method("get_active_world_scene"):
		var vilag = build.call("get_active_world_scene")
		if vilag is Node:
			var gyoker = (vilag as Node).get_parent()
			if gyoker != null:
				return gyoker.name
			return (vilag as Node).name
	if not is_inside_tree() or get_tree().root == null:
		return "ismeretlen"
	var found = get_tree().root.find_child("WorldRoot", true, false)
	if found != null:
		return found.name
	return "ismeretlen"

func _log_panel_megnyitas() -> void:
	if not debug_enabled:
		return
	var build = _get_build_controller()
	var vilag_nev = "ismeretlen"
	var engedely = false
	if build != null:
		if build.has_method("get_active_world_scene"):
			var vilag = build.call("get_active_world_scene")
			if vilag is Node:
				vilag_nev = (vilag as Node).name
		if build.has_method("is_build_allowed"):
			engedely = bool(build.call("is_build_allowed"))
	var items = 0
	if _catalog == null:
		_catalog = BuildCatalog.new()
	items = _catalog.get_items().size()
	print("[BUILD] vilag=%s engedelyezett=%s elemek=%d" % [vilag_nev, str(engedely), items])
