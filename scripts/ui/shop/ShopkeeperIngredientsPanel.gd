extends Control

const ShopCatalog = preload("res://scripts/shop/ShopCatalog.gd")
const CATEGORY_NAMES = {
	"alapanyagok": "🥕 Alapanyagok",
	"receptek": "📜 Receptek",
	"magvak": "🌱 Magvak",
	"állatok": "🐄 Állatok",
	"eszközök": "🪓 Eszközök",
	"kiszolgálóeszközök": "🍽️ Kiszolgálóeszközök",
	"építőanyagok": "🧱 Építőanyagok",
	"terület": "🗺️ Terület",
	"eladás": "💰 Eladás"
}
const FARM_UNLOCK_KEY = "farm_land_level"
const FARM_CONTROLLER_PATH = "Main/WorldRoot/FarmWorld/FarmWorldController"
const LAND_CONTROLLER_PATH = "Main/WorldRoot/FarmWorld/FarmLandController"
const ALAP_SHOP_ID = ShopCatalog.SHOP_SHOPKEEPER_ID

@export var categories_container_path: NodePath = ^"MarginContainer/VBox/HBoxContainer/Categories"
@export var items_container_path: NodePath = ^"MarginContainer/VBox/HBoxContainer/ItemsScroll/Items"
@export var close_button_path: NodePath = ^"MarginContainer/VBox/CloseButton"
@export var status_label_path: NodePath = ^"MarginContainer/VBox/StatusLabel"
@export var shop_id: String = ALAP_SHOP_ID

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
var _shop_cache: Dictionary = {}
var _land_cache: Node = null
var _farm_ctrl_cache: Node = null
var _shop_id: String = ""

func _ready() -> void:
	_shop_id = _normalize_shop_id(shop_id)
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

func set_shop_id(uj_id: String) -> void:
	var cel = _normalize_shop_id(uj_id)
	if cel == "":
		return
	_shop_id = cel
	shop_id = cel
	_shop_cache.clear()
	_active_category = ""
	_epit_kategoriak()

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

func _aktualis_shop_id() -> String:
	if _shop_id == "":
		_shop_id = _normalize_shop_id(shop_id)
	return _shop_id

func _normalize_shop_id(azonosito: String) -> String:
	var cel = str(azonosito).strip_edges()
	if cel == "":
		return ALAP_SHOP_ID
	return cel

func _megnyit() -> void:
	if _is_open:
		return
	_is_open = true
	_shop_id = _aktualis_shop_id()
	_prev_mouse_mode = Input.mouse_mode
	_frissit_adatokat()
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
	var kategoriak = _kategoriak_listaja()
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
	var lista = _termekek_kategoria_szerint(category_id)
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

	var tipus = str(adat.get("type", "")).strip_edges()
	if tipus == "territory":
		_frissit_terulet_gomb(btn, adat)
	elif _is_recipe_owned(adat):
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
	var nev = str(adat.get("display", adat.get("name", adat.get("id", "Ismeretlen"))))
	var tipus = str(adat.get("type", ""))
	if tipus == "ingredient":
		var qty = int(adat.get("qty_g", adat.get("pack_g", 0)))
		if qty > 0:
			return "%s – %d g" % [nev, qty]
	return nev

func _ar_szoveg(adat: Dictionary) -> String:
	var tipus = str(adat.get("type", ""))
	if tipus == "territory":
		var terulet_ar = _kovetkezo_farm_ar(adat)
		if terulet_ar <= 0:
			return "Nincs új szint"
		return "%d Ft" % terulet_ar
	var ar = _szezonal_ar(adat)
	return "%d Ft" % ar

func _on_buy_pressed(adat: Dictionary, button: Button) -> void:
	var tipus = str(adat.get("type", "")).strip_edges()
	match tipus:
		"ingredient":
			_buy_ingredient(adat)
		"recipe":
			_buy_recipe(adat, button)
		"territory":
			_buy_territory(adat, button)
		_:
			_buy_placeholder(adat)

func _buy_ingredient(adat: Dictionary) -> void:
	var id = str(adat.get("id", "")).strip_edges()
	var qty = int(adat.get("qty_g", adat.get("pack_g", 0)))
	var price = _szezonal_ar(adat)
	var display = str(adat.get("display", adat.get("name", id)))
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
	var display = str(adat.get("display", adat.get("name", recipe_id)))
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
	var ar = _szezonal_ar(adat)
	var display = str(adat.get("display", adat.get("name", id)))
	if ar <= 0 or id == "":
		_toast("❌ Hibás termék adat, nem vásárolható.")
		return
	if not _van_eleg_penz(ar):
		_toast("❌ Nincs elég pénz: %d Ft szükséges." % ar)
		return
	_spend_money(ar, "Bolt vásárlás: %s" % display)
	var current = int(_owned_misc.get(id, 0))
	_owned_misc[id] = current + 1
	_jeloles_vasarlas(adat)
	_toast("✅ Megvásárolva: %s" % display)

func _buy_territory(adat: Dictionary, button: Button) -> void:
	var display = str(adat.get("display", adat.get("name", "Farm terület")))
	var allapot = _terulet_allapot(adat)
	if not bool(allapot.get("fejlesztheto", true)):
		_toast("ℹ️ A farm terület már maximális.")
		_frissit_terulet_gomb(button, adat)
		return
	var ar = _kovetkezo_farm_ar(adat)
	if ar <= 0:
		_toast("ℹ️ Nincs további fejlesztési szint.")
		_frissit_terulet_gomb(button, adat)
		return
	var land = _land_controller()
	if land != null and land.has_method("probal_fejleszteni"):
		if not land.call("probal_fejleszteni", "Farm terület vásárlása/fejlesztése a boltban"):
			return
	else:
		if not _van_eleg_penz(ar):
			_toast("❌ Nincs elég pénz: %d Ft szükséges." % ar)
			return
		_spend_money(ar, "Farm terület megvásárlása/fejlesztése")
		_allit_farm_tulajdon()
	_frissit_terulet_gomb(button, adat)
	var uj_allapot = _terulet_allapot(adat)
	var szint = int(uj_allapot.get("szint", -1)) + 1
	if szint < 0:
		szint = 0
	_toast("✅ Farm terület frissítve (szint: %d) – %s" % [szint, display])

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
			return
	var eb = _eb()
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "state.add", {
			"key": "money",
			"delta": -abs(ar),
			"reason": reason
		})

func _szezonal_ar(adat: Dictionary) -> int:
	var alap = int(adat.get("price", 0))
	var id = str(adat.get("id", ""))
	var szorzo = _ar_szorzo(id)
	var vegso = int(round(float(alap) * szorzo))
	if vegso < 1:
		return 1
	return vegso

func _ar_szorzo(item_id: String) -> float:
	var season_node = get_tree().root.get_node_or_null("SeasonSystem1")
	if season_node != null:
		if season_node.has_method("get_price_multiplier"):
			var sz = float(season_node.call("get_price_multiplier", item_id))
			if sz > 0.0:
				return sz
		if season_node.has_method("get_season_modifiers"):
			var mod_any = season_node.call("get_season_modifiers")
			var mod = mod_any if mod_any is Dictionary else {}
			var arak_any = mod.get("price_multipliers", {})
			var arak = arak_any if arak_any is Dictionary else {}
			var kulcs = str(item_id).to_lower()
			var alt_szorzo = float(arak.get(kulcs, 1.0))
			if alt_szorzo > 0.0:
				return alt_szorzo
	return 1.0

func _is_recipe_owned(adat: Dictionary) -> bool:
	var recipe_id = str(adat.get("recipe_id", adat.get("id", ""))).strip_edges()
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen != null and kitchen.has_method("owns_recipe"):
		return bool(kitchen.call("owns_recipe", recipe_id))
	return false

func _game_data() -> Node:
	return get_tree().root.get_node_or_null("GameData1")

func _frissit_adatokat() -> void:
	var gd = _game_data()
	var frissitett: Dictionary = {}
	if gd != null and gd.has_method("get_shop_catalog"):
		var adat_any = gd.call("get_shop_catalog", _aktualis_shop_id())
		if adat_any is Dictionary:
			frissitett = adat_any
	_shop_cache = frissitett
	if not _shop_cache.has(_active_category):
		_active_category = ""
	_category_buttons.clear()
	_epit_kategoriak()

func _kategoriak_listaja() -> Array:
	var lista: Array = []
	if not _shop_cache.is_empty():
		for key in _shop_cache.keys():
			lista.append({
				"id": key,
				"display_name": CATEGORY_NAMES.get(key, key)
			})
	if lista.is_empty():
		lista = ShopCatalog.get_categories(_aktualis_shop_id())
	return lista

func _termekek_kategoria_szerint(category_id: String) -> Array:
	var cid = str(category_id).strip_edges()
	if _shop_cache.has(cid):
		var lista_any = _shop_cache.get(cid, [])
		var lista = lista_any if lista_any is Array else []
		var eredmeny: Array = []
		for adat_any in lista:
			var adat = adat_any if adat_any is Dictionary else {}
			if not bool(adat.get("enabled", true)):
				continue
			eredmeny.append(adat)
		return eredmeny
	return ShopCatalog.get_items_for_category(category_id, _aktualis_shop_id())

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

func _jeloles_vasarlas(adat: Dictionary) -> void:
	var tipus = str(adat.get("type", ""))
	var id = str(adat.get("id", ""))
	if id == "":
		return
	match tipus:
		"building":
			_gs_add("build_owned_%s" % id, 1, "Építési elem vásárlás")
		"tool":
			_gs_add("tool_owned_%s" % id, 1, "Eszköz vásárlás")
		"serving_tool":
			_gs_add("tool_owned_%s" % id, 1, "Eszköz vásárlás")
		_:
			pass

func _gs_add(kulcs: String, delta: int, reason: String) -> void:
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("add_value"):
		gs.call("add_value", kulcs, delta, reason)

func _terulet_allapot(adat: Dictionary) -> Dictionary:
	var land = _land_controller()
	var szint: int = -1
	var van = false
	var fejlesztheto = true
	var kov_ar = int(adat.get("price", 0))
	if land != null:
		if land.has_method("get_szint"):
			szint = int(land.call("get_szint"))
		if land.has_method("van_farm"):
			van = bool(land.call("van_farm"))
		if land.has_method("fejlesztheto"):
			fejlesztheto = bool(land.call("fejlesztheto"))
		if land.has_method("kovetkezo_ar"):
			kov_ar = int(land.call("kovetkezo_ar"))
	else:
		var gs = _gs()
		if gs != null and gs.has_method("get_value"):
			szint = int(gs.call("get_value", FARM_UNLOCK_KEY, -1))
			van = szint >= 0
			fejlesztheto = szint < 0
	var ar_lista_any = adat.get("price_tiers", [])
	var ar_lista = ar_lista_any if ar_lista_any is Array else []
	if ar_lista.size() > 0:
		var idx = clamp(szint + 1, 0, ar_lista.size() - 1)
		if idx >= 0 and idx < ar_lista.size():
			kov_ar = int(ar_lista[idx])
	return {
		"van": van,
		"fejlesztheto": fejlesztheto,
		"kov_ar": kov_ar,
		"szint": szint
	}

func _kovetkezo_farm_ar(adat: Dictionary) -> int:
	var allapot = _terulet_allapot(adat)
	return int(allapot.get("kov_ar", int(adat.get("price", 0))))

func _frissit_terulet_gomb(button: Button, adat: Dictionary) -> void:
	if button == null:
		return
	var allapot = _terulet_allapot(adat)
	var ar = _kovetkezo_farm_ar(adat)
	button.disabled = false
	button.text = "Vásárlás"
	if bool(allapot.get("van", false)):
		button.text = "Fejlesztés"
	if not bool(allapot.get("fejlesztheto", true)) or ar <= 0:
		button.disabled = true
		if ar <= 0:
			button.text = "Nincs fejlesztés"
		else:
			button.text = "Max szint"

func _allit_farm_tulajdon() -> void:
	var gs = _gs()
	if gs != null and gs.has_method("set_value"):
		gs.call("set_value", FARM_UNLOCK_KEY, 0, "Farm terület megvásárlása")
	var land = _land_controller()
	if land != null:
		if land.has_method("get"):
			var jelenlegi_any = land.get("_szint")
			var jelenlegi = -1
			if jelenlegi_any != null:
				jelenlegi = int(jelenlegi_any)
			if jelenlegi < 0:
				land.set("_szint", 0)
		if land.has_method("_alkalmaz_szint"):
			land.call("_alkalmaz_szint")
		if land.has_method("_ment_szint"):
			land.call("_ment_szint")
	var ctrl = _farm_controller()
	if ctrl != null and ctrl.has_method("refresh_after_upgrade"):
		ctrl.call("refresh_after_upgrade")

func _is_territory_owned(adat: Dictionary) -> bool:
	var allapot = _terulet_allapot(adat)
	return bool(allapot.get("van", false))

func _land_controller() -> Node:
	if _land_cache != null and is_instance_valid(_land_cache):
		return _land_cache
	var root = get_tree().root
	_land_cache = root.get_node_or_null(LAND_CONTROLLER_PATH)
	return _land_cache

func _farm_controller() -> Node:
	if _farm_ctrl_cache != null and is_instance_valid(_farm_ctrl_cache):
		return _farm_ctrl_cache
	var root = get_tree().root
	_farm_ctrl_cache = root.get_node_or_null(FARM_CONTROLLER_PATH)
	return _farm_ctrl_cache

func _gs() -> Node:
	return get_tree().root.get_node_or_null("GameState1")

func _eb() -> Node:
	if _bus_node != null and is_instance_valid(_bus_node):
		return _bus_node
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb == null:
		eb = root.get_node_or_null("EventBus")
	_bus_node = eb
	return _bus_node

func _is_fps_mode() -> bool:
	var root = get_tree().root
	var gk = root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode")).to_upper() == "FPS"
	return true
