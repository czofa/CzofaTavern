extends Node3D

@export var max_hp: int = 3
@export var loot_level_bonus: int = 0
@export var loot_pickup_scene: PackedScene

var _hp: int = 0
var _broken: bool = false

func _ready() -> void:
	_hp = max_hp
	add_to_group("mineable")

func apply_damage(amount: int, _attacker: Node = null) -> void:
	if _broken:
		return
	var dmg: int = max(int(amount), 0)
	if dmg <= 0:
		return
	_hp = max(_hp - dmg, 0)
	if _hp <= 0:
		_break_rock()

func _break_rock() -> void:
	if _broken:
		return
	_broken = true
	_spawn_loot()
	queue_free()

func _spawn_loot() -> void:
	var level: int = 1
	if typeof(MineProgressionSystem1) != TYPE_NIL and MineProgressionSystem1 != null and MineProgressionSystem1.has_method("get_level"):
		level = MineProgressionSystem1.get_level()
	level += loot_level_bonus
	var drop: Dictionary = MineLootTable.pick_rock_drop(level)
	if drop.is_empty():
		return
	var scene: PackedScene = loot_pickup_scene
	if scene == null:
		var res = load("res://scenes/mine/LootPickup.tscn")
		if res is PackedScene:
			scene = res
	if scene == null:
		return
	var inst = scene.instantiate()
	if not (inst is Node3D):
		return
	var node3d = inst as Node3D
	node3d.global_transform = global_transform
	if inst.has_method("set_loot_data"):
		inst.call("set_loot_data", str(drop.get("id", "")), int(drop.get("qty", 1)), int(drop.get("value", 0)))
	else:
		inst.set("item_id", str(drop.get("id", "")))
		inst.set("qty", int(drop.get("qty", 1)))
		inst.set("value_each", int(drop.get("value", 0)))
	var parent = get_parent()
	if parent == null:
		parent = get_tree().current_scene
	if parent != null:
		parent.add_child(inst)
