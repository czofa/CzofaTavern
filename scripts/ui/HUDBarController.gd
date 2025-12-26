extends Node

@export var time_label_path: NodePath = ^"TimeLabel"
@export var calendar_label_path: NodePath = ^"CalendarLabel"
@export var money_label_path: NodePath = ^"MoneyLabel"
@export var stock_label_path: NodePath = ^"StockLabel"

const _HONAP_NEVEK = [
	"Január",
	"Február",
	"Március",
	"Április",
	"Május",
	"Június",
	"Július",
	"Augusztus",
	"Szeptember",
	"Október",
	"November",
	"December"
]

var _time_label: Label = null
var _calendar_label: Label = null
var _money_label: Label = null
var _stock_label: Label = null

func _ready() -> void:
	_time_label = get_node_or_null(time_label_path) as Label
	_calendar_label = get_node_or_null(calendar_label_path) as Label
	_money_label = get_node_or_null(money_label_path) as Label
	_stock_label = get_node_or_null(stock_label_path) as Label

	if _time_label == null:
		push_error("❌ Nem található a TimeLabel: %s" % time_label_path)
	if _calendar_label == null:
		push_error("❌ Nem található a CalendarLabel: %s" % calendar_label_path)
	if _money_label == null:
		push_error("❌ Nem található a MoneyLabel: %s" % money_label_path)
	if _stock_label != null:
		_stock_label.visible = false
		_stock_label.text = ""

	set_process(true)

func _process(_delta: float) -> void:
	_update_time()
	_update_calendar()
	_update_money()
	_update_keszlet_csend()

func _update_keszlet_csend() -> void:
	if _stock_label == null:
		return
	_stock_label.visible = false
	_stock_label.text = ""

func _update_time() -> void:
	if _time_label == null:
		return

	_time_label.text = TimeSystem1.get_game_time_string()

func _update_calendar() -> void:
	if _calendar_label == null:
		return
	var nap_index = 1
	if typeof(TimeSystem1) != TYPE_NIL and TimeSystem1 != null and TimeSystem1.has_method("get_day"):
		nap_index = int(TimeSystem1.get_day())
	nap_index = max(1, nap_index)
	var nap_evben = ((nap_index - 1) % 120) + 1
	var honap_index = int((nap_evben - 1) / 10)
	if honap_index < 0 or honap_index >= _HONAP_NEVEK.size():
		honap_index = 0
	var nap_honapban = ((nap_evben - 1) % 10) + 1
	var honap_nev = String(_HONAP_NEVEK[honap_index])
	var szezon = "Ismeretlen évszak"
	if typeof(SeasonSystem1) != TYPE_NIL and SeasonSystem1 != null and SeasonSystem1.has_method("get_season_name_hu"):
		szezon = str(SeasonSystem1.call("get_season_name_hu"))
	_calendar_label.text = "%d. nap • %s • %s" % [nap_honapban, szezon, honap_nev]

func _update_money() -> void:
	if _money_label == null:
		return

	var ceges: int = 0
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		ceges = int(EconomySystem1.get_money())
	var magan: int = 0
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		magan = int(gs.call("get_value", "personal_money_ft", 0))

	_money_label.text = "💼 %d Ft | 👤 %d Ft" % [ceges, magan]
