extends Node
# Automatikus betöltés: EmployeeSystem1 -> res://scripts/systems/employees/EmployeeSystem.gd

const _ALLAPOT_KULCS := "employees_state"

var _candidates: Array = []
var _hired: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_betolt_allapot()
	seed_candidates()
	_ment_allapot()

# -------------------------------------------------------------------
# Új publikus API
# -------------------------------------------------------------------

func get_candidates() -> Array:
	return _deep_copy_array(_candidates)

func get_hired() -> Array:
	return _deep_copy_array(_hired)

func hire(id: String) -> bool:
	var target = str(id).strip_edges()
	if target == "":
		return false
	var uj_lista: Array = []
	var talalt: Dictionary = {}
	for c_any in _candidates:
		var c = c_any if c_any is Dictionary else {}
		if _dict_str(c, "id", "") == target:
			talalt = _deep_copy_dict(c)
			continue
		uj_lista.append(c)
	if talalt.is_empty():
		return false
	_candidates = uj_lista
	_hired.append(_normalizal_munkatars(talalt))
	_notify("✅ Felvetted: %s" % _dict_str(talalt, "name", target))
	_ment_allapot()
	seed_candidates()
	return true

func reject(id: String) -> void:
	var target = str(id).strip_edges()
	if target == "":
		return
	var uj_lista: Array = []
	var nev = target
	for c_any in _candidates:
		var c = c_any if c_any is Dictionary else {}
		if _dict_str(c, "id", "") == target:
			nev = _dict_str(c, "name", target)
			continue
		uj_lista.append(c)
	_candidates = uj_lista
	_notify("❌ Elutasítva: %s" % nev)
	_ment_allapot()
	seed_candidates()

func fire(id: String) -> bool:
	var target = str(id).strip_edges()
	if target == "":
		return false
	var uj_lista: Array = []
	var nev = target
	var eltavolitva = false
	for h_any in _hired:
		var h = h_any if h_any is Dictionary else {}
		if _dict_str(h, "id", "") == target:
			eltavolitva = true
			nev = _dict_str(h, "name", target)
			continue
		uj_lista.append(h)
	_hired = uj_lista
	if eltavolitva:
		_notify("🧾 Kirúgtad: %s" % nev)
		_ment_allapot()
	return eltavolitva

func seed_candidates() -> void:
	if _candidates.size() >= 3:
		return
	var sablonok = _alap_jeloltek()
	for adat in sablonok:
		if _candidates.size() >= 3:
			break
		if adat is Dictionary:
			var jelolt = adat as Dictionary
			var id = _dict_str(jelolt, "id", "")
			if id == "" or _has_candidate_id(id):
				continue
			_candidates.append(_deep_copy_dict(jelolt))
	while _candidates.size() < 3:
		_candidates.append(_general_jelolt())

# -------------------------------------------------------------------
# Kompatibilitás régi hívásokhoz
# -------------------------------------------------------------------

func get_employees() -> Array:
	return get_hired()

func get_job_seekers() -> Array:
	return get_candidates()

func ensure_candidates_seeded() -> void:
	seed_candidates()

func hire_employee(seeker_id: String) -> bool:
	return hire(seeker_id)

func reject_seeker(seeker_id: String) -> void:
	reject(seeker_id)

func fire_employee(emp_id: String) -> bool:
	return fire(emp_id)

func set_payroll(employee_id: String, gross_monthly_ft: int, _preset_id: String) -> void:
	var target = str(employee_id).strip_edges()
	if target == "":
		return
	for i in _hired.size():
		var emp_any = _hired[i]
		var emp = emp_any if emp_any is Dictionary else {}
		if _dict_str(emp, "id", "") != target:
			continue
		emp["gross"] = max(int(gross_monthly_ft), 0)
		_hired[i] = emp
		break
	_ment_allapot()

func get_monthly_total_cost(employee_id: String) -> int:
	var emp = _find_employee(employee_id)
	if emp.is_empty():
		return 0
	var gross = _dict_int(emp, "gross", 0)
	if gross > 0:
		return gross
	return _dict_int(emp, "wage_request", 0)

func is_any_staff_active(_now_minutes: int = -1) -> bool:
	return not _hired.is_empty()

func is_tavern_open(_now_minutes: int = -1) -> bool:
	return not _hired.is_empty()

func on_new_day(_day_index: int) -> void:
	pass

func request_closed_notification() -> void:
	_notify("🔒 Nincs aktív alkalmazott.")

# -------------------------------------------------------------------
# Belső logika
# -------------------------------------------------------------------

func _alap_jeloltek() -> Array:
	return [
		{
			"id": "cand_anna",
			"name": "Anna",
			"speed": 4,
			"cook": 3,
			"reliability": 5,
			"wage_request": 1200
		},
		{
			"id": "cand_dani",
			"name": "Dani",
			"speed": 6,
			"cook": 2,
			"reliability": 4,
			"wage_request": 1500
		},
		{
			"id": "cand_kata",
			"name": "Kata",
			"speed": 3,
			"cook": 5,
			"reliability": 6,
			"wage_request": 1700
		}
	]

func _general_jelolt() -> Dictionary:
	var id = "cand_%d" % Time.get_ticks_msec()
	return {
		"id": id,
		"name": "Új jelölt",
		"speed": 2,
		"cook": 2,
		"reliability": 2,
		"wage_request": 1000
	}

func _normalizal_munkatars(emp: Dictionary) -> Dictionary:
	var uj = _deep_copy_dict(emp)
	if not uj.has("id"):
		uj["id"] = "emp_%d" % Time.get_ticks_msec()
	if not uj.has("wage_request"):
		uj["wage_request"] = 0
	return uj

func _has_candidate_id(id: String) -> bool:
	for c_any in _candidates:
		var c = c_any if c_any is Dictionary else {}
		if _dict_str(c, "id", "") == id:
			return true
	return false

func _find_employee(employee_id: String) -> Dictionary:
	var target = str(employee_id).strip_edges()
	for emp_any in _hired:
		var emp = emp_any if emp_any is Dictionary else {}
		if _dict_str(emp, "id", "") == target:
			return emp
	return {}

func _betolt_allapot() -> void:
	var gs = _get_game_state()
	if gs == null or not gs.has_method("get_data"):
		return
	var adat_any = gs.call("get_data", _ALLAPOT_KULCS, {})
	if not (adat_any is Dictionary):
		return
	var adat = adat_any as Dictionary
	var cand_any = adat.get("candidates", [])
	var hired_any = adat.get("hired", [])
	if cand_any is Array:
		_candidates = _deep_copy_array(cand_any)
	if hired_any is Array:
		_hired = _deep_copy_array(hired_any)

func _ment_allapot() -> void:
	var gs = _get_game_state()
	if gs == null or not gs.has_method("set_data"):
		return
	var adat: Dictionary = {
		"candidates": _deep_copy_array(_candidates),
		"hired": _deep_copy_array(_hired)
	}
	gs.call("set_data", _ALLAPOT_KULCS, adat)

func _get_game_state() -> Node:
	if typeof(GameState1) != TYPE_NIL and GameState1 != null:
		return GameState1
	return get_tree().root.get_node_or_null("GameState1")

func _notify(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", str(text))

func _dict_str(adat: Dictionary, kulcs: String, alap: String) -> String:
	if adat.has(kulcs):
		return str(adat[kulcs])
	return alap

func _dict_int(adat: Dictionary, kulcs: String, alap: int) -> int:
	if adat.has(kulcs):
		return int(adat[kulcs])
	return alap

func _deep_copy_dict(src: Dictionary) -> Dictionary:
	var dest: Dictionary = {}
	for k in src.keys():
		dest[k] = src[k]
	return dest

func _deep_copy_array(src: Array) -> Array:
	var dest: Array = []
	for item in src:
		if item is Dictionary:
			dest.append(_deep_copy_dict(item))
		else:
			dest.append(item)
	return dest
