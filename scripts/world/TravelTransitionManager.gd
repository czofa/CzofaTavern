extends Node
class_name TravelTransitionManager

@export var screen_fade_path: NodePath = ^"../../UIRoot/ScreenFade"
@export var game_mode_controller_path: NodePath = ^"../GameModeController"
@export var tavern_camera_rig_path: NodePath = ^"../WorldRoot/TavernWorld/TavernCameraRig"
@export var player_path: NodePath = ^"../WorldRoot/TownWorld/Player"

const IDO_MINIMUM: float = 0.2
const IDO_MAXIMUM: float = 0.4
const ALAP_IDO: float = 0.3
const OK_ALLAS: String = "travel_transition"

func travel_to(scene_path: String, spawn_marker: String, time_cost_minutes: int = 60) -> void:
	var cel_vilag = _resolve_world(scene_path)
	if cel_vilag == null:
		return
	var spawn = _resolve_spawn(cel_vilag, spawn_marker)
	var fade = _get_fade()
	_lock_input(true)
	if fade != null and fade.has_method("fade_out_in"):
		await fade.call("fade_out_in", Callable(self, "_apply_travel").bind(cel_vilag, spawn, time_cost_minutes), _fade_ido())
	else:
		_apply_travel(cel_vilag, spawn, time_cost_minutes)
	_lock_input(false)

func _apply_travel(cel_vilag: Node, spawn: Node3D, time_cost_minutes: int) -> void:
	_ido_frissit(time_cost_minutes)
	_helyez_at(cel_vilag, spawn)
	_allit_mod(cel_vilag)

func _resolve_world(scene_path: String) -> Node3D:
	var path_szoveg = str(scene_path).strip_edges()
	if path_szoveg == "":
		_toast("❌ Hiányzik a cél világ útvonala.")
		return null
	var cel: Node = null
	var np = NodePath(path_szoveg)
	if has_node(np):
		cel = get_node(np)
	else:
		cel = get_node_or_null(np)
	if cel == null:
		var root = get_tree().root
		if root != null:
			cel = root.get_node_or_null(np)
	if cel == null and get_tree() != null and get_tree().root != null:
		var root2 = get_tree().root
		cel = root2.find_child(path_szoveg, true, false)
	var cel3d = cel as Node3D
	if cel3d == null:
		_toast("❌ Nem található a cél világ: %s" % path_szoveg)
	return cel3d

func _resolve_spawn(cel_vilag: Node, spawn_marker: String) -> Node3D:
	if cel_vilag == null:
		return null
	var nev = str(spawn_marker).strip_edges()
	if nev == "":
		return null
	var np = NodePath(nev)
	if cel_vilag.has_node(np):
		var n = cel_vilag.get_node(np)
		if n is Node3D:
			return n as Node3D
	var talalt = cel_vilag.find_child(nev, true, false)
	if talalt is Node3D:
		return talalt as Node3D
	_toast("⚠️ Nem található a spawn jelölő: %s" % nev)
	return null

func _get_fade() -> Node:
	if screen_fade_path != NodePath("") and has_node(screen_fade_path):
		return get_node(screen_fade_path)
	if screen_fade_path != NodePath("") and get_tree() != null and get_tree().root != null:
		var root = get_tree().root
		if root.has_node(screen_fade_path):
			return root.get_node(screen_fade_path)
	if get_tree() != null and get_tree().root != null:
		return get_tree().root.find_child("ScreenFade", true, false)
	return null

func _ido_frissit(time_cost_minutes: int) -> void:
	if typeof(TimeSystem1) == TYPE_NIL or TimeSystem1 == null:
		return
	if TimeSystem1.has_method("add_minutes"):
		TimeSystem1.call("add_minutes", float(time_cost_minutes))

func _helyez_at(cel_vilag: Node, spawn: Node3D) -> void:
	if cel_vilag == null:
		return
	if str(cel_vilag.name).to_lower().find("town") >= 0:
		_teleportal_player(spawn)
	else:
		_teleportal_rts_kamera(spawn)

func _teleportal_player(spawn: Node3D) -> void:
	var player = _get_player()
	if player == null:
		_toast("⚠️ A játékos nem elérhető.")
		return
	if spawn != null:
		player.global_transform = spawn.global_transform
	if player.has_method("set"):
		player.set("velocity", Vector3.ZERO)

func _teleportal_rts_kamera(spawn: Node3D) -> void:
	var rig = _get_tavern_rig()
	if rig == null:
		_toast("⚠️ A kamera rig nem található.")
		return
	if spawn != null:
		rig.global_position = spawn.global_position

func _allit_mod(cel_vilag: Node) -> void:
	var mod = "RTS"
	if cel_vilag != null and str(cel_vilag.name).to_lower().find("town") >= 0:
		mod = "FPS"
	if mod == "RTS":
		var gm = _get_game_mode_controller()
		if gm != null and gm.has_method("set_rts_world"):
			gm.call("set_rts_world", "tavern")
	_bus("mode.set", {"mode": mod})

func _lock_input(locked: bool) -> void:
	if locked:
		_bus("input.lock", {"reason": OK_ALLAS})
	else:
		_bus("input.unlock", {"reason": OK_ALLAS})

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _get_game_mode_controller() -> Node:
	if game_mode_controller_path != NodePath("") and has_node(game_mode_controller_path):
		return get_node(game_mode_controller_path)
	if game_mode_controller_path != NodePath("") and get_tree() != null and get_tree().root != null:
		var root = get_tree().root
		if root.has_node(game_mode_controller_path):
			return root.get_node(game_mode_controller_path)
	return null

func _get_tavern_rig() -> Node3D:
	if tavern_camera_rig_path != NodePath("") and has_node(tavern_camera_rig_path):
		var n = get_node(tavern_camera_rig_path)
		if n is Node3D:
			return n as Node3D
	if tavern_camera_rig_path != NodePath("") and get_tree() != null and get_tree().root != null:
		var root = get_tree().root
		if root.has_node(tavern_camera_rig_path):
			var n2 = root.get_node(tavern_camera_rig_path)
			if n2 is Node3D:
				return n2 as Node3D
	return null

func _get_player() -> Node3D:
	if player_path != NodePath("") and has_node(player_path):
		var n = get_node(player_path)
		if n is Node3D:
			return n as Node3D
	if player_path != NodePath("") and get_tree() != null and get_tree().root != null:
		var root = get_tree().root
		if root.has_node(player_path):
			var n2 = root.get_node(player_path)
			if n2 is Node3D:
				return n2 as Node3D
	return get_tree().root.find_child("Player", true, false) as Node3D

func _fade_ido() -> float:
	return clamp(ALAP_IDO, IDO_MINIMUM, IDO_MAXIMUM)

func _toast(szoveg: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)
