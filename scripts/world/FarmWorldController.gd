extends Node3D
class_name FarmWorldController

@export var town_world_path: NodePath = ^"../TownWorld"
@export var tavern_world_path: NodePath = ^"../TavernWorld"
@export var mode_controller_path: NodePath = ^"../../CoreRoot/GameModeController"
@export var land_controller_path: NodePath = ^"./FarmLandController"
@export var build_controller_path: NodePath = ^"./BuildController"
@export var camera_rig_path: NodePath = ^"./FarmCameraRig"
@export var spawn_path: NodePath = ^"./Spawns/FarmSpawn"

const RTS_FARM_ID = "farm"
const RTS_TAVERN_ID = "tavern"

var _town_world: Node3D = null
var _tavern_world: Node3D = null
var _land: Node = null
var _build: Node = null
var _camera_rig: Node3D = null
var _mode_ctrl: Node = null
var _spawn: Node3D = null
var _aktiv: bool = false
var _elozo_rts: String = RTS_TAVERN_ID

func _ready() -> void:
	_cache_nodes()
	_frissit_build_allapot()

func enter_from_town() -> void:
	_cache_nodes()
	if _land == null or not _land.has_method("van_farm"):
		_toast("❌ A farm területkezelő hiányzik.")
		return
	if not _land.call("van_farm"):
		_toast("❌ A farm terület még nincs megvéve.")
		return
	_aktiv = true
	_elozo_rts = _aktualis_rts_id()
	_set_rts_vilag(RTS_FARM_ID)
	_allit_mod("RTS")
	_set_world_state(true)
	_felold_input_zar()
	_frissit_build_allapot()
	_reset_kamera()
	_aktival_rendszerek(true)
	_log_belpes("farm_belépés")
	_toast("🚜 Beléptél a farm területre.")

func return_to_town() -> void:
	_cache_nodes()
	_aktiv = false
	_aktival_rendszerek(false)
	_frissit_build_allapot()
	_set_rts_vilag(_elozo_rts)
	_allit_mod("FPS")
	_set_world_state(false)
	_toast("↩️ Visszatértél a faluba.")

func refresh_after_upgrade() -> void:
	_frissit_build_allapot()

func _cache_nodes() -> void:
	_town_world = get_node_or_null(town_world_path) as Node3D
	_tavern_world = get_node_or_null(tavern_world_path) as Node3D
	_land = get_node_or_null(land_controller_path)
	_build = get_node_or_null(build_controller_path)
	_camera_rig = get_node_or_null(camera_rig_path) as Node3D
	_mode_ctrl = get_node_or_null(mode_controller_path)
	_spawn = get_node_or_null(spawn_path) as Node3D

func _allat_rendszer(aktiv: bool) -> void:
	if AnimalSystem1 != null and AnimalSystem1.has_method("set_world_active"):
		AnimalSystem1.set_world_active(aktiv, self)

func _farm_rendszer(aktiv: bool) -> void:
	if FarmSystem1 != null and FarmSystem1.has_method("set_world_active"):
		FarmSystem1.set_world_active(aktiv, self)

func _aktival_rendszerek(aktiv: bool) -> void:
	_allat_rendszer(aktiv)
	_farm_rendszer(aktiv)

func _frissit_build_allapot() -> void:
	if _land != null and _land.has_method("van_farm") and _build != null and _build.has_method("set_build_enabled"):
		_build.call("set_build_enabled", _land.call("van_farm"))

func _reset_kamera() -> void:
	if _camera_rig == null or _spawn == null:
		return
	var cel = _spawn.global_position
	var kozpont = _camera_rig.get("hatar_kozeppont")
	if typeof(kozpont) == TYPE_VECTOR3:
		cel = kozpont
	_camera_rig.global_position = cel

func _allit_mod(mod: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "mode.set", {"mode": mod})

func _set_world_state(farm_aktiv: bool) -> void:
	_allit_vilag(_town_world, not farm_aktiv)
	_allit_vilag(self, farm_aktiv)
	if _tavern_world != null:
		_allit_vilag(_tavern_world, false)
	if _camera_rig != null and _camera_rig.has_method("set_active"):
		_camera_rig.call("set_active", farm_aktiv)

func _allit_vilag(vilag: Node3D, aktiv: bool) -> void:
	if vilag == null:
		return
	vilag.visible = aktiv
	vilag.process_mode = Node.PROCESS_MODE_INHERIT if aktiv else Node.PROCESS_MODE_DISABLED
	vilag.set_process(aktiv)
	vilag.set_physics_process(aktiv)
	vilag.set_process_input(aktiv)
	vilag.set_process_unhandled_input(aktiv)

func _set_rts_vilag(rts_id: String) -> void:
	if _mode_ctrl != null and _mode_ctrl.has_method("set_rts_world"):
		_mode_ctrl.call("set_rts_world", rts_id)

func _aktualis_rts_id() -> String:
	if _mode_ctrl != null and _mode_ctrl.has_method("get_rts_world"):
		return str(_mode_ctrl.call("get_rts_world"))
	return RTS_TAVERN_ID

func _toast(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)

func _felold_input_zar() -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "input.unlock", {"reason": "farm_enter"})

func _log_belpes(cimke: String) -> void:
	var rig_cam = _rig_kamera()
	if rig_cam != null and not rig_cam.current:
		rig_cam.current = true
	var viewport = get_viewport()
	var cam = null
	if viewport != null:
		cam = viewport.get_camera_3d()
	var cam_path = "nincs"
	if cam != null:
		cam_path = str(cam.get_path())
	var cam_poz = "nincs"
	var cam_rot = "nincs"
	if cam != null:
		cam_poz = str(cam.global_position)
		cam_rot = str(cam.global_rotation_degrees)
	var mouse = str(Input.mouse_mode)
	var lock_info = _input_lock_info()
	var szog_adat = _rig_szogek()
	var pitch_deg = szog_adat.get("pitch", null)
	var yaw_deg = szog_adat.get("yaw", null)
	var pitch_szoveg = str(pitch_deg)
	var yaw_szoveg = str(yaw_deg)
	if pitch_deg is float:
		pitch_szoveg = "%.2f" % pitch_deg
	if yaw_deg is float:
		yaw_szoveg = "%.2f" % yaw_deg
	print("[FARM_DIAG] %s világ=%s kamera=%s poz=%s rot=%s pitch=%s yaw=%s mouse=%s lock=%s" % [cimke, name, cam_path, cam_poz, cam_rot, pitch_szoveg, yaw_szoveg, mouse, lock_info])
	if pitch_deg is float and pitch_deg >= 0.0:
		print("[FARM_DIAG] figyelem: pitch_felfele=%s" % pitch_szoveg)

func _input_lock_info() -> String:
	if typeof(InputRouter1) == TYPE_NIL or InputRouter1 == null:
		return "nincs_router"
	var locked = false
	if InputRouter1.has_method("is_locked"):
		locked = bool(InputRouter1.call("is_locked"))
	var reasons: Array = []
	if InputRouter1.has_method("get_lock_reasons"):
		var adat_any = InputRouter1.call("get_lock_reasons")
		if adat_any is Array:
			reasons = adat_any
	if locked and not reasons.is_empty():
		return "zárva:%s" % ",".join(reasons)
	if locked:
		return "zárva"
	return "szabad"

func _rig_szogek() -> Dictionary:
	var adat: Dictionary = {"pitch": null, "yaw": null}
	if _camera_rig == null:
		return adat
	var yaw_node = _camera_rig.get_node_or_null("Yaw") as Node3D
	if yaw_node != null:
		adat["yaw"] = rad_to_deg(yaw_node.rotation.y)
		var pitch_node = yaw_node.get_node_or_null("Pitch") as Node3D
		if pitch_node != null:
			adat["pitch"] = rad_to_deg(pitch_node.rotation.x)
	return adat

func _rig_kamera() -> Camera3D:
	if _camera_rig != null and _camera_rig.has_method("get_camera"):
		var cam_any = _camera_rig.call("get_camera")
		if cam_any is Camera3D:
			return cam_any as Camera3D
	return null
