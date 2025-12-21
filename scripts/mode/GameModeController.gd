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

const MODE_RTS: String = "RTS"
const MODE_FPS: String = "FPS"
const DEBUG_FPS_DIAG := true
const RTS_WORLD_TAVERN := "tavern"
const RTS_WORLD_FARM := "farm"

var _tavern_world: Node = null
var _town_world: Node = null
var _farm_world: Node = null
var _rts_cam: Camera3D = null
var _farm_rts_cam: Camera3D = null
var _fps_cam: Camera3D = null
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

	var cel_rts_vilag = _get_rts_vilag_node()
	var cel_rts_kamera = _get_rts_kamera()

	if mode == MODE_FPS:
		_set_visible(_tavern_world, false, "TavernWorld")
		_set_visible(_farm_world, false, "FarmWorld")
		_set_visible(_town_world, true, "TownWorld")
		_set_camera_current(_rts_cam, false, "RTSCamera")
		_set_camera_current(_farm_rts_cam, false, "Farm RTSCamera")
		_set_camera_current(_fps_cam, true, "PlayerCamera")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if DEBUG_FPS_DIAG:
			var cam_path = str(_fps_cam.get_path()) if _fps_cam != null else "nincs kamera"
			print("[FPS_DIAG] FPS mód aktiválva, kamera=%s, mouse_mode=%s" % [cam_path, str(Input.mouse_mode)])
	else:
		_set_visible(_tavern_world, cel_rts_vilag == _tavern_world, "TavernWorld")
		_set_visible(_farm_world, cel_rts_vilag == _farm_world, "FarmWorld")
		_set_visible(_town_world, false, "TownWorld")
		_set_camera_current(_rts_cam, cel_rts_kamera == _rts_cam, "RTSCamera")
		_set_camera_current(_farm_rts_cam, cel_rts_kamera == _farm_rts_cam, "Farm RTSCamera")
		_set_camera_current(_fps_cam, false, "PlayerCamera")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if is_startup:
			var cam_path = str(cel_rts_kamera.get_path()) if cel_rts_kamera != null else "nincs kamera"
			print("[MODE] start_mode=RTS active_cam=%s" % cam_path)
		if DEBUG_FPS_DIAG:
			var cam_path_rts = str(cel_rts_kamera.get_path()) if cel_rts_kamera != null else "nincs kamera"
			print("[FPS_DIAG] RTS mód aktiválva, kamera=%s mouse_mode=%s" % [cam_path_rts, str(Input.mouse_mode)])

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
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode if use_physical else 0
	InputMap.action_add_event(action_name, ev)

func _cache_nodes() -> void:
	_tavern_world = _get_node_or_warn(tavern_world_path, "TavernWorld", "tavern_world_path")
	_town_world = _get_node_or_warn(town_world_path, "TownWorld", "town_world_path")
	_farm_world = _get_node_or_warn(farm_world_path, "FarmWorld", "farm_world_path")
	_rts_cam = _get_camera_or_warn(rts_camera_path, "RTSCamera", "rts_camera_path")
	_farm_rts_cam = _get_camera_or_warn(farm_rts_camera_path, "Farm RTSCamera", "farm_rts_camera_path")
	_fps_cam = _get_camera_or_warn(fps_camera_path, "PlayerCamera", "fps_camera_path")

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

func _normalize_rts_world(world_id: String) -> String:
	var w = str(world_id).strip_edges().to_lower()
	if w == RTS_WORLD_FARM:
		return RTS_WORLD_FARM
	return RTS_WORLD_TAVERN

func _get_rts_vilag_node() -> Node:
	return _farm_world if _aktiv_rts_vilag == RTS_WORLD_FARM else _tavern_world

func _get_rts_kamera() -> Camera3D:
	return _farm_rts_cam if _aktiv_rts_vilag == RTS_WORLD_FARM else _rts_cam
