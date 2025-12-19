extends Control
class_name UIRootController

@export var interaction_prompt_path: NodePath = ^"InteractionPrompt"
@export var encounter_modal_path: NodePath = ^"Modals/EncounterModal"
@export var book_menu_path: NodePath = ^"BookMenu"
@export var bookkeeping_panel_path: NodePath = ^"BookkeepingPanel"
@export var stock_panel_path: NodePath = ^"Bookkeeping_StockPanel"
const DEBUG_FPS_DIAG := true

var _interaction_prompt: InteractionPromptController
var _encounter_modal: Control
var _book_menu: Control
var _bookkeeping_panel: Control
var _stock_panel: Control

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

	if _book_menu != null and _book_menu.has_method("close_menu"):
		_book_menu.call("close_menu")

	if _interaction_prompt != null and _interaction_prompt.has_method("set_prompt"):
		_interaction_prompt.set_prompt(false, "")

func _alap_allapot() -> void:
	if _interaction_prompt != null and _interaction_prompt.has_method("set_prompt"):
		_interaction_prompt.set_prompt(false, "")
	if _encounter_modal != null:
		_encounter_modal.visible = false
