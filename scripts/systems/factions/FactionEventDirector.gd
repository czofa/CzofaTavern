extends Node
class_name FactionEventDirector
# Autoload: FactionEventDirector1

const FactionConfig = preload("res://scripts/systems/factions/FactionConfig.gd")

@export var check_hour: int = 9
@export var debug_toast: bool = false

var _triggered_today: bool = false
var _last_day_seen: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()

func _process(_delta: float) -> void:
	if TimeSystem1 == null:
		return
	var minutes = TimeSystem1.get_current_game_minutes()
	var current_day = int(minutes / TimeSystem.MINUTES_PER_DAY)
	if current_day != _last_day_seen:
		_last_day_seen = current_day
		_triggered_today = false

	if _triggered_today:
		return
	if _is_time_to_check(minutes):
		_triggered_today = true
		_run_daily_events()

func _is_time_to_check(game_minutes: float) -> bool:
	var check_minutes = float(check_hour) * 60.0
	return abs(game_minutes - check_minutes) <= 3.0

func _run_daily_events() -> void:
	var rep = _get_state_value("reputation")
	var risk = _get_state_value("risk")
	var authority_value = _get_state_value("authority")
	if _has_faction_system():
		authority_value = FactionSystem1.get_faction_value("authority")

	var audit_chance = _calc_audit_chance(rep, risk, authority_value)
	var offer_chance = _calc_underworld_chance(rep, risk, authority_value)

	if randf() <= audit_chance:
		_trigger_event("authority_audit")
	if randf() <= offer_chance:
		_trigger_event("underworld_offer")

func _calc_audit_chance(reputation: int, risk: int, authority_value: int) -> float:
	var rule = FactionConfig.CHANCE_RULES.get("authority_audit", {})
	var base = float(rule.get("base", 0.0))
	var risk_term = max(risk, 0) * float(rule.get("risk_scale", 0.0))
	var rep_term = max(reputation, 0) * float(rule.get("reputation_penalty", 0.0))
	var authority_term = -min(authority_value, 0) * float(rule.get("authority_penalty", 0.0))
	var chance = base + risk_term - rep_term + authority_term
	return FactionConfig.clamp_chance(chance, float(rule.get("max_chance", 1.0)))

func _calc_underworld_chance(reputation: int, risk: int, authority_value: int) -> float:
	var rule = FactionConfig.CHANCE_RULES.get("underworld_offer", {})
	var base = float(rule.get("base", 0.0))
	var risk_term = max(risk, 0) * float(rule.get("risk_scale", 0.0))
	var negative_rep_bonus = -min(reputation, 0) * float(rule.get("negative_reputation_bonus", 0.0))
	var authority_bonus = -min(authority_value, 0) * float(rule.get("authority_mistrust_bonus", 0.0))
	var chance = base + risk_term + negative_rep_bonus + authority_bonus
	return FactionConfig.clamp_chance(chance, float(rule.get("max_chance", 1.0)))

func _trigger_event(kind: String) -> void:
	var data = FactionConfig.EVENT_DEFINITIONS.get(kind, {})
	var text = str(data.get("notification", ""))
	if text != "":
		_notify(text)
	var encounter_id = str(data.get("encounter_id", "")).strip_edges()
	if encounter_id != "":
		_start_encounter(encounter_id)

func _start_encounter(encounter_id: String) -> void:
	if _has_catalog(encounter_id):
		_bus("encounter.request", {"id": encounter_id})
		return
	_notify("❔ Encounter hiányzik: %s" % encounter_id)

func _has_catalog(encounter_id: String) -> bool:
	var catalog = get_tree().root.get_node_or_null("EncounterCatalog1")
	if catalog != null and catalog.has_method("has"):
		return bool(catalog.call("has", encounter_id))
	return false

func _has_faction_system() -> bool:
	return typeof(FactionSystem1) != TYPE_NIL and FactionSystem1 != null

func _get_state_value(key: String) -> int:
	if GameState1 != null and GameState1.has_method("get_value"):
		return int(GameState1.call("get_value", key, 0))
	return 0

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, _payload: Dictionary) -> void:
	match str(topic):
		"time.new_day":
			_triggered_today = false
		_:
			pass

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _notify(text: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
		return
	print(text)
