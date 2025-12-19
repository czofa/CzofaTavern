extends Control

@export var start_open: bool = false
@export var bookkeeping_button_path: NodePath = ^"MarginContainer/VBoxContainer/Könyvelés"
@export var bookkeeping_panel_path: NodePath = ^"BookkeepingPanel"
@export var day_end_summary_path: NodePath = ^"../DayEndSummary"
@export var encounter_modal_path: NodePath = ^"../Modals/EncounterModal"
@export var modals_root_path: NodePath = ^"../Modals"

const _LOCK_REASON := "book_menu"

var is_open: bool = false
var _bookkeeping_button: Button
var _bookkeeping_panel: Control
var _day_end_summary: Control
var _encounter_modal: Control
var _modals_root: Control
var _has_bus_toggle: bool = false

func _ready() -> void:
	print("📖 BookMenuController READY")
	_cache_nodes()
	_connect_button()
	_connect_bus()
	_hide_bookkeeping_panel()
	is_open = start_open and not _has_blocking_modal()
	if start_open and _has_blocking_modal():
		push_warning("ℹ️ BookMenu: nyitás blokkolva egy aktív modal miatt.")
	if is_open:
		_lock_input()
	_apply_state()
	set_process(true)

func toggle_menu() -> void:
	if is_open:
		close_menu()
		return
	if not _can_open_menu():
		return
	open_menu()

func open_menu() -> void:
	if not _can_open_menu():
		return
	is_open = true
	_lock_input()
	_apply_state()

func close_menu() -> void:
	_unlock_input()
	_hide_bookkeeping_panel()
	is_open = false
	_apply_state()

func is_menu_open() -> bool:
	return is_open

func _apply_state() -> void:
	var show_menu := is_open and not _is_bookkeeping_panel_active()
	visible = show_menu
	mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE

	_apply_mouse_mode()

	for c in get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_toggle_book_menu"):
		if _has_bus_toggle:
			return
		toggle_menu()

func _on_bookkeeping_pressed() -> void:
	if _bookkeeping_panel == null:
		push_warning("❌ Könyvelési panel nem található, a gombot kihagyjuk.")
		return

	print("🧾 Könyvelés gomb megnyomva.")
	if _bookkeeping_panel.has_method("show_panel"):
		_bookkeeping_panel.call("show_panel")
	else:
		_bookkeeping_panel.show()
	_apply_state()

func _cache_nodes() -> void:
	_bookkeeping_button = get_node_or_null(bookkeeping_button_path)
	_bookkeeping_panel = get_node_or_null(bookkeeping_panel_path)
	_day_end_summary = get_node_or_null(day_end_summary_path)
	_encounter_modal = get_node_or_null(encounter_modal_path)
	_modals_root = get_node_or_null(modals_root_path)

	if _bookkeeping_button == null:
		push_warning("❌ BookMenu: nem található a könyvelés gomb (%s)." % bookkeeping_button_path)
	if _bookkeeping_panel == null:
		push_warning("❌ BookMenu: nem található a könyvelés panel (%s)." % bookkeeping_panel_path)

func _connect_button() -> void:
	if _bookkeeping_button != null:
		var cb := Callable(self, "_on_bookkeeping_pressed")
		if not _bookkeeping_button.pressed.is_connected(cb):
			_bookkeeping_button.pressed.connect(cb)

func _connect_bus() -> void:
	var eb := _get_bus()
	if eb == null:
		push_warning("ℹ️ BookMenu: EventBus1 nem érhető el, csak InputMap fog működni.")
		return
	if eb.has_signal("request_toggle_book_menu"):
		var cb_toggle := Callable(self, "_on_request_toggle_menu")
		if not eb.is_connected("request_toggle_book_menu", cb_toggle):
			eb.connect("request_toggle_book_menu", cb_toggle)
			_has_bus_toggle = true
	if eb.has_signal("request_close_all_popups"):
		var cb_close := Callable(self, "_on_request_close_all_popups")
		if not eb.is_connected("request_close_all_popups", cb_close):
			eb.connect("request_close_all_popups", cb_close)

func _on_request_toggle_menu() -> void:
	toggle_menu()

func _on_request_close_all_popups() -> void:
	if is_open or _is_bookkeeping_panel_active():
		close_menu()

func _can_open_menu() -> bool:
	if _has_blocking_modal():
		print("ℹ️ BookMenu: modal vagy bolt nyitva, a menü nem nyílik meg.")
		return false
	if _is_input_locked_externally():
		print("ℹ️ BookMenu: input lock aktív, a menü nyitását kihagyjuk.")
		return false
	return true

func _has_blocking_modal() -> bool:
	if (_day_end_summary != null and _day_end_summary.visible) or (_encounter_modal != null and _encounter_modal.visible):
		return true
	if _modals_root != null and _modals_root.visible:
		return true
	return _is_shop_modal_visible()

func _is_shop_modal_visible() -> bool:
	var ui_root := get_tree().root.get_node_or_null("Main/UIRoot")
	if ui_root == null:
		return false
	for child in ui_root.get_children():
		if child is Control and str(child.name).begins_with("Shopkeeper"):
			if (child as Control).visible:
				return true
	return false

func _is_input_locked_externally() -> bool:
	if typeof(InputRouter1) == TYPE_NIL:
		return false
	if InputRouter1 == null:
		return false
	if InputRouter1.has_method("is_locked"):
		return InputRouter1.is_locked()
	return false

func _is_bookkeeping_panel_active() -> bool:
	return _bookkeeping_panel != null and _bookkeeping_panel.visible

func _hide_bookkeeping_panel() -> void:
	if _bookkeeping_panel == null:
		return
	if _bookkeeping_panel.has_method("hide_panel"):
		_bookkeeping_panel.call("hide_panel")
	else:
		_bookkeeping_panel.hide()

func _lock_input() -> void:
	_bus("input.lock", {"reason": _LOCK_REASON})

func _unlock_input() -> void:
	_bus("input.unlock", {"reason": _LOCK_REASON})

func _apply_mouse_mode() -> void:
	if is_open or _has_blocking_modal() or _is_bookkeeping_panel_active():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _is_fps_mode() else Input.MOUSE_MODE_VISIBLE

func _is_fps_mode() -> bool:
	var root := get_tree().root
	var gk := root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true

func _bus(topic: String, payload: Dictionary) -> void:
	var eb := _get_bus()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _get_bus() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _process(_delta: float) -> void:
	if is_open and _has_blocking_modal():
		close_menu()
