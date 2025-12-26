# res://scripts/mode/GameModeController.gd
extends Node
class_name GameModeController

# -----------------------------------------------------------------------------
# GameModeController (NEM autoload)
# - RTS ↔ FPS vizuális váltás (világ + kamera)
# - EventBus / EventBus1 game_mode_changed jelére reagál
# - Fail-soft: hiányzó node/signal -> warning, nincs crash
# -----------------------------------------------------------------------------

@export var tavern_world_path: NodePath = ^"../../WorldRoot/TavernWorld"
@export var town_world_path: NodePath = ^"../../WorldRoot/TownWorld"
@export var farm_world_path: NodePath = ^"../../WorldRoot/FarmWorld"
@export var rts_camera_path: NodePath = ^"../../WorldRoot/TavernWorld/TavernCameraRig/RTSCamera"
@export var farm_rts_camera_path: NodePath = ^"../../WorldRoot/FarmWorld/FarmCameraRig/RTSCamera"
@export var fps_camera_path: NodePath = ^"../../WorldRoot/TownWorld/Player/PlayerCamera"
@export var rts_controller_path: NodePath = ^"../../WorldRoot/TavernWorld/TavernCameraRig"
@export var farm_rts_controller_path: NodePath = ^"../../WorldRoot/FarmWorld/FarmCameraRig"
@export var fps_camera_controller_path: NodePath = ^"../../WorldRoot/TownWorld/Player/PlayerCamera"

const MODE_RTS: String = "RTS"
const MODE_FPS: String = "FPS"
const DEBUG_FPS_DIAG = true
const RTS_WORLD_TAVERN = "tavern"
const RTS_WORLD_FARM = "farm"

var _tavern_world: Node = null
var _town_world: Node = null
var _farm_world: Node = null
var _rts_cam: Camera3D = null
var _farm_rts_cam: Camera3D = null
var _fps_cam: Camera3D = null
var _rts_controller: Node = null
var _farm_rts_controller: Node = null
var _fps_cam_controller: Node = null
var _aktiv_rts_vilag: String = RTS_WORLD_TAVERN

func _ready() -> void:
	_ensure_move_actions()
	_cache_nodes()
	_connect_event_bus()

	var initial_mode = _get_current_mode()
	if initial_mode == "":
		initial_mode = MODE_RTS
	_apply_mode(_normalize_mode(initial_mode), true)

func _exit_tree() -> void:
	_disconnect_event_bus()

# -----------------------------------------------------------------------------
# EventBus wiring
# -----------------------------------------------------------------------------

func _get_event_bus() -> Node:
	if has_node("/root/EventBus"):
		return get_node("/root/EventBus")
	if has_node("/root/EventBus1"):
		return get_node("/root/EventBus1")
	return null

func _connect_event_bus() -> void:
	var eb = _get_event_bus()
	if eb == null:
		push_warning("GameModeController: EventBus/EventBus1 not found; mode changes won't apply.")
		return
	if not eb.has_signal("game_mode_changed"):
		push_warning("GameModeController: EventBus has no signal 'game_mode_changed'.")
		return

	var cb = Callable(self, "_on_game_mode_changed")
	if not eb.is_connected("game_mode_changed", cb):
		eb.connect("game_mode_changed", cb)

func _disconnect_event_bus() -> void:
	var eb = _get_event_bus()
	if eb == null:
		return
	var cb = Callable(self, "_on_game_mode_changed")
	if eb.has_signal("game_mode_changed") and eb.is_connected("game_mode_changed", cb):
		eb.disconnect("game_mode_changed", cb)

func _on_game_mode_changed(mode: String) -> void:
	_apply_mode(_normalize_mode(mode), false)

# -----------------------------------------------------------------------------
# Mode application
# -----------------------------------------------------------------------------

func _apply_mode(mode: String, is_startup: bool) -> void:
	if _tavern_world == null or _town_world == null or _rts_cam == null or _fps_cam == null or _farm_world == null:
		_cache_nodes()
		_frissit_kamerak()

	var cel_rts_vilag = _get_rts_vilag_node()
	var cel_rts_kamera = _get_rts_kamera()
	var cel_rts_controller = _get_rts_controller()

	if mode == MODE_FPS:
		_set_visible(_tavern_world, false, "TavernWorld")
		_set_visible(_farm_world, false, "FarmWorld")
		_set_visible(_town_world, true, "TownWorld")
		_set_camera_current(_rts_cam, false, "RTSCamera")
		_set_camera_current(_farm_rts_cam, false, "Farm RTSCamera")
		_set_camera_current(_fps_cam, true, "PlayerCamera")
		_set_controller_active(_rts_controller, false, "Tavern RTS kamera vezérlő")
		_set_controller_active(_farm_rts_controller, false, "Farm RTS kamera vezérlő")
		_set_controller_active(_fps_cam_controller, true, "FPS kamera vezérlő")
		_apply_mouse_mode_for_mode(mode)
		if DEBUG_FPS_DIAG:
			var cam_path = "nincs kamera"
			if _fps_cam != null:
				cam_path = str(_fps_cam.get_path())
			print("[FPS_DIAG] FPS mód aktiválva, kamera=%s, mouse_mode=%s" % [cam_path, str(Input.mouse_mode)])
	else:
		_set_visible(_tavern_world, cel_rts_vilag == _tavern_world, "TavernWorld")
		_set_visible(_farm_world, cel_rts_vilag == _farm_world, "FarmWorld")
		_set_visible(_town_world, false, "TownWorld")
		_set_camera_current(_rts_cam, cel_rts_kamera == _rts_cam, "RTSCamera")
		_set_camera_current(_farm_rts_cam, cel_rts_kamera == _farm_rts_cam, "Farm RTSCamera")
		_set_camera_current(_fps_cam, false, "PlayerCamera")
		_set_controller_active(_rts_controller, cel_rts_controller == _rts_controller, "Tavern RTS kamera vezérlő")
		_set_controller_active(_farm_rts_controller, cel_rts_controller == _farm_rts_controller, "Farm RTS kamera vezérlő")
		_set_controller_active(_fps_cam_controller, false, "FPS kamera vezérlő")
		_apply_mouse_mode_for_mode(mode)
		if is_startup:
			var cam_path = "nincs kamera"
			if cel_rts_kamera != null:
				cam_path = str(cel_rts_kamera.get_path())
			print("[MODE] start_mode=RTS active_cam=%s" % cam_path)
		if DEBUG_FPS_DIAG:
			var cam_path_rts = "nincs kamera"
			if cel_rts_kamera != null:
				cam_path_rts = str(cel_rts_kamera.get_path())
			print("[FPS_DIAG] RTS mód aktiválva, kamera=%s mouse_mode=%s" % [cam_path_rts, str(Input.mouse_mode)])
	var aktiv_log_vilag = cel_rts_vilag
	if mode == MODE_FPS:
		aktiv_log_vilag = _town_world
	_log_mode_state(mode, aktiv_log_vilag)

func apply_current_mode() -> void:
	_cache_nodes()
	var mode = _get_current_mode()
	if mode == "":
		mode = MODE_RTS
	_apply_mode(_normalize_mode(mode), false)

func _set_visible(node: Node, v: bool, label: String) -> void:
	if node == null:
		push_warning("GameModeController: %s not found; cannot set visible=%s." % [label, str(v)])
		return
	if node is Node3D:
		(node as Node3D).visible = v
	elif node is CanvasItem:
		(node as CanvasItem).visible = v
	else:
		push_warning("GameModeController: %s has no visible; using process toggles only." % label)

	node.process_mode = Node.PROCESS_MODE_INHERIT if v else Node.PROCESS_MODE_DISABLED
	node.set_process(v)
	node.set_physics_process(v)
	node.set_process_input(v)
	node.set_process_unhandled_input(v)

func _set_camera_current(cam: Camera3D, is_current: bool, label: String) -> void:
	if cam == null:
		push_warning("GameModeController: %s not found; cannot set current=%s." % [label, str(is_current)])
		return
	cam.current = is_current

func _set_controller_active(node: Node, aktiv: bool, label: String) -> void:
	if node == null:
		push_warning("GameModeController: %s nem elérhető; active=%s" % [label, str(aktiv)])
		return
	if node.has_method("set_active"):
		node.call("set_active", aktiv)
	else:
		push_warning("GameModeController: %s nem tudja a set_active metódust." % label)

func _apply_mouse_mode_for_mode(mode: String) -> void:
	if mode == MODE_FPS:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _log_mode_state(mode: String, aktiv_vilag: Node) -> void:
	var vilag_nev = "ismeretlen"
	if aktiv_vilag != null:
		vilag_nev = aktiv_vilag.name
	var cam_path = "nincs"
	var viewport = get_viewport()
	if viewport != null:
		var cam = viewport.get_camera_3d()
		if cam != null:
			cam_path = str(cam.get_path())
	var lock_info = _lock_informacio()
	print("[MODE_LOG] mod=%s vilag=%s kamera=%s mouse=%s lock=%s" % [mode, vilag_nev, cam_path, str(Input.mouse_mode), lock_info])

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

func _ensure_move_actions() -> void:
	var mappings: Array = [
		{
			"nev": "move_forward",
			"physical": KEY_W,
			"arrow": KEY_UP
		},
		{
			"nev": "move_backward",
			"physical": KEY_S,
			"arrow": KEY_DOWN
		},
		{
			"nev": "move_left",
			"physical": KEY_A,
			"arrow": KEY_LEFT
		},
		{
			"nev": "move_right",
			"physical": KEY_D,
			"arrow": KEY_RIGHT
		}
	]

	for mapping in mappings:
		var action = str(mapping.get("nev", "")).strip_edges()
		if action == "":
			continue
		var physical: int = int(mapping.get("physical", 0))
		var arrow: int = int(mapping.get("arrow", 0))
		_ensure_action_keys(action, physical, arrow)

func _ensure_action_keys(action_name: String, physical_key: int, arrow_key: int) -> void:
	if action_name == "":
		return
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	_add_key_event_if_missing(action_name, physical_key, true)
	_add_key_event_if_missing(action_name, arrow_key, false)

func _add_key_event_if_missing(action_name: String, keycode: int, use_physical: bool) -> void:
	if keycode <= 0:
		return
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey:
			var k = existing as InputEventKey
			if use_physical and k.physical_keycode == keycode:
				return
			if not use_physical and k.keycode == keycode:
				return
	var ev = InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode if use_physical else 0
	InputMap.action_add_event(action_name, ev)

func _cache_nodes() -> void:
	_tavern_world = _get_node_or_warn(tavern_world_path, "TavernWorld", "tavern_world_path")
	_town_world = _get_node_or_warn(town_world_path, "TownWorld", "town_world_path")
	_farm_world = _get_node_or_warn(farm_world_path, "FarmWorld", "farm_world_path")
	_rts_controller = _get_node_or_warn(rts_controller_path, "RTS kamera vezérlő", "rts_controller_path")
	_farm_rts_controller = _get_node_or_warn(farm_rts_controller_path, "Farm RTS kamera vezérlő", "farm_rts_controller_path")
	_fps_cam_controller = _get_node_or_warn(fps_camera_controller_path, "FPS kamera vezérlő", "fps_camera_controller_path")
	_frissit_kamerak()

func _frissit_kamerak() -> void:
	_rts_cam = _leker_controller_kamera(_rts_controller, "RTS kamera vezérlő", rts_camera_path, "RTSCamera", "rts_camera_path")
	_farm_rts_cam = _leker_controller_kamera(_farm_rts_controller, "Farm RTS kamera vezérlő", farm_rts_camera_path, "Farm RTSCamera", "farm_rts_camera_path")
	_fps_cam = _leker_controller_kamera(_fps_cam_controller, "FPS kamera vezérlő", fps_camera_path, "PlayerCamera", "fps_camera_path")

func _get_node_or_warn(path: NodePath, label: String, export_name: String) -> Node:
	if path == NodePath("") or str(path) == "":
		push_warning("GameModeController: %s is empty; cannot resolve %s." % [export_name, label])
		return null
	if not has_node(path):
		push_warning("GameModeController: Node not found at %s (%s)." % [str(path), label])
		return null
	return get_node(path)

func _get_camera_or_warn(path: NodePath, label: String, export_name: String) -> Camera3D:
	var n = _get_node_or_warn(path, label, export_name)
	if n == null:
		return null
	if n is Camera3D:
		return n as Camera3D
	push_warning("GameModeController: %s is not a Camera3D at %s." % [label, str(path)])
	return null

func _leker_controller_kamera(controller: Node, label: String, fallback_path: NodePath, fallback_label: String, export_name: String) -> Camera3D:
	if controller != null and controller.has_method("get_camera"):
		var cam_val = controller.call("get_camera")
		if cam_val is Camera3D:
			return cam_val as Camera3D
		push_warning("GameModeController: %s get_camera nem Camera3D-t adott vissza." % label)
	if fallback_path == NodePath(""):
		return null
	return _get_camera_or_warn(fallback_path, fallback_label, export_name)

func _normalize_mode(mode: String) -> String:
	var m = str(mode).strip_edges().to_upper()
	if m == MODE_FPS:
		return MODE_FPS
	return MODE_RTS

func _get_current_mode() -> String:
	if has_node("/root/GameKernel"):
		var gk = get_node("/root/GameKernel")
		if gk != null and gk.has_method("get_mode"):
			return str(gk.call("get_mode"))
	return ""

func set_rts_world(world_id: String) -> void:
	var cel = _normalize_rts_world(world_id)
	if cel == _aktiv_rts_vilag:
		return
	_aktiv_rts_vilag = cel
	_apply_mode(_normalize_mode(_get_current_mode()), false)

func get_rts_world() -> String:
	return _aktiv_rts_vilag

func get_world_context() -> String:
	_cache_nodes()
	var aktiv_vilag = _get_aktiv_vilag()
	return _world_context_from_node(aktiv_vilag)

func _get_aktiv_vilag() -> Node:
	var mode = _normalize_mode(_get_current_mode())
	if mode == MODE_FPS:
		return _town_world
	return _get_rts_vilag_node()

func _world_context_from_node(vilag: Node) -> String:
	if vilag == null:
		return "ismeretlen"
	if vilag.is_in_group("world_tavern"):
		return "tavern"
	if vilag.is_in_group("world_farm"):
		return "farm"
	if vilag.is_in_group("world_town"):
		return "town"
	return "ismeretlen"

func _normalize_rts_world(world_id: String) -> String:
	var w = str(world_id).strip_edges().to_lower()
	if w == RTS_WORLD_FARM:
		return RTS_WORLD_FARM
	return RTS_WORLD_TAVERN

func _get_rts_vilag_node() -> Node:
	return _farm_world if _aktiv_rts_vilag == RTS_WORLD_FARM else _tavern_world

func _get_rts_kamera() -> Camera3D:
	return _farm_rts_cam if _aktiv_rts_vilag == RTS_WORLD_FARM else _rts_cam

func _get_rts_controller() -> Node:
	return _farm_rts_controller if _aktiv_rts_vilag == RTS_WORLD_FARM else _rts_controller

func _lock_informacio() -> String:
	if typeof(InputRouter1) == TYPE_NIL or InputRouter1 == null:
		return "nincs_router"
	if InputRouter1.has_method("get_lock_reasons"):
		var okok = InputRouter1.call("get_lock_reasons")
		if okok is Array and not okok.is_empty():
			return "zár:%s" % ",".join(okok)
	if InputRouter1.has_method("is_locked") and bool(InputRouter1.call("is_locked")):
		return "zárva"
	return "szabad"
