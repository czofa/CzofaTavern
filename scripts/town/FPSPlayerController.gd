extends CharacterBody3D
class_name FPSPlayerController

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.0025
@export var max_pitch_deg: float = 80.0
@export var camera_path: NodePath = ^"PlayerCamera"
@export var camera_controller_path: NodePath = ^"PlayerCamera"

const ACT_MOVE_FWD = "move_forward"
const ACT_MOVE_BACK = "move_backward"
const ACT_MOVE_LEFT = "move_left"
const ACT_MOVE_RIGHT = "move_right"
const ACT_DEBUG_NOTIFY = "debug_notify"
const DEBUG_FPS_DIAG: bool = false

var _camera: Camera3D = null
var _camera_controller: Node = null
var _yaw: float = 0.0
var _pitch: float = 0.0

var _pause_reasons: Dictionary = {} # reason -> true
var _lock_reasons: Dictionary = {}  # reason -> true
var _wants_capture: bool = true
var _mine_diag_enabled: bool = false
var _diag_prints: int = 0
var _diag_flags: Dictionary = {}

func _ready() -> void:
	_mine_diag_enabled = _is_in_mine_world()
	_cache_camera_controller()
	_cache_camera()
	_connect_bus()
	_apply_mouse_mode()
	print("[PLAYER_FIX] has PlayerCamera=", get_node_or_null("PlayerCamera") != null, " has Raycaster=", get_node_or_null("InteractRaycaster") != null)
	set_process_input(true)
	set_process_unhandled_input(true)
	if DEBUG_FPS_DIAG:
		print("[FPS_DIAG] FPSPlayerController indul, egér mód: %s" % [str(Input.mouse_mode)])

func _exit_tree() -> void:
	_disconnect_bus()

func _input(event: InputEvent) -> void:
	_log_mouse_motion(event, "input")
	_handle_input_event(event)

func _unhandled_input(event: InputEvent) -> void:
	_log_mouse_motion(event, "unhandled_input")

func _handle_input_event(event: InputEvent) -> void:
	if event == null:
		return

	# Modal/pause alatt ne kezeljünk semmit
	if _is_blocked():
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _camera_controller == null:
			_apply_mouse_look(event as InputEventMouseMotion)
		elif DEBUG_FPS_DIAG:
			print("[FPS_DIAG] Egérmozgás érkezett, de a capture kikapcsolt (mode=%s)" % str(Input.mouse_mode))

	if event is InputEventKey and event.pressed and not event.echo:
		var key = event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			_wants_capture = false
			_apply_mouse_mode()
		elif key.keycode == KEY_F1:
			_emit_debug_notification()
		elif key.keycode == KEY_E and DEBUG_FPS_DIAG:
			print("[FPS_DIAG] E lenyomva FPSPlayerController-ben")

	if _action_pressed(ACT_DEBUG_NOTIFY, event):
		_emit_debug_notification()

func _physics_process(delta: float) -> void:
	if _camera == null:
		_cache_camera()
		if _camera == null:
			_stop_movement()
			_maybe_diag("[FPS_BIND] missing camera/pivot -> movement disabled", "missing_camera")
			return

	if _is_blocked():
		velocity = Vector3.ZERO
		move_and_slide()
		_maybe_diag("[FPS_BIND] input blokkolt, mozgás letiltva", "blocked_input")
		return

	var input_dir = _get_move_input()
	var basis = global_transform.basis
	var forward = -basis.z
	var right = basis.x

	var move = (right * input_dir.x) + (forward * input_dir.y)
	move.y = 0.0
	if move.length() > 1e-5:
		move = move.normalized()

	velocity.x = move.x * move_speed
	velocity.z = move.z * move_speed

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

# -------------------- Blocking --------------------

func _is_blocked() -> bool:
	return _pause_reasons.size() > 0 or _lock_reasons.size() > 0

func _norm_reason(reason: String) -> String:
	var r = str(reason).strip_edges()
	return r if r != "" else "unknown"

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _disconnect_bus() -> void:
	var eb = _eb()
	if eb == null:
		return
	var cb = Callable(self, "_on_bus")
	if eb.has_signal("bus_emitted") and eb.is_connected("bus_emitted", cb):
		eb.disconnect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	var t = str(topic)

	if t == "input.lock":
		var r = _norm_reason(str(payload.get("reason","encounter")))
		_lock_reasons[r] = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if t == "input.unlock":
		var r2 = _norm_reason(str(payload.get("reason","encounter")))
		if _lock_reasons.has(r2):
			_lock_reasons.erase(r2)
		_apply_mouse_mode()
		return

	if t == "input.unlock_all":
		_lock_reasons.clear()
		_apply_mouse_mode()
		return

	if t == "time.pause":
		var pr = _norm_reason(str(payload.get("reason","encounter")))
		_pause_reasons[pr] = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if t == "time.resume":
		var pr2 = _norm_reason(str(payload.get("reason","encounter")))
		if _pause_reasons.has(pr2):
			_pause_reasons.erase(pr2)
		_apply_mouse_mode()
		return

	if t == "time.resume_all":
		_pause_reasons.clear()
		_apply_mouse_mode()
		return

func _apply_mouse_mode() -> void:
	if _is_blocked():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _wants_capture else Input.MOUSE_MODE_VISIBLE
	if DEBUG_FPS_DIAG:
		print("[FPS_DIAG] Egér mód frissítve: %s (wants_capture=%s, blocked=%s)" % [str(Input.mouse_mode), str(_wants_capture), str(_is_blocked())])

# -------------------- Internals --------------------

func _cache_camera() -> void:
	_camera = null
	if _camera_controller != null and _camera_controller.has_method("get_camera"):
		var cam_val = _camera_controller.call("get_camera")
		if cam_val is Camera3D:
			_camera = cam_val as Camera3D
	if _camera != null:
		_yaw = rotation.y
		_pitch = _camera.rotation.x
		return
	if camera_path == NodePath("") or str(camera_path) == "":
		_maybe_diag("[FPS_BIND] missing camera/pivot -> movement disabled", "missing_camera")
		return
	if not has_node(camera_path):
		_maybe_diag("[FPS_BIND] missing camera/pivot -> movement disabled", "missing_camera")
		return
	var n = get_node(camera_path)
	if n is Camera3D:
		_camera = n as Camera3D
		_yaw = rotation.y
		_pitch = _camera.rotation.x

func _cache_camera_controller() -> void:
	_camera_controller = null
	if camera_controller_path == NodePath("") or str(camera_controller_path) == "":
		return
	if not has_node(camera_controller_path):
		return
	var n = get_node(camera_controller_path)
	if n is FPSCameraController:
		_camera_controller = n

func _apply_mouse_look(ev: InputEventMouseMotion) -> void:
	_yaw -= ev.relative.x * mouse_sensitivity
	_pitch -= ev.relative.y * mouse_sensitivity

	var max_pitch = deg_to_rad(max_pitch_deg)
	_pitch = clamp(_pitch, -max_pitch, max_pitch)

	rotation.y = _yaw
	if _camera != null:
		var cam_rot = _camera.rotation
		cam_rot.x = _pitch
		_camera.rotation = cam_rot
	if DEBUG_FPS_DIAG:
		print("[FPS_DIAG] Egérmozgatás: forrás=motion, rel=(%.3f, %.3f), yaw=%.3f, pitch=%.3f" % [ev.relative.x, ev.relative.y, _yaw, _pitch])

func _get_move_input() -> Vector2:
	var x = 0.0
	var y = 0.0

	if InputMap.has_action(ACT_MOVE_LEFT) and Input.is_action_pressed(ACT_MOVE_LEFT): x -= 1.0
	if InputMap.has_action(ACT_MOVE_RIGHT) and Input.is_action_pressed(ACT_MOVE_RIGHT): x += 1.0
	if InputMap.has_action(ACT_MOVE_FWD) and Input.is_action_pressed(ACT_MOVE_FWD): y += 1.0
	if InputMap.has_action(ACT_MOVE_BACK) and Input.is_action_pressed(ACT_MOVE_BACK): y -= 1.0

	if x == 0.0 and y == 0.0:
		if Input.is_key_pressed(KEY_A): x -= 1.0
		if Input.is_key_pressed(KEY_D): x += 1.0
		if Input.is_key_pressed(KEY_W): y += 1.0
		if Input.is_key_pressed(KEY_S): y -= 1.0

	return Vector2(x, y)

func _action_pressed(action_name: String, event: InputEvent) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")

func _emit_debug_notification() -> void:
	var eb = _eb()
	if eb == null:
		return
	if eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text":"DEBUG: FPSPlayerController F1"})
	elif eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", "DEBUG: FPSPlayerController F1")

func _log_mouse_motion(event: InputEvent, source: String) -> void:
	if not DEBUG_FPS_DIAG:
		return
	if event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		print("[FPS_DIAG] MouseMotion érkezett (%s): rel=(%.3f, %.3f), mouse_mode=%s" % [source, mm.relative.x, mm.relative.y, str(Input.mouse_mode)])

func _is_in_mine_world() -> bool:
	var node: Node = self
	while node != null:
		if node.name == "MineWorld":
			return true
		node = node.get_parent()
	return false

func _maybe_diag(msg: String, key: String) -> void:
	if not _mine_diag_enabled:
		return
	if _diag_prints >= 3:
		return
	if _diag_flags.has(key):
		return
	_diag_flags[key] = true
	_diag_prints += 1
	print(msg)

func _stop_movement() -> void:
	velocity = Vector3.ZERO
	move_and_slide()
