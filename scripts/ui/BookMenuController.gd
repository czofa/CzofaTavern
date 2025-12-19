extends Control

@export var start_open: bool = false
@export var bookkeeping_button_path: NodePath = ^"MarginContainer/VBoxContainer/Könyvelés"
@export var bookkeeping_panel_path: NodePath = ^"BookkeepingPanel"

var is_open: bool = false
var _bookkeeping_button: Button
var _bookkeeping_panel: Control

func _ready() -> void:
	print("📖 BookMenuController READY")
	is_open = start_open
	_apply_state()

	_bookkeeping_button = get_node(bookkeeping_button_path)
	_bookkeeping_panel = get_node(bookkeeping_panel_path)

	_bookkeeping_button.pressed.connect(_on_bookkeeping_pressed)
	_bookkeeping_panel.hide()

	print("✅ Könyvelés gomb és panel beállítva.")

func toggle_menu() -> void:
	is_open = not is_open
	_apply_state()

func open_menu() -> void:
	is_open = true
	_apply_state()

func close_menu() -> void:
	is_open = false
	_apply_state()

func is_menu_open() -> bool:
	return is_open

func _apply_state() -> void:
	visible = is_open
	mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE

	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	for c in get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_book_menu"):
		toggle_menu()

func _on_bookkeeping_pressed() -> void:
	print("🧾 Könyvelés gomb megnyomva.")
	visible = false  # 👉 Főmenü eltüntetése
	_bookkeeping_panel.show_panel()  # ✅ új hívás, már létező metódus
