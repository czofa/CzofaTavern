extends Node
class_name MineCombatController

@export var run_controller_path: NodePath = ^"../MineRunController"
@export var attack_area_path: NodePath = ^"../AttackArea"
@export var attack_cooldown: float = 0.3

var _run: Node = null
var _attack_area: Area3D = null
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
	if event.is_action_pressed("attack"):
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
	if _attack_area == null:
		return
	var targets: Array = []
	for body in _attack_area.get_overlapping_bodies():
		if body != null:
			targets.append(body)
	for area in _attack_area.get_overlapping_areas():
		if area != null:
			targets.append(area)

	var unique: Array = []
	for t in targets:
		if t != null and not unique.has(t):
			unique.append(t)

	for t in unique:
		if t != null and is_instance_valid(t):
			if _run.has_method("deal_damage_to_enemy"):
				_run.call("deal_damage_to_enemy", t)

func _cache_nodes() -> void:
	if run_controller_path != NodePath(""):
		_run = get_node_or_null(run_controller_path)
	if attack_area_path != NodePath(""):
		_attack_area = get_node_or_null(attack_area_path) as Area3D

func _ensure_attack_action() -> void:
	if InputMap.has_action("attack"):
		return
	var ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	InputMap.add_action("attack")
	InputMap.action_add_event("attack", ev)
