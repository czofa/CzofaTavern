extends CharacterBody3D
class_name Guest

@export var navigation_agent_path: NodePath = ^"NavigationAgent3D"
@export var sebesseg: float = 2.5
@export var cel_tavolsag: float = 0.35

var order: String = "Sör"
var reached_seat: bool = false

var _nav: NavigationAgent3D
var _cel_pont: Node3D
var _seat_manager: Node
var _elfogyasztva: bool = false

func _ready() -> void:
	_nav = get_node_or_null(navigation_agent_path) as NavigationAgent3D
	_seat_manager = get_tree().root.get_node_or_null("SeatManager1")
	_connect_nav()
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _nav == null:
		reached_seat = true
		return

	if _nav.is_navigation_finished():
		_on_cel_elerve()
		return

	var kov_pont: Vector3 = _nav.get_next_path_position()
	var irany := (kov_pont - global_position)
	irany.y = 0.0

	if irany.length() < 0.01:
		velocity = Vector3.ZERO
		return

	velocity = irany.normalized() * sebesseg
	move_and_slide()

func set_target(target: Node3D) -> void:
	_cel_pont = target
	reached_seat = false
	if _nav != null and target != null:
		_nav.target_position = target.global_position

func set_order(new_order: String) -> void:
	var o := new_order.strip_edges()
	if o != "":
		order = o

func has_consumed() -> bool:
	return _elfogyasztva

func mark_as_consumed() -> void:
	if _elfogyasztva:
		return
	_elfogyasztva = true
	_szek_felszabadit()
	queue_free()

func _on_cel_elerve() -> void:
	reached_seat = true
	velocity = Vector3.ZERO

func _connect_nav() -> void:
	if _nav == null:
		return
	_nav.path_desired_distance = cel_tavolsag
	_nav.target_desired_distance = cel_tavolsag
	var cb := Callable(self, "_on_cel_elerve")
	if not _nav.target_reached.is_connected(cb):
		_nav.target_reached.connect(cb)

func _exit_tree() -> void:
	_szek_felszabadit()

func _szek_felszabadit() -> void:
	if _seat_manager != null and _seat_manager.has_method("free_seat_by_guest"):
		_seat_manager.call("free_seat_by_guest", self)
