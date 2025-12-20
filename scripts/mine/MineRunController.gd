extends Node
class_name MineRunController

@export var player_path: NodePath = ^"/root/Main/WorldRoot/MineWorld/Player"
@export var combat_controller_path: NodePath = ^"/root/Main/WorldRoot/MineWorld/Player/MineCombat"
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
const ACT_MOVE_FWD := "move_forward"
const ACT_MOVE_BACK := "move_backward"
const ACT_MOVE_LEFT := "move_left"
const ACT_MOVE_RIGHT := "move_right"
const MINE_PLAYER_PATH := NodePath("/root/Main/WorldRoot/MineWorld/Player")
const MINE_CAMERA_PATH := NodePath("/root/Main/WorldRoot/MineWorld/Player/PlayerCamera")
const INPUT_DIAG_COOLDOWN_MS := 2000
const INPUT_ACTIONS := [ACT_MOVE_FWD, ACT_MOVE_BACK, ACT_MOVE_LEFT, ACT_MOVE_RIGHT]
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
var _player_camera: Camera3D = null
var _input_diag_count: int = 0
var _input_diag_running: bool = false
var _last_missing_input_diag_ms: int = -10000
var _last_input_diag_ms: int = -10000

func _ready() -> void:
	_ensure_move_actions()
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

	_set_game_mode("FPS")
	_respawn_player()
	_spawn_enemy()
	_toggle_worlds(true)
	_apply_mine_entry_state()
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
	_player = _resolve_player()
	_player_camera = _resolve_player_camera(_player)
	_combat = _get_node(combat_controller_path)
	_mine_world = _get_node(mine_world_path) as Node3D
	_town_world = _get_node(town_world_path) as Node3D
	_exit_area = _get_node(exit_area_path) as Area3D
	_next_area = _get_node(next_floor_area_path) as Area3D
	_enemy_container = _get_node(enemy_container_path)

	if _combat != null and _combat.has_method("set_run_controller"):
		_combat.call("set_run_controller", self)
	_log_player_paths()

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
	var pstr = str(path)
	if pstr.begins_with("/root"):
		var root = get_tree().root if get_tree() != null else null
		if root != null:
			return root.get_node_or_null(path)
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

	_unlock_player_controls("force_unblock")

func _post_spawn_player_fix() -> void:
	_unlock_player_controls("post_spawn")
	_log_viewport_camera()

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
	var now_ms = Time.get_ticks_msec()
	for act in INPUT_ACTIONS:
		if not InputMap.has_action(act):
			if now_ms - _last_missing_input_diag_ms >= INPUT_DIAG_COOLDOWN_MS:
				print("[MINE_INPUT] hiányzó action: %s (diag szüneteltetve)" % act)
				_last_missing_input_diag_ms = now_ms
			return
	if now_ms - _last_input_diag_ms < INPUT_DIAG_COOLDOWN_MS:
		return
	_last_input_diag_ms = now_ms

	print("[MINE_INPUT] fwd=%s back=%s left=%s right=%s vec=%s" % [
		str(Input.is_action_pressed(ACT_MOVE_FWD)),
		str(Input.is_action_pressed(ACT_MOVE_BACK)),
		str(Input.is_action_pressed(ACT_MOVE_LEFT)),
		str(Input.is_action_pressed(ACT_MOVE_RIGHT)),
		str(_read_input_vector())
	])

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")

func _resolve_player() -> CharacterBody3D:
	var candidates: Array = [MINE_PLAYER_PATH, player_path]
	for path in candidates:
		if path == NodePath("") or str(path) == "":
			continue
		var n = _get_node(path)
		if n is CharacterBody3D:
			return n as CharacterBody3D
	return null

func _resolve_player_camera(player: Node) -> Camera3D:
	if player != null and player.has_node("PlayerCamera"):
		var cam = player.get_node_or_null("PlayerCamera")
		if cam is Camera3D:
			return cam as Camera3D
	if MINE_CAMERA_PATH != NodePath("") and str(MINE_CAMERA_PATH) != "":
		var cam2 = _get_node(MINE_CAMERA_PATH)
		if cam2 is Camera3D:
			return cam2 as Camera3D
	if player != null:
		var found_cams = player.find_children("*", "Camera3D", true, false)
		for c in found_cams:
			if c is Camera3D:
				return c as Camera3D
	return null

func _log_player_paths() -> void:
	var player_ok = _player != null and is_instance_valid(_player)
	var cam_ok = _player_camera != null and is_instance_valid(_player_camera)
	var player_path_str = str(MINE_PLAYER_PATH)
	if player_ok:
		player_path_str = str(_player.get_path())
	var cam_path_str = str(MINE_CAMERA_PATH)
	if cam_ok:
		cam_path_str = str(_player_camera.get_path())
	print("[MINE_PLAYER] player_path=%s cam_path=%s found_player=%s found_cam=%s" % [
		player_path_str,
		cam_path_str,
		str(player_ok),
		str(cam_ok)
	])

func _ensure_move_actions() -> void:
	var mappings: Array = [
		{"nev": ACT_MOVE_FWD, "physical": KEY_W, "arrow": KEY_UP},
		{"nev": ACT_MOVE_BACK, "physical": KEY_S, "arrow": KEY_DOWN},
		{"nev": ACT_MOVE_LEFT, "physical": KEY_A, "arrow": KEY_LEFT},
		{"nev": ACT_MOVE_RIGHT, "physical": KEY_D, "arrow": KEY_RIGHT}
	]
	for mapping in mappings:
		var action = str(mapping.get("nev", "")).strip_edges()
		if action == "":
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		_add_key_event_if_missing(action, int(mapping.get("physical", 0)), true)
		_add_key_event_if_missing(action, int(mapping.get("arrow", 0)), false)

func _add_key_event_if_missing(action_name: String, keycode: int, use_physical: bool) -> void:
	if keycode <= 0:
		return
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey:
			var k = existing as InputEventKey
			if use_physical and k.physical_keycode == keycode:
				return
			if not use_physical and k.keycode == keycode:
				return
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode if use_physical else 0
	InputMap.action_add_event(action_name, ev)

func _read_input_vector() -> Vector2:
	var x = 0.0
	var y = 0.0
	if InputMap.has_action(ACT_MOVE_LEFT) and Input.is_action_pressed(ACT_MOVE_LEFT):
		x -= 1.0
	if InputMap.has_action(ACT_MOVE_RIGHT) and Input.is_action_pressed(ACT_MOVE_RIGHT):
		x += 1.0
	if InputMap.has_action(ACT_MOVE_FWD) and Input.is_action_pressed(ACT_MOVE_FWD):
		y += 1.0
	if InputMap.has_action(ACT_MOVE_BACK) and Input.is_action_pressed(ACT_MOVE_BACK):
		y -= 1.0
	return Vector2(x, y)

func _unlock_player_controls(reason: String) -> void:
	_player = _resolve_player()
	_player_camera = _resolve_player_camera(_player)

	var tree = get_tree()
	if tree != null:
		tree.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if _player != null:
		_player.process_mode = Node.PROCESS_MODE_INHERIT
		_player.set_process(true)
		_player.set_physics_process(true)
		_player.set_process_input(true)
		_player.set_process_unhandled_input(true)
		if _player.has_method("set_input_blocked"):
			_player.call("set_input_blocked", false)
		if _player.has_method("set_controls_enabled"):
			_player.call("set_controls_enabled", true)
		if _player.has_method("set_player_blocked"):
			_player.call("set_player_blocked", false)

	if _player_camera != null:
		_player_camera.current = true

	print("[MINE_UNLOCK] paused=%s mouse_mode=%s phys=%s input=%s process_mode=%s reason=%s" % [
		str(tree != null and tree.paused),
		str(Input.get_mouse_mode()),
		str(_player != null and _player.is_physics_processing()),
		str(_player != null and _player.is_processing_input()),
		str(_player.process_mode) if _player != null else "nincs",
		reason
	])

func _log_viewport_camera() -> void:
	var vp = get_viewport()
	var viewport_cam: Camera3D = null
	if vp != null:
		viewport_cam = vp.get_camera_3d()
	print("[MINE_CAM] current=%s found=%s path=%s" % [
		str(viewport_cam),
		str(_player_camera),
		_player_camera.get_path() if _player_camera != null else "null"
	])

func _apply_mine_entry_state() -> void:
	var tree = get_tree()
	if tree != null:
		tree.paused = false
	_unlock_player_controls("entry_state")
	print("[MINE] mode=FPS paused=%s mouse=%s controller=%s" % [
		str(tree != null and tree.paused),
		str(Input.get_mouse_mode()),
		get_script().resource_path.get_file()
	])

func _set_game_mode(mode: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("request_set_game_mode"):
		eb.emit_signal("request_set_game_mode", str(mode))
