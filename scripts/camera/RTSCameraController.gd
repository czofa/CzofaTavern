extends Node3D
class_name RTSCameraController

@export var yaw_path: NodePath = ^"Yaw"
@export var pitch_path: NodePath = ^"Yaw/Pitch"
@export var camera_path: NodePath = ^"Yaw/Pitch/RTSCamera"
@export var hatar_kozeppont: Vector3 = Vector3.ZERO
@export var hatar_felmeret: Vector2 = Vector2(25, 25)
@export var sebesseg: float = 12.0
@export var gyors_szorzo: float = 2.0
@export var zoom_lepes: float = 2.0
@export var min_tavolsag: float = 10.0
@export var max_tavolsag: float = 40.0
@export var kezdo_offset: Vector3 = Vector3(0, 18, 18)
@export var kezdo_pitch_fok: float = -55.0
@export var kezdo_yaw_fok: float = 45.0
@export var min_pitch_fok: float = -80.0
@export var max_pitch_fok: float = -25.0
@export var forgas_erzekenyseg: float = 0.2
@export var build_controller_path: NodePath = ^"../BuildController"
@export var collision_mask: int = 1

var _cam: Camera3D = null
var _build: Node = null
var _aktiv: bool = true
var _forgas_aktiv: bool = false
var _yaw: Node3D = null
var _pitch: Node3D = null

func _ready() -> void:
	_cache()
	_ensure_move_actions()
	_beallit_alaphelyzet()
	set_physics_process(true)
	set_process_unhandled_input(true)

func _physics_process(delta: float) -> void:
	if not _aktiv:
		return
	if _cam == null:
		_cache()
		if _cam == null:
			return
	_mozgas(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not _aktiv:
		return
	if _cam == null:
		return
	if event is InputEventMouseButton and event.pressed:
		var e = event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT:
			if _build_mod_aktiv():
				return
			_indit_interakcio()
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-1.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			_forgas_aktiv = true
	if event is InputEventMouseButton and not event.pressed:
		var e2 = event as InputEventMouseButton
		if e2.button_index == MOUSE_BUTTON_RIGHT:
			_forgas_aktiv = false
	if event.is_action_pressed("rts_rotate"):
		_forgas_aktiv = true
	if event.is_action_released("rts_rotate"):
		_forgas_aktiv = false
	if event is InputEventMouseMotion and _forgas_aktiv:
		var mozg = event as InputEventMouseMotion
		_forgat(mozg.relative)

func set_active(aktiv: bool) -> void:
	_aktiv = aktiv
	_allit_kamera_current(aktiv)
	if not aktiv:
		_forgas_aktiv = false

func _cache() -> void:
	_cam = null
	_yaw = null
	_pitch = null
	if yaw_path != NodePath("") and has_node(yaw_path):
		var yn = get_node(yaw_path)
		if yn is Node3D:
			_yaw = yn as Node3D
	if _yaw == null and has_node("Yaw"):
		var alap_yaw = get_node("Yaw")
		if alap_yaw is Node3D:
			_yaw = alap_yaw as Node3D
	if pitch_path != NodePath("") and has_node(pitch_path):
		var pn = get_node(pitch_path)
		if pn is Node3D:
			_pitch = pn as Node3D
	if _pitch == null and _yaw != null and _yaw.has_node("Pitch"):
		var alap_pitch = _yaw.get_node("Pitch")
		if alap_pitch is Node3D:
			_pitch = alap_pitch as Node3D
	if camera_path != NodePath("") and has_node(camera_path):
		var n = get_node(camera_path)
		if n is Camera3D:
			_cam = n as Camera3D
	_allit_kamera_current(_aktiv)
	_build = get_node_or_null(build_controller_path)

func _mozgas(delta: float) -> void:
	var dir = _billentyu_irany()
	var elmozdulas = _szamit_elmozdulas(dir, _aktualis_sebesseg(), delta)
	if elmozdulas == Vector3.ZERO:
		return
	global_position += elmozdulas
	_alkalmaz_hatar()

func _alkalmaz_hatar() -> void:
	var p = global_position
	p.x = clamp(p.x, hatar_kozeppont.x - hatar_felmeret.x, hatar_kozeppont.x + hatar_felmeret.x)
	p.z = clamp(p.z, hatar_kozeppont.z - hatar_felmeret.y, hatar_kozeppont.z + hatar_felmeret.y)
	p.y = hatar_kozeppont.y
	global_position = p

func _billentyu_irany() -> Vector2:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("rts_pan_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("rts_pan_down"):
		dir.y += 1.0
	if Input.is_action_pressed("rts_pan_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("rts_pan_right"):
		dir.x += 1.0
	return dir

func _szamit_elmozdulas(irany: Vector2, seb: float, delta: float) -> Vector3:
	if irany == Vector2.ZERO:
		return Vector3.ZERO
	var v = Vector3(irany.x, 0.0, irany.y)
	if _yaw != null:
		v = _yaw.global_transform.basis * v
	else:
		v = global_transform.basis * v
	v.y = 0.0
	if v.length() > 0.0:
		v = v.normalized()
	return v * seb * delta

func _zoom(irany: float) -> void:
	if _cam == null:
		return
	var pos = _cam.position
	var tav = pos.length()
	if tav <= 0.0:
		tav = min_tavolsag
	tav += irany * zoom_lepes
	tav = clamp(tav, min_tavolsag, max_tavolsag)
	var iranyvektor = pos.normalized()
	if iranyvektor == Vector3.ZERO:
		iranyvektor = Vector3(0.0, 1.0, 1.0).normalized()
	_cam.position = iranyvektor * tav

func _forgat(relativ: Vector2) -> void:
	if _yaw == null or _pitch == null:
		return
	var yaw_valtozas = -relativ.x * forgas_erzekenyseg * 0.01
	var pitch_valtozas = -relativ.y * forgas_erzekenyseg * 0.01
	_yaw.rotate_y(yaw_valtozas)
	var cel_pitch = _pitch.rotation.x + pitch_valtozas
	var min_rad = deg_to_rad(min_pitch_fok)
	var max_rad = deg_to_rad(max_pitch_fok)
	cel_pitch = clamp(cel_pitch, min_rad, max_rad)
	_pitch.rotation.x = cel_pitch

func _allit_kamera_current(aktiv: bool) -> void:
	if _cam == null:
		return
	_cam.current = aktiv

func _indit_interakcio() -> void:
	var cel = _keres_cel()
	if cel == null:
		return
	if cel.has_method("interact"):
		cel.call("interact")

func _keres_cel() -> Node:
	if _cam == null:
		return null
	var viewport = get_viewport()
	if viewport == null:
		return null
	var mouse = viewport.get_mouse_position()
	var origin = _cam.project_ray_origin(mouse)
	var normal = _cam.project_ray_normal(mouse)
	var query = PhysicsRayQueryParameters3D.create(origin, origin + normal * 200.0)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var world = get_world_3d()
	if world == null or world.direct_space_state == null:
		return null
	var hit = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider = hit.get("collider", null)
	var node = collider as Node
	if node == null:
		return null
	return _felold_interakcio(node)

func _felold_interakcio(kiindulo: Node) -> Node:
	var cur: Node = kiindulo
	var lepes: int = 0
	while cur != null and lepes < 8:
		if cur.has_method("interact"):
			return cur
		if cur.is_in_group("interactable"):
			if cur.get_parent() != null and cur.get_parent().has_method("interact"):
				return cur.get_parent()
			return cur
		cur = cur.get_parent()
		lepes += 1
	return null

func _build_mod_aktiv() -> bool:
	if _build != null and _build.has_method("is_build_mode_active"):
		return bool(_build.call("is_build_mode_active"))
	return false

func _ensure_move_actions() -> void:
	_biztosit_key_action("rts_pan_up", KEY_W, true)
	_biztosit_key_action("rts_pan_up", KEY_UP, false)
	_biztosit_key_action("rts_pan_down", KEY_S, true)
	_biztosit_key_action("rts_pan_down", KEY_DOWN, false)
	_biztosit_key_action("rts_pan_left", KEY_A, true)
	_biztosit_key_action("rts_pan_left", KEY_LEFT, false)
	_biztosit_key_action("rts_pan_right", KEY_D, true)
	_biztosit_key_action("rts_pan_right", KEY_RIGHT, false)
	_biztosit_mouse_action("rts_rotate", MOUSE_BUTTON_RIGHT)
	_biztosit_key_action("rts_fast", KEY_SHIFT, true)

func _biztosit_key_action(action: String, keycode: int, physical: bool) -> void:
	if action == "" or keycode <= 0:
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k = ev as InputEventKey
			if physical and k.physical_keycode == keycode:
				return
			if not physical and k.keycode == keycode:
				return
	var uj = InputEventKey.new()
	uj.keycode = keycode
	uj.physical_keycode = keycode if physical else 0
	InputMap.action_add_event(action, uj)

func _biztosit_mouse_action(action: String, button_index: int) -> void:
	if action == "" or button_index <= 0:
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton:
			var b = ev as InputEventMouseButton
			if b.button_index == button_index:
				return
	var uj = InputEventMouseButton.new()
	uj.button_index = button_index
	InputMap.action_add_event(action, uj)

func get_camera() -> Camera3D:
	return _cam

func _aktualis_sebesseg() -> float:
	var seb = sebesseg
	if Input.is_action_pressed("rts_fast"):
		seb = seb * gyors_szorzo
	return seb

func _beallit_alaphelyzet() -> void:
	if _yaw == null or _pitch == null or _cam == null:
		return
	global_position = Vector3(hatar_kozeppont.x, hatar_kozeppont.y, hatar_kozeppont.z)
	var cel_pitch = clamp(kezdo_pitch_fok, min_pitch_fok, max_pitch_fok)
	_pitch.rotation.x = deg_to_rad(cel_pitch)
	_yaw.rotation.y = deg_to_rad(kezdo_yaw_fok)
	_cam.position = kezdo_offset
	_allit_kamera_current(_aktiv)
