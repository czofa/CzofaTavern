extends Control

const ShopCatalog = preload("res://scripts/shop/ShopCatalog.gd")

@export var categories_container_path: NodePath = ^"MarginContainer/VBox/HBoxContainer/Categories"
@export var items_container_path: NodePath = ^"MarginContainer/VBox/HBoxContainer/ItemsScroll/Items"
@export var close_button_path: NodePath = ^"MarginContainer/VBox/CloseButton"
@export var status_label_path: NodePath = ^"MarginContainer/VBox/StatusLabel"

var _categories_box: VBoxContainer
var _items_box: VBoxContainer
var _btn_close: Button
var _status_label: Label

var _category_buttons: Dictionary = {}
var _active_category: String = ""
var _owned_misc: Dictionary = {}
var _bus_node: Node = null
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var _is_open: bool = false

func _ready() -> void:
	_cache_nodes()
	_connect_bus()
	_epit_kategoriak()
	visibility_changed.connect(_on_visibility_changed)
	hide()

func open_panel() -> void:
	if _is_open:
		return
	visible = true
	_megnyit()

func close_panel() -> void:
	if not _is_open and not visible:
		return
	visible = false
	_bezaras()

func _on_visibility_changed() -> void:
	if visible:
		_megnyit()
	else:
		_bezaras()

func _cache_nodes() -> void:
	_categories_box = get_node_or_null(categories_container_path)
	_items_box = get_node_or_null(items_container_path)
	_btn_close = get_node_or_null(close_button_path)
	_status_label = get_node_or_null(status_label_path)
	if _btn_close != null:
		var cb = Callable(self, "close_panel")
		if not _btn_close.pressed.is_connected(cb):
			_btn_close.pressed.connect(cb)

func _connect_bus() -> void:
	var root = get_tree().root
	_bus_node = root.get_node_or_null("EventBus1")
	if _bus_node == null:
		_bus_node = root.get_node_or_null("EventBus")
	if _bus_node != null and _bus_node.has_signal("request_close_all_popups"):
		var cb = Callable(self, "_on_close_all_requested")
		if not _bus_node.is_connected("request_close_all_popups", cb):
			_bus_node.connect("request_close_all_popups", cb)

func _on_close_all_requested() -> void:
	close_panel()

func _megnyit() -> void:
	if _is_open:
		return
	_is_open = true
	_prev_mouse_mode = Input.mouse_mode
	_bus("input.lock", {"reason": "shop"})
	_refresh_categories()
	_show_category(_active_category)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_toast("Bolt: válassz kategóriát.")

func _bezaras() -> void:
	if not _is_open and not visible:
		return
	_is_open = false
	_bus("input.unlock", {"reason": "shop"})
	if _is_fps_mode():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = _prev_mouse_mode
	_prev_mouse_mode = Input.mouse_mode

func _epit_kategoriak() -> void:
	if _categories_box == null:
		push_warning("❌ Shop panel: hiányzik a kategória konténer.")
		return
	for child in _categories_box.get_children():
		child.queue_free()
	_category_buttons.clear()
	var kategoriak = ShopCatalog.get_categories()
	for adat in kategoriak:
		var cid = str(adat.get("id", "")).strip_edges()
		if cid == "":
			continue
		var btn = Button.new()
		btn.text = str(adat.get("display_name", cid))
		btn.toggle_mode = true
		btn.pressed.connect(_on_category_pressed.bind(cid))
		_categories_box.add_child(btn)
		_category_buttons[cid] = btn
		if _active_category == "":
			_active_category = cid

func _refresh_categories() -> void:
	if _category_buttons.is_empty():
		_epit_kategoriak()
	_update_category_buttons()

func _update_category_buttons() -> void:
	for cid in _category_buttons.keys():
		var btn_any = _category_buttons.get(cid)
		var btn = btn_any if btn_any is Button else null
		if btn != null:
			btn.button_pressed = (cid == _active_category)

func _on_category_pressed(category_id: String) -> void:
	_show_category(category_id)

func _show_category(category_id: String) -> void:
	var cid = str(category_id).strip_edges()
	if cid == "":
		cid = "ingredients"
	_active_category = cid
	_update_category_buttons()
	_render_items_for_category(cid)

func _render_items_for_category(category_id: String) -> void:
	if _items_box == null:
		push_warning("❌ Shop panel: hiányzik a lista konténer.")
		return
	for child in _items_box.get_children():
		child.queue_free()
	if _status_label != null:
		_status_label.text = ""
	if category_id == "sell":
		_render_sell_placeholder()
		return
	var lista = ShopCatalog.get_items_for_category(category_id)
	if lista.is_empty():
		if _status_label != null:
			_status_label.text = "⚠️ Ehhez a kategóriához nincs termék."
		return
	for adat in lista:
		_items_box.add_child(_build_item_row(adat))

func _build_item_row(adat: Dictionary) -> Control:
	var sor = HBoxContainer.new()
	sor.alignment = BoxContainer.ALIGNMENT_BEGIN
	var cimke = Label.new()
	cimke.text = _item_szoveg(adat)
	sor.add_child(cimke)

	var ar_cimke = Label.new()
	ar_cimke.text = _ar_szoveg(adat)
	ar_cimke.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ar_cimke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sor.add_child(ar_cimke)

	var btn = Button.new()
	btn.text = "Vásárlás"
	btn.pressed.connect(_on_buy_pressed.bind(adat, btn))

	if _is_recipe_owned(adat):
		btn.disabled = true
		btn.text = "Már megvan"

	sor.add_child(btn)
	return sor

func _render_sell_placeholder() -> void:
	if _items_box == null:
		return
	var cimke = Label.new()
	cimke.text = "💰 TODO: eladás kezelőpanel"
	_items_box.add_child(cimke)
	var btn = Button.new()
	btn.text = "Jelzés küldése"
	btn.pressed.connect(func(): _toast("ℹ️ Eladás később kerül beépítésre."))
	_items_box.add_child(btn)

func _item_szoveg(adat: Dictionary) -> String:
	var nev = str(adat.get("display", adat.get("id", "Ismeretlen")))
	var tipus = str(adat.get("type", ""))
	if tipus == "ingredient":
		var qty = int(adat.get("qty_g", 0))
		if qty > 0:
			return "%s – %d g" % [nev, qty]
	return nev

func _ar_szoveg(adat: Dictionary) -> String:
	var ar = int(adat.get("price", 0))
	return "%d Ft" % ar

func _on_buy_pressed(adat: Dictionary, button: Button) -> void:
	var tipus = str(adat.get("type", "")).strip_edges()
	match tipus:
		"ingredient":
			_buy_ingredient(adat)
		"recipe":
			_buy_recipe(adat, button)
		_:
			_buy_placeholder(adat)

func _buy_ingredient(adat: Dictionary) -> void:
	var id = str(adat.get("id", "")).strip_edges()
	var qty = int(adat.get("qty_g", 0))
	var price = int(adat.get("price", 0))
	var display = str(adat.get("display", id))
	if id == "" or qty <= 0 or price <= 0:
		_toast("❌ Hiányzó adat, nem sikerült a vásárlás.")
		return
	var unit_price = _egysegar_gramonkent(price, qty)
	_elokeszit_konyhai_buffer(id, unit_price)
	_bus("economy.buy", {
		"item": id,
		"qty": qty,
		"unit_price": unit_price,
		"total_price": price,
		"triggered_by": "button"
	})
	_toast("🛒 Vásárlás: %s +%d g" % [display, qty])

func _buy_recipe(adat: Dictionary, button: Button) -> void:
	var recipe_id = str(adat.get("recipe_id", adat.get("id", ""))).strip_edges()
	var price = int(adat.get("price", 0))
	var display = str(adat.get("display", recipe_id))
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen != null and kitchen.has_method("owns_recipe") and kitchen.call("owns_recipe", recipe_id):
		_toast("✅ Már birtoklod: %s" % display)
		return
	if price <= 0 or recipe_id == "":
		_toast("❌ Hibás recept adat, nem vásárolható.")
		return
	if not _van_eleg_penz(price):
		_toast("❌ Nincs elég pénz a recepthez.")
		return
	_bus("economy.buy_recipe", {
		"id": recipe_id,
		"price": price,
		"reason": "Recept vásárlás"
	})
	if kitchen != null and kitchen.has_method("unlock_recipe"):
		kitchen.call("unlock_recipe", recipe_id)
	if button != null:
		button.disabled = true
		button.text = "Már megvan"
	_toast("📜 Recept feloldva: %s" % display)

func _buy_placeholder(adat: Dictionary) -> void:
	var id = str(adat.get("id", "")).strip_edges()
	var ar = int(adat.get("price", 0))
	var display = str(adat.get("display", id))
	if ar <= 0 or id == "":
		_toast("❌ Hibás termék adat, nem vásárolható.")
		return
	if not _van_eleg_penz(ar):
		_toast("❌ Nincs elég pénz: %d Ft szükséges." % ar)
		return
	_spend_money(ar, "Bolt vásárlás: %s" % display)
	var current = int(_owned_misc.get(id, 0))
	_owned_misc[id] = current + 1
	_toast("✅ Megvásárolva: %s" % display)

func _van_eleg_penz(ar: int) -> bool:
	if typeof(EconomySystem1) == TYPE_NIL or EconomySystem1 == null:
		return false
	if EconomySystem1.has_method("get_money"):
		return int(EconomySystem1.get_money()) >= ar
	return false

func _spend_money(ar: int, reason: String) -> void:
	if typeof(EconomySystem1) != TYPE_NIL and EconomySystem1 != null:
		if EconomySystem1.has_method("add_money"):
			EconomySystem1.add_money(-abs(ar), reason)

func _is_recipe_owned(adat: Dictionary) -> bool:
	var recipe_id = str(adat.get("recipe_id", adat.get("id", ""))).strip_edges()
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen != null and kitchen.has_method("owns_recipe"):
		return bool(kitchen.call("owns_recipe", recipe_id))
	return false

func _toast(msg: String) -> void:
	if _bus_node != null and _bus_node.has_signal("notification_requested"):
		_bus_node.emit_signal("notification_requested", msg)

func _bus(topic: String, payload: Dictionary) -> void:
	if _bus_node != null and _bus_node.has_method("bus"):
		_bus_node.call("bus", topic, payload)

func _elokeszit_konyhai_buffer(item_id: String, unit_price: int) -> void:
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen == null:
		return
	if not kitchen.has("stock_unbooked"):
		return
	var forras_any = kitchen.stock_unbooked.get(item_id, {})
	var forras = forras_any if forras_any is Dictionary else {}
	var buffer_adat: Dictionary = {}
	buffer_adat["qty"] = int(forras.get("qty", 0))
	buffer_adat["unit_price"] = int(forras.get("unit_price", unit_price))
	buffer_adat["total_cost"] = int(forras.get("total_cost", 0))
	kitchen.stock_unbooked[item_id] = buffer_adat

func _egysegar_gramonkent(csomag_ar: int, mennyiseg_gramm: int) -> int:
	var gramm = max(int(mennyiseg_gramm), 1)
	var osszeg = max(int(csomag_ar), 0)
	var ar = float(osszeg) / float(gramm)
	var kerekitett = int(round(ar))
	if kerekitett < 1:
		return 1
	return kerekitett

func _is_fps_mode() -> bool:
	var root = get_tree().root
	var gk = root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true
