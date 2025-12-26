extends Node
class_name EncounterManager
# Autoload neve: EncounterManager1 (ha autoloadban van)

@export var daily_encounter_chance: int = 60
@export var encounter_check_hour: int = 9

const DEBUG_FORCE_DAILY = true
const FORCE_MINUTES_WITHOUT_ENCOUNTER = 10.0

var _encounter_triggered_today: bool = false
var _last_day_seen: int = -1
var _last_encounter_minutes = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _process(_delta: float) -> void:
	if not has_node("/root/TimeSystem1"):
		return

	var current_minutes: float = TimeSystem1.get_current_game_minutes()
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

	var catalog = get_tree().root.get_node_or_null("EncounterCatalog1")
	if catalog == null or not catalog.has(encounter_id):
		push_warning("EncounterManager: encounter not found: %s" % encounter_id)
		return false

	var data: Dictionary = catalog.get_data(encounter_id)

	# Értesítés
	if EventBus1.has_signal("notification_requested"):
		EventBus1.emit_signal(
			"notification_requested",
			"❗ Egy különös esemény történik..."
		)

	# Kis késleltetés, hogy az értesítés látszódjon
	await get_tree().create_timer(1.2).timeout

	# Encounter indítása (ID ALAPÚ, a Director kezeli)
	if EventBus1.has_signal("request_show_encounter"):
		EventBus1.emit_signal("request_show_encounter", encounter_id)
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
	if typeof(EmployeeSystem1) == TYPE_NIL or EmployeeSystem1 == null:
		return true
	if not EmployeeSystem1.has_method("is_tavern_open"):
		return true
	return EmployeeSystem1.is_tavern_open(int(current_minutes))

func _select_random_encounter_id() -> String:
	# Jelenleg fix (a bíró)
	# Később ide jön random / súlyozás / frakció / nap / évszak
	return "test_judge"
