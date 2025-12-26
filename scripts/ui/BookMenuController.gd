extends Control

@export var start_open: bool = false
@export var bookkeeping_button_path: NodePath = ^"MarginContainer/VBoxContainer/Könyvelés"
@export var bookkeeping_panel_path: NodePath = ^"BookkeepingPanel"
@export var economy_button_path: NodePath = ^"MarginContainer/VBoxContainer/Gazdaság"
@export var economy_panel_path: NodePath = ^"../EconomyPanel"
@export var inventory_button_path: NodePath = ^"MarginContainer/VBoxContainer/Leltár"
@export var inventory_panel_path: NodePath = ^"../InventoryPanel"
@export var build_button_path: NodePath = ^"MarginContainer/VBoxContainer/Építés"
@export var build_panel_path: NodePath = ^"../BuildPanel"
@export var employees_button_path: NodePath = ^"MarginContainer/VBoxContainer/Alkalmazottak"
@export var employees_panel_path: NodePath = ^"EmployeesHubPanel"
@export var employees_hire_panel_path: NodePath = ^"EmployeesHirePanel"
@export var employees_my_panel_path: NodePath = ^"EmployeesMyPanel"
@export var day_end_summary_path: NodePath = ^"../DayEndSummary"
@export var encounter_modal_path: NodePath = ^"../Modals/EncounterModal"
@export var modals_root_path: NodePath = ^"../Modals"
@export var faction_panel_path: NodePath = ^"MarginContainer/VBoxContainer/FactionPanel"

const _LOCK_REASON := "book_menu"

var is_open: bool = false
var _bookkeeping_button: Button
var _bookkeeping_panel: Control
var _economy_button: Button
var _economy_panel: Control
var _inventory_button: Button
var _inventory_panel: Control
var _build_button: Button
var _build_panel: Control
var _employees_button: Button
var _employees_panel: Control
var _employees_hire_panel: Control
var _employees_my_panel: Control
var _day_end_summary: Control
var _encounter_modal: Control
var _modals_root: Control
var _has_bus_toggle: bool = false
var _faction_panel: Control
var _ui_root: UIRootController

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
	_refresh_faction_panel()
	_apply_state()
	_log_pause_state("BookMenu megnyitva")

func close_menu() -> void:
	_unlock_input()
	_hide_bookkeeping_panel()
	_hide_employee_panel()
	_hide_extra_panels()
	is_open = false
	_apply_state()
	_restore_after_close()
	_log_pause_state("BookMenu bezárva")

func is_menu_open() -> bool:
	return is_open

func _apply_state() -> void:
	var show_menu = is_open and not _is_bookkeeping_panel_active() and not _is_employee_panel_active() and not _is_extra_panel_active()
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

func _on_economy_pressed() -> void:
	print("💰 Gazdaság gomb megnyomva.")
	_hide_employee_panel()
	_hide_bookkeeping_panel()
	_hide_inventory_panel()
	_hide_build_panel()
	if _economy_panel == null:
		push_warning("ℹ️ Gazdasági panel nem található, a gombot kihagyjuk.")
		_apply_state()
		return
	if _economy_panel.has_method("show_panel"):
		_economy_panel.call("show_panel")
	else:
		_economy_panel.show()
	_apply_state()

func _on_inventory_pressed() -> void:
	print("📦 Leltár gomb megnyomva.")
	_hide_employee_panel()
	_hide_bookkeeping_panel()
	_hide_economy_panel()
	_hide_build_panel()
	if _inventory_panel == null:
		push_warning("ℹ️ Leltár panel nem található, a gombot kihagyjuk.")
		_apply_state()
		return
	if _inventory_panel.has_method("show_panel"):
		_inventory_panel.call("show_panel")
	else:
		_inventory_panel.show()
	_apply_state()

func _on_build_pressed() -> void:
	print("🏗️ Építés gomb megnyomva.")
	_hide_employee_panel()
	_hide_bookkeeping_panel()
	_hide_economy_panel()
	_hide_inventory_panel()
	if _build_panel == null:
		push_warning("ℹ️ Építési panel nem található, a gombot kihagyjuk.")
		_apply_state()
		return
	if _build_panel.has_method("show_panel"):
		_build_panel.call("show_panel")
	else:
		_build_panel.show()
	_apply_state()

func _on_employees_pressed() -> void:
	var hub_ok = _employees_panel != null
	if not hub_ok:
		push_error("[EMP] missing node: %s" % str(employees_panel_path))
		print("[EMP] open pressed ok=false hub=false")
		return
	print("[EMP] open pressed ok=true hub=true")
	_hide_bookkeeping_panel()
	_hide_economy_panel()
	_hide_inventory_panel()
	_hide_build_panel()
	if _employees_panel.has_method("show_panel"):
		_employees_panel.call("show_panel")
	else:
		_employees_panel.show()
	_apply_state()

func _cache_nodes() -> void:
	_ui_root = _get_ui_root()
	_bookkeeping_button = get_node_or_null(bookkeeping_button_path)
	_bookkeeping_panel = get_node_or_null(bookkeeping_panel_path)
	_economy_button = get_node_or_null(economy_button_path)
	_economy_panel = get_node_or_null(economy_panel_path)
	_inventory_button = get_node_or_null(inventory_button_path)
	_inventory_panel = get_node_or_null(inventory_panel_path)
	_build_button = get_node_or_null(build_button_path)
	_build_panel = get_node_or_null(build_panel_path)
	_employees_button = get_node_or_null(employees_button_path)
	_employees_panel = _find_employee_panel("EmployeesHubPanel", employees_panel_path)
	_employees_hire_panel = _find_employee_panel("EmployeesHirePanel", employees_hire_panel_path)
	_employees_my_panel = _find_employee_panel("EmployeesMyPanel", employees_my_panel_path)
	_day_end_summary = get_node_or_null(day_end_summary_path)
	_encounter_modal = get_node_or_null(encounter_modal_path)
	_modals_root = get_node_or_null(modals_root_path)
	_faction_panel = get_node_or_null(faction_panel_path)

	if _bookkeeping_button == null:
		push_warning("❌ BookMenu: nem található a könyvelés gomb (%s)." % bookkeeping_button_path)
	if _bookkeeping_panel == null:
		push_warning("❌ BookMenu: nem található a könyvelés panel (%s)." % bookkeeping_panel_path)
	if _economy_button == null:
		push_warning("ℹ️ BookMenu: nem található a gazdasági gomb (%s)." % economy_button_path)
	if _economy_panel == null:
		push_warning("ℹ️ BookMenu: nem található a gazdasági panel (%s)." % economy_panel_path)
	if _inventory_button == null:
		push_warning("ℹ️ BookMenu: nem található a leltár gomb (%s)." % inventory_button_path)
	if _inventory_panel == null:
		push_warning("ℹ️ BookMenu: nem található a leltár panel (%s)." % inventory_panel_path)
	if _build_button == null:
		push_warning("ℹ️ BookMenu: nem található az építés gomb (%s)." % build_button_path)
	if _build_panel == null:
		push_warning("ℹ️ BookMenu: nem található az építés panel (%s)." % build_panel_path)
	if _employees_button == null:
		push_warning("ℹ️ BookMenu: nem található az alkalmazott gomb (%s)." % employees_button_path)
	if _employees_panel == null:
		push_warning("ℹ️ BookMenu: nem található az alkalmazott panel (%s)." % employees_panel_path)
	if _employees_hire_panel == null:
		push_warning("ℹ️ BookMenu: nem található az alkalmazotti felvételi panel (%s)." % employees_hire_panel_path)
	if _employees_my_panel == null:
		push_warning("ℹ️ BookMenu: nem található a saját alkalmazotti panel (%s)." % employees_my_panel_path)
	if _faction_panel == null:
		push_warning("ℹ️ BookMenu: frakció panel nem található (%s)." % faction_panel_path)

func _connect_button() -> void:
	if _bookkeeping_button != null:
		var cb = Callable(self, "_on_bookkeeping_pressed")
		if not _bookkeeping_button.pressed.is_connected(cb):
			_bookkeeping_button.pressed.connect(cb)
	if _economy_button != null:
		var cb_eco = Callable(self, "_on_economy_pressed")
		if not _economy_button.pressed.is_connected(cb_eco):
			_economy_button.pressed.connect(cb_eco)
	if _inventory_button != null:
		var cb_inv = Callable(self, "_on_inventory_pressed")
		if not _inventory_button.pressed.is_connected(cb_inv):
			_inventory_button.pressed.connect(cb_inv)
	if _build_button != null:
		var cb_build = Callable(self, "_on_build_pressed")
		if not _build_button.pressed.is_connected(cb_build):
			_build_button.pressed.connect(cb_build)
	if _employees_button != null:
		var cb_emp = Callable(self, "_on_employees_pressed")
		if not _employees_button.pressed.is_connected(cb_emp):
			_employees_button.pressed.connect(cb_emp)

func _connect_bus() -> void:
	var eb = _get_bus()
	if eb == null:
		push_warning("ℹ️ BookMenu: EventBus1 nem érhető el, csak InputMap fog működni.")
		return
	if eb.has_signal("request_toggle_book_menu"):
		var cb_toggle = Callable(self, "_on_request_toggle_menu")
		if not eb.is_connected("request_toggle_book_menu", cb_toggle):
			eb.connect("request_toggle_book_menu", cb_toggle)
			_has_bus_toggle = true
	if eb.has_signal("request_close_all_popups"):
		var cb_close = Callable(self, "_on_request_close_all_popups")
		if not eb.is_connected("request_close_all_popups", cb_close):
			eb.connect("request_close_all_popups", cb_close)

func _on_request_toggle_menu() -> void:
	toggle_menu()

func _on_request_close_all_popups() -> void:
	if is_open or _is_bookkeeping_panel_active() or _is_employee_panel_active() or _is_extra_panel_active():
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
	var root = _get_fa_gyoker()
	if root == null:
		return false
	var ui_root = root.get_node_or_null("Main/UIRoot")
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
	if _bookkeeping_panel != null and _bookkeeping_panel.visible:
		return true
	if _is_named_panel_visible("Bookkeeping_StockPanel"):
		return true
	if _is_named_panel_visible("Bookkeeping_EmployeesPanel"):
		return true
	if _is_named_panel_visible("TaxReportPanel"):
		return true
	return false

func _hide_bookkeeping_panel() -> void:
	if _bookkeeping_panel == null:
		return
	if _bookkeeping_panel.has_method("hide_panel"):
		_bookkeeping_panel.call("hide_panel")
	else:
		_bookkeeping_panel.hide()

func _hide_employee_panel() -> void:
	if _employees_panel == null:
		return
	if _employees_panel.has_method("hide_panel"):
		_employees_panel.call("hide_panel")
	else:
		_employees_panel.hide()
	if _employees_hire_panel != null:
		if _employees_hire_panel.has_method("hide_panel"):
			_employees_hire_panel.call("hide_panel")
		else:
			_employees_hire_panel.hide()
	if _employees_my_panel != null:
		if _employees_my_panel.has_method("hide_panel"):
			_employees_my_panel.call("hide_panel")
		else:
			_employees_my_panel.hide()

func _hide_economy_panel() -> void:
	if _economy_panel == null:
		return
	if _economy_panel.has_method("hide_panel"):
		_economy_panel.call("hide_panel")
	else:
		_economy_panel.hide()

func _hide_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	if _inventory_panel.has_method("hide_panel"):
		_inventory_panel.call("hide_panel")
	else:
		_inventory_panel.hide()

func _hide_build_panel() -> void:
	if _build_panel == null:
		return
	if _build_panel.has_method("hide_panel"):
		_build_panel.call("hide_panel")
	else:
		_build_panel.hide()

func _hide_extra_panels() -> void:
	_hide_economy_panel()
	_hide_inventory_panel()
	_hide_build_panel()

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
	var root = _get_fa_gyoker()
	if root == null:
		return true
	var gk = root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _get_bus()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _get_bus() -> Node:
	var root = _get_fa_gyoker()
	if root == null:
		return null
	return root.get_node_or_null("EventBus1")

func _get_ui_root() -> UIRootController:
	var root = _get_fa_gyoker()
	if root == null:
		return null
	var found = root.find_child("UiRoot", true, false)
	if found == null:
		found = root.find_child("UIRoot", true, false)
	if found is UIRootController:
		return found
	return found as UIRootController

func _get_fa_gyoker() -> Node:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	if tree.root == null:
		return null
	return tree.root

func _process(_delta: float) -> void:
	if is_open and _has_blocking_modal():
		close_menu()

func _find_employee_panel(name: String, fallback_path: NodePath) -> Control:
	var panel = get_node_or_null(fallback_path)
	if panel != null:
		return panel
	if _ui_root != null and _ui_root.has_method("_find_ui"):
		return _ui_root._find_ui(name) as Control
	if is_inside_tree() and get_tree().root != null:
		return get_tree().root.find_child(name, true, false)
	return null

func _is_named_panel_visible(name: String) -> bool:
	if not is_inside_tree():
		return false
	if get_tree().root == null:
		return false
	var panel = get_tree().root.find_child(name, true, false)
	if panel is Control:
		return panel.visible
	return false

func _refresh_faction_panel() -> void:
	if _faction_panel != null and _faction_panel.has_method("refresh_panel"):
		_faction_panel.call("refresh_panel")

func _restore_after_close() -> void:
	var modal_marad = _has_blocking_modal()
	if not modal_marad and get_tree().paused:
		get_tree().paused = false
	if _is_input_locked():
		_bus("input.unlock", {"reason": _LOCK_REASON})
	if not modal_marad:
		_bus("time.resume", {"reason": _LOCK_REASON})
	_apply_mouse_mode()

func _is_employee_panel_active() -> bool:
	if _employees_panel != null and _employees_panel.visible:
		return true
	if _employees_hire_panel != null and _employees_hire_panel.visible:
		return true
	if _employees_my_panel != null and _employees_my_panel.visible:
		return true
	return false

func _is_extra_panel_active() -> bool:
	if _economy_panel != null and _economy_panel.visible:
		return true
	if _inventory_panel != null and _inventory_panel.visible:
		return true
	if _build_panel != null and _build_panel.visible:
		return true
	return false

func _log_pause_state(context: String) -> void:
	var paused_flag = get_tree().paused
	var mouse_mode_value = Input.mouse_mode
	var router_locked = _is_input_locked()
	var player_blocked = _is_player_blocked()
	print("[PAUSE_FIX] %s | paused=%s | mouse_mode=%s | input_zar=%s | jatekos_blokk=%s" % [
		context,
		str(paused_flag),
		str(mouse_mode_value),
		str(router_locked),
		str(player_blocked)
	])

func _is_input_locked() -> bool:
	if typeof(InputRouter1) == TYPE_NIL:
		return false
	if InputRouter1 == null:
		return false
	if InputRouter1.has_method("is_locked"):
		return InputRouter1.is_locked()
	return false

func _is_player_blocked() -> bool:
	var player = get_tree().root.get_node_or_null("Main/WorldRoot/TownWorld/Player")
	if player == null:
		return false
	if player.has_method("_is_blocked"):
		return bool(player.call("_is_blocked"))
	return not player.is_physics_processing() or not player.is_processing_input()
