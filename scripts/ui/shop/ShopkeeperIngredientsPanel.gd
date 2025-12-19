extends Control

@export var buttons_container_path: NodePath = ^"VBoxContainer"
@export var button_back_path: NodePath = ^"VBoxContainer/ButtonBack"

@onready var _container: VBoxContainer = get_node(buttons_container_path)
@onready var _btn_back: Button = get_node(button_back_path)

var _btn_lista: Array = []

func _ready() -> void:
	_epit_gombok()
	_btn_back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	visible = false
	_toast("🔙 Visszaléptél")

func _epit_gombok() -> void:
	if _container == null:
		push_error("❌ ShopkeeperIngredientsPanel: a gomb konténer nem található.")
		return
	_torli_regi_gombok()
	var termekek = _osszefoglalo_termekek()
	for adat in termekek:
		var btn = Button.new()
		btn.text = _gomb_felirat(adat)
		btn.pressed.connect(_on_buy_pressed.bind(adat))
		_container.add_child(btn)
		_btn_lista.append(btn)
	if _btn_back != null:
		_container.move_child(_btn_back, _container.get_child_count() - 1)

func _torli_regi_gombok() -> void:
	for child in _container.get_children():
		if child is Button and child != _btn_back:
			child.queue_free()
	for b in _btn_lista:
		if is_instance_valid(b):
			b.queue_free()
	_btn_lista.clear()

func _gomb_felirat(adat: Dictionary) -> String:
	var item = String(adat.get("id", ""))
	var qty = int(adat.get("qty", 0))
	var ar = int(adat.get("price", 0))
	return "%s – %d g (%d Ft)" % [item, qty, ar]

func _osszefoglalo_termekek() -> Array:
	var termekek: Array = []
	var arak: Dictionary = {
		"bread": 1200,
		"potato": 600,
		"sausage": 4500,
		"beer": 2000
	}
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	var alapanyagok: Dictionary = {}
	if kitchen != null and kitchen.has("_recipes"):
		var recipes_any = kitchen._recipes
		var recipes: Dictionary = recipes_any if recipes_any is Dictionary else {}
		for rid in recipes.keys():
			var adat_any = recipes.get(rid, {})
			var adat: Dictionary = adat_any if adat_any is Dictionary else {}
			var inputs_any = adat.get("inputs", {})
			var inputs: Dictionary = inputs_any if inputs_any is Dictionary else {}
			for kulcs in inputs.keys():
				var id = String(kulcs).strip_edges()
				if id == "":
					continue
				alapanyagok[id] = true
	if alapanyagok.is_empty():
		alapanyagok["bread"] = true
		alapanyagok["potato"] = true
		alapanyagok["sausage"] = true
	_alap_bolt_lista(termekek, alapanyagok.keys(), arak)
	var mar_hozzaadva: Dictionary = {}
	for t in termekek:
		var iid = String(t.get("id", ""))
		if iid != "":
			mar_hozzaadva[iid] = true
	if not mar_hozzaadva.has("beer"):
		termekek.append({
			"id": "beer",
			"qty": 1000,
			"price": int(arak.get("beer", 2000))
		})
	return termekek

func _alap_bolt_lista(termekek: Array, alapanyag_lista: Array, arak: Dictionary) -> void:
	for item_any in alapanyag_lista:
		var id = String(item_any).strip_edges()
		if id == "":
			continue
		termekek.append({
			"id": id,
			"qty": 1000,
			"price": int(arak.get(id, 1500))
		})

func _on_buy_pressed(adat: Dictionary) -> void:
	var id = String(adat.get("id", "")).strip_edges()
	var qty = int(adat.get("qty", 0))
	var ar = int(adat.get("price", 0))
	if id == "" or qty <= 0:
		push_warning("❌ Hiányzó termék adat, vásárlás megszakítva.")
		return
	_buy_ingredient(id, qty, ar)

func _buy_ingredient(item: String, qty_grams: int, package_price: int) -> void:
	var safe_item = str(item).strip_edges()
	var safe_qty_grams = int(qty_grams)
	var safe_package_price = max(int(package_price), 0)
	var unit_price = _egysegar_gramonkent(safe_package_price, safe_qty_grams)
	var payload: Dictionary = {
		"item": safe_item,
		"qty": safe_qty_grams if safe_qty_grams > 0 else 0,
		"unit_price": unit_price,
		"total_price": safe_package_price
	}
	if payload["item"] == "" or payload["qty"] <= 0:
		print("[SHOP_FIX] Hiányzó vagy hibás termékadat: %s" % safe_item)
		return
	print("[SHOP_ITEMS] bought=", safe_item, " qty_g=", safe_qty_grams)
	print("[SHOP_QTY] termék: %s, gramm: %d, csomagár: %d Ft" % [safe_item, payload["qty"], safe_package_price])
	_elokeszit_konyhai_buffer(safe_item, unit_price)
	# 1. Levonás gazdasági rendszerből
	_bus("economy.buy", payload)

	# 2. Visszajelzés
	_toast("✅ Vásároltál: %d g %s (könyvelés szükséges)" % [safe_qty_grams, item])

func _toast(msg: String) -> void:
	var eb = _eb()
	if eb:
		eb.emit_signal("notification_requested", msg)

func _bus(topic: String, payload: Dictionary) -> void:
	var eb = _eb()
	if eb and eb.has_method("bus"):
		eb.call("bus", topic, payload)

func _elokeszit_konyhai_buffer(item_id: String, unit_price: int) -> void:
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen == null:
		return
	if not kitchen.has("stock_unbooked"):
		return
	var forras_any = kitchen.stock_unbooked.get(item_id, {})
	var forras: Dictionary = forras_any if forras_any is Dictionary else {}
	var buffer_adat: Dictionary = {}
	buffer_adat["qty"] = int(forras.get("qty", 0))
	buffer_adat["unit_price"] = int(forras.get("unit_price", unit_price))
	buffer_adat["total_cost"] = int(forras.get("total_cost", 0))
	kitchen.stock_unbooked[item_id] = buffer_adat

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if not eb:
		eb = root.get_node_or_null("EventBus")
	return eb

func _egysegar_gramonkent(csomag_ar: int, mennyiseg_gramm: int) -> int:
	var gramm = max(int(mennyiseg_gramm), 1)
	var osszeg = max(int(csomag_ar), 0)
	var ar = float(osszeg) / float(gramm)
	var kerekitett = int(round(ar))
	if kerekitett < 1:
		return 1
	return kerekitett
