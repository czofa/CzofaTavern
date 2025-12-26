extends Node3D

const BuildCatalog = preload("res://scripts/world/BuildCatalog.gd")

@export var kamera_path: NodePath = ^"../TavernCameraRig/RTSCamera"
@export var nav_regio_path: NodePath = ^"../TavernNav"
@export var lerakott_gyoker_path: NodePath = ^"../PlacedObjects"
@export var build_hint_path: NodePath = ^"../../../UIRoot/UiRoot/BuildHint"
@export var racs_meret_alap: float = 1.0
@export var epitkezes_engedelyezett: bool = true

static var _binding_logged: bool = false

var _catalog: BuildCatalog
var _buildable_kulcsok: Array = []
var _aktualis_index: int = 0
var _build_mod: bool = false
var _ghost: Node3D
var _ghost_ervenyes: bool = false
var _ghost_forgas: float = 0.0
var _kamera: Camera3D
var _nav_regio: NavigationRegion3D
var _nav_map: RID
var _lerakott_gyoker: Node3D
var _build_hint: Label
var _uzenet_kesleltetes_ms: int = 0
var _kulso_engedely: bool = true

func _ready() -> void:
	_catalog = BuildCatalog.new()
	_buildable_kulcsok = _catalog.list_keys()
	_biztosit_build_hotkey()
	_cache_nodes()
	_ellenoriz_kihagyott()
	set_process(true)
	set_process_unhandled_input(true)

func _cache_nodes() -> void:
	_kamera = get_node_or_null(kamera_path) as Camera3D
	_nav_regio = get_node_or_null(nav_regio_path) as NavigationRegion3D
	if _nav_regio != null:
		_nav_map = _nav_regio.get_navigation_map()
	_lerakott_gyoker = get_node_or_null(lerakott_gyoker_path) as Node3D
	if _lerakott_gyoker == null and get_parent() != null:
		_lerakott_gyoker = Node3D.new()
		_lerakott_gyoker.name = "PlacedObjects"
		get_parent().add_child(_lerakott_gyoker)
	_build_hint = get_node_or_null(build_hint_path) as Label

func _ellenoriz_kihagyott() -> void:
	if _buildable_kulcsok.is_empty():
		push_warning("⚠️ Nincs építhető elem a katalógusban.")
	if _lerakott_gyoker == null:
		push_warning("⚠️ Hiányzik a lerakott elemek gyökere.")
	if _build_hint == null:
		push_warning("ℹ️ Build felirat nem található, a státusz rejtett marad.")

func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if not is_inside_tree():
		return
	if not _build_aktiv():
		return
	var viewport = get_viewport()
	var toggle_jel = event.is_action_pressed("ui_toggle_build")
	if toggle_jel:
		_valt_build_mod()
		print("[BUILD] B handled -> build_mode=%s" % str(_build_mod).to_lower())
		if viewport != null:
			viewport.set_input_as_handled()
		return
	if not _build_mod:
		return

	if event.is_action_pressed("build_cancel"):
		_kilep_build_mod()
		if viewport != null:
			viewport.set_input_as_handled()
		return

	if event.is_action_pressed("build_place"):
		_helyez()
		if viewport != null:
			viewport.set_input_as_handled()
		return

	if event.is_action_pressed("build_rotate"):
		_forgat()
		if viewport != null:
			viewport.set_input_as_handled()
		return

	if event.is_action_pressed("build_prev"):
		_valt_elem(-1)
		if viewport != null:
			viewport.set_input_as_handled()
		return

	if event.is_action_pressed("build_next"):
		_valt_elem(1)
		if viewport != null:
			viewport.set_input_as_handled()
		return

func _process(_delta: float) -> void:
	if not _build_mod:
		return
	_frissit_ghost()

func _valt_build_mod() -> void:
	if not _build_aktiv():
		_kijelzo("❌ Építés nem engedélyezett ebben a világban.")
		return
	if _build_mod:
		_kilep_build_mod()
		return
	_belep_build_mod()

func _belep_build_mod() -> void:
	_build_mod = true
	_ghost_forgas = 0.0
	_frissit_kijelolt_ghost()
	if _ghost != null:
		print("[BUILD] build_mode=true ghost_ready=true")
	_frissit_hint()

func _kilep_build_mod() -> void:
	_build_mod = false
	_szabadit_ghost()
	_frissit_hint(true)

func _frissit_kijelolt_ghost() -> void:
	_szabadit_ghost()
	var adat = _aktualis_adat()
	var scena_utvonal = String(adat.get("scene", ""))
	if scena_utvonal == "":
		return
	var scene = load(scena_utvonal) as PackedScene
	if scene == null:
		push_warning("⚠️ Nem tölthető be a prefab: %s" % scena_utvonal)
		return
	_ghost = scene.instantiate() as Node3D
	if _ghost == null:
		return
	add_child(_ghost)
	_jelol_ghost_szint()

func _szabadit_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_ervenyes = false

func _aktualis_adat() -> Dictionary:
	if _buildable_kulcsok.is_empty():
		return {}
	_aktualis_index = clamp(_aktualis_index, 0, _buildable_kulcsok.size() - 1)
	var kulcs = String(_buildable_kulcsok[_aktualis_index])
	return _catalog.get_data(kulcs)

func _frissit_ghost() -> void:
	if _ghost == null:
		_frissit_kijelolt_ghost()
	if _ghost == null or _kamera == null:
		return

	var hit_pozicio = _egyenes_ray_hit()
	if hit_pozicio == null:
		_ghost_ervenyes = false
		_jelol_ghost_szint()
		return

	var adat = _aktualis_adat()
	var racs = float(adat.get("grid", racs_meret_alap))
	var racs_meret = max(0.1, racs)
	var cel = _snap_pont(hit_pozicio, racs_meret)
	_ghost.global_position = cel
	_ghost.rotation = Vector3(0.0, _ghost_forgas, 0.0)
	_ghost_ervenyes = _ellenoriz_navmesh(cel)
	_jelol_ghost_szint()

func _egyenes_ray_hit() -> Variant:
	if _kamera == null:
		return null
	var viewport = get_viewport()
	if viewport == null:
		return null
	var mouse = viewport.get_mouse_position()
	var from = _kamera.project_ray_origin(mouse)
	var irany = _kamera.project_ray_normal(mouse)
	var params = PhysicsRayQueryParameters3D.create(from, from + irany * 100.0)
	var world = get_world_3d()
	if world == null:
		return null
	var space = world.direct_space_state
	if space == null:
		return null
	var hit = space.intersect_ray(params)
	if hit.is_empty():
		return null
	return hit.get("position", null)

func _snap_pont(pozicio: Vector3, meret: float) -> Vector3:
	var cel = pozicio
	cel.x = round(cel.x / meret) * meret
	cel.z = round(cel.z / meret) * meret
	return cel

func _ellenoriz_navmesh(pozicio: Vector3) -> bool:
	if _nav_map == RID() and _nav_regio != null:
		_nav_map = _nav_regio.get_navigation_map()
	if _nav_map == RID():
		return true
	var legkozelebbi = NavigationServer3D.map_get_closest_point(_nav_map, pozicio)
	return pozicio.distance_to(legkozelebbi) < 0.6

func _jelol_ghost_szint() -> void:
	if _ghost == null:
		return
	var szin = Color(1, 0.3, 0.3, 0.35)
	if _ghost_ervenyes:
		szin = Color(0.3, 1, 0.3, 0.35)
	var mesh_nodek = _ghost.find_children("*", "MeshInstance3D", true)
	for mesh in mesh_nodek:
		if mesh is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = szin
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			(mesh as MeshInstance3D).material_override = mat

func _helyez() -> void:
	if not _build_mod or not _ghost_ervenyes:
		return
	var adat = _aktualis_adat()
	var scena_utvonal = String(adat.get("scene", ""))
	var build_key = String(adat.get("build_key", ""))
	if not _build_engedelyezett(build_key):
		return
	if scena_utvonal == "":
		return
	var scene = load(scena_utvonal) as PackedScene
	if scene == null:
		push_warning("⚠️ Nem tölthető be a prefab: %s" % scena_utvonal)
		return
	if _lerakott_gyoker == null:
		return
	var instance = scene.instantiate() as Node3D
	if instance == null:
		return
	instance.global_transform = _ghost.global_transform
	_lerakott_gyoker.add_child(instance)
	_fogyaszt_keszlet(build_key)
	if bool(adat.get("seat", false)):
		instance.add_to_group("seats")
		_frissit_seat_manager()
	_frissit_kijelolt_ghost()

func _frissit_seat_manager() -> void:
	if not is_inside_tree():
		return
	var tree = get_tree()
	if tree == null or tree.root == null:
		return
	var seat_manager = tree.root.get_node_or_null("SeatManager1")
	if seat_manager != null and seat_manager.has_method("refresh_seats"):
		seat_manager.call("refresh_seats")

func _forgat() -> void:
	_ghost_forgas += deg_to_rad(90.0)

func _valt_elem(lepes: int) -> void:
	if _buildable_kulcsok.is_empty():
		return
	_aktualis_index = (_aktualis_index + lepes) % _buildable_kulcsok.size()
	if _aktualis_index < 0:
		_aktualis_index = _buildable_kulcsok.size() - 1
	_frissit_kijelolt_ghost()
	_frissit_hint()

func _frissit_hint(force_rejt: bool = false) -> void:
	if _build_hint == null:
		return
	if force_rejt or not _build_mod:
		_build_hint.visible = false
		return
	_build_hint.visible = true
	var adat = _aktualis_adat()
	var cimke = String(adat.get("cimke", "Ismeretlen"))
	_build_hint.text = "Build: %s | LMB: lerak | R: forgat | Q/E: vált | ESC: kilép" % cimke

func _build_engedelyezett(build_key: String) -> bool:
	var kulcs = String(build_key).strip_edges()
	if kulcs == "":
		return true
	if kulcs == "chicken_coop":
		var darab = _gs_int("build_owned_chicken_coop")
		if darab <= 0:
			_kijelzo("❌ Előbb vásárolj egy tyúkólat a boltban.")
			return false
		return true
	if kulcs == "farm_plot":
		if not _van_eszkoz("hoe"):
			_kijelzo("❌ Kapa nélkül nem tudsz parcellát építeni.")
			return false
		return true
	return true

func _fogyaszt_keszlet(build_key: String) -> void:
	var kulcs = String(build_key).strip_edges()
	if kulcs == "":
		return
	if kulcs == "chicken_coop":
		_gs_add("build_owned_chicken_coop", -1, "Tyúkól lerakás")

func _gs_int(kulcs: String) -> int:
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", kulcs, 0))
	return 0

func _gs_add(kulcs: String, delta: int, reason: String) -> void:
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("add_value"):
		gs.call("add_value", kulcs, delta, reason)

func _van_eszkoz(tool_id: String) -> bool:
	var kulcs = "tool_owned_%s" % String(tool_id)
	return _gs_int(kulcs) > 0

func _kijelzo(szoveg: String) -> void:
	var most = Time.get_ticks_msec()
	if most < _uzenet_kesleltetes_ms:
		return
	_uzenet_kesleltetes_ms = most + 800
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)

func set_build_enabled(engedelyezett: bool) -> void:
	_kulso_engedely = engedelyezett
	if not _build_aktiv():
		_kilep_build_mod()
		_frissit_hint(true)

func is_build_mode_active() -> bool:
	return _build_mod

func toggle_build_mode_from_ui() -> void:
	_valt_build_mod()

func _biztosit_build_hotkey() -> void:
	var billentyu = KEY_B
	if not InputMap.has_action("ui_toggle_build"):
		InputMap.add_action("ui_toggle_build")
	if not _action_has_key("ui_toggle_build", billentyu):
		var ev = InputEventKey.new()
		ev.physical_keycode = billentyu
		ev.keycode = billentyu
		InputMap.action_add_event("ui_toggle_build", ev)
	if not _binding_logged:
		print("[INPUT_FIX] build action bound to B.")
		_binding_logged = true

func _action_has_key(action_name: String, keycode: int) -> bool:
	if not InputMap.has_action(action_name):
		return false
	var esemenyek = InputMap.action_get_events(action_name)
	for e_any in esemenyek:
		if e_any is InputEventKey:
			var e = e_any as InputEventKey
			if e.physical_keycode == keycode or e.keycode == keycode:
				return true
	return false

func _build_aktiv() -> bool:
	return epitkezes_engedelyezett and _kulso_engedely
