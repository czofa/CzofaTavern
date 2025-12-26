extends Control

@export var list_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll/List"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"
@export var hub_panel_path: NodePath = ^"../EmployeesHubPanel"
@export var my_panel_path: NodePath = ^"../EmployeesMyPanel"

var _list_container: VBoxContainer
var _back_button: Button
var _hub_panel: Control
var _my_panel: Control
var _jelzett_hianyok: Dictionary = {}

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	hide()

func show_panel() -> void:
	if _list_container == null:
		push_error("❌ Hiányzó NodePath: %s" % list_container_path)
		return
	_refresh_list()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_list_container = get_node_or_null(list_container_path)
	_back_button = get_node_or_null(back_button_path)
	_hub_panel = get_node_or_null(hub_panel_path)
	_my_panel = get_node_or_null(my_panel_path)

func _connect_signals() -> void:
	if _back_button != null:
		var cb_back = Callable(self, "_on_back_pressed")
		if _back_button.has_signal("pressed") and not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

func _refresh_list() -> void:
	if _list_container == null:
		_warn_once("lista", "❌ Jelentkező lista konténer hiányzik.")
		return
	for child in _list_container.get_children():
		child.queue_free()
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		_add_info("❌ Alkalmazotti rendszer nem érhető el.")
		return
	var seekers = EmployeeSystem1.get_job_seekers()
	if seekers.is_empty():
		_add_info("Nincs új jelentkező.")
		return
	for seeker_any in seekers:
		var seeker = seeker_any if seeker_any is Dictionary else {}
		_add_card(seeker)

func _add_info(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _list_container != null:
		_list_container.add_child(lbl)

func _add_card(seeker: Dictionary) -> void:
	var kartya = PanelContainer.new()
	kartya.add_theme_constant_override("margin_left", 8)
	kartya.add_theme_constant_override("margin_right", 8)
	kartya.add_theme_constant_override("margin_top", 4)
	kartya.add_theme_constant_override("margin_bottom", 4)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	kartya.add_child(hbox)

	var kep = TextureRect.new()
	kep.custom_minimum_size = Vector2(64, 64)
	kep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path = ""
	if seeker.has("portrait_path"):
		portrait_path = str(seeker["portrait_path"])
	var tex = null
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		tex = load(portrait_path)
	else:
		if ResourceLoader.exists("res://icon.svg"):
			tex = load("res://icon.svg")
	kep.texture = tex
	hbox.add_child(kep)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_child(vbox)

	var nev = "Ismeretlen"
	if seeker.has("name"):
		nev = str(seeker["name"])
	elif seeker.has("id"):
		nev = str(seeker["id"])
	var level = 1
	if seeker.has("level"):
		level = int(seeker["level"])
	var lbl_nev = Label.new()
	lbl_nev.text = "%s (szint %d)" % [nev, level]
	vbox.add_child(lbl_nev)

	var statok = "Sebesség: %d | Főzés: %d | Megbízhatóság: %d" % [
		_int_kulcs(seeker, "speed"),
		_int_kulcs(seeker, "cook"),
		_int_kulcs(seeker, "reliability")
	]
	var lbl_stat = Label.new()
	lbl_stat.text = statok
	vbox.add_child(lbl_stat)

	var igeny = _int_kulcs(seeker, "wage_request")
	var lbl_wage = Label.new()
	lbl_wage.text = "Bérigény: %d Ft / hó" % igeny
	vbox.add_child(lbl_wage)

	var gombsor = HBoxContainer.new()
	gombsor.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(gombsor)

	var btn_hire = Button.new()
	btn_hire.text = "Felvétel"
	btn_hire.pressed.connect(_on_hire_pressed.bind(_str_kulcs(seeker, "id")))
	gombsor.add_child(btn_hire)

	var btn_reject = Button.new()
	btn_reject.text = "Elutasítás"
	btn_reject.pressed.connect(_on_reject_pressed.bind(_str_kulcs(seeker, "id")))
	gombsor.add_child(btn_reject)

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

func _on_hire_pressed(seeker_id: String) -> void:
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s jelentkezo=%s rendszer_null=%s vilag=%s" % [
		_aktualis_gomb_nev(),
		seeker_id,
		str(typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null),
		kontextus
	])
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		push_error("❌ Alkalmazotti rendszer hiányzik, felvétel megszakítva.")
		return
	if EmployeeSystem1.hire_employee(seeker_id):
		_refresh_list()
		_refresh_my_panel()

func _on_reject_pressed(seeker_id: String) -> void:
	var kontextus = _world_kontextus()
	print("[EMP_UI] gomb=%s jelentkezo=%s rendszer_null=%s vilag=%s" % [
		_aktualis_gomb_nev(),
		seeker_id,
		str(typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null),
		kontextus
	])
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		push_error("❌ Alkalmazotti rendszer hiányzik, elutasítás megszakítva.")
		return
	EmployeeSystem1.reject_seeker(seeker_id)
	_refresh_list()

func _refresh_my_panel() -> void:
	if _my_panel != null and _my_panel.has_method("refresh_list"):
		_my_panel.call("refresh_list")

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
