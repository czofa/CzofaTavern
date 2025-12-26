extends Control

@export var title_label_path: NodePath = ^"MarginContainer/VBoxContainer/Title"
@export var status_label_path: NodePath = ^"MarginContainer/VBoxContainer/Status"
@export var toggle_button_path: NodePath = ^"MarginContainer/VBoxContainer/ToggleButton"
@export var back_button_path: NodePath = ^"MarginContainer/VBoxContainer/BackButton"
@export var build_controller_path: NodePath = ^"../../../WorldRoot/TavernWorld/BuildController"
@export var game_mode_controller_path: NodePath = ^"../../../CoreRoot/GameModeController"
@export var book_menu_path: NodePath = ^"../BookMenu"

const _LOCK_REASON := "build_menu"

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
	var engedely = _is_build_allowed_for_menu()
	_log_open_pressed(engedely)
	if not _ensure_build_available(engedely):
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
			_toggle_button.pressed.connect(_on_toggle_pressed)
	if _back_button != null:
		if _back_button.has_signal("pressed"):
			_back_button.pressed.connect(_on_back_pressed)

func _on_toggle_pressed() -> void:
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
	hide_panel()
	var main_menu = get_node_or_null(book_menu_path)
	if main_menu is Control:
		main_menu.visible = true
		if main_menu.has_method("_apply_state"):
			main_menu.call_deferred("_apply_state")

func _ensure_build_available(engedely: bool) -> bool:
	if not engedely:
		_notify_once("Építés itt nem engedélyezett.", _get_scene_key())
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
	var gmc = _get_game_mode_controller()
	if gmc != null and gmc.has_method("get_world_context"):
		return str(gmc.call("get_world_context")).to_lower()
	return "ismeretlen"

func _is_build_allowed_for_menu() -> bool:
	var build = _get_build_controller()
	if build != null and build.has_method("is_build_allowed"):
		return bool(build.call("is_build_allowed"))
	var kontextus = _get_world_context()
	return _is_build_world(kontextus)

func _get_scene_key() -> String:
	var scene = _get_active_world_scene()
	if scene == null:
		return "ismeretlen"
	var path = String(scene.scene_file_path)
	if path != "":
		return path
	return String(scene.name)

func _log_open_pressed(engedely: bool) -> void:
	var scene = _get_active_world_scene()
	var path = ""
	var name = "ismeretlen"
	if scene != null:
		path = String(scene.scene_file_path)
		name = String(scene.name)
	print("[BUILD] open pressed | scene=%s name=%s allowed=%s" % [path, name, str(engedely).to_lower()])

func _get_active_world_scene() -> Node:
	var build = _get_build_controller()
	if build != null and build.has_method("get_active_world_scene"):
		return build.call("get_active_world_scene")
	var tree = get_tree()
	if tree == null:
		return null
	return tree.current_scene

func _is_build_world(kontextus: String) -> bool:
	var vilag = str(kontextus).to_lower()
	if vilag == "tavern":
		return true
	if vilag == "farm":
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
