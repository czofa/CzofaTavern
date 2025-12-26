extends Control

@export var list_container_path: NodePath = ^"MarginContainer/VBoxContainer/Scroll/List"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BtnBack"
@export var hub_panel_path: NodePath = ^"../EmployeesHubPanel"
@export var my_panel_path: NodePath = ^"../EmployeesMyPanel"

var _list_container: VBoxContainer
var _back_button: Button
var _hub_panel: Control
var _my_panel: Control

func _ready() -> void:
	_cache_nodes()
	_connect_signals()
	hide()

func show_panel() -> void:
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
		if not _back_button.pressed.is_connected(cb_back):
			_back_button.pressed.connect(cb_back)

func _refresh_list() -> void:
	if _list_container == null:
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
	var portrait_path = str(seeker.get("portrait_path", ""))
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

	var nev = str(seeker.get("name", seeker.get("id", "Ismeretlen")))
	var level = int(seeker.get("level", 1))
	var lbl_nev = Label.new()
	lbl_nev.text = "%s (szint %d)" % [nev, level]
	vbox.add_child(lbl_nev)

	var statok = "Sebesség: %d | Főzés: %d | Megbízhatóság: %d" % [
		int(seeker.get("speed", 0)),
		int(seeker.get("cook", 0)),
		int(seeker.get("reliability", 0))
	]
	var lbl_stat = Label.new()
	lbl_stat.text = statok
	vbox.add_child(lbl_stat)

	var igeny = int(seeker.get("wage_request", 0))
	var lbl_wage = Label.new()
	lbl_wage.text = "Bérigény: %d Ft / hó" % igeny
	vbox.add_child(lbl_wage)

	var gombsor = HBoxContainer.new()
	gombsor.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(gombsor)

	var btn_hire = Button.new()
	btn_hire.text = "Felvétel"
	btn_hire.pressed.connect(_on_hire_pressed.bind(str(seeker.get("id", ""))))
	gombsor.add_child(btn_hire)

	var btn_reject = Button.new()
	btn_reject.text = "Elutasítás"
	btn_reject.pressed.connect(_on_reject_pressed.bind(str(seeker.get("id", ""))))
	gombsor.add_child(btn_reject)

	_list_container.add_child(kartya)

func _on_back_pressed() -> void:
	hide()
	if _hub_panel != null and _hub_panel.has_method("show_panel"):
		_hub_panel.call("show_panel")

func _on_hire_pressed(seeker_id: String) -> void:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return
	if EmployeeSystem1.hire_employee(seeker_id):
		_refresh_list()
		_refresh_my_panel()

func _on_reject_pressed(seeker_id: String) -> void:
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return
	EmployeeSystem1.reject_seeker(seeker_id)
	_refresh_list()

func _refresh_my_panel() -> void:
	if _my_panel != null and _my_panel.has_method("refresh_list"):
		_my_panel.call("refresh_list")
