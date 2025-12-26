extends Node
class_name EmployeeSystem
# Automatikus betöltés: EmployeeSystem1 -> res://scripts/systems/employees/EmployeeSystem.gd

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
# Publikus API
# -------------------------------------------------------------------

func get_employees() -> Array:
	return _employees.duplicate()

func get_job_seekers() -> Array:
	_ensure_job_seekers_seeded()
	return _job_seekers.duplicate()

func ensure_candidates_seeded() -> void:
	if not _job_seekers.is_empty():
		return
	_seed_basic_candidates()

func hire_employee(seeker_id: String) -> bool:
	var target = str(seeker_id).strip_edges()
	if target == "":
		return false
	var felvett = {}
	var marad: Array = []
	for s in _job_seekers:
		var seeker = s if s is Dictionary else {}
		if _dict_str(seeker, "id", "") == target:
			felvett = seeker
			continue
		marad.append(seeker)
	if felvett.is_empty():
		return false
	_job_seekers = marad
	var uj_emp = _copy_seeker_to_employee(felvett)
	_employees.append(uj_emp)
	var nev = _dict_str(uj_emp, "name", target)
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
		if _dict_str(seeker, "id", "") == target:
			nev = _dict_str(seeker, "name", target)
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
		if _dict_str(emp, "id", "") == target:
			removed = true
			nev = _dict_str(emp, "name", target)
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
		if _dict_str(emp, "id", "") != target:
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
	var gross = _dict_int(emp, "gross", 0)
	if gross <= 0:
		return 0
	var preset_id = _dict_str(emp, "payroll_preset", "")
	var preset = _get_preset(preset_id)
	var contrib = _dict_float(preset, "employer_contrib_rate", 0.0)
	var health = _dict_float(preset, "health_rate", 0.0)
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
# Belső logika
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
		emp["free_until_day"] = start_day + _dict_int(emp, "free_days", 0)
		_employees.append(emp)
	_tavern_closed_due_to_payroll = false
	_last_closed_noti_ms = 0
	_ensure_job_seekers_seeded()

func _ensure_job_seekers_seeded() -> void:
	if _job_seekers.size() >= 3:
		return
	var catalog = _get_catalog()
	var default_list: Array = []
	if catalog != null:
		var list_any = catalog.default_job_seekers
		if list_any is Array:
			default_list = list_any
	_seed_job_seekers_from_list(default_list)
	if _job_seekers.size() < 3:
		_seed_job_seekers_from_list(_fallback_job_seekers())

func _seed_basic_candidates() -> void:
	var lista: Array = [
		{
			"id": "seed_emp_1",
			"name": "Anna",
			"speed": 2,
			"cook": 1,
			"reliability": 2,
			"wage_ft": 130000,
			"wage_request": 130000
		},
		{
			"id": "seed_emp_2",
			"name": "Dani",
			"speed": 1,
			"cook": 2,
			"reliability": 3,
			"wage_ft": 150000,
			"wage_request": 150000
		},
		{
			"id": "seed_emp_3",
			"name": "Kata",
			"speed": 3,
			"cook": 2,
			"reliability": 2,
			"wage_ft": 180000,
			"wage_request": 180000
		}
	]
	for seeker_any in lista:
		if seeker_any is Dictionary:
			var seeker = seeker_any as Dictionary
			var id = ""
			if seeker.has("id"):
				id = str(seeker["id"]).strip_edges()
			if id == "":
				continue
			if _has_seeker_id(id):
				continue
			_job_seekers.append(_deep_copy_dict(seeker))

func _seed_job_seekers_from_list(lista: Array) -> void:
	for seeker_any in lista:
		if _job_seekers.size() >= 3:
			return
		var seeker: Dictionary = {}
		if seeker_any is Dictionary:
			seeker = seeker_any
		var id = ""
		if seeker.has("id"):
			id = str(seeker["id"]).strip_edges()
		if id == "":
			continue
		if _has_seeker_id(id):
			continue
		var uj = _deep_copy_dict(seeker)
		if not uj.has("wage_ft"):
			if uj.has("wage_request"):
				uj["wage_ft"] = int(uj["wage_request"])
			else:
				uj["wage_ft"] = 0
		_job_seekers.append(uj)

func _has_seeker_id(id: String) -> bool:
	for s in _job_seekers:
		var seeker = s if s is Dictionary else {}
		if seeker.has("id") and str(seeker["id"]) == id:
			return true
	return false

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
			var day_index = 1
			if payload.has("day"):
				day_index = int(payload["day"])
			on_new_day(day_index)
		_:
			pass

func _find_employee(employee_id: String) -> Dictionary:
	var target = str(employee_id).strip_edges()
	for emp_any in _employees:
		var emp = emp_any if emp_any is Dictionary else {}
		if _dict_str(emp, "id", "") == target:
			return emp
	return {}

func _get_catalog() -> Node:
	return load("res://scripts/systems/employees/EmployeeCatalog.gd").new()

func _get_preset(preset_id: String) -> Dictionary:
	var catalog = _get_catalog()
	var preset_key = str(preset_id)
	if catalog != null and catalog.payroll_presets is Dictionary:
		var presets = catalog.payroll_presets as Dictionary
		if presets.has(preset_key):
			var preset_any = presets[preset_key]
			return preset_any if preset_any is Dictionary else {}
		if presets.has(catalog.DEFAULT_PAYROLL_PRESET):
			var fallback_any = presets[catalog.DEFAULT_PAYROLL_PRESET]
			return fallback_any if fallback_any is Dictionary else {}
	return {}

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
	var start = _dict_int(emp, "shift_start", 0)
	var end = _dict_int(emp, "shift_end", 0)
	if start == 0 and end == 0:
		return true
	return minutes >= start and minutes <= end

func _refresh_free_helper(day_index: int) -> void:
	for i in _employees.size():
		var emp_any = _employees[i]
		var emp = emp_any if emp_any is Dictionary else {}
		var free_limit = _dict_int(emp, "free_until_day", 0)
		if day_index > free_limit and _dict_int(emp, "gross", 0) <= 0:
			emp["gross"] = _get_catalog().DEFAULT_GROSS_AFTER_FREE
			_employees[i] = emp

func _run_payroll(day_index: int) -> void:
	var total_cost = 0
	var fizetett_letszam = 0
	for emp_any in _employees:
		var emp = emp_any if emp_any is Dictionary else {}
		var free_limit = _dict_int(emp, "free_until_day", 0)
		if day_index <= free_limit:
			continue
		var emp_cost = get_monthly_total_cost(_dict_str(emp, "id", ""))
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
	uj["gross"] = _dict_int(uj, "gross", 0)
	var payroll_preset = _dict_str(uj, "payroll_preset", "")
	if payroll_preset == "":
		payroll_preset = _get_catalog().DEFAULT_PAYROLL_PRESET
	uj["payroll_preset"] = payroll_preset
	var shift_start = _dict_int(uj, "shift_start", 6 * 60)
	var shift_end = _dict_int(uj, "shift_end", 22 * 60)
	uj["shift_start"] = shift_start
	uj["shift_end"] = shift_end
	uj["wage_request"] = _dict_int(uj, "wage_request", 0)
	return uj

func _dict_str(adat: Dictionary, kulcs: String, alap: String) -> String:
	if adat.has(kulcs):
		return str(adat[kulcs])
	return alap

func _dict_int(adat: Dictionary, kulcs: String, alap: int) -> int:
	if adat.has(kulcs):
		return int(adat[kulcs])
	return alap

func _dict_float(adat: Dictionary, kulcs: String, alap: float) -> float:
	if adat.has(kulcs):
		return float(adat[kulcs])
	return alap

func _deep_copy_dict(src: Dictionary) -> Dictionary:
	var dest: Dictionary = {}
	for k in src.keys():
		dest[k] = src[k]
	return dest
