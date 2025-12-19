extends Node

@export var time_label_path: NodePath = ^"TimeLabel"
@export var money_label_path: NodePath = ^"MoneyLabel"
@export var stock_label_path: NodePath = ^"StockLabel"

var _time_label: Label = null
var _money_label: Label = null
var _stock_label: Label = null
var _utolso_keszlet_szoveg: String = ""
var _stock_idozito: float = 0.0
var _stock_frissitesi_intervallum: float = 0.5

func _ready() -> void:
	print("🟢 HUDBarController READY")

	_time_label = get_node_or_null(time_label_path) as Label
	_money_label = get_node_or_null(money_label_path) as Label
	_stock_label = get_node_or_null(stock_label_path) as Label

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
	_stock_idozito += _delta
	if _stock_idozito >= _stock_frissitesi_intervallum:
		_stock_idozito = 0.0
		_update_stock()

func _update_time() -> void:
	if _time_label == null:
		return

	_time_label.text = TimeSystem1.get_game_time_string()

func _update_money() -> void:
	if _money_label == null:
		return

	var money: int = EconomySystem1._get_money()
	_money_label.text = "💰 %d Ft" % money

func _update_stock() -> void:
	if _stock_label == null:
		return

	_stock_label.visible = true

	var tetelek = _ossz_keszlet_kulcsok()
	var text = ""
	if tetelek.is_empty():
		text = "📦 Készlet: (üres)"
	else:
		var sorok: Array = []
		for item in tetelek:
			var gramm: int = _unbooked_grammok(item)
			var adag: int = _adag_konyhaban(item)
			sorok.append("%s: %dg | adag: %d" % [item, gramm, adag])
		text = "📦 Készlet:\n" + "\n".join(sorok)
	if text == _utolso_keszlet_szoveg:
		return
	_utolso_keszlet_szoveg = text
	_stock_label.text = text

func _ossz_keszlet_kulcsok() -> Array:
	var kulcsok: Array = []
	if typeof(StockSystem1) != TYPE_NIL and StockSystem1 != null:
		for id in StockSystem1.get_unbooked_items():
			var safe_id = String(id).strip_edges()
			if safe_id != "" and not kulcsok.has(safe_id):
				kulcsok.append(safe_id)
	if typeof(KitchenSystem1) != TYPE_NIL and KitchenSystem1 != null and KitchenSystem1.has("_portions"):
		var portions_any = KitchenSystem1._portions
		if portions_any is Dictionary:
			for id in portions_any.keys():
				var safe_id_2 = String(id).strip_edges()
				if safe_id_2 != "" and not kulcsok.has(safe_id_2):
					kulcsok.append(safe_id_2)
	kulcsok.sort()
	return kulcsok

func _unbooked_grammok(item: String) -> int:
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return 0
	return StockSystem1.get_unbooked_qty(item)

func _adag_konyhaban(item: String) -> int:
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return 0
	return KitchenSystem1.get_total_portions(item)
