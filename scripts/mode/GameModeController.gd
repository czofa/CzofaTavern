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
@export var rts_camera_path: NodePath = ^"../../WorldRoot/TavernWorld/TavernCameraRig/RTSCamera"
@export var fps_camera_path: NodePath = ^"../../WorldRoot/TownWorld/Player/PlayerCamera"

const MODE_RTS: String = "RTS"
const MODE_FPS: String = "FPS"
const DEBUG_FPS_DIAG := true

var _tavern_world: Node = null
var _town_world: Node = null
var _rts_cam: Camera3D = null
var _fps_cam: Camera3D = null

func _ready() -> void:
	_cache_nodes()
	_connect_event_bus()

	var initial_mode = _get_current_mode()
	if initial_mode == "":
		initial_mode = MODE_RTS
	_apply_mode(_normalize_mode(initial_mode))

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
	_apply_mode(_normalize_mode(mode))

# -----------------------------------------------------------------------------
# Mode application
# -----------------------------------------------------------------------------

func _apply_mode(mode: String) -> void:
	if _tavern_world == null or _town_world == null or _rts_cam == null or _fps_cam == null:
		_cache_nodes()

	if mode == MODE_FPS:
		_set_visible(_tavern_world, false, "TavernWorld")
		_set_visible(_town_world, true, "TownWorld")
		_set_camera_current(_rts_cam, false, "RTSCamera")
		_set_camera_current(_fps_cam, true, "PlayerCamera")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if DEBUG_FPS_DIAG:
			var cam_path = str(_fps_cam.get_path()) if _fps_cam != null else "nincs kamera"
			print("[FPS_DIAG] FPS mód aktiválva, kamera=%s, mouse_mode=%s" % [cam_path, str(Input.mouse_mode)])
	else:
		_set_visible(_tavern_world, true, "TavernWorld")
		_set_visible(_town_world, false, "TownWorld")
		_set_camera_current(_rts_cam, true, "RTSCamera")
		_set_camera_current(_fps_cam, false, "PlayerCamera")
		if DEBUG_FPS_DIAG:
			print("[FPS_DIAG] RTS mód aktiválva, mouse_mode=%s" % str(Input.mouse_mode))

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

func _cache_nodes() -> void:
	_tavern_world = _get_node_or_warn(tavern_world_path, "TavernWorld", "tavern_world_path")
	_town_world = _get_node_or_warn(town_world_path, "TownWorld", "town_world_path")
	_rts_cam = _get_camera_or_warn(rts_camera_path, "RTSCamera", "rts_camera_path")
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
