extends Control

@export var title_label_path: NodePath = ^"VBoxContainer/Title"
@export var scroll_container_path: NodePath = ^"VBoxContainer/Scroll"
@export var card_grid_path: NodePath = ^"VBoxContainer/Scroll/Grid"
@export var back_button_path: NodePath = ^"VBoxContainer/BackButton"
@export var book_menu_path: NodePath = ^"../BookMenu"

var _title_label: Label
var _card_grid: GridContainer
var _back_button: Button

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	visible = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_as_relative = false
	z_index = 1100
	move_to_front()
	show()
	print("[INV] open")
	_frissit()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_card_grid = get_node_or_null(card_grid_path) as GridContainer
	_back_button = get_node_or_null(back_button_path) as Button
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
	var unbooked = _leker_unbooked_adatok()
	var booked = _leker_konyvelt_adatok()
	var portions = _leker_konyha_adatok()
	var kulcsok = _osszegyujt_kulcsok(unbooked, booked, portions)
	var kartyak: int = 0
	for item_id in kulcsok:
		var raktar = int(unbooked.get(item_id, 0))
		var konyvelt = int(booked.get(item_id, 0))
		var adag = int(portions.get(item_id, 0))
		if raktar <= 0 and konyvelt <= 0 and adag <= 0:
			continue
		_hozzaad_kartya(_card_grid, item_id, raktar, konyvelt, adag)
		kartyak += 1
	_naplo_megnyitas(unbooked, booked, portions, kulcsok, kartyak)
	if kartyak <= 0:
		_hozzaad_uressor(_card_grid)

func _osszegyujt_kulcsok(unbooked: Dictionary, booked: Dictionary, portions: Dictionary) -> Array:
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

func _leker_unbooked_adatok() -> Dictionary:
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
	elif lista_any is Array:
		for t in lista_any:
			var id2 = String(t).strip_edges()
			if id2 == "":
				continue
			var menny: int = 0
			if StockSystem1.has_method("get_unbooked_qty"):
				menny = int(StockSystem1.call("get_unbooked_qty", id2))
			eredmeny[id2] = menny
	return eredmeny

func _leker_konyvelt_adatok() -> Dictionary:
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
	elif lista_any is Array:
		for t in lista_any:
			var id2 = String(t).strip_edges()
			if id2 == "":
				continue
			var menny: int = 0
			if StockSystem1.has_method("get_qty"):
				menny = int(StockSystem1.call("get_qty", id2))
			eredmeny[id2] = menny
	return eredmeny

func _leker_konyha_adatok() -> Dictionary:
	var eredmeny: Dictionary = {}
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return eredmeny
	if KitchenSystem1.has_method("get_total_portions"):
		var portions_any = KitchenSystem1.get("_portions")
		if portions_any is Dictionary:
			for kulcs in portions_any.keys():
				var id = String(kulcs).strip_edges()
				if id == "":
					continue
				var menny = int(KitchenSystem1.call("get_total_portions", id))
				eredmeny[id] = menny
	return eredmeny

func _naplo_megnyitas(unbooked: Dictionary, booked: Dictionary, portions: Dictionary, kulcsok: Array, kartyak: int) -> void:
	var unbooked_kulcsok = _format_kulcsok(unbooked)
	var booked_kulcsok = _format_kulcsok(booked)
	var portions_kulcsok = _format_kulcsok(portions)
	print("[INV] unbooked_count=%d keys=%s" % [unbooked_kulcsok.size(), unbooked_kulcsok])
	print("[INV] booked_count=%d keys=%s" % [booked_kulcsok.size(), booked_kulcsok])
	print("[INV] portions_count=%d keys=%s" % [portions_kulcsok.size(), portions_kulcsok])
	print("[INV] union_count=%d" % kulcsok.size())
	print("[INV] cards_built=%d" % kartyak)
	if kartyak <= 0:
		var ok = "források üresek"
		if kulcsok.size() > 0:
			ok = "minden érték 0"
		print("[INV][WARN] no cards built — %s" % ok)

func _format_kulcsok(adatok: Dictionary) -> Array:
	var lista: Array = []
	for kulcs in adatok.keys():
		var id = String(kulcs).strip_edges()
		if id != "":
			lista.append(id)
	lista.sort()
	return lista

func _leker_raktar_gramm(item_id: String) -> int:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return 0
	if not StockSystem1.has_method("get_unbooked_qty"):
		return 0
	return int(StockSystem1.call("get_unbooked_qty", item_id))

func _leker_konyvelt_gramm(item_id: String) -> int:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return 0
	if not StockSystem1.has_method("get_qty"):
		return 0
	return int(StockSystem1.call("get_qty", item_id))

func _leker_konyha_adag(item_id: String) -> int:
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return 0
	if KitchenSystem1.has_method("get_total_portions"):
		return int(KitchenSystem1.call("get_total_portions", item_id))
	var portions_any = KitchenSystem1.get("_portions")
	if portions_any is Dictionary:
		if portions_any.has(item_id):
			var adat_any = portions_any[item_id]
			if adat_any is Dictionary:
				var adat = adat_any as Dictionary
				if adat.has("total"):
					return int(adat["total"])
	return 0

func _torol_tartalom(tarto: Control) -> void:
	for child in tarto.get_children():
		child.queue_free()

func _hozzaad_kartya(tarto: Control, nev: String, raktar_gramm: int, konyvelt_gramm: int, adag: int) -> void:
	var kartya = PanelContainer.new()
	kartya.custom_minimum_size = Vector2(220, 140)
	if raktar_gramm <= 0 and konyvelt_gramm <= 0 and adag <= 0:
		kartya.modulate = Color(1, 1, 1, 0.55)
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
	raktar.text = "Könyveletlen: %d g" % raktar_gramm
	box.add_child(raktar)

	var konyvelt = Label.new()
	konyvelt.text = "Könyvelt: %d g" % konyvelt_gramm
	box.add_child(konyvelt)

	var konyha = Label.new()
	konyha.text = "Konyha: %d adag" % adag
	box.add_child(konyha)

	tarto.add_child(kartya)

func _hozzaad_uressor(tarto: Control) -> void:
	var label = Label.new()
	label.text = "Nincs leltár tétel."
	tarto.add_child(label)
