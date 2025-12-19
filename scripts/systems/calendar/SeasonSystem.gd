extends Node
class_name SeasonSystem
# Autoload: SeasonSystem1 -> res://scripts/systems/calendar/SeasonSystem.gd

const DAYS_PER_SEASON = 30
const SEASONS = ["spring", "summer", "autumn", "winter"]
const DAYS_PER_YEAR = DAYS_PER_SEASON * 4

var _season_nevek: Dictionary = {
	"spring": "Tavasz",
	"summer": "Nyár",
	"autumn": "Ősz",
	"winter": "Tél"
}

var seasonal_price_multiplier: Dictionary = {
	"winter": {
		"beer": 1.1,
		"bread": 0.95
	},
	"summer": {
		"beer": 1.2
	}
}

var seasonal_guest_multiplier: Dictionary = {
	"winter": 0.9,
	"summer": 1.1
}

var _day_index: int = 1
var _day_in_year: int = 1
var _year_index: int = 1
var _season_id: String = "spring"
var _extra_guest_mult_today: float = 1.0

func _ready() -> void:
	_init_from_time()
	_connect_bus()

func _init_from_time() -> void:
	var start_day = 1
	var time_node = get_tree().root.get_node_or_null("TimeSystem1")
	if time_node != null and time_node.has_method("get_day"):
		start_day = int(time_node.call("get_day"))
	on_day_advanced(start_day)

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.new_day":
			on_day_advanced(int(payload.get("day", _day_index + 1)))
		_:
			pass

func on_day_advanced(day_index: int) -> void:
	var elozo_szezon = _season_id
	_frissit_nap_szamlalok(day_index)
	if _season_id != elozo_szezon:
		_jelent_szezonvaltast()

func _frissit_nap_szamlalok(day_index: int) -> void:
	_day_index = max(1, int(day_index))
	var day_zero_index = _day_index - 1
	_day_in_year = (day_zero_index % DAYS_PER_YEAR) + 1
	var szezon_index = int((_day_in_year - 1) / DAYS_PER_SEASON) % SEASONS.size()
	_season_id = String(SEASONS[szezon_index])
	_year_index = int(day_zero_index / DAYS_PER_YEAR) + 1
	_extra_guest_mult_today = 1.0

func _jelent_szezonvaltast() -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		var nev = get_season_name_hu()
		var emoji = _szezon_emoji(_season_id)
		var szoveg = "%s %s kezdődik (Év %d, Nap %d)" % [emoji, nev, _year_index, _day_in_year]
		eb.emit_signal("notification_requested", szoveg)

func get_day_index() -> int:
	return _day_index

func get_day_in_year() -> int:
	return _day_in_year

func get_year_index() -> int:
	return _year_index

func get_season_id() -> String:
	return _season_id

func get_season_name_hu() -> String:
	return String(_season_nevek.get(_season_id, _season_id))

func get_season_modifiers() -> Dictionary:
	var ar_szorzok_any = seasonal_price_multiplier.get(_season_id, {})
	var ar_szorzok = ar_szorzok_any if ar_szorzok_any is Dictionary else {}
	return {
		"season_id": _season_id,
		"guest_multiplier": _aktualis_vendeg_szorzo(),
		"price_multipliers": ar_szorzok
	}

func get_price_multiplier(item_id: String) -> float:
	var ar_szorzok_any = seasonal_price_multiplier.get(_season_id, {})
	var ar_szorzok = ar_szorzok_any if ar_szorzok_any is Dictionary else {}
	var kulcs = str(item_id).to_lower()
	var szorzo = float(ar_szorzok.get(kulcs, 1.0))
	if szorzo <= 0.0:
		szorzo = 1.0
	return szorzo

func add_guest_bonus_for_today(multiplier: float) -> void:
	var m = float(multiplier)
	if m <= 0.0:
		return
	_extra_guest_mult_today *= m

func _aktualis_vendeg_szorzo() -> float:
	var alap = float(seasonal_guest_multiplier.get(_season_id, 1.0))
	var eredmeny = alap * _extra_guest_mult_today
	if eredmeny <= 0.0:
		return 1.0
	return eredmeny

func _szezon_emoji(season_id: String) -> String:
	match season_id:
		"spring":
			return "🌿"
		"summer":
			return "🌞"
		"autumn":
			return "🍂"
		"winter":
			return "❄️"
		_:
			return "🌱"

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")
