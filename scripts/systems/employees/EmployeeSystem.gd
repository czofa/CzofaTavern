extends Node
class_name EmployeeSystem
# Autoload: EmployeeSystem1 -> res://scripts/systems/employees/EmployeeSystem.gd

const NOTI_COOLDOWN_MS = 5000

var _employees: Array = []
var _job_seekers: Array = []
var _tavern_closed_due_to_payroll: bool = false
var _last_closed_noti_ms: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	_init_defaults()

# -------------------------------------------------------------------
# PUBLIC API
# -------------------------------------------------------------------

func get_employees() -> Array:
	return _employees.duplicate()

func get_job_seekers() -> Array:
	_ensure_job_seekers_seeded()
	return _job_seekers.duplicate()

func hire_employee(seeker_id: String) -> bool:
	var target = str(seeker_id).strip_edges()
	if target == "":
		return false
	var felvett = {}
	var marad: Array = []
	for s in _job_seekers:
		var seeker = s if s is Dictionary else {}
		if str(seeker.get("id", "")) == target:
			felvett = seeker
			continue
		marad.append(seeker)
	if felvett.is_empty():
		return false
	_job_seekers = marad
	var uj_emp = _copy_seeker_to_employee(felvett)
	_employees.append(uj_emp)
	var nev = str(uj_emp.get("name", target))
	_notify("👷 Felvetted: %s" % nev)
	return true

func reject_seeker(seeker_id: String) -> void:
	var target = str(seeker_id).strip_edges()
	if target == "":
		return
	var kept: Array = []
	var nev = target
	for s in _job_seekers:
		var seeker = s if s is Dictionary else {}
		if str(seeker.get("id", "")) == target:
			nev = str(seeker.get("name", target))
			continue
		kept.append(seeker)
	_job_seekers = kept
	_notify("❌ Elutasítva: %s" % nev)

func fire_employee(employee_id: String) -> bool:
	var target = str(employee_id).strip_edges()
	if target == "":
		return false
	var removed = false
	var kept: Array = []
	var nev = target
	for e in _employees:
		var emp = e if e is Dictionary else {}
		if str(emp.get("id", "")) == target:
			removed = true
			nev = str(emp.get("name", target))
			continue
		kept.append(emp)
	_employees = kept
	if removed:
		_notify("🧾 Kirúgtad: %s" % nev)
	return removed

func set_payroll(employee_id: String, gross_monthly_ft: int, preset_id: String) -> void:
	var target = str(employee_id).strip_edges()
	if target == "":
		return
	var uj_gross = max(int(gross_monthly_ft), 0)
	var preset = str(preset_id).strip_edges()
	for i in _employees.size():
		var emp_any = _employees[i]
		var emp = emp_any if emp_any is Dictionary else {}
		if str(emp.get("id", "")) != target:
			continue
		emp["gross"] = uj_gross
		if preset != "":
			emp["payroll_preset"] = preset
		_employees[i] = emp
		break

func get_monthly_total_cost(employee_id: String) -> int:
	var emp = _find_employee(employee_id)
	if emp.is_empty():
		return 0
	var gross = int(emp.get("gross", 0))
	if gross <= 0:
		return 0
	var preset_id = str(emp.get("payroll_preset", ""))
	var preset = _get_preset(preset_id)
	var contrib = float(preset.get("employer_contrib_rate", 0.0))
	var health = float(preset.get("health_rate", 0.0))
	var total = float(gross) + round(float(gross) * contrib) + round(float(gross) * health)
	return int(total)

func is_any_staff_active(now_minutes: int = -1) -> bool:
	var perc = now_minutes
	if perc < 0:
		perc = _resolve_minutes(null)
	var _has_any_active_employee = false
	for emp_any in _employees:
		var emp = emp_any if emp_any is Dictionary else {}
		if emp.is_empty():
			continue
		_has_any_active_employee = true
		if perc < 0:
			break
		if _is_employee_active(emp, perc):
			return true
	if perc < 0:
		return _has_any_active_employee
	return false

func is_tavern_open(now_minutes: int = -1) -> bool:
	if _tavern_closed_due_to_payroll:
		return false
	return is_any_staff_active(now_minutes)

func on_new_day(day_index: int) -> void:
	_refresh_free_helper(day_index)
	if day_index % 30 == 0:
		_run_payroll(day_index)

# -------------------------------------------------------------------
# BELSO LOGIKA
# -------------------------------------------------------------------

func _init_defaults() -> void:
	var start_day = 1
	if typeof(TimeSystem1) != TYPE_NIL and TimeSystem1 != null and TimeSystem1.has_method("get_day"):
		start_day = int(TimeSystem1.get_day())
	var catalog = _get_catalog()
	_employees.clear()
	_job_seekers.clear()
	for seeker_any in catalog.default_job_seekers:
		var seeker = seeker_any if seeker_any is Dictionary else {}
		_job_seekers.append(_deep_copy_dict(seeker))
	for e in catalog.default_employees:
		var emp = e if e is Dictionary else {}
		emp["free_until_day"] = start_day + int(emp.get("free_days", 0))
		_employees.append(emp)
	_tavern_closed_due_to_payroll = false
	_last_closed_noti_ms = 0

func _ensure_job_seekers_seeded() -> void:
	if not _job_seekers.is_empty():
		return
	var catalog = _get_catalog()
	var default_list: Array = []
	if catalog != null:
		var list_any = catalog.default_job_seekers
		if list_any is Array:
			default_list = list_any
	for seeker_any in default_list:
		var seeker: Dictionary = {}
		if seeker_any is Dictionary:
			seeker = seeker_any
		_job_seekers.append(_deep_copy_dict(seeker))
	if _job_seekers.is_empty():
		for seeker_any in _fallback_job_seekers():
			var fallback_seeker: Dictionary = {}
			if seeker_any is Dictionary:
				fallback_seeker = seeker_any
			_job_seekers.append(_deep_copy_dict(fallback_seeker))

func _fallback_job_seekers() -> Array:
	return [
		{
			"id": "cand_fallback_1",
			"name": "Erika",
			"level": 1,
			"speed": 1,
			"cook": 1,
			"reliability": 2,
			"wage_request": 120000,
			"portrait_path": "res://icon.svg",
			"shift_start": 7 * 60,
			"shift_end": 19 * 60
		},
		{
			"id": "cand_fallback_2",
			"name": "Bence",
			"level": 2,
			"speed": 2,
			"cook": 1,
			"reliability": 2,
			"wage_request": 160000,
			"portrait_path": "res://icon.svg",
			"shift_start": 8 * 60,
			"shift_end": 20 * 60
		},
		{
			"id": "cand_fallback_3",
			"name": "Lili",
			"level": 3,
			"speed": 2,
			"cook": 3,
			"reliability": 2,
			"wage_request": 210000,
			"portrait_path": "res://icon.svg",
			"shift_start": 10 * 60,
			"shift_end": 22 * 60
		}
	]

func _connect_bus() -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.new_day":
			on_new_day(int(payload.get("day", 1)))
		_:
			pass

func _find_employee(employee_id: String) -> Dictionary:
	var target = str(employee_id).strip_edges()
	for emp_any in _employees:
		var emp = emp_any if emp_any is Dictionary else {}
		if str(emp.get("id", "")) == target:
			return emp
	return {}

func _get_catalog() -> Node:
	return load("res://scripts/systems/employees/EmployeeCatalog.gd").new()

func _get_preset(preset_id: String) -> Dictionary:
	var catalog = _get_catalog()
	var preset_any = catalog.payroll_presets.get(str(preset_id), catalog.payroll_presets.get(catalog.DEFAULT_PAYROLL_PRESET, {}))
	return preset_any if preset_any is Dictionary else {}

func _resolve_minutes(now_minutes_or_time) -> int:
	if now_minutes_or_time == null:
		if typeof(TimeSystem1) != TYPE_NIL and TimeSystem1 != null and TimeSystem1.has_method("get_game_minutes"):
			return int(TimeSystem1.get_game_minutes()) % int(TimeSystem.MINUTES_PER_DAY)
		return -1
	if typeof(now_minutes_or_time) == TYPE_FLOAT or typeof(now_minutes_or_time) == TYPE_INT:
		var val = int(now_minutes_or_time)
		if val < 0:
			return val
		return val % int(TimeSystem.MINUTES_PER_DAY)
	return -1

func _is_employee_active(emp: Dictionary, minutes: int) -> bool:
	if emp.is_empty():
		return false
	var start = int(emp.get("shift_start", 0))
	var end = int(emp.get("shift_end", 0))
	if start == 0 and end == 0:
		return true
	return minutes >= start and minutes <= end

func _refresh_free_helper(day_index: int) -> void:
	for i in _employees.size():
		var emp_any = _employees[i]
		var emp = emp_any if emp_any is Dictionary else {}
		var free_limit = int(emp.get("free_until_day", 0))
		if day_index > free_limit and int(emp.get("gross", 0)) <= 0:
			emp["gross"] = _get_catalog().DEFAULT_GROSS_AFTER_FREE
			_employees[i] = emp

func _run_payroll(day_index: int) -> void:
	var total_cost = 0
	var fizetett_letszam = 0
	for emp_any in _employees:
		var emp = emp_any if emp_any is Dictionary else {}
		var free_limit = int(emp.get("free_until_day", 0))
		if day_index <= free_limit:
			continue
		var emp_cost = get_monthly_total_cost(str(emp.get("id", "")))
		if emp_cost <= 0:
			continue
		total_cost += emp_cost
		fizetett_letszam += 1

	if total_cost <= 0:
		_tavern_closed_due_to_payroll = false
		_set_flag("tavern_closed_due_to_payroll", false)
		return

	var money = _get_money()
	if money < total_cost:
		_handle_payroll_failure()
		return

	_pay_money(total_cost)
	_notify("👷 Bérkifizetés megtörtént: -%d Ft (%d fő)" % [total_cost, fizetett_letszam])
	_tavern_closed_due_to_payroll = false
	_set_flag("tavern_closed_due_to_payroll", false)

func _get_money() -> int:
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		return int(EconomySystem1.get_money())
	return 0

func _pay_money(amount: int) -> void:
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("add_money"):
		EconomySystem1.add_money(-abs(int(amount)), "Bérkifizetés")

func _handle_payroll_failure() -> void:
	_add_state_value("risk", 1, "Bérfizetés hiánya")
	_add_state_value("reputation", -1, "Bérfizetés hiánya")
	_tavern_closed_due_to_payroll = true
	_set_flag("tavern_closed_due_to_payroll", true)
	_notify("⚠️ Nincs elég pénz bérre! A kocsma bezár.")

func _add_state_value(key: String, delta: int, reason: String) -> void:
	if typeof(GameState1) != TYPE_NIL and GameState1 != null and GameState1.has_method("add_value"):
		GameState1.add_value(key, delta, reason)

func _set_flag(key: String, value: bool) -> void:
	if typeof(GameState1) != TYPE_NIL and GameState1 != null and GameState1.has_method("set_flag"):
		GameState1.set_flag(key, value)

func request_closed_notification() -> void:
	var now_ms = Time.get_ticks_msec()
	if now_ms - _last_closed_noti_ms < NOTI_COOLDOWN_MS:
		return
	_last_closed_noti_ms = now_ms
	_notify("🔒 Kocsma zárva: nincs aktív alkalmazott.")

func _notify(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(text))

func _copy_seeker_to_employee(seeker: Dictionary) -> Dictionary:
	var uj = _deep_copy_dict(seeker)
	if not uj.has("id"):
		uj["id"] = str("emp_", Time.get_ticks_msec())
	uj["gross"] = int(uj.get("gross", 0))
	uj["payroll_preset"] = str(uj.get("payroll_preset", _get_catalog().DEFAULT_PAYROLL_PRESET))
	var shift_start = int(uj.get("shift_start", 6 * 60))
	var shift_end = int(uj.get("shift_end", 22 * 60))
	uj["shift_start"] = shift_start
	uj["shift_end"] = shift_end
	uj["wage_request"] = int(uj.get("wage_request", 0))
	return uj

func _deep_copy_dict(src: Dictionary) -> Dictionary:
	var dest: Dictionary = {}
	for k in src.keys():
		dest[k] = src[k]
	return dest
