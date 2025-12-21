extends Node3D
class_name FPSCameraController

@export var player_body_path: NodePath = ^".."
@export var camera_path: NodePath = ^"."
@export var erzekenyseg: float = 0.0025
@export var max_pitch_fok: float = 80.0

var _jatekostest: Node3D = null
var _kamera: Camera3D = null
var _yaw: float = 0.0
var _pitch: float = 0.0
var _aktiv: bool = true

func _ready() -> void:
	_cache_nodes()
	_szinkron_alaphelyzet()
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not _aktiv:
		return
	if event is InputEventMouseMotion:
		_kezel_mouse_mozgas(event as InputEventMouseMotion)

func set_active(aktiv: bool) -> void:
	_aktiv = aktiv
	if aktiv:
		_szinkron_alaphelyzet()
	set_process_unhandled_input(aktiv)
	if not aktiv:
		_reset_forgas_allapot()

func _kezel_mouse_mozgas(mozgas: InputEventMouseMotion) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if _input_blokkolt():
		return
	_yaw -= mozgas.relative.x * erzekenyseg
	_pitch -= mozgas.relative.y * erzekenyseg

	var max_pitch = deg_to_rad(max_pitch_fok)
	_pitch = clamp(_pitch, -max_pitch, max_pitch)

	if _jatekostest != null:
		_jatekostest.rotation.y = _yaw
	if _kamera != null:
		var cam_rot = _kamera.rotation
		cam_rot.x = _pitch
		_kamera.rotation = cam_rot

func _input_blokkolt() -> bool:
	if _jatekostest != null and _jatekostest.has_method("_is_blocked") and bool(_jatekostest.call("_is_blocked")):
		return true
	return false

func _cache_nodes() -> void:
	_jatekostest = get_node_or_null(player_body_path) as Node3D
	_kamera = null
	if self is Camera3D:
		_kamera = self as Camera3D
	if _kamera == null and camera_path != NodePath("") and has_node(camera_path):
		var n = get_node(camera_path)
		if n is Camera3D:
			_kamera = n as Camera3D

func _szinkron_alaphelyzet() -> void:
	if _jatekostest != null:
		_yaw = _jatekostest.rotation.y
	if _kamera != null:
		_pitch = _kamera.rotation.x

func _reset_forgas_allapot() -> void:
	_forgas_visszaallit()

func _forgas_visszaallit() -> void:
	if _jatekostest != null:
		_jatekostest.rotation.y = _yaw
	if _kamera != null:
		var cam_rot = _kamera.rotation
		cam_rot.x = _pitch
		_kamera.rotation = cam_rot
