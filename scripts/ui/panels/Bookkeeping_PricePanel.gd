extends Control

@export var title_label_path: NodePath = ^"VBoxContainer/TitleLabel"
@export var bread_line_edit_path: NodePath = ^"VBoxContainer/PriceBread/BreadLineEdit"
@export var sausage_line_edit_path: NodePath = ^"VBoxContainer/PriceSausage/SausageLineEdit"
@export var palinka_line_edit_path: NodePath = ^"VBoxContainer/PricePalinka/PalinkaLineEdit"
@export var save_button_path: NodePath = ^"VBoxContainer/SaveButton"
@export var back_button_path: NodePath = ^"VBoxContainer/BackButton"

var _title_label: Label
var _bread_input: LineEdit
var _sausage_input: LineEdit
var _palinka_input: LineEdit
var _save_button: Button
var _back_button: Button

func _ready() -> void:
	print("💰 Árkezelés panel READY")
	_init_paths()
	hide()

func _init_paths() -> void:
	_title_label = get_node(title_label_path)
	_bread_input = get_node(bread_line_edit_path)
	_sausage_input = get_node(sausage_line_edit_path)
	_palinka_input = get_node(palinka_line_edit_path)
	_save_button = get_node(save_button_path)
	_back_button = get_node(back_button_path)

	_save_button.pressed.connect(_on_save_pressed)
	_back_button.pressed.connect(_on_back_pressed)

func show_panel() -> void:
	print("💰 Árkezelés megnyitva")
	show()

func hide_panel() -> void:
	print("📕 Árkezelés elrejtve")
	hide()

func _on_save_pressed() -> void:
	var bread_price = _bread_input.text.to_float()
	var sausage_price = _sausage_input.text.to_float()
	var palinka_price = _palinka_input.text.to_float()

	print("💾 Árak mentve:")
	print("   Kenyér: €", bread_price)
	print("   Kolbász: €", sausage_price)
	print("   Pálinka: €", palinka_price)

	# TODO: itt később EconomySystem1-be vagy PriceSystem1-be menteni
	hide_panel()

func _on_back_pressed() -> void:
	print("🔙 Visszalépés a főmenübe")
	hide_panel()
	var main_menu = get_tree().get_root().get_node("Main/UIRoot/UIRoot/BookMenu")
	if main_menu:
		main_menu.visible = true
