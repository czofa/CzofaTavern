extends Node3D
class_name FarmCameraController

@export var camera_path: NodePath = ^"RTSCamera"
@export var sebesseg: float = 10.0
@export var zoom_lepes: float = 1.5
@export var min_magassag: float = 6.0
@export var max_magassag: float = 18.0
@export var hatar_meret: Vector2 = Vector2(30, 30)
@export var build_controller_path: NodePath = ^"../BuildController"
@export var collision_mask: int = 1

var _kamera: Camera3D = null
var _build: Node = null
var _aktiv: bool = true

func _ready() -> void:
	_cache()
	_ensure_move_actions()
	set_physics_process(true)
	set_process_unhandled_input(true)

func _physics_process(delta: float) -> void:
	if not _aktiv:
		return
	_mozgas(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not _aktiv:
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

func set_active(aktiv: bool) -> void:
	_aktiv = aktiv

func _cache() -> void:
	_kamera = null
	if camera_path != NodePath("") and has_node(camera_path):
		var n = get_node(camera_path)
		if n is Camera3D:
			_kamera = n as Camera3D
	_build = get_node_or_null(build_controller_path)

func _mozgas(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_backward"):
		dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0

	if dir == Vector2.ZERO:
		return

	var v = Vector3(dir.x, 0.0, dir.y).normalized() * sebesseg * delta
	global_position += v
	_alkalmaz_hatar()

func _alkalmaz_hatar() -> void:
	var fel = hatar_meret * 0.5
	var p = global_position
	p.x = clamp(p.x, -fel.x, fel.x)
	p.z = clamp(p.z, -fel.y, fel.y)
	global_position = p

func _zoom(irany: float) -> void:
	if _kamera == null:
		return
	var pos = _kamera.global_position
	pos.y = clamp(pos.y + (irany * zoom_lepes), min_magassag, max_magassag)
	_kamera.global_position = pos

func _indit_interakcio() -> void:
	var cel = _keres_cel()
	if cel == null:
		return
	if cel.has_method("interact"):
		cel.call("interact")

func _keres_cel() -> Node:
	if _kamera == null:
		return null
	var viewport = get_viewport()
	if viewport == null:
		return null
	var mouse = viewport.get_mouse_position()
	var origin = _kamera.project_ray_origin(mouse)
	var normal = _kamera.project_ray_normal(mouse)
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
	var mappingok: Array = [
		{"nev": "move_forward", "key": KEY_W, "arrow": KEY_UP},
		{"nev": "move_backward", "key": KEY_S, "arrow": KEY_DOWN},
		{"nev": "move_left", "key": KEY_A, "arrow": KEY_LEFT},
		{"nev": "move_right", "key": KEY_D, "arrow": KEY_RIGHT}
	]
	for adat in mappingok:
		var nev = str(adat.get("nev", "")).strip_edges()
		if nev == "":
			continue
		var key = int(adat.get("key", 0))
		var arrow = int(adat.get("arrow", 0))
		_biztosit_action(nev, key)
		_biztosit_action(nev, arrow, false)

func _biztosit_action(action: String, keycode: int, physical: bool = true) -> void:
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
	var uj := InputEventKey.new()
	uj.keycode = keycode
	uj.physical_keycode = keycode if physical else 0
	InputMap.action_add_event(action, uj)
