extends Control

@export var panel_container_path: NodePath = ^"PanelContainer"
@export var title_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Title"
@export var empty_state_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/EmptyState"
@export var empty_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/EmptyState/EmptyLabel"
@export var scroll_container_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Scroll"
@export var card_grid_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Scroll/Grid"
@export var back_button_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/BackButton"
@export var book_menu_path: NodePath = ^"../BookMenu"

var _panel_container: PanelContainer
var _title_label: Label
var _empty_state: CenterContainer
var _empty_label: Label
var _scroll_container: ScrollContainer
var _card_grid: GridContainer
var _back_button: Button
var _ui_root: Node

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	_cache_nodes()
	_beallit_panel_meret()
	_ujraepit_kartyak()
	visible = true
	z_as_relative = false
	z_index = 1100
	move_to_front()
	show()

func hide_panel() -> void:
	hide()

func raise() -> void:
	move_to_front()

func _cache_nodes() -> void:
	_panel_container = get_node_or_null(panel_container_path) as PanelContainer
	_title_label = get_node_or_null(title_label_path) as Label
	_empty_state = get_node_or_null(empty_state_path) as CenterContainer
	_empty_label = get_node_or_null(empty_label_path) as Label
	_scroll_container = get_node_or_null(scroll_container_path) as ScrollContainer
	_card_grid = get_node_or_null(card_grid_path) as GridContainer
	_back_button = get_node_or_null(back_button_path) as Button
	_ui_root = _get_ui_root()

	if _title_label != null:
		_title_label.text = "📦 Leltár"
	if _card_grid != null:
		_card_grid.columns = 3
	if _empty_label != null:
		_empty_label.text = "Nincs semmi a leltárban."
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

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

func _ujraepit_kartyak() -> void:
	if _card_grid == null:
		return
	_torol_tartalom(_card_grid)
	var kartyak = 0
	var lista = _leker_inventory_lista()
	for adat_any in lista:
		var adat = adat_any if adat_any is Dictionary else {}
		var id = str(adat.get("id", "")).strip_edges()
		if id == "":
			continue
		var raktar = int(adat.get("warehouse_qty", 0))
		var raktar_unit = str(adat.get("warehouse_unit", "g"))
		var konyha = int(adat.get("kitchen_qty", 0))
		var konyha_unit = str(adat.get("kitchen_unit", raktar_unit))
		if raktar <= 0 and konyha <= 0:
			continue
		_hozzaad_kartya(_card_grid, id, raktar, raktar_unit, konyha, konyha_unit)
		kartyak += 1
	_mutat_uressor(kartyak == 0)

func _mutat_uressor(ures: bool) -> void:
	if _empty_state != null:
		_empty_state.visible = ures
	if _scroll_container != null:
		_scroll_container.visible = not ures

func _union_kulcsok(unbooked: Dictionary, booked: Dictionary, portions: Dictionary) -> Array:
	var kulcsok: Array = []
	for kulcs in unbooked.keys():
		var tiszta = String(kulcs).strip_edges()
		if tiszta != "" and not kulcsok.has(tiszta):
			kulcsok.append(tiszta)
	for kulcs in booked.keys():
		var tiszta2 = String(kulcs).strip_edges()
		if tiszta2 != "" and not kulcsok.has(tiszta2):
			kulcsok.append(tiszta2)
	for kulcs in portions.keys():
		var tiszta3 = String(kulcs).strip_edges()
		if tiszta3 != "" and not kulcsok.has(tiszta3):
			kulcsok.append(tiszta3)
	kulcsok.sort()
	return kulcsok

func _leker_unbooked_map() -> Dictionary:
	var eredmeny: Dictionary = {}
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return eredmeny
	if not StockSystem1.has_method("get_unbooked_items"):
		return eredmeny
	var lista_any = StockSystem1.call("get_unbooked_items")
	if lista_any is Dictionary:
		for kulcs in lista_any.keys():
			var id = String(kulcs).strip_edges()
			if id != "":
				eredmeny[id] = int(lista_any.get(kulcs, 0))
		return eredmeny
	if lista_any is Array:
		for t in lista_any:
			var id2 = String(t).strip_edges()
			if id2 == "":
				continue
			var menny = 0
			if StockSystem1.has_method("get_unbooked_qty"):
				menny = int(StockSystem1.call("get_unbooked_qty", id2))
			eredmeny[id2] = menny
	return eredmeny

func _leker_booked_map() -> Dictionary:
	var eredmeny: Dictionary = {}
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return eredmeny
	if not StockSystem1.has_method("get_booked_items"):
		return eredmeny
	var lista_any = StockSystem1.call("get_booked_items")
	if lista_any is Dictionary:
		for kulcs in lista_any.keys():
			var id = String(kulcs).strip_edges()
			if id != "":
				eredmeny[id] = int(lista_any.get(kulcs, 0))
		return eredmeny
	if lista_any is Array:
		for t in lista_any:
			var id2 = String(t).strip_edges()
			if id2 == "":
				continue
			var menny = 0
			if StockSystem1.has_method("get_qty"):
				menny = int(StockSystem1.call("get_qty", id2))
			eredmeny[id2] = menny
	return eredmeny

func _leker_portions_map() -> Dictionary:
	var eredmeny: Dictionary = {}
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return eredmeny
	var portions_any = KitchenSystem1.get("_portions")
	if portions_any is Dictionary:
		for kulcs in portions_any.keys():
			var id2 = String(kulcs).strip_edges()
			if id2 == "":
				continue
			var menny = 0
			if KitchenSystem1.has_method("get_total_portions"):
				menny = int(KitchenSystem1.call("get_total_portions", id2))
			eredmeny[id2] = menny
	return eredmeny

func _torol_tartalom(tarto: Control) -> void:
	for child in tarto.get_children():
		child.queue_free()

func _hozzaad_kartya(tarto: Control, nev: String, raktar_menny: int, raktar_unit: String, konyha_menny: int, konyha_unit: String) -> void:
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(240, 180)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	kartya.add_child(box)

	var kep = Label.new()
	kep.text = "Kép helye"
	kep.custom_minimum_size = Vector2(0, 64)
	kep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(kep)

	var cim = Label.new()
	cim.text = nev
	box.add_child(cim)

	var raktar = Label.new()
	raktar.text = "Raktár: %s" % _format_raktar_mennyiseg(nev, raktar_menny, raktar_unit)
	box.add_child(raktar)

	var konyha = Label.new()
	konyha.text = "Konyha: %s" % _format_mennyiseg(konyha_menny, konyha_unit)
	box.add_child(konyha)

	tarto.add_child(kartya)

func _leker_inventory_lista() -> Array:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return []
	if StockSystem1.has_method("get_inventory_snapshot"):
		var lista_any = StockSystem1.call("get_inventory_snapshot")
		return lista_any if lista_any is Array else []
	return _fallback_inventory_lista()

func _fallback_inventory_lista() -> Array:
	var lista: Array = []
	var unbooked_map = _leker_unbooked_map()
	var booked_map = _leker_booked_map()
	var kulcsok = _union_kulcsok(unbooked_map, booked_map, {})
	for item_id in kulcsok:
		var raktar = int(unbooked_map.get(item_id, 0))
		var konyvelt = int(booked_map.get(item_id, 0))
		var unit = "g"
		if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and StockSystem1.has_method("get_item_unit"):
			unit = str(StockSystem1.call("get_item_unit", item_id))
		lista.append({
			"id": item_id,
			"warehouse_qty": raktar,
			"warehouse_unit": unit,
			"kitchen_qty": konyvelt,
			"kitchen_unit": unit
		})
	return lista

func _format_mennyiseg(menny: int, unit: String) -> String:
	match unit:
		"pcs":
			return "%d db" % menny
		"ml":
			return _format_ml_mennyiseg(menny)
		_:
			return "%d g" % menny

func _format_raktar_mennyiseg(item_id: String, menny: int, unit: String) -> String:
	var shown = ""
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and StockSystem1.has_method("format_qty_for_ui"):
		shown = str(StockSystem1.call("format_qty_for_ui", item_id, menny, unit))
	if shown == "":
		shown = _format_mennyiseg(menny, unit)
	print("[UNBOOKED_UI] id=%s qty=%d unit=%s shown=\"%s\"" % [item_id, menny, unit, shown])
	return shown

func _format_ml_mennyiseg(menny: int) -> String:
	if menny >= 1000:
		return "%d ml (%.1f L)" % [menny, float(menny) / 1000.0]
	return "%d ml" % menny

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

func _beallit_panel_meret() -> void:
	if _panel_container == null or not is_inside_tree():
		return
	var viewport = get_viewport()
	if viewport == null:
		return
	var viewport_size = viewport.get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var cel_meret = _panel_container.custom_minimum_size
	if cel_meret == Vector2.ZERO:
		cel_meret = Vector2(520, 420)
	var max_meret = viewport_size * 0.9
	cel_meret.x = min(cel_meret.x, max_meret.x)
	cel_meret.y = min(cel_meret.y, max_meret.y)
	_panel_container.set_anchors_preset(Control.PRESET_CENTER)
	_panel_container.size = cel_meret
	_panel_container.position = (viewport_size - cel_meret) * 0.5
