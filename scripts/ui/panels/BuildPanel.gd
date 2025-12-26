extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var status_label_path: NodePath = ^"MarginContainer/VBoxContainer/Status"
@export var toggle_button_path: NodePath = ^"MarginContainer/VBoxContainer/ToggleButton"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"
@export var build_controller_path: NodePath = ^"../../../WorldRoot/TavernWorld/BuildController"
@export var game_mode_controller_path: NodePath = ^"../../../CoreRoot/GameModeController"
@export var book_menu_path: NodePath = ^"../BookMenu"

const _LOCK_REASON := "build_menu"
const _WORLD_GROUPS := ["world_tavern", "world_town", "world_farm", "world_mine"]

var _title_label: Label
var _status_label: Label
var _toggle_button: Button
var _back_button: Button
var _build_controller: Node
var _game_mode_controller: Node
var _tiltas_ertesites_ms: int = 0
var _tiltas_vilag: String = ""

func _ready() -> void:
	_cache_nodes()
	hide()

func show_panel() -> void:
	if _status_label == null:
		push_error("❌ Hiányzó NodePath: %s" % status_label_path)
		return
	if _toggle_button == null:
		push_error("❌ Hiányzó NodePath: %s" % toggle_button_path)
		return
	if _back_button == null:
		push_error("❌ Hiányzó NodePath: %s" % back_button_path)
		return
	if not _ensure_build_available():
		return
	if _is_fps_mode():
		_set_rts_mode()
	_frissit_status()
	_lock_input(true)
	_apply_mouse_mode(true)
	show()
	print("🏗️ Építés menü megnyitva.")

func hide_panel() -> void:
	hide()
	_lock_input(false)
	_apply_mouse_mode(false)

func _cache_nodes() -> void:
	_title_label = get_node_or_null(title_label_path) as Label
	_status_label = get_node_or_null(status_label_path) as Label
	_toggle_button = get_node_or_null(toggle_button_path) as Button
	_back_button = get_node_or_null(back_button_path) as Button
	_build_controller = get_node_or_null(build_controller_path)
	_game_mode_controller = get_node_or_null(game_mode_controller_path)

	if _title_label != null:
		_title_label.text = "🏗️ Építés"
	if _toggle_button != null:
		if _toggle_button.has_signal("pressed"):
			var cb_toggle = Callable(self, "_on_toggle_pressed")
			if not _toggle_button.pressed.is_connected(cb_toggle):
				_toggle_button.pressed.connect(cb_toggle)
	if _back_button != null:
		if _back_button.has_signal("pressed"):
			var cb_back = Callable(self, "_on_back_pressed")
			if not _back_button.pressed.is_connected(cb_back):
				_back_button.pressed.connect(cb_back)

func _on_toggle_pressed() -> void:
	var kontextus = _world_kontextus()
	print("[BUILD_UI] gomb=%s build_vezerlo_null=%s vilag=%s" % [
		_gomb_nev(_toggle_button),
		str(_get_build_controller() == null),
		kontextus
	])
	var build = _get_build_controller()
	if build == null:
		_frissit_status("❌ Építési vezérlő nem érhető el.")
		return
	if build.has_method("toggle_build_mode_from_ui"):
		build.call("toggle_build_mode_from_ui")
	elif build.has_method("_valt_build_mod"):
		build.call("_valt_build_mod")
	_frissit_status()

func _on_back_pressed() -> void:
	var kontextus = _world_kontextus()
	print("[BUILD_UI] gomb=%s fomenü_null=%s vilag=%s" % [
		_gomb_nev(_back_button),
		str(get_node_or_null(book_menu_path) == null),
		kontextus
	])
	hide_panel()
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu == null:
		push_error("❌ Hiányzó NodePath: %s" % book_menu_path)
		return
	if main_menu is Control:
		var menu_control = main_menu as Control
		menu_control.visible = true
		if menu_control.has_method("_apply_state"):
			menu_control.call_deferred("_apply_state")
	else:
		push_error("❌ Főmenü nem Control, visszalépés megszakítva.")
		return

func _ensure_build_available() -> bool:
	var kontextus = _world_kontextus()
	var csoportok = _aktiv_vilag_csoportok()
	if not _vilag_engedi_epitest(kontextus, csoportok):
		_log_build_tiltas(kontextus, "vilag_tiltott", csoportok)
		_notify_once("Építés itt nem engedélyezett.", kontextus)
		return false
	var build = _get_build_controller()
	if build != null:
		return true
	_notify("❌ Építési vezérlő nem érhető el.")
	return false

func _set_rts_mode() -> void:
	_bus("mode.set", {"mode": "RTS"})
	var root = get_tree().root
	if root == null:
		return
	var eb = root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("request_set_game_mode"):
		eb.emit_signal("request_set_game_mode", "RTS")

func _lock_input(locked: bool) -> void:
	if locked:
		_bus("input.lock", {"reason": _LOCK_REASON})
	else:
		_bus("input.unlock", {"reason": _LOCK_REASON})

func _apply_mouse_mode(panel_open: bool) -> void:
	if panel_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if _is_book_menu_open():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if _is_fps_mode():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _is_book_menu_open() -> bool:
	var menu = get_node_or_null(book_menu_path)
	if menu == null:
		return false
	if menu.has_method("is_menu_open"):
		return bool(menu.call("is_menu_open"))
	if menu is Control:
		return (menu as Control).visible
	return false

func _is_fps_mode() -> bool:
	var root = get_tree().root
	if root == null:
		return true
	var gk = root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true

func _bus(topic: String, payload: Dictionary) -> void:
	var root = get_tree().root
	if root == null:
		return
	var eb = root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _notify(text: String) -> void:
	var root = get_tree().root
	if root == null:
		return
	var eb = root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)

func _get_build_controller() -> Node:
	if _build_controller != null:
		return _build_controller
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	var found = root.find_child("BuildController", true, false)
	if found != null:
		_build_controller = found
	return _build_controller

func _get_game_mode_controller() -> Node:
	if _game_mode_controller != null:
		return _game_mode_controller
	if not is_inside_tree():
		return null
	var root = get_tree().root
	if root == null:
		return null
	var found = root.find_child("GameModeController", true, false)
	if found != null:
		_game_mode_controller = found
	return _game_mode_controller

func _get_world_context() -> String:
	return _world_kontextus()

func _world_kontextus() -> String:
	var vilag = _get_aktiv_vilag()
	if vilag != null:
		var csoport_alap = _vilag_kontextus_csoportbol(vilag)
		if csoport_alap != "":
			return csoport_alap
	return _fallback_vilag_kontextus()

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

func _get_aktiv_vilag() -> Node:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	for csoport in _WORLD_GROUPS:
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

func _aktiv_vilag_csoportok() -> Array:
	var vilag = _get_aktiv_vilag()
	var eredmeny: Array = []
	if vilag == null:
		return eredmeny
	for csoport in _WORLD_GROUPS:
		if vilag.is_in_group(csoport):
			eredmeny.append(csoport)
	return eredmeny

func _vilag_engedi_epitest(kontextus: String, csoportok: Array) -> bool:
	for csoport in csoportok:
		if str(csoport) == "world_tavern" or str(csoport) == "world_farm":
			return true
	if kontextus.find("tavern") != -1:
		return true
	if kontextus.find("farm") != -1:
		return true
	return false

func _frissit_status(uz: String = "") -> void:
	if _status_label == null:
		return
	var build = _get_build_controller()
	if uz != "":
		_status_label.text = uz
		return
	if build == null:
		_status_label.text = "ℹ️ Építési mód nem elérhető."
		return
	var aktiv = false
	if build.has_method("is_build_mode_active"):
		aktiv = bool(build.call("is_build_mode_active"))
	if aktiv:
		_status_label.text = "Építési mód: AKTÍV"
	else:
		_status_label.text = "Építési mód: ki"

func _notify_once(text: String, kontextus: String) -> void:
	var most = Time.get_ticks_msec()
	if _tiltas_vilag == kontextus and most < _tiltas_ertesites_ms:
		return
	_tiltas_vilag = kontextus
	_tiltas_ertesites_ms = most + 2500
	_notify(text)

func _log_build_tiltas(kontextus: String, ok: String, csoportok: Array) -> void:
	print("[BUILD] denied world=%s reason=%s groups=%s" % [
		kontextus,
		ok,
		str(csoportok)
	])

func _gomb_nev(gomb: Button) -> String:
	if gomb == null:
		return "ismeretlen"
	return str(gomb.name)
