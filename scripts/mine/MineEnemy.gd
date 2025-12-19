extends CharacterBody3D

@export var max_hp: int = 3
@export var touch_damage: int = 1
@export var touch_cooldown: float = 0.6
@export var damage_area_path: NodePath = ^"DamageArea"

var _run: Node = null
var _hp: int = 0
var _cooldown: float = 0.0
var _damage_area: Area3D = null
var _targets: Array = []

func _ready() -> void:
	_cache_damage_area()
	reset_enemy()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _cooldown <= 0.0 and _player_near():
		_apply_touch_damage()

func set_run_controller(node: Node) -> void:
	_run = node

func reset_enemy() -> void:
	_hp = max_hp
	_cooldown = 0.0
	_targets.clear()

func take_hit(amount: int) -> void:
	var dmg = max(int(amount), 0)
	if dmg <= 0:
		return
	_hp = max(_hp - dmg, 0)
	if _hp <= 0:
		_on_death()

func _on_death() -> void:
	if _run != null and _run.has_method("on_enemy_killed"):
		_run.call("on_enemy_killed", self)
	queue_free()

func _apply_touch_damage() -> void:
	_cooldown = touch_cooldown
	if _run != null and _run.has_method("apply_enemy_damage"):
		_run.call("apply_enemy_damage", touch_damage)

func _player_near() -> bool:
	_prune_targets()
	return _targets.size() > 0

func _prune_targets() -> void:
	var valid: Array = []
	for t in _targets:
		if t != null and is_instance_valid(t):
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
	if not _targets.has(body):
		_targets.append(body)

func _on_damage_area_body_exited(body: Node) -> void:
	if body == null:
		return
	if _targets.has(body):
		_targets.erase(body)
