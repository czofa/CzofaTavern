extends CharacterBody3D

@export var max_hp: int = 3
@export var touch_damage: int = 1
@export var touch_cooldown: float = 0.6
@export var move_speed: float = 2.2
@export var attack_range: float = 1.2
@export var damage_area_path: NodePath = ^"DamageArea"

var _run: Node = null
var _hp: int = 0
var _cooldown: float = 0.0
var _damage_area: Area3D = null
var _targets: Array = []
var _player_target: CharacterBody3D = null
var _attacking: bool = false

func _ready() -> void:
	add_to_group("enemy")
	_cache_damage_area()
	reset_enemy()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_update_target_player()
	_move_towards_player(delta)
	_tick_attack(delta)

func set_run_controller(node: Node) -> void:
	_run = node

func reset_enemy() -> void:
	_hp = max_hp
	_cooldown = 0.0
	_targets.clear()
	_player_target = null
	_attacking = false

func take_hit(amount: int) -> void:
	var dmg = max(int(amount), 0)
	if dmg <= 0:
		return
	_hp = max(_hp - dmg, 0)
	if _hp <= 0:
		_on_death()

func apply_damage(amount: int, attacker: Node = null) -> void:
	take_hit(amount)

func _on_death() -> void:
	if _run != null and _run.has_method("on_enemy_killed"):
		_run.call("on_enemy_killed", self)
	queue_free()

func _apply_touch_damage() -> void:
	_cooldown = touch_cooldown
	if _run != null and _run.has_method("apply_enemy_damage"):
		_run.call("apply_enemy_damage", touch_damage, "overlap", self)

func _tick_attack(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _cooldown > 0.0:
		return
	if _has_player_overlap():
		_apply_touch_damage()
		return
	if _attacking and _is_in_attack_range():
		_cooldown = touch_cooldown
		if _run != null and _run.has_method("apply_enemy_damage"):
			_run.call("apply_enemy_damage", touch_damage, "distance", self)

func _update_target_player() -> void:
	_prune_targets()
	_player_target = _get_player()
	_attacking = _player_target != null

func _prune_targets() -> void:
	var valid: Array = []
	for t in _targets:
		if t != null and is_instance_valid(t):
			if t is CharacterBody3D and (t as CharacterBody3D).name == "Player":
				valid.append(t)
	_targets = valid

func _cache_damage_area() -> void:
	if damage_area_path != NodePath("") and has_node(damage_area_path):
		_damage_area = get_node(damage_area_path) as Area3D
	if _damage_area != null:
		var cb_enter = Callable(self, "_on_damage_area_body_entered")
		var cb_exit = Callable(self, "_on_damage_area_body_exited")
		if not _damage_area.is_connected("body_entered", cb_enter):
			_damage_area.connect("body_entered", cb_enter)
		if not _damage_area.is_connected("body_exited", cb_exit):
			_damage_area.connect("body_exited", cb_exit)

func _on_damage_area_body_entered(body: Node) -> void:
	if body == null:
		return
	if not (body is CharacterBody3D):
		return
	if (body as CharacterBody3D).name != "Player":
		return
	if not _targets.has(body):
		_targets.append(body)

func _on_damage_area_body_exited(body: Node) -> void:
	if body == null:
		return
	if _targets.has(body):
		_targets.erase(body)

func _has_player_overlap() -> bool:
	_prune_targets()
	return _targets.size() > 0

func _is_in_attack_range() -> bool:
	if _player_target == null:
		return false
	var pos = global_transform.origin
	var target_pos = _player_target.global_transform.origin
	var flat = target_pos - pos
	flat.y = 0.0
	return flat.length() <= attack_range

func _move_towards_player(_delta: float) -> void:
	if _player_target == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var pos = global_transform.origin
	var target_pos = _player_target.global_transform.origin
	var dir = target_pos - pos
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	velocity.y = 0.0
	move_and_slide()

func _get_player() -> CharacterBody3D:
	if _run != null and _run.has_method("get_player"):
		var p = _run.call("get_player")
		if p is CharacterBody3D:
			return p as CharacterBody3D
	return null
