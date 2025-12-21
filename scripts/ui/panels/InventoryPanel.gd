extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var unbooked_list_path: NodePath = ^"MarginContainer/VBoxContainer/UnbookedList"
@export var booked_list_path: NodePath = ^"MarginContainer/VBoxContainer/BookedList"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"

var _title_label: Label
var _unbooked_list: VBoxContainer
var _booked_list: VBoxContainer
var _back_button: Button

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	show()
	_frissit()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_unbooked_list = get_node_or_null(unbooked_list_path) as VBoxContainer
	_booked_list = get_node_or_null(booked_list_path) as VBoxContainer
	_back_button = get_node_or_null(back_button_path) as Button
	if _title_label != null:
		_title_label.text = "📦 Leltár"
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	hide_panel()
	var main_menu = get_tree().get_root().get_node_or_null("Main/UIRoot/UiRoot/BookMenu")
	if main_menu is Control:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _frissit() -> void:
	_frissit_unbooked()
	_frissit_booked()

func _frissit_unbooked() -> void:
	if _unbooked_list == null:
		return
	_torol_tartalom(_unbooked_list)
	var csomag = _osszefoglalt_unbooked()
	var adat_any = csomag.get("adat", {})
	var adat = adat_any if adat_any is Dictionary else {}
	var elerheto = bool(csomag.get("elerheto", false))
	if not elerheto:
		_hozzaad_sor(_unbooked_list, "n/a")
		return
	var kulcsok: Array = adat.keys()
	kulcsok.sort()
	if kulcsok.is_empty():
		_hozzaad_sor(_unbooked_list, "(üres)")
		return
	for kulcs in kulcsok:
		var mennyiseg = int(adat.get(kulcs, 0))
		_hozzaad_sor(_unbooked_list, "%s: %dg" % [kulcs, mennyiseg])

func _frissit_booked() -> void:
	if _booked_list == null:
		return
	_torol_tartalom(_booked_list)
	var csomag = _osszefoglalt_konyvelt()
	var adat_any = csomag.get("adat", {})
	var adat = adat_any if adat_any is Dictionary else {}
	var adag_any = csomag.get("adagok", {})
	var adagok = adag_any if adag_any is Dictionary else {}
	var elerheto = bool(csomag.get("elerheto", false))
	if not elerheto:
		_hozzaad_sor(_booked_list, "n/a")
		return
	var kulcsok: Array = []
	for k in adat.keys():
		if not kulcsok.has(k):
			kulcsok.append(k)
	for k2 in adagok.keys():
		if not kulcsok.has(k2):
			kulcsok.append(k2)
	kulcsok.sort()
	if kulcsok.is_empty():
		_hozzaad_sor(_booked_list, "(üres)")
		return
	for kulcs in kulcsok:
		var gramm = int(adat.get(kulcs, 0))
		var adag = int(adagok.get(kulcs, 0))
		_hozzaad_sor(_booked_list, "%s: %dg | adag: %d" % [kulcs, gramm, adag])

func _osszefoglalt_unbooked() -> Dictionary:
	var adat: Dictionary = {}
	var elerheto: bool = false
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and StockSystem1.has_method("get_unbooked_items"):
		elerheto = true
		var tetelek_any = StockSystem1.get_unbooked_items()
		var tetelek = tetelek_any if tetelek_any is Array else []
		for t in tetelek:
			var kulcs = String(t).strip_edges()
			if kulcs == "":
				continue
			var mennyiseg = 0
			if StockSystem1.has_method("get_unbooked_qty"):
				mennyiseg = int(StockSystem1.call("get_unbooked_qty", kulcs))
			adat[kulcs] = int(adat.get(kulcs, 0)) + mennyiseg
	if typeof(KitchenSystem1) != TYPE_NIL and KitchenSystem1 != null and KitchenSystem1.has_method("get_unbooked_items"):
		elerheto = true
		var lista_any = KitchenSystem1.get_unbooked_items()
		var lista = lista_any if lista_any is Array else []
		for t2 in lista:
			var kulcs2 = String(t2).strip_edges()
			if kulcs2 == "":
				continue
			var mennyiseg2 = 0
			if KitchenSystem1.has_method("get_unbooked_qty"):
				mennyiseg2 = int(KitchenSystem1.call("get_unbooked_qty", kulcs2))
			adat[kulcs2] = int(adat.get(kulcs2, 0)) + mennyiseg2
	return {"adat": adat, "elerheto": elerheto}

func _osszefoglalt_konyvelt() -> Dictionary:
	var adat: Dictionary = {}
	var adagok: Dictionary = {}
	var elerheto: bool = false
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null and StockSystem1.has_method("get_booked_items"):
		elerheto = true
		var tetelek_any = StockSystem1.get_booked_items()
		var tetelek = tetelek_any if tetelek_any is Array else []
		for t in tetelek:
			var kulcs = String(t).strip_edges()
			if kulcs == "":
				continue
			var mennyiseg = 0
			if StockSystem1.has_method("get_qty"):
				mennyiseg = int(StockSystem1.call("get_qty", kulcs))
			if mennyiseg > 0:
				adat[kulcs] = int(adat.get(kulcs, 0)) + mennyiseg
	if typeof(KitchenSystem1) != TYPE_NIL and KitchenSystem1 != null:
		var portions_any = KitchenSystem1.get("_portions")
		if portions_any is Dictionary:
			elerheto = true
			for kulcs_any in portions_any.keys():
				var kulcs2 = String(kulcs_any).strip_edges()
				if kulcs2 == "":
					continue
				var osszes = 0
				if KitchenSystem1.has_method("get_total_portions"):
					osszes = int(KitchenSystem1.call("get_total_portions", kulcs2))
				else:
					var adat_any = portions_any.get(kulcs_any, {})
					var adat_dict = adat_any if adat_any is Dictionary else {}
					osszes = int(adat_dict.get("total", 0))
				if osszes > 0:
					adagok[kulcs2] = osszes
	return {
		"adat": adat,
		"adagok": adagok,
		"elerheto": elerheto
	}

func _torol_tartalom(tarto: Control) -> void:
	for child in tarto.get_children():
		child.queue_free()

func _hozzaad_sor(tarto: Control, szoveg: String) -> void:
	var label = Label.new()
	label.text = szoveg
	tarto.add_child(label)
