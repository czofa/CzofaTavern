extends Node
class_name MineRunController

@export var player_path: NodePath = ^"../Player"
@export var combat_controller_path: NodePath = ^"../Player/MineCombat"
@export var mine_world_path: NodePath = ^".."
@export var town_world_path: NodePath = ^"../../TownWorld"
@export var enemy_spawn_path: NodePath = ^"../Spawns/EnemySpawn"
@export var player_spawn_path: NodePath = ^"../Spawns/PlayerSpawn"
@export var exit_area_path: NodePath = ^"../ExitArea"
@export var next_floor_area_path: NodePath = ^"../Spawns/NextFloorArea"
@export var enemy_container_path: NodePath = ^"../Enemies"
@export var enemy_scene: PackedScene

var floor_index: int = 1
var player_hp: int = 10
var loot: Dictionary = {}

const MAX_FLOOR: int = 3
const PLAYER_MAX_HP: int = 10
const LOOT_TABLE: Array = [
	{
		"id": "iron_ore",
		"chance": 30,
		"qty": 200
	},
	{
		"id": "tool_scrap",
		"chance": 10,
		"qty": 1
	}
]

var _player: CharacterBody3D = null
var _combat: Node = null
var _enemy: Node3D = null
var _mine_world: Node3D = null
var _town_world: Node3D = null
var _exit_area: Area3D = null
var _next_area: Area3D = null
var _enemy_container: Node = null
var _active: bool = false
var _input_diag_count: int = 0
var _input_diag_running: bool = false

func _ready() -> void:
	_cache_nodes()
	_connect_areas()
	_set_world_state(_mine_world, false)
	_force_unblock_player()
	call_deferred("_post_spawn_player_fix")

func start_run() -> void:
	_start_run_core()

func start_run_with_fade() -> void:
	_run_with_fade(Callable(self, "_start_run_core"))

func _start_run_core() -> void:
	_cache_nodes()
	floor_index = 1
	player_hp = PLAYER_MAX_HP
	loot.clear()
	_active = true

	_respawn_player()
	_spawn_enemy()
	_toggle_worlds(true)
	_notify("⛏️ Belépés a bányába (1. szint)")
	_start_input_diag()

func is_run_active() -> bool:
	return _active

func deal_damage_to_enemy(enemy: Node) -> void:
	if not _active:
		return
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("take_hit"):
		enemy.call("take_hit", 1)

func apply_enemy_damage(damage: int) -> void:
	if not _active:
		return
	var dmg = max(int(damage), 0)
	if dmg <= 0:
		return

	player_hp = max(player_hp - dmg, 0)
	_notify("🩸 Sebzés: -%d HP (jelenleg: %d)" % [dmg, player_hp])
	if player_hp <= 0:
		_notify("💀 Elestél a bányában")
		_complete_run(true)

func on_enemy_killed(enemy: Node) -> void:
	if not _active:
		return
	if _enemy != null and enemy == _enemy:
		_enemy = null
	_handle_loot_drop()
	if floor_index >= MAX_FLOOR:
		_notify("🏁 Utolsó szint teljesítve, menj a kijárathoz.")

func request_exit() -> void:
	if not _active:
		return
	_notify("🚪 Kilépés a bányából")
	_complete_run(false)

func _complete_run(fell: bool) -> void:
	_run_with_fade(Callable(self, "_complete_run_core").bind(fell))

func _complete_run_core(fell: bool) -> void:
	_active = false
	_clear_enemy()
	_transfer_loot()
	_apply_heal_cost()
	_toggle_worlds(false)
	if fell:
		_notify("⚠️ Gyógyulás szükséges, visszatérés a faluba.")
	else:
		_notify("⬆️ Visszatérés a faluba")

func _connect_areas() -> void:
	_exit_area = _get_node(exit_area_path) as Area3D
	_next_area = _get_node(next_floor_area_path) as Area3D
	if _exit_area != null:
		var cb = Callable(self, "_on_exit_body_entered")
		if not _exit_area.is_connected("body_entered", cb):
			_exit_area.connect("body_entered", cb)
	if _next_area != null:
		var cb2 = Callable(self, "_on_next_floor_body_entered")
		if not _next_area.is_connected("body_entered", cb2):
			_next_area.connect("body_entered", cb2)

func _on_exit_body_entered(body: Node) -> void:
	if body == _player:
		request_exit()

func _on_next_floor_body_entered(body: Node) -> void:
	if body != _player:
		return
	if not _active:
		return

	if floor_index >= MAX_FLOOR:
		_notify("🏁 Bánya run lezárása")
		_complete_run(false)
		return

	floor_index += 1
	_notify("⬇️ Következő szint: %d" % floor_index)
	_respawn_player()
	_spawn_enemy()

func _cache_nodes() -> void:
	_player = _get_node(player_path) as CharacterBody3D
	_combat = _get_node(combat_controller_path)
	_mine_world = _get_node(mine_world_path) as Node3D
	_town_world = _get_node(town_world_path) as Node3D
	_exit_area = _get_node(exit_area_path) as Area3D
	_next_area = _get_node(next_floor_area_path) as Area3D
	_enemy_container = _get_node(enemy_container_path)

	if _combat != null and _combat.has_method("set_run_controller"):
		_combat.call("set_run_controller", self)

func _respawn_player() -> void:
	if _player == null:
		return
	var spawn = _get_node(player_spawn_path) as Node3D
	if spawn == null:
		return
	_player.global_transform = spawn.global_transform
	_player.velocity = Vector3.ZERO

func _spawn_enemy() -> void:
	_clear_enemy()
	if enemy_scene == null:
		return

	if _enemy_container == null:
		_enemy_container = Node3D.new()
		add_child(_enemy_container)

	var inst = enemy_scene.instantiate()
	_enemy = inst as Node3D
	_enemy_container.add_child(inst)

	var spawn = _get_node(enemy_spawn_path) as Node3D
	if spawn != null and _enemy != null:
		_enemy.global_transform = spawn.global_transform

	if inst.has_method("set_run_controller"):
		inst.call("set_run_controller", self)
	if inst.has_method("reset_enemy"):
		inst.call("reset_enemy")

func _clear_enemy() -> void:
	if _enemy != null and is_instance_valid(_enemy):
		_enemy.queue_free()
	_enemy = null

func _handle_loot_drop() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for entry in LOOT_TABLE:
		var id = str(entry.get("id", ""))
		var chance = int(entry.get("chance", 0))
		var qty = int(entry.get("qty", 0))
		if id == "" or qty <= 0 or chance <= 0:
			continue
		var roll = rng.randi_range(0, 99)
		if roll < chance:
			var current_qty: int = int(loot.get(id, 0))
			loot[id] = current_qty + qty
			_notify("💎 Loot: %s +%d" % [id, qty])

func _transfer_loot() -> void:
	if loot.is_empty():
		_notify("ℹ️ Nincs loot a futamban")
		return

	var eb = _eb()
	var stock = _get_root_node("StockSystem1")
	for k in loot.keys():
		var qty: int = int(loot.get(k, 0))
		if qty <= 0:
			continue
		if eb != null and eb.has_method("bus"):
			eb.call("bus", "stock.buy", {
				"item": str(k),
				"qty": qty,
				"unit_price": 0
			})
		elif stock != null and stock.has_method("add_unbooked"):
			stock.call("add_unbooked", str(k), qty, 0)
	_notify("⛏️ Bánya loot átadva: %s" % ", ".join(loot.keys()))

func _apply_heal_cost() -> void:
	var missing = max(PLAYER_MAX_HP - player_hp, 0)
	if missing <= 0:
		return

	var cost = missing * 200
	var econ = _get_root_node("EconomySystem1")
	if econ != null and econ.has_method("add_money"):
		econ.call("add_money", -cost, "Bánya gyógyköltség")
	else:
		var eb = _eb()
		if eb != null and eb.has_method("bus"):
			eb.call("bus", "state.add", {
				"key": "money",
				"delta": -cost,
				"reason": "Bánya gyógyköltség"
			})
	_notify("🩹 Gyógyköltség: -%d Ft" % cost)

func _toggle_worlds(mine_active: bool) -> void:
	_set_world_state(_mine_world, mine_active)
	_set_world_state(_town_world, not mine_active)
	if mine_active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _set_world_state(world: Node3D, active: bool) -> void:
	if world == null:
		return
	world.visible = active
	world.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	world.set_process(active)
	world.set_physics_process(active)
	world.set_process_input(active)
	world.set_process_unhandled_input(active)

func _get_root_node(name: String) -> Node:
	return get_tree().root.get_node_or_null(str(name))

func _get_node(path: NodePath) -> Node:
	if path == NodePath("") or str(path) == "":
		return null
	return get_node_or_null(path)

func _notify(text: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(text))

func _run_with_fade(mid_action: Callable) -> void:
	if not mid_action.is_valid():
		return
	var fade = _find_fade()
	if fade != null and fade.has_method("fade_out_in"):
		fade.call("fade_out_in", mid_action)
		return
	mid_action.call()

func _force_unblock_player() -> void:
	var tree = get_tree()
	if tree != null:
		tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var eb = _eb()
	if eb != null and eb.has_signal("request_close_all_popups"):
		eb.emit_signal("request_close_all_popups")

	var player = _get_node(player_path)
	if player != null:
		if player.has_method("set_input_blocked"):
			player.call("set_input_blocked", false)
		if player.has_method("set_player_blocked"):
			player.call("set_player_blocked", false)
		if player.has_method("set_controls_enabled"):
			player.call("set_controls_enabled", true)
	print("[MINE_FIX] paused=%s eger_mod=%s jatekos=%s zarak=%s" % [
		str(tree != null and tree.paused),
		str(Input.get_mouse_mode()),
		str(player),
		_collect_lock_state(player)
	])

func _post_spawn_player_fix() -> void:
	var player = _find_player()
	if player == null:
		print("[MINE_FIX] játékos nem található")
		return

	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	player.set_process_unhandled_input(true)

	var cam: Camera3D = null
	var direct_cam = player.get_node_or_null("PlayerCamera")
	if direct_cam is Camera3D:
		cam = direct_cam as Camera3D
	if cam == null:
		var found_cams = player.find_children("*", "Camera3D", true, false)
		if not found_cams.is_empty():
			var first_cam = found_cams[0]
			if first_cam is Camera3D:
				cam = first_cam as Camera3D
	if cam != null:
		cam.current = true

	var viewport_cam: Camera3D = null
	var vp = get_viewport()
	if vp != null:
		viewport_cam = vp.get_camera_3d()
	print("[MINE_CAM] current=%s found=%s path=%s" % [
		str(viewport_cam),
		str(cam),
		cam.get_path() if cam != null else "null"
	])

	var tree = get_tree()
	if tree != null:
		tree.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if player.has_method("set_input_blocked"):
		player.call("set_input_blocked", false)
	if player.has_method("set_controls_enabled"):
		player.call("set_controls_enabled", true)
	if player.has_method("set_player_blocked"):
		player.call("set_player_blocked", false)

	var paused_state = tree != null and tree.paused
	print("[MINE_FIX] paused=%s mouse_mode=%s player_physics=%s player_input=%s" % [
		str(paused_state),
		str(Input.get_mouse_mode()),
		str(player.is_physics_processing()),
		str(player.is_processing_input())
	])

func _find_player() -> CharacterBody3D:
	if player_path != NodePath("") and str(player_path) != "":
		var by_path = _get_node(player_path)
		if by_path is CharacterBody3D:
			return by_path as CharacterBody3D
		if by_path != null:
			return by_path as CharacterBody3D

	var tree = get_tree()
	if tree != null:
		var scene = tree.current_scene
		if scene != null:
			var by_name = scene.find_child("Player", true, false)
			if by_name is CharacterBody3D:
				return by_name as CharacterBody3D

	var mine_root = _mine_world
	if mine_root == null:
		mine_root = _get_node(mine_world_path) as Node3D
	if mine_root != null:
		var found = mine_root.find_children("*", "CharacterBody3D", true, false)
		for node in found:
			if node is CharacterBody3D:
				return node as CharacterBody3D

	return null

func _collect_lock_state(player: Node) -> String:
	var flags: Array = []
	if player != null:
		var pause_reasons = player.get("_pause_reasons")
		if pause_reasons is Dictionary and pause_reasons.size() > 0:
			flags.append("jatekos_szunet=%s" % str((pause_reasons as Dictionary).keys()))
		var lock_reasons = player.get("_lock_reasons")
		if lock_reasons is Dictionary and lock_reasons.size() > 0:
			flags.append("jatekos_zar=%s" % str((lock_reasons as Dictionary).keys()))

	var router = _get_root_node("InputRouter1")
	if router != null:
		var router_locks = router.get("_lock_reasons")
		if router_locks is Dictionary and router_locks.size() > 0:
			flags.append("input_router=%s" % str((router_locks as Dictionary).keys()))

	if flags.is_empty():
		return "nincs_zar"
	return ", ".join(flags)

func _find_fade() -> Node:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.find_child("ScreenFade", true, false)

func _start_input_diag() -> void:
	_input_diag_count = 0
	if _input_diag_running:
		return
	_input_diag_running = true
	_schedule_input_diag()

func _schedule_input_diag() -> void:
	if not _input_diag_running:
		return
	if _input_diag_count >= 10:
		_input_diag_running = false
		return
	var tree = get_tree()
	if tree == null:
		_input_diag_running = false
		return
	var timer = tree.create_timer(1.0)
	if timer == null:
		_input_diag_running = false
		return
	timer.timeout.connect(Callable(self, "_on_input_diag_timeout"))

func _on_input_diag_timeout() -> void:
	if not _active:
		_input_diag_running = false
		return
	_print_input_diag()
	_input_diag_count += 1
	_schedule_input_diag()

func _print_input_diag() -> void:
	print("[MINE_INPUT] move_forward=%s move_backward=%s move_left=%s move_right=%s" % [
		str(Input.is_action_pressed("move_forward")),
		str(Input.is_action_pressed("move_backward")),
		str(Input.is_action_pressed("move_left")),
		str(Input.is_action_pressed("move_right"))
	])

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")
