extends Control

@export var title_label_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Title"
@export var scroll_container_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Scroll"
@export var card_grid_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/Scroll/Grid"
@export var back_button_path: NodePath = ^"PanelContainer/MarginContainer/VBoxContainer/BackButton"
@export var book_menu_path: NodePath = ^"../BookMenu"

var _title_label: Label
var _card_grid: GridContainer
var _back_button: Button
var _ui_root: Node

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	_cache_nodes()
	_ensure_on_screen()
	_ujraepit_kartyak()
	visible = true
	z_as_relative = false
	z_index = 1100
	move_to_front()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_card_grid = get_node_or_null(card_grid_path) as GridContainer
	_back_button = get_node_or_null(back_button_path) as Button
	_ui_root = _get_ui_root()
	if _title_label != null:
		_title_label.text = "📦 Leltár"
	if _card_grid != null:
		_card_grid.columns = 3
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
	var unbooked_map = _leker_unbooked_map()
	var booked_map = _leker_booked_map()
	var portions_map = _leker_portions_map()
	var kulcsok = _union_kulcsok(unbooked_map, booked_map, portions_map)
	var kartyak = 0
	for item_id in kulcsok:
		var raktar = int(unbooked_map.get(item_id, 0))
		var konyvelt = int(booked_map.get(item_id, 0))
		var adag = int(portions_map.get(item_id, 0))
		if raktar <= 0 and konyvelt <= 0 and adag <= 0:
			continue
		_hozzaad_kartya(_card_grid, item_id, raktar, konyvelt, adag)
		kartyak += 1
	if kartyak == 0:
		_hozzaad_uressor(_card_grid)

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
	if KitchenSystem1.has_method("get_portions_map"):
		var lista_any = KitchenSystem1.call("get_portions_map")
		if lista_any is Dictionary:
			for kulcs in lista_any.keys():
				var id = String(kulcs).strip_edges()
				if id != "":
					eredmeny[id] = int(lista_any.get(kulcs, 0))
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

func _hozzaad_kartya(tarto: Control, nev: String, raktar_gramm: int, konyvelt_gramm: int, adag: int) -> void:
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(240, 170)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kartya.add_child(box)

	var kep = TextureRect.new()
	kep.custom_minimum_size = Vector2(64, 64)
	kep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(kep)

	var cim = Label.new()
	cim.text = nev
	box.add_child(cim)

	var raktar = Label.new()
	raktar.text = "Raktár (könyveletlen): %d g" % raktar_gramm
	box.add_child(raktar)

	var konyvelt = Label.new()
	konyvelt.text = "Raktár (könyvelt): %d g" % konyvelt_gramm
	box.add_child(konyvelt)

	var konyha = Label.new()
	konyha.text = "Konyha: %d adag" % adag
	box.add_child(konyha)

	tarto.add_child(kartya)

func _hozzaad_uressor(tarto: Control) -> void:
	var label = Label.new()
	label.text = "Nincs semmi a leltárban."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tarto.add_child(label)

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

func _ensure_on_screen() -> void:
	if not is_inside_tree():
		return
	var viewport = get_viewport()
	if viewport == null:
		return
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var viewport_size = viewport.get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var cel_meret = size
	if cel_meret.x > viewport_size.x * 0.9 or cel_meret.y > viewport_size.y * 0.9:
		cel_meret = Vector2(
			min(cel_meret.x, viewport_size.x * 0.9),
			min(cel_meret.y, viewport_size.y * 0.9)
		)
		size = cel_meret
	position.x = clamp(position.x, 8.0, viewport_size.x - size.x - 8.0)
	position.y = clamp(position.y, 8.0, viewport_size.y - size.y - 8.0)
