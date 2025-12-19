extends Node
class_name SeatManager

@export var debug_toast: bool = true

var _seats: Array[Node3D] = []
var _occupied: Dictionary = {}         # seat_path -> guest
var _guest_to_seat: Dictionary = {}    # guest -> seat_path

func _ready() -> void:
	_scan_seats()
	call_deferred("_deferred_scan")

func _deferred_scan() -> void:
	_scan_seats()
	if debug_toast:
		_toast("✅ SeatManager aktív – %d szék beolvasva" % _seats.size())

func _scan_seats() -> void:
	_seats.clear()
	_occupied.clear()
	_guest_to_seat.clear()

	var seat_root := get_node_or_null("/root/Main/WorldRoot/TavernWorld/TavernNav/Seats")
	if seat_root == null:
		push_error("❌ Székgyökér nem található: /root/Main/WorldRoot/TavernWorld/TavernNav/Seats")
		return

	for child in seat_root.get_children():
		if child is Node3D:
			_seats.append(child)
			_occupied[child.get_path()] = null

# -------------------- Public API --------------------

func find_free_seat() -> Node3D:
	for seat in _seats:
		if _occupied.get(seat.get_path()) == null:
			return seat
	return null

func reserve_seat(seat: Node3D, guest: Node) -> void:
	if seat == null or guest == null:
		return
	if not _seats.has(seat):
		return
	var seat_path = seat.get_path()
	_occupied[seat_path] = guest
	_guest_to_seat[guest] = seat_path
	if debug_toast:
		_toast("🪑 Szék foglalva: %s" % str(seat.name))

func free_seat_by_guest(guest: Node) -> void:
	if not _guest_to_seat.has(guest):
		return

	var seat_path = _guest_to_seat[guest]
	if _occupied.has(seat_path):
		_occupied[seat_path] = null
	if debug_toast:
		_toast("✅ Szék felszabadítva a vendégtől")

	_guest_to_seat.erase(guest)

# -------------------- Helper --------------------

func _toast(msg: String) -> void:
	var eb := get_tree().root.get_node_or_null("EventBus1")
	if eb and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", msg)
