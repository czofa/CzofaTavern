extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var card_grid_path: NodePath = ^"MarginContainer/VBoxContainer/CardsGrid"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"
@export var book_menu_path: NodePath = ^"../BookMenu"

var _title_label: Label
var _card_grid: GridContainer
var _back_button: Button

func _ready() -> void:
	_cache_nodes()
	print("📦 Leltár panel ready")
	hide()

func show_panel() -> void:
	show()
	_frissit()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_card_grid = get_node_or_null(card_grid_path) as GridContainer
	_back_button = get_node_or_null(back_button_path) as Button
	if _title_label != null:
		_title_label.text = "📦 Leltár"
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	hide_panel()
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu is Control:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _frissit() -> void:
	_frissit_kartyak()

func _frissit_kartyak() -> void:
	if _card_grid == null:
		return
	_torol_tartalom(_card_grid)
	var tetelek = _osszegyujt_tetelek()
	if tetelek.is_empty():
		_hozzaad_uressor(_card_grid)
		return
	for id_any in tetelek:
		var item_id = String(id_any).strip_edges()
		if item_id == "":
			continue
		var raktar = _leker_raktar_gramm(item_id)
		var adag = _leker_konyha_adag(item_id)
		_hozzaad_kartya(_card_grid, item_id, raktar, adag)

func _osszegyujt_tetelek() -> Array:
	var kulcsok: Array = []
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null:
		if StockSystem1.has_method("get_unbooked_items"):
			var lista_any = StockSystem1.call("get_unbooked_items")
			var lista = lista_any if lista_any is Array else []
			for t in lista:
				var kulcs = String(t).strip_edges()
				if kulcs != "" and not kulcsok.has(kulcs):
					kulcsok.append(kulcs)
		if StockSystem1.has_method("get_booked_items"):
			var lista2_any = StockSystem1.call("get_booked_items")
			var lista2 = lista2_any if lista2_any is Array else []
			for t2 in lista2:
				var kulcs2 = String(t2).strip_edges()
				if kulcs2 != "" and not kulcsok.has(kulcs2):
					kulcsok.append(kulcs2)
	if typeof(KitchenSystem1) != TYPE_NIL and KitchenSystem1 != null:
		if KitchenSystem1.has_method("get_unbooked_items"):
			var lista3_any = KitchenSystem1.call("get_unbooked_items")
			var lista3 = lista3_any if lista3_any is Array else []
			for t3 in lista3:
				var kulcs3 = String(t3).strip_edges()
				if kulcs3 != "" and not kulcsok.has(kulcs3):
					kulcsok.append(kulcs3)
		var portions_any = KitchenSystem1.get("_portions")
		if portions_any is Dictionary:
			for kulcs_any in portions_any.keys():
				var kulcs4 = String(kulcs_any).strip_edges()
				if kulcs4 != "" and not kulcsok.has(kulcs4):
					kulcsok.append(kulcs4)
	kulcsok.sort()
	return kulcsok

func _leker_raktar_gramm(item_id: String) -> int:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return 0
	if not StockSystem1.has_method("get_unbooked_qty"):
		return 0
	return int(StockSystem1.call("get_unbooked_qty", item_id))

func _leker_konyha_adag(item_id: String) -> int:
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return 0
	if KitchenSystem1.has_method("get_total_portions"):
		return int(KitchenSystem1.call("get_total_portions", item_id))
	var portions_any = KitchenSystem1.get("_portions")
	if portions_any is Dictionary:
		var adat_any = portions_any.get(item_id, {})
		var adat = adat_any if adat_any is Dictionary else {}
		return int(adat.get("total", 0))
	return 0

func _torol_tartalom(tarto: Control) -> void:
	for child in tarto.get_children():
		child.queue_free()

func _hozzaad_kartya(tarto: Control, nev: String, raktar_gramm: int, adag: int) -> void:
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(220, 140)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kartya.add_child(box)

	var kep = TextureRect.new()
	kep.custom_minimum_size = Vector2(64, 64)
	kep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(kep)

	var cim = Label.new()
	cim.text = nev
	box.add_child(cim)

	var raktar = Label.new()
	raktar.text = "Raktár: %d g" % raktar_gramm
	box.add_child(raktar)

	var konyha = Label.new()
	konyha.text = "Konyha: %d adag" % adag
	box.add_child(konyha)

	tarto.add_child(kartya)

func _hozzaad_uressor(tarto: Control) -> void:
	var label = Label.new()
	label.text = "Nincs leltár tétel."
	tarto.add_child(label)
