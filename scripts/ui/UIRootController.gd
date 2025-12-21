extends Control
class_name UIRootController

@export var interaction_prompt_path: NodePath = ^"InteractionPrompt"
@export var encounter_modal_path: NodePath = ^"Modals/EncounterModal"
@export var book_menu_path: NodePath = ^"BookMenu"
@export var bookkeeping_panel_path: NodePath = ^"BookkeepingPanel"
@export var stock_panel_path: NodePath = ^"Bookkeeping_StockPanel"
@export var employees_panel_path: NodePath = ^"EmployeesHubPanel"
@export var employees_hire_panel_path: NodePath = ^"EmployeesHirePanel"
@export var employees_my_panel_path: NodePath = ^"EmployeesMyPanel"
@export var bookkeeping_employees_panel_path: NodePath = ^"Bookkeeping_EmployeesPanel"
@export var tax_panel_path: NodePath = ^"TaxReportPanel"
@export var economy_panel_path: NodePath = ^"EconomyPanel"
@export var inventory_panel_path: NodePath = ^"InventoryPanel"
@export var build_panel_path: NodePath = ^"BuildPanel"
const DEBUG_FPS_DIAG := true

var _interaction_prompt: InteractionPromptController
var _encounter_modal: Control
var _book_menu: Control
var _bookkeeping_panel: Control
var _stock_panel: Control
var _employees_panel: Control
var _employees_hire_panel: Control
var _employees_my_panel: Control
var _bookkeeping_employees_panel: Control
var _tax_panel: Control
var _economy_panel: Control
var _inventory_panel: Control
var _build_panel: Control

func _ready() -> void:
	_cache_nodes()
	_connect_event_bus()
	_alap_allapot()

func _cache_nodes() -> void:
	_interaction_prompt = get_node_or_null(interaction_prompt_path) as InteractionPromptController
	_encounter_modal = get_node_or_null(encounter_modal_path) as Control
	_book_menu = get_node_or_null(book_menu_path) as Control
	_bookkeeping_panel = get_node_or_null(bookkeeping_panel_path) as Control
	_stock_panel = get_node_or_null(stock_panel_path) as Control
	_employees_panel = get_node_or_null(employees_panel_path) as Control
	_employees_hire_panel = get_node_or_null(employees_hire_panel_path) as Control
	_employees_my_panel = get_node_or_null(employees_my_panel_path) as Control
	_bookkeeping_employees_panel = get_node_or_null(bookkeeping_employees_panel_path) as Control
	_tax_panel = get_node_or_null(tax_panel_path) as Control
	_economy_panel = get_node_or_null(economy_panel_path) as Control
	_inventory_panel = get_node_or_null(inventory_panel_path) as Control
	_build_panel = get_node_or_null(build_panel_path) as Control

func _connect_event_bus() -> void:
	if not is_inside_tree():
		return
	var tree = get_tree()
	if tree == null or tree.root == null:
		push_warning("ℹ️ EventBus1 nem érhető el, a prompt jelzés nem működik.")
		return
	var eb = tree.root.get_node_or_null("EventBus1")
	if eb == null:
		push_warning("ℹ️ EventBus1 nem érhető el, a prompt jelzés nem működik.")
		return

	if eb.has_signal("request_show_interaction_prompt"):
		var cb = Callable(self, "_on_request_interaction_prompt")
		if not eb.is_connected("request_show_interaction_prompt", cb):
			eb.connect("request_show_interaction_prompt", cb)
			if DEBUG_FPS_DIAG:
				print("[FPS_DIAG] UIRootController feliratkozva: request_show_interaction_prompt")

	if eb.has_signal("request_close_all_popups"):
		var cb2 = Callable(self, "_on_request_close_all_popups")
		if not eb.is_connected("request_close_all_popups", cb2):
			eb.connect("request_close_all_popups", cb2)
			if DEBUG_FPS_DIAG:
				print("[FPS_DIAG] UIRootController feliratkozva: request_close_all_popups")

func _on_request_interaction_prompt(show: bool, text: String) -> void:
	if DEBUG_FPS_DIAG:
		print("[FPS_DIAG] UI prompt frissítés: show=%s, text=%s" % [str(show), text])
	if _interaction_prompt != null and _interaction_prompt.has_method("set_prompt"):
		_interaction_prompt.set_prompt(show, text)

func _on_request_close_all_popups() -> void:
	if _encounter_modal != null and _encounter_modal.has_method("close_modal"):
		_encounter_modal.call("close_modal")

	if _stock_panel != null and _stock_panel.has_method("hide_panel"):
		_stock_panel.call("hide_panel")

	if _bookkeeping_panel != null and _bookkeeping_panel.has_method("hide_panel"):
		_bookkeeping_panel.call("hide_panel")

	if _bookkeeping_employees_panel != null and _bookkeeping_employees_panel.has_method("hide_panel"):
		_bookkeeping_employees_panel.call("hide_panel")

	if _tax_panel != null and _tax_panel.has_method("hide_panel"):
		_tax_panel.call("hide_panel")
	elif _tax_panel != null:
		_tax_panel.hide()

	if _employees_panel != null and _employees_panel.has_method("hide_panel"):
		_employees_panel.call("hide_panel")
	if _employees_hire_panel != null and _employees_hire_panel.has_method("hide_panel"):
		_employees_hire_panel.call("hide_panel")
	if _employees_my_panel != null and _employees_my_panel.has_method("hide_panel"):
		_employees_my_panel.call("hide_panel")

	if _book_menu != null and _book_menu.has_method("close_menu"):
		_book_menu.call("close_menu")

	if _economy_panel != null and _economy_panel.has_method("hide_panel"):
		_economy_panel.call("hide_panel")
	elif _economy_panel != null:
		_economy_panel.hide()

	if _inventory_panel != null and _inventory_panel.has_method("hide_panel"):
		_inventory_panel.call("hide_panel")
	elif _inventory_panel != null:
		_inventory_panel.hide()

	if _build_panel != null and _build_panel.has_method("hide_panel"):
		_build_panel.call("hide_panel")
	elif _build_panel != null:
		_build_panel.hide()

	if _interaction_prompt != null and _interaction_prompt.has_method("set_prompt"):
		_interaction_prompt.set_prompt(false, "")

func _find_ui(name: String) -> Node:
	if has_node(name):
		return get_node(name)
	if is_inside_tree():
		return get_tree().root.find_child(name, true, false)
	return null

func show_employees_hub() -> void:
	var hub_panel = _find_ui("EmployeesHubPanel") as Control
	var hire_panel = _find_ui("EmployeesHirePanel") as Control
	var my_panel = _find_ui("EmployeesMyPanel") as Control

	if hub_panel == null or hire_panel == null or my_panel == null:
		if hub_panel == null:
			print("[EMP_UI] panel not found: EmployeesHubPanel")
		elif hire_panel == null:
			print("[EMP_UI] panel not found: EmployeesHirePanel")
		else:
			print("[EMP_UI] panel not found: EmployeesMyPanel")
		return

	_hide_panel(hire_panel)
	_hide_panel(my_panel)
	hub_panel.call_deferred("show")
	hub_panel.call_deferred("raise")
	hub_panel.call_deferred("grab_focus")

func _alap_allapot() -> void:
	if _interaction_prompt != null and _interaction_prompt.has_method("set_prompt"):
		_interaction_prompt.set_prompt(false, "")
	if _encounter_modal != null:
		_encounter_modal.visible = false

func _hide_panel(panel: Control) -> void:
	if panel == null:
		return
	if panel.has_method("hide_panel"):
		panel.call("hide_panel")
	else:
		panel.hide()
