extends Control

@export var list_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll/List"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"
@export var hub_panel_path: NodePath = ^"../EmployeesHubPanel"

var _list_container: VBoxContainer
var _back_button: Button
var _hub_panel: Control
var _jelzett_hianyok: Dictionary = {}

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	hide()

func show_panel() -> void:
	if _list_container == null:
		push_error("❌ Hiányzó NodePath: %s" % list_container_path)
		return
	refresh_list()
	show()

func hide_panel() -> void:
	hide()

func refresh_list() -> void:
	if _list_container == null:
		_warn_once("lista", "❌ Alkalmazott lista konténer hiányzik.")
		return
	for child in _list_container.get_children():
		child.queue_free()
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		_add_info("❌ Alkalmazotti rendszer nem érhető el.")
		return
	var lista = EmployeeSystem1.get_employees()
	if lista.is_empty():
		_add_info("Nincs alkalmazott.")
		return
	for emp_any in lista:
		var emp = emp_any if emp_any is Dictionary else {}
		_add_card(emp)

func _cache_nodes() -> void:
	_list_container = get_node_or_null(list_container_path)
	_back_button = get_node_or_null(back_button_path)
	_hub_panel = get_node_or_null(hub_panel_path)

func _connect_signals() -> void:
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

func _add_info(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _list_container != null:
		_list_container.add_child(lbl)

func _add_card(emp: Dictionary) -> void:
	var kartya = PanelContainer.new()
	kartya.add_theme_constant_override("margin_left", 8)
	kartya.add_theme_constant_override("margin_right", 8)
	kartya.add_theme_constant_override("margin_top", 4)
	kartya.add_theme_constant_override("margin_bottom", 4)

	var hbox = HBoxContainer.new()
	kartya.add_child(hbox)

	var kep = TextureRect.new()
	kep.custom_minimum_size = Vector2(64, 64)
	kep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path = ""
	if emp.has("portrait_path"):
		portrait_path = str(emp["portrait_path"])
	var tex = null
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		tex = load(portrait_path)
	else:
		if ResourceLoader.exists("res://icon.svg"):
			tex = load("res://icon.svg")
	kep.texture = tex
	hbox.add_child(kep)

	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)

	var nev = "Ismeretlen"
	if emp.has("name"):
		nev = str(emp["name"])
	elif emp.has("id"):
		nev = str(emp["id"])
	var level = 1
	if emp.has("level"):
		level = int(emp["level"])
	var lbl_nev = Label.new()
	lbl_nev.text = "%s (szint %d)" % [nev, level]
	vbox.add_child(lbl_nev)

	var statok = "Sebesség: %d | Főzés: %d | Megbízhatóság: %d" % [
		_int_kulcs(emp, "speed"),
		_int_kulcs(emp, "cook"),
		_int_kulcs(emp, "reliability")
	]
	var lbl_stat = Label.new()
	lbl_stat.text = statok
	vbox.add_child(lbl_stat)

	var bruttok = _int_kulcs(emp, "gross")
	var igeny = _int_kulcs(emp, "wage_request")
	var lbl_ber = Label.new()
	if bruttok > 0:
		lbl_ber.text = "Beállított bér: %d Ft / hó" % bruttok
	elif igeny > 0:
		lbl_ber.text = "Bérigény: %d Ft / hó" % igeny
	else:
		lbl_ber.text = "Bérigény: nincs megadva"
	vbox.add_child(lbl_ber)

	var gomb_sor = HBoxContainer.new()
	vbox.add_child(gomb_sor)

	var btn_fire = Button.new()
	btn_fire.text = "Kirúgás"
	btn_fire.pressed.connect(_on_fire_pressed.bind(_str_kulcs(emp, "id")))
	gomb_sor.add_child(btn_fire)

	_list_container.add_child(kartya)

func _on_back_pressed() -> void:
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s kozpont_panel_null=%s vilag=%s" % [
		_aktualis_gomb_nev(),
		str(_hub_panel == null),
		kontextus
	])
	hide()
	if _hub_panel == null:
		push_error("❌ Hiányzó NodePath: %s" % hub_panel_path)
		return
	if _hub_panel.has_method("show_panel"):
		_hub_panel.call("show_panel")
	elif _hub_panel is Control:
		_hub_panel.show()
	else:
		push_error("❌ Alkalmazotti főpanel nem Control.")
		return

func _on_fire_pressed(emp_id: String) -> void:
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s dolgozo=%s rendszer_null=%s vilag=%s" % [
		_aktualis_gomb_nev(),
		emp_id,
		str(typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null),
		kontextus
	])
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		push_error("❌ Alkalmazotti rendszer hiányzik, kirúgás megszakítva.")
		return
	if EmployeeSystem1.fire_employee(emp_id):
		refresh_list()

func _warn_once(kulcs: String, uzenet: String) -> void:
	if _jelzett_hianyok.has(kulcs):
		return
	_jelzett_hianyok[kulcs] = true
	push_warning(uzenet)

func _int_kulcs(adat: Dictionary, kulcs: String) -> int:
	if adat.has(kulcs):
		return int(adat[kulcs])
	return 0

func _str_kulcs(adat: Dictionary, kulcs: String) -> String:
	if adat.has(kulcs):
		return str(adat[kulcs])
	return ""

func _aktualis_gomb_nev() -> String:
	var vp = get_viewport()
	if vp == null:
		return "ismeretlen"
	var fokus = vp.gui_get_focus_owner()
	if fokus != null:
		return str(fokus.name)
	return "ismeretlen"

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
