extends CharacterBody3D
class_name FPSPlayerController

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.0025
@export var max_pitch_deg: float = 80.0
@export var camera_path: NodePath = ^"PlayerCamera"

const ACT_MOVE_FWD := "move_forward"
const ACT_MOVE_BACK := "move_backward"
const ACT_MOVE_LEFT := "move_left"
const ACT_MOVE_RIGHT := "move_right"
const ACT_DEBUG_NOTIFY := "debug_notify"

var _camera: Camera3D = null
var _yaw: float = 0.0
var _pitch: float = 0.0

var _pause_reasons: Dictionary = {} # reason -> true
var _lock_reasons: Dictionary = {}  # reason -> true
var _wants_capture: bool = true

func _ready() -> void:
	_cache_camera()
	_connect_bus()
	_apply_mouse_mode()
	set_process_unhandled_input(true)
	print("[FPS_FIX] FPSPlayerController elindult, egér mód: %s" % [str(Input.mouse_mode)])

func _exit_tree() -> void:
	_disconnect_bus()

func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return

	# Modal/pause alatt ne kezeljünk semmit
	if _is_blocked():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event as InputEventMouseMotion)

	if event is InputEventKey and event.pressed and not event.echo:
		var key = event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			_wants_capture = false
			_apply_mouse_mode()
		elif key.keycode == KEY_F1:
			_emit_debug_notification()

	if _action_pressed(ACT_DEBUG_NOTIFY, event):
		_emit_debug_notification()

func _physics_process(delta: float) -> void:
	if _is_blocked():
		velocity = Vector3.ZERO
		move_and_slide()
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
	print("[FPS_FIX] Egér mód frissítve: %s (wants_capture=%s, blocked=%s)" % [str(Input.mouse_mode), str(_wants_capture), str(_is_blocked())])

# -------------------- Internals --------------------

func _cache_camera() -> void:
	_camera = null
	if camera_path == NodePath("") or str(camera_path) == "":
		return
	if not has_node(camera_path):
		return
	var n = get_node(camera_path)
	if n is Camera3D:
		_camera = n as Camera3D

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
	print("[FPS_FIX] Egérmozgatás: rel=(%.3f, %.3f), yaw=%.3f, pitch=%.3f" % [ev.relative.x, ev.relative.y, _yaw, _pitch])

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
