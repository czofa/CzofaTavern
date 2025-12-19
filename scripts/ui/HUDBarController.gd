extends Node

@export var time_label_path: NodePath = ^"TimeLabel"
@export var money_label_path: NodePath = ^"MoneyLabel"
@export var stock_label_path: NodePath = ^"StockLabel"

var _time_label: Label
var _money_label: Label
var _stock_label: Label

func _ready() -> void:
	print("🟢 HUDBarController READY")

	_time_label = get_node_or_null(time_label_path)
	_money_label = get_node_or_null(money_label_path)
	_stock_label = get_node_or_null(stock_label_path)

	if _time_label == null:
		push_error("❌ Nem található a TimeLabel: %s" % time_label_path)
	if _money_label == null:
		push_error("❌ Nem található a MoneyLabel: %s" % money_label_path)
	if _stock_label == null:
		push_error("❌ Nem található a StockLabel: %s" % stock_label_path)

	set_process(true)

func _process(_delta: float) -> void:
	_update_time()
	_update_money()
	_update_stock()

func _update_time() -> void:
	if _time_label == null:
		return

	var total_minutes: int = int(TimeSystem1.get_game_minutes())
	var hour: int = total_minutes / 60
	var minute: int = total_minutes - (hour * 60)

	_time_label.text = "%02d:%02d" % [hour, minute]

func _update_money() -> void:
	if _money_label == null:
		return

	var money: int = EconomySystem1._get_money()
	_money_label.text = "💰 %d Ft" % money

func _update_stock() -> void:
	if _stock_label == null:
		return

	var text := "📦 Készlet:\n"
	var keys := StockSystem1.stock.keys()
	keys.sort()

	for item in keys:
		var qty := StockSystem1.get_qty(item)
		text += "- %s: %d\n" % [item, qty]

	_stock_label.text = text.strip_edges()
