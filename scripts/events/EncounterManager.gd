extends Node
class_name EncounterManager
# Autoload neve: EncounterManager1 (ha autoloadban van)

@export var daily_encounter_chance: int = 60
@export var encounter_check_hour: int = 9
@export var time_system_path: NodePath
@export var employee_system_path: NodePath
@export var event_bus_path: NodePath
@export var encounter_catalog_path: NodePath

const DEBUG_FORCE_DAILY = true
const FORCE_MINUTES_WITHOUT_ENCOUNTER = 10.0

var _encounter_triggered_today: bool = false
var _last_day_seen: int = -1
var _last_encounter_minutes = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("[ENCOUNTER] EncounterManager READY")

func _process(_delta: float) -> void:
	var time_system = _get_time_system()
	if time_system == null:
		return
	if not time_system.has_method("get_current_game_minutes"):
		return

	var current_minutes: float = float(time_system.get_current_game_minutes())
	var current_day: int = int(current_minutes / 1440.0)

	# Új nap → reset
	if current_day != _last_day_seen:
		_last_day_seen = current_day
		_encounter_triggered_today = false
		_last_encounter_minutes = current_minutes

	if not _is_tavern_open(current_minutes):
		return

	if DEBUG_FORCE_DAILY and not _encounter_triggered_today:
		if _should_force_encounter(current_minutes):
			var forced = _trigger_encounter()
			if forced:
				_mark_encounter_triggered(current_minutes)
			return

	# Napi egyszeri ellenőrzés
	if not _encounter_triggered_today and _is_time_to_check(current_minutes):
		_check_for_encounter(current_minutes)

func _is_time_to_check(game_minutes: float) -> bool:
	var check_minutes = float(encounter_check_hour) * 60.0
	return abs(game_minutes - check_minutes) <= 2.5

func _check_for_encounter(current_minutes: float) -> void:
	if randi_range(1, 100) <= daily_encounter_chance:
		var started = _trigger_encounter()
		if started:
			_mark_encounter_triggered(current_minutes)

func _trigger_encounter() -> bool:
	var encounter_id = _select_random_encounter_id()

	var catalog = _get_encounter_catalog()
	if catalog == null:
		push_warning("EncounterManager: nem található EncounterCatalog.")
		return false
	if not catalog.has_method("has"):
		push_warning("EncounterManager: hiányzik az EncounterCatalog.has().")
		return false
	if not catalog.has_method("get_data"):
		push_warning("EncounterManager: hiányzik az EncounterCatalog.get_data().")
		return false
	if not catalog.has(encounter_id):
		push_warning("EncounterManager: encounter nem található: %s" % encounter_id)
		return false

	var event_bus = _get_event_bus()

	# Értesítés
	if event_bus != null and event_bus.has_signal("notification_requested"):
		event_bus.emit_signal(
			"notification_requested",
			"❗ Egy különös esemény történik..."
		)

	# Kis késleltetés, hogy az értesítés látszódjon
	await get_tree().create_timer(1.2).timeout

	# Encounter indítása (ID ALAPÚ, a Director kezeli)
	if event_bus != null and event_bus.has_signal("request_show_encounter"):
		event_bus.emit_signal("request_show_encounter", encounter_id)
		print("[ENCOUNTER] Encounter triggerelve: %s" % encounter_id)
		return true
	return false

func _should_force_encounter(current_minutes: float) -> bool:
	if _last_encounter_minutes < 0.0:
		return true
	return (current_minutes - _last_encounter_minutes) >= FORCE_MINUTES_WITHOUT_ENCOUNTER

func _mark_encounter_triggered(current_minutes: float) -> void:
	_encounter_triggered_today = true
	_last_encounter_minutes = current_minutes

func _is_tavern_open(current_minutes: float) -> bool:
	var employee_system = _get_employee_system()
	if employee_system == null:
		return true
	if not employee_system.has_method("is_tavern_open"):
		return true
	return employee_system.is_tavern_open(int(current_minutes))

func _select_random_encounter_id() -> String:
	# Jelenleg fix (a bíró)
	# Később ide jön random / súlyozás / frakció / nap / évszak
	return "test_judge"

func _get_time_system() -> Node:
	if time_system_path.is_empty():
		return null
	return get_node_or_null(time_system_path)

func _get_employee_system() -> Node:
	if employee_system_path.is_empty():
		return null
	return get_node_or_null(employee_system_path)

func _get_event_bus() -> Node:
	if event_bus_path.is_empty():
		return null
	return get_node_or_null(event_bus_path)

func _get_encounter_catalog() -> Node:
	if encounter_catalog_path.is_empty():
		return null
	return get_node_or_null(encounter_catalog_path)
