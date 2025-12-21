extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var company_label_path: NodePath = ^"MarginContainer/VBoxContainer/Company"
@export var personal_label_path: NodePath = ^"MarginContainer/VBoxContainer/Personal"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"

var _title_label: Label
var _company_label: Label
var _personal_label: Label
var _back_button: Button

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	_frissit()
	show()

func hide_panel() -> void:
	hide()

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_company_label = get_node_or_null(company_label_path) as Label
	_personal_label = get_node_or_null(personal_label_path) as Label
	_back_button = get_node_or_null(back_button_path) as Button
	if _title_label != null:
		_title_label.text = "💹 Gazdaság"
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
	var ceg = _ceges_penz()
	var magan = _magan_penz()
	if _company_label != null:
		_company_label.text = "💼 Cégpénz: %s" % _penz_szoveg(ceg)
	if _personal_label != null:
		_personal_label.text = "👤 Magánpénz: %s" % _penz_szoveg(magan)

func _ceges_penz() -> Dictionary:
	var adat: Dictionary = {"ertek": 0, "elerheto": false}
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		adat["ertek"] = int(EconomySystem1.get_money())
		adat["elerheto"] = true
		return adat
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		adat["ertek"] = int(gs.call("get_value", "company_money_ft", 0))
		adat["elerheto"] = true
	return adat

func _magan_penz() -> Dictionary:
	var adat: Dictionary = {"ertek": 0, "elerheto": false}
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		adat["ertek"] = int(gs.call("get_value", "personal_money_ft", 0))
		adat["elerheto"] = true
	return adat

func _penz_szoveg(adat: Dictionary) -> String:
	var elerheto = bool(adat.get("elerheto", false))
	var ertek = int(adat.get("ertek", 0))
	if not elerheto:
		return "n/a"
	return "%d Ft" % ertek
