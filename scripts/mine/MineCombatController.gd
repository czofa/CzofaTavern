extends Node
class_name MineCombatController

@export var run_controller_path: NodePath = ^"../MineRunController"
@export var camera_path: NodePath = ^"../PlayerCamera"
@export var attack_range: float = 4.0
@export var attack_cooldown: float = 0.3
@export var base_damage: int = 2
@export var attack_mask: int = 6

var _run: Node = null
var _camera: Camera3D = null
var _cooldown_left: float = 0.0

func _ready() -> void:
	_cache_nodes()
	_ensure_attack_action()
	set_process_input(true)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

func _input(event: InputEvent) -> void:
	if event == null:
		return
	if event.is_action_pressed("mine_attack"):
		_handle_attack()

func set_run_controller(node: Node) -> void:
	_run = node

func _handle_attack() -> void:
	if _run == null:
		return
	if _run.has_method("is_run_active") and not _run.call("is_run_active"):
		return
	if _cooldown_left > 0.0:
		return

	_cooldown_left = attack_cooldown
	_apply_attack_to_targets()

func _apply_attack_to_targets() -> void:
	_cache_nodes()
	var target = _raycast_target()
	if target == null:
		print("[MINE_HIT] no_hit")
		return
	var damage: int = base_damage
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	damage = clamp(rng.randi_range(1, max(base_damage, 1)), 1, 3)
	if target.has_method("apply_damage"):
		target.call("apply_damage", damage, _run)
	elif _run != null and _run.has_method("deal_damage_to_enemy"):
		_run.call("deal_damage_to_enemy", target)
	print("[MINE_HIT] hit=%s" % str(target.name))

func _cache_nodes() -> void:
	if run_controller_path != NodePath(""):
		_run = get_node_or_null(run_controller_path)
	if camera_path != NodePath(""):
		_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		_camera = _find_camera_from_run()

func _ensure_attack_action() -> void:
	if InputMap.has_action("mine_attack"):
		return
	var ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	InputMap.add_action("mine_attack")
	InputMap.action_add_event("mine_attack", ev)

func _find_camera_from_run() -> Camera3D:
	if _run != null and _run.has_method("get_player"):
		var player = _run.call("get_player")
		if player != null and player.has_node("PlayerCamera"):
			var cam = player.get_node_or_null("PlayerCamera")
			if cam is Camera3D:
				return cam as Camera3D
	return null

func _raycast_target() -> Node:
	if _camera == null:
		return null
	var space = _camera.get_world_3d().direct_space_state
	if space == null:
		return null
	var from = _camera.global_transform.origin
	var forward = -_camera.global_transform.basis.z
	var to = from + forward * attack_range
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = attack_mask
	var exclude: Array = []
	exclude.append(_camera)
	if _run != null and _run.has_method("get_player"):
		var p = _run.call("get_player")
		if p != null:
			exclude.append(p)
	query.exclude = exclude
	var result = space.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider", null)
