# res://scripts/town/InteractRaycaster.gd
extends Node3D
class_name InteractRaycaster

@export var camera_path: NodePath = ^"../PlayerCamera"
@export var max_distance: float = 3.5
@export var collision_mask: int = 1
@export var prompt_text: String = "E - Interakció"
@export var debug_toast: bool = true
const DEBUG_FPS_DIAG := true

var _camera: Camera3D = null
var _current_target: Node = null
var _prompt_visible: bool = false
var _last_prompt_text: String = ""
var _last_hit_collider: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_ensure_input_action()
	_cache_camera()
	_connect_bus()
	if debug_toast:
		_notify("Raycaster READY")
	if DEBUG_FPS_DIAG:
		print("[FPS_DIAG] InteractRaycaster READY, camera_path=%s" % str(camera_path))

func _exit_tree() -> void:
	_disconnect_bus()
	_request_prompt(false, "")

func _process(_delta: float) -> void:
	if _camera == null:
		_cache_camera()
		if _camera == null:
			return

	var target = _find_interactable_target()
	if target != _current_target:
		if DEBUG_FPS_DIAG and target != null:
			var collider_name = _last_hit_collider.name if _last_hit_collider != null else "ismeretlen"
			print("[FPS_DIAG] Ray találat: target=%s, collider=%s" % [target.name, collider_name])
		_current_target = target
		if _current_target != null:
			_request_prompt(true, prompt_text)
		else:
			_request_prompt(false, "")

# -------------------- BUS --------------------

func _eb() -> Node:
	var root = get_tree().root
	var eb1 = root.get_node_or_null("EventBus1")
	if eb1 != null:
		return eb1
	return root.get_node_or_null("EventBus")

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null:
		push_warning("InteractRaycaster: no EventBus1/EventBus.")
		return

	# 1) klasszikus signal út
	if eb.has_signal("request_interact"):
		var cb = Callable(self, "_on_request_interact")
		if not eb.is_connected("request_interact", cb):
			eb.connect("request_interact", cb)

	# 2) bus út (biztonsági)
	if eb.has_signal("bus_emitted"):
		var cb2 = Callable(self, "_on_bus")
		if not eb.is_connected("bus_emitted", cb2):
			eb.connect("bus_emitted", cb2)

func _disconnect_bus() -> void:
	var eb = _eb()
	if eb == null:
		return

	var cb = Callable(self, "_on_request_interact")
	if eb.has_signal("request_interact") and eb.is_connected("request_interact", cb):
		eb.disconnect("request_interact", cb)

	var cb2 = Callable(self, "_on_bus")
	if eb.has_signal("bus_emitted") and eb.is_connected("bus_emitted", cb2):
		eb.disconnect("bus_emitted", cb2)

func _on_bus(topic: String, _payload: Dictionary) -> void:
	var t = str(topic)
	if t == "input.interact" or t == "request.interact" or t == "interact":
		_on_request_interact()

# -------------------- INTERACT --------------------

func _on_request_interact() -> void:
	if DEBUG_FPS_DIAG:
		var target_name = _current_target.name if _current_target != null else "nincs"
		print("[FPS_DIAG] Interakció kérve, current_target=%s" % target_name)
	if debug_toast:
		_notify("Raycaster GOT INTERACT")

	if _current_target == null:
		if DEBUG_FPS_DIAG:
			print("[FPS_DIAG] Interakció kérve, de nincs target")
		_notify("Nincs mit interaktálni")
		return

	if _current_target.has_method("interact"):
		if DEBUG_FPS_DIAG:
			print("[FPS_DIAG] Interakció futtatása: %s" % _current_target.name)
		_current_target.call("interact")
		return

	_notify("Nincs mit interaktálni")

# -------------------- RAY --------------------

func _find_interactable_target() -> Node:
	var w = get_world_3d()
	if w == null or w.direct_space_state == null:
		return null

	var origin = _camera.global_transform.origin
	var dir = -_camera.global_transform.basis.z
	var to = origin + dir * max_distance

	var params = PhysicsRayQueryParameters3D.create(origin, to)
	params.collision_mask = collision_mask
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.hit_from_inside = true
	params.exclude = _build_exclude_list()

	var hit = w.direct_space_state.intersect_ray(params)
	if hit.is_empty():
		_last_hit_collider = null
		return null

	var collider_obj: Object = hit.get("collider", null)
	var collider_node = collider_obj as Node
	if collider_node == null:
		_last_hit_collider = null
		return null
	_last_hit_collider = collider_node

	return _resolve_interactable(collider_node)

func _build_exclude_list() -> Array:
	var arr: Array = []
	var player = get_parent()
	if player != null:
		if player is CollisionObject3D:
			arr.append(player)
		for c in player.get_children():
			if c is CollisionObject3D:
				arr.append(c)
	return arr

func _resolve_interactable(n: Node) -> Node:
	var cur = n
	var steps = 0
	while cur != null and steps < 8:
		if cur.has_method("interact"):
			return cur
		if cur.is_in_group("interactable"):
			if cur.get_parent() != null and cur.get_parent().has_method("interact"):
				return cur.get_parent()
			return cur
		cur = cur.get_parent()
		steps += 1
	return null

# -------------------- UI + CAMERA --------------------

func _request_prompt(show: bool, text: String) -> void:
	if show == _prompt_visible and _last_prompt_text == text:
		return
	_prompt_visible = show
	_last_prompt_text = text
	if DEBUG_FPS_DIAG:
		print("[FPS_DIAG] Prompt kérés: show=%s, text=%s" % [str(show), text])

	var eb = _eb()
	if eb != null and eb.has_signal("request_show_interaction_prompt"):
		eb.emit_signal("request_show_interaction_prompt", show, text)

func _notify(text: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)

func _cache_camera() -> void:
	_camera = null
	if camera_path == NodePath("") or str(camera_path) == "":
		return
	if not has_node(camera_path):
		return
	var n = get_node(camera_path)
	if n is Camera3D:
		_camera = n as Camera3D

func _ensure_input_action() -> void:
	if not InputMap.has_action("ui_interact"):
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.add_action("ui_interact")
		InputMap.action_add_event("ui_interact", ev)
		if DEBUG_FPS_DIAG:
			print("[FPS_DIAG] Input action ui_interact hozzáadva E-re")

	if not InputMap.has_action("interact"):
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = KEY_E
		InputMap.add_action("interact")
		InputMap.action_add_event("interact", ev2)
		if DEBUG_FPS_DIAG:
			print("[FPS_DIAG] Input action interact hozzáadva E-re")
