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

	var unbooked = _leker_unbooked_keszlet()
	var adagok = _leker_adagok()
	var tetelek = _keszlet_kulcsok(unbooked, adagok)
	var uj_szoveg = ""
	if tetelek.is_empty():
		uj_szoveg = "📦 Készlet: (üres)"
	else:
		var sorok: Array = []
		for item in tetelek:
			var gramm: int = int(unbooked.get(item, 0))
			var adag: int = int(adagok.get(item, 0))
			sorok.append("%s: %dg | adag: %d" % [item, gramm, adag])
		uj_szoveg = "📦 Készlet:\n" + "\n".join(sorok)
	if uj_szoveg == _utolso_keszlet_szoveg:
		return
	_utolso_keszlet_szoveg = uj_szoveg
	_stock_label.text = uj_szoveg

func _keszlet_kulcsok(unbooked: Dictionary, adagok: Dictionary) -> Array:
	var kulcsok: Array = []
	for id in unbooked.keys():
		var safe_id = String(id).strip_edges()
		if safe_id != "" and not kulcsok.has(safe_id):
			kulcsok.append(safe_id)
	for adag_id in adagok.keys():
		var safe_id_2 = String(adag_id).strip_edges()
		if safe_id_2 != "" and not kulcsok.has(safe_id_2):
			kulcsok.append(safe_id_2)
	kulcsok.sort()
	return kulcsok

func _leker_unbooked_keszlet() -> Dictionary:
	var eredmeny: Dictionary = {}
	if typeof(StockSystem1) == TYPE_NIL or StockSystem1 == null:
		return eredmeny
	var tetelek = StockSystem1.get_unbooked_items()
	for t in tetelek:
		var kulcs = String(t).strip_edges()
		if kulcs == "":
			continue
		eredmeny[kulcs] = StockSystem1.get_unbooked_qty(kulcs)
	return eredmeny

func _leker_adagok() -> Dictionary:
	var eredmeny: Dictionary = {}
	if typeof(KitchenSystem1) == TYPE_NIL or KitchenSystem1 == null:
		return eredmeny
	var portions_any = KitchenSystem1.get("_portions")
	if portions_any is Dictionary:
		for kulcs_any in portions_any.keys():
			var kulcs = String(kulcs_any).strip_edges()
			if kulcs == "":
				continue
			var osszes = 0
			if KitchenSystem1.has_method("get_total_portions"):
				osszes = int(KitchenSystem1.call("get_total_portions", kulcs))
			else:
				var adat_any = portions_any.get(kulcs_any, {})
				var adat = adat_any if adat_any is Dictionary else {}
				osszes = int(adat.get("total", 0))
			eredmeny[kulcs] = osszes
	return eredmeny
