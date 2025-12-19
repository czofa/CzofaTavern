extends Node3D
class_name GuestSpawner

@export var guest_scene: PackedScene
@export var spawn_point_path: NodePath = ^"../TavernNav/SpawnPoint"
@export var target_point_path: NodePath = ^"../TavernNav/TargetPoint"
@export var spawn_interval: float = 6.0
@export var max_guests: int = 4
@export var debug_toast: bool = true

var _spawn_point: Node3D
var _target_point: Node3D
var _aktiv_vendegek: Array[Node3D] = []
var _ido_meres: float = 0.0
var _rendelesek: Array[String] = ["Sör", "Bor", "Víz"]

func _ready() -> void:
	_cache_nodes()
	set_process(true)

func _process(delta: float) -> void:
	_takarit_aktiv_lista()

	if guest_scene == null or spawn_interval <= 0.0:
		return
	if _aktiv_vendegek.size() >= max_guests:
		return

	_ido_meres += delta
	if _ido_meres < spawn_interval:
		return

	_ido_meres = 0.0
	_spawn_guest()

func get_active_guests() -> Array:
	_takarit_aktiv_lista()
	return _aktiv_vendegek.duplicate()

func _spawn_guest() -> void:
	var seat_manager := _get_seat_manager()
	var cel_szek: Node3D = null
	if seat_manager != null and seat_manager.has_method("find_free_seat"):
		cel_szek = seat_manager.call("find_free_seat")

	if cel_szek == null:
		_toast("ℹ️ Nincs szabad szék, spawn kihagyva.")
		return

	var guest := guest_scene.instantiate() as Node3D
	if guest == null:
		push_error("❌ Guest prefab nem példányosítható.")
		return

	_regisztral_guest(guest)
	_elhelyez_guest(guest)

	if seat_manager != null and seat_manager.has_method("reserve_seat"):
		seat_manager.call("reserve_seat", cel_szek, guest)

	if guest.has_method("set_target"):
		guest.call("set_target", cel_szek)
	elif guest is Node3D:
		guest.global_position = cel_szek.global_position

	_beallit_rendeles(guest)
	_toast("🧍 Új vendég érkezett: %s" % guest.name)

func _regisztral_guest(guest: Node3D) -> void:
	guest.name = "Guest_%d" % _aktiv_vendegek.size()
	_aktiv_vendegek.append(guest)
	add_child(guest)

	var cb := Callable(self, "_on_guest_exited").bind(guest)
	if not guest.tree_exited.is_connected(cb):
		guest.tree_exited.connect(cb)

func _elhelyez_guest(guest: Node3D) -> void:
	if _spawn_point != null:
		guest.global_position = _spawn_point.global_position
	elif _target_point != null:
		guest.global_position = _target_point.global_position
	else:
		guest.global_position = global_position

func _beallit_rendeles(guest: Node) -> void:
	var rendeles := _kovetkezo_rendeles()
	if guest.has_method("set_order"):
		guest.call("set_order", rendeles)
	elif guest.has_variable("order"):
		guest.order = rendeles

func _kovetkezo_rendeles() -> String:
	if _rendelesek.is_empty():
		return "Sör"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return _rendelesek[rng.randi_range(0, _rendelesek.size() - 1)]

func _on_guest_exited(guest: Node) -> void:
	if _aktiv_vendegek.has(guest):
		_aktiv_vendegek.erase(guest)

func _takarit_aktiv_lista() -> void:
	for g in _aktiv_vendegek.duplicate():
		if not is_instance_valid(g):
			_aktiv_vendegek.erase(g)

func _cache_nodes() -> void:
	_spawn_point = get_node_or_null(spawn_point_path) as Node3D
	_target_point = get_node_or_null(target_point_path) as Node3D

	if _spawn_point == null:
		push_warning("ℹ️ Spawn pont nem található: %s" % spawn_point_path)
	if _target_point == null:
		push_warning("ℹ️ Célpont nem található: %s" % target_point_path)

func _get_seat_manager() -> Node:
	return get_tree().root.get_node_or_null("SeatManager1")

func _toast(szoveg: String) -> void:
	if not debug_toast:
		return
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)
