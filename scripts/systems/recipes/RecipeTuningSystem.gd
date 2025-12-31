extends Node
class_name RecipeTuningSystem
# Autoload neve: RecipeTuningSystem1

const SAVE_KEY := "recipe_tuning_v1"
const SAVE_KEY_OPINION := "public_opinion_v1"
const ALAP_ITAL_ML := 300

var _configok: Dictionary = {}
var _public_opinion: float = 0.0
var _rng := RandomNumberGenerator.new()
var _utolso_pletyka_perc: int = -999999
var _utolso_global_szorzo: float = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_betolt_adatok()
	ensure_seed_for_owned_recipes()

func ensure_seed_for_owned_recipes() -> void:
	var owned = get_owned_recipes()
	if owned.is_empty():
		return
	for rid_any in owned:
		var rid = str(rid_any).strip_edges()
		if rid == "":
			continue
		var cfg_any = _configok.get(rid, {})
		var cfg = cfg_any if cfg_any is Dictionary else {}
		var uj = cfg.duplicate(true)
		var alap = _recept_alapadat(rid)
		if not uj.has("enabled"):
			uj["enabled"] = true
		var alap_ar = int(alap.get("sell_price", 0))
		if alap_ar > 0 and not uj.has("price_ft"):
			uj["price_ft"] = alap_ar
		if _alap_ital_ml(alap) > 0 and (not uj.has("portion_ml") or int(uj.get("portion_ml", 0)) <= 0):
			uj["portion_ml"] = ALAP_ITAL_ML
		if _alap_ital_ml(alap) <= 0 and (not uj.has("portion_g") or int(uj.get("portion_g", 0)) <= 0):
			var alap_g = _alap_ossz_gramm(alap)
			if alap_g > 0:
				uj["portion_g"] = alap_g
		if uj != cfg:
			_configok[rid] = uj
			_mentes(rid)

func get_owned_recipes() -> Array:
	var konyha = _konyha()
	if konyha == null or not konyha.has("_owned_recipes"):
		return []
	var owned_any = konyha._owned_recipes
	var owned = owned_any if owned_any is Dictionary else {}
	var lista: Array = []
	for rid in owned.keys():
		lista.append(str(rid))
	lista.sort()
	return lista

func is_recipe_enabled(recipe_id: String) -> bool:
	var cfg = get_recipe_config(recipe_id)
	return bool(cfg.get("enabled", false))

func get_active_recipes() -> Array:
	var lista: Array = []
	for rid in get_owned_recipes():
		if is_recipe_enabled(rid):
			lista.append(rid)
	return lista

func get_recipe_config(recipe_id: String) -> Dictionary:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return {}
	var alap = _recept_alapadat(rid)
	var cfg_any = _configok.get(rid, {})
	var cfg = cfg_any if cfg_any is Dictionary else {}
	var enabled_alap = _alap_enabled(rid, alap)
	var price_alap = int(alap.get("sell_price", 0))
	var portion_alap = _alap_ital_ml(alap)
	var portion_g_alap = _aktualis_ossz_gramm(rid, alap)
	return {
		"id": rid,
		"enabled": bool(cfg.get("enabled", enabled_alap)),
		"price_ft": int(cfg.get("price_ft", price_alap)),
		"portion_ml": int(cfg.get("portion_ml", portion_alap)),
		"portion_g": int(cfg.get("portion_g", portion_g_alap)),
		"ingredients_override": cfg.get("ingredients_override", {}).duplicate(true)
	}

func get_recipe_label(recipe_id: String) -> String:
	var alap = _recept_alapadat(recipe_id)
	var nev = str(alap.get("name", "")).strip_edges()
	if nev == "":
		return str(recipe_id)
	return nev

func get_recipe_type(recipe_id: String) -> String:
	var alap = _recept_alapadat(recipe_id)
	return str(alap.get("type", "")).to_lower()

func get_recipe_output_portions(recipe_id: String) -> int:
	var alap = _recept_alapadat(recipe_id)
	return int(alap.get("output_portions", 1))

func get_recipe_portion_ml(recipe_id: String) -> int:
	return int(get_recipe_config(recipe_id).get("portion_ml", ALAP_ITAL_ML))

func get_recipe_portion_g(recipe_id: String) -> int:
	return int(get_recipe_config(recipe_id).get("portion_g", 0))

func get_recipe_price(recipe_id: String) -> int:
	return int(get_recipe_config(recipe_id).get("price_ft", 0))

func get_effective_price(recipe_id: String) -> int:
	var rid_input = str(recipe_id).strip_edges()
	if rid_input == "":
		return 0
	var rid = _rendeles_recept_id(rid_input)
	var cfg_any = _configok.get(rid, {})
	var cfg = cfg_any if cfg_any is Dictionary else {}
	if cfg.has("price_ft"):
		return int(cfg.get("price_ft", 0))
	var alap_ar = _recept_alap_ar(rid)
	if alap_ar <= 0:
		_log_hianyzo_ar(rid_input)
	return max(alap_ar, 0)

func get_recipe_ingredients(recipe_id: String) -> Array:
	var alap = _recept_alapadat(recipe_id)
	var lista_any = alap.get("ingredients", [])
	var lista: Array = []
	if lista_any is Array:
		for ing_any in lista_any:
			var ing = ing_any if ing_any is Dictionary else {}
			var id = str(ing.get("item_id", "")).strip_edges()
			if id == "":
				continue
			var alap_ertek = int(ing.get("g", 0))
			var aktualis = get_recipe_ingredient_amount(recipe_id, id, alap_ertek, "g")
			lista.append({
				"id": id,
				"unit": "g",
				"base": alap_ertek,
				"amount": aktualis
			})
	return lista

func get_recipe_ingredient_amount(recipe_id: String, ingredient_id: String, alap_ertek: int, unit: String) -> int:
	var rid = str(recipe_id).strip_edges()
	var iid = str(ingredient_id).strip_edges()
	if rid == "" or iid == "":
		return int(alap_ertek)
	var cfg_any = _configok.get(rid, {})
	var cfg = cfg_any if cfg_any is Dictionary else {}
	var overrides_any = cfg.get("ingredients_override", {})
	var overrides = overrides_any if overrides_any is Dictionary else {}
	var entry_any = overrides.get(iid, {})
	var entry = entry_any if entry_any is Dictionary else {}
	if entry.is_empty():
		return int(alap_ertek)
	var unit_cfg = str(entry.get("unit", unit))
	if unit_cfg != unit:
		return int(alap_ertek)
	return int(entry.get("amount", alap_ertek))

func set_recipe_enabled(recipe_id: String, enabled: bool) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	var cfg = _config_or_create(rid)
	cfg["enabled"] = bool(enabled)
	_configok[rid] = cfg
	_mentes(rid)

func set_recipe_price(recipe_id: String, price_ft: int) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	var cfg = _config_or_create(rid)
	cfg["price_ft"] = max(int(price_ft), 0)
	_configok[rid] = cfg
	_mentes(rid)

func set_recipe_portion_ml(recipe_id: String, portion_ml: int) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	var cfg = _config_or_create(rid)
	cfg["portion_ml"] = max(int(portion_ml), 50)
	_configok[rid] = cfg
	_mentes(rid)

func set_recipe_portion_g(recipe_id: String, portion_g: int) -> void:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return
	var alap = _recept_alapadat(rid)
	var alap_g = _alap_ossz_gramm(alap)
	if alap_g <= 0:
		return
	var cel = max(int(portion_g), 10)
	var szorzo = float(cel) / float(alap_g)
	var overrides: Dictionary = {}
	var lista_any = alap.get("ingredients", [])
	if lista_any is Array:
		for ing_any in lista_any:
			var ing = ing_any if ing_any is Dictionary else {}
			var id = str(ing.get("item_id", "")).strip_edges()
			if id == "":
				continue
			var alap_ertek = int(ing.get("g", 0))
			var uj = max(int(round(float(alap_ertek) * szorzo)), 1)
			overrides[id] = {
				"amount": uj,
				"unit": "g"
			}
	var cfg = _config_or_create(rid)
	cfg["portion_g"] = cel
	cfg["ingredients_override"] = overrides
	_configok[rid] = cfg
	_mentes(rid)

func set_recipe_ingredient_amount(recipe_id: String, ingredient_id: String, amount: int, unit: String) -> void:
	var rid = str(recipe_id).strip_edges()
	var iid = str(ingredient_id).strip_edges()
	if rid == "" or iid == "":
		return
	var cfg = _config_or_create(rid)
	var overrides_any = cfg.get("ingredients_override", {})
	var overrides = overrides_any if overrides_any is Dictionary else {}
	var uj = max(int(amount), 0)
	if uj <= 0:
		overrides.erase(iid)
	else:
		overrides[iid] = {
			"amount": uj,
			"unit": unit
		}
	cfg["ingredients_override"] = overrides
	_configok[rid] = cfg
	_mentes(rid)

func get_recipe_popularity(recipe_id: String) -> int:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return 50
	var alap = _recept_alapadat(rid)
	var cfg = get_recipe_config(rid)
	var pont = 60
	var alap_ar = int(alap.get("sell_price", 0))
	var ar = int(cfg.get("price_ft", alap_ar))
	if alap_ar > 0:
		var ratio = float(ar) / float(alap_ar)
		if ratio > 1.0:
			pont -= int(min((ratio - 1.0) * 50.0, 30.0))
		else:
			pont += int(min((1.0 - ratio) * 40.0, 20.0))
	var tipus = str(alap.get("type", "")).to_lower()
	if tipus == "drink":
		var base_ml = _alap_ital_ml(alap)
		var ml = int(cfg.get("portion_ml", base_ml))
		if base_ml > 0:
			var ml_ratio = float(ml) / float(base_ml)
			if ml_ratio < 1.0:
				pont -= int(min((1.0 - ml_ratio) * 40.0, 20.0))
			else:
				pont += int(min((ml_ratio - 1.0) * 25.0, 10.0))
	else:
		var base_sum = _alap_ossz_gramm(alap)
		var aktualis_sum = _aktualis_ossz_gramm(rid, alap)
		if base_sum > 0:
			var gram_ratio = float(aktualis_sum) / float(base_sum)
			if gram_ratio < 1.0:
				pont -= int(min((1.0 - gram_ratio) * 40.0, 20.0))
			else:
				pont += int(min((gram_ratio - 1.0) * 25.0, 10.0))
	return clamp(pont, 0, 100)

func get_popularity_badge(score: int) -> String:
	if score >= 80:
		return "🔥"
	if score >= 60:
		return "🙂"
	if score >= 40:
		return "😐"
	if score >= 20:
		return "😬"
	return "❌"

func get_popularity_label(score: int) -> String:
	if score >= 80:
		return "🔥 Kiemelkedő"
	if score >= 60:
		return "🙂 Jó"
	if score >= 40:
		return "😐 Közepes"
	if score >= 20:
		return "😬 Drága/spórolós"
	return "❌ Lehúzás"

func get_popularity_effect_text(score: int) -> String:
	var szorzo = _popularity_to_multiplier(score)
	var pletyka = _pletyka_szoveg(score)
	var trend = _falusi_trend(score)
	return "Vendégszorzó: %.2f | Pletyka: %s | Falusiak: %s" % [szorzo, pletyka, trend]

func get_global_popularity_multiplier() -> float:
	return get_demand_multiplier()

func get_public_opinion() -> float:
	return _public_opinion

func get_demand_multiplier() -> float:
	var szorzo = clamp(1.0 + _public_opinion / 200.0, 0.5, 1.5)
	_log_global_szorzo(szorzo)
	return szorzo

func get_public_opinion_label() -> String:
	if _public_opinion >= 40.0:
		return "Kifejezetten pozitív"
	if _public_opinion >= 10.0:
		return "Pozitív"
	if _public_opinion >= -10.0:
		return "Semleges"
	if _public_opinion >= -40.0:
		return "Negatív"
	return "Kifejezetten negatív"

func get_public_opinion_trend() -> String:
	var szorzo = get_demand_multiplier()
	if szorzo >= 1.1:
		return "↗"
	if szorzo <= 0.9:
		return "↘"
	return "—"

func get_public_opinion_effect_text() -> String:
	return "Vendégszorzó: %.2f | Hatás: %s" % [get_demand_multiplier(), get_public_opinion_trend()]

func register_served_order(order_id: String, order_price: int) -> void:
	var rid = _rendeles_recept_id(order_id)
	var alap_ar = _recept_alap_ar(rid)
	var aktualis_ar = _recept_aktualis_ar(rid, order_price)
	var delta = 0.0
	if alap_ar > 0:
		var arany = float(aktualis_ar) / float(alap_ar)
		if arany <= 1.0:
			delta += 0.4
		elif arany <= 1.2:
			delta += 0.1
		else:
			delta -= 0.4
	var atlag_arany = _atlag_arany()
	if atlag_arany > 1.15:
		delta -= 0.2
	elif atlag_arany < 0.95:
		delta += 0.1
	if delta != 0.0:
		_hozzaad_kozelem(delta)

func register_no_service(order_id: String) -> void:
	if str(order_id).strip_edges() == "":
		return
	_hozzaad_kozelem(-0.6)

func apply_order_effects() -> void:
	var _dummy = get_demand_multiplier()

# -------------------- BELSŐ SEGÉDEK --------------------

func _config_or_create(rid: String) -> Dictionary:
	var cfg_any = _configok.get(rid, {})
	var cfg = cfg_any if cfg_any is Dictionary else {}
	return cfg

func _mentes(rid: String) -> void:
	var gs = _game_state()
	if gs != null and gs.has_method("set_data"):
		gs.call("set_data", SAVE_KEY, _configok.duplicate(true))
		gs.call("set_data", SAVE_KEY_OPINION, _public_opinion)
	var gd = _game_data()
	if gd != null:
		if gd.has_method("set_recipe_tuning"):
			gd.call("set_recipe_tuning", _configok.duplicate(true))
		if gd.has_method("set_public_opinion"):
			gd.call("set_public_opinion", _public_opinion)
	var cfg = get_recipe_config(rid)
	print("[RECIPE_TUNE] mentés id=%s aktív=%s ár=%d adag_ml=%d" % [rid, str(cfg.get("enabled", false)), int(cfg.get("price_ft", 0)), int(cfg.get("portion_ml", 0))])
	_frissit_rendelesek()

func _betolt_adatok() -> void:
	var betoltve = false
	var gd = _game_data()
	if gd != null:
		if gd.has_method("get_recipe_tuning"):
			var adat_any = gd.call("get_recipe_tuning")
			var adat = adat_any if adat_any is Dictionary else {}
			if not adat.is_empty():
				_configok = adat.duplicate(true)
				betoltve = true
		if gd.has_method("get_public_opinion"):
			_public_opinion = float(gd.call("get_public_opinion"))
	if not betoltve:
		_betolt_game_state()
	_public_opinion = clamp(_public_opinion, -100.0, 100.0)

func _betolt_game_state() -> void:
	var gs = _game_state()
	if gs == null or not gs.has_method("get_data"):
		return
	var adat_any = gs.call("get_data", SAVE_KEY, {})
	var adat = adat_any if adat_any is Dictionary else {}
	_configok = adat.duplicate(true)
	_public_opinion = float(gs.call("get_data", SAVE_KEY_OPINION, 0.0))

func _game_state() -> Node:
	if typeof(GameState1) != TYPE_NIL and GameState1 != null:
		return GameState1
	return get_tree().root.get_node_or_null("GameState1")

func _konyha() -> Node:
	if typeof(KitchenSystem1) != TYPE_NIL and KitchenSystem1 != null:
		return KitchenSystem1
	return get_tree().root.get_node_or_null("KitchenSystem1")

func _game_data() -> Node:
	if typeof(GameData1) != TYPE_NIL and GameData1 != null:
		return GameData1
	return get_tree().root.get_node_or_null("GameData1")

func _recept_alapadat(recipe_id: String) -> Dictionary:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return {}
	var konyha = _konyha()
	if konyha != null and konyha.has("_recipes"):
		var rec_any = konyha._recipes
		var rec = rec_any if rec_any is Dictionary else {}
		var adat_any = rec.get(rid, {})
		return adat_any if adat_any is Dictionary else {}
	var gd = get_tree().root.get_node_or_null("GameData1")
	if gd != null and gd.has_method("get_recipes"):
		var rec2_any = gd.call("get_recipes")
		var rec2 = rec2_any if rec2_any is Dictionary else {}
		var adat2_any = rec2.get(rid, {})
		return adat2_any if adat2_any is Dictionary else {}
	return {}

func _alap_enabled(rid: String, alap: Dictionary) -> bool:
	if alap.is_empty():
		return false
	var konyha = _konyha()
	if konyha != null and konyha.has_method("owns_recipe"):
		return bool(konyha.call("owns_recipe", rid))
	return bool(alap.get("unlocked", false))

func _alap_ital_ml(alap: Dictionary) -> int:
	var tipus = str(alap.get("type", "")).to_lower()
	if tipus == "drink":
		return ALAP_ITAL_ML
	return 0

func _alap_ossz_gramm(alap: Dictionary) -> int:
	var osszeg = 0
	var lista_any = alap.get("ingredients", [])
	if lista_any is Array:
		for ing_any in lista_any:
			var ing = ing_any if ing_any is Dictionary else {}
			osszeg += int(ing.get("g", 0))
	return osszeg

func _aktualis_ossz_gramm(rid: String, alap: Dictionary) -> int:
	var osszeg = 0
	var lista_any = alap.get("ingredients", [])
	if lista_any is Array:
		for ing_any in lista_any:
			var ing = ing_any if ing_any is Dictionary else {}
			var id = str(ing.get("item_id", ""))
			var alap_g = int(ing.get("g", 0))
			osszeg += get_recipe_ingredient_amount(rid, id, alap_g, "g")
	return osszeg

func _popularity_to_multiplier(score: float) -> float:
	var t = clamp(float(score) / 100.0, 0.0, 1.0)
	return lerp(0.7, 1.2, t)

func _pletyka_szoveg(score: int) -> String:
	if score >= 70:
		return "Alacsony"
	if score >= 40:
		return "Közepes"
	return "Magas"

func _falusi_trend(score: int) -> String:
	if score >= 70:
		return "↗"
	if score >= 40:
		return "—"
	return "↘"

func _pletyka_ellenorzes(szorzo: float) -> void:
	var perc = _jatek_perc()
	if perc - _utolso_pletyka_perc < 120:
		return
	var rossz = _van_rossz_recept()
	var esely = 0.0
	if szorzo < 0.9:
		esely = max(esely, 0.04)
	if rossz:
		esely = max(esely, 0.08)
	if esely <= 0.0:
		return
	if _rng.randf() > esely:
		return
	_utolso_pletyka_perc = perc
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", "🗣️ Pletyka terjed a fogadó minőségéről...")

func _falusi_reputacio_frissit(szorzo: float) -> void:
	var delta = 0
	if szorzo >= 1.05:
		if _rng.randf() <= 0.1:
			delta = 1
	elif szorzo <= 0.9:
		if _rng.randf() <= 0.1:
			delta = -1
	if delta == 0:
		return
	var fs = get_tree().root.get_node_or_null("FactionSystem1")
	if fs != null and fs.has_method("add_faction_value"):
		fs.call("add_faction_value", "villagers", delta, "receptek közvéleménye")

func _van_rossz_recept() -> bool:
	for rid in get_active_recipes():
		if get_recipe_popularity(rid) < 20:
			return true
	return false

func _jatek_perc() -> int:
	if typeof(TimeSystem1) != TYPE_NIL and TimeSystem1 != null and TimeSystem1.has_method("get_game_minutes"):
		return int(TimeSystem1.get_game_minutes())
	return int(Time.get_ticks_msec() / 60000)

func _frissit_rendelesek() -> void:
	var spawner = get_tree().root.get_node_or_null("Main/WorldRoot/TavernWorld/GuestSpawner")
	if spawner == null:
		spawner = get_tree().root.get_node_or_null("/root/Main/TavernWorld/GuestSpawner")
	if spawner != null and spawner.has_method("_epit_rendeles_lista"):
		spawner.call("_epit_rendeles_lista")

func _log_global_szorzo(szorzo: float) -> void:
	if abs(_utolso_global_szorzo - szorzo) < 0.01:
		return
	_utolso_global_szorzo = szorzo
	print("[RECIPE_TUNE] globális vendégszorzó=%.2f" % szorzo)

func _log_hianyzo_ar(recipe_id: String) -> void:
	if not OS.is_debug_build():
		return
	print("[PRICE_FIX] hiányzó ár id=%s" % recipe_id)

func _hozzaad_kozelem(delta: float) -> void:
	if delta == 0.0:
		return
	var elozo = _public_opinion
	_public_opinion = clamp(_public_opinion + delta, -100.0, 100.0)
	if abs(_public_opinion - elozo) < 0.01:
		return
	var gs = _game_state()
	if gs != null and gs.has_method("set_data"):
		gs.call("set_data", SAVE_KEY_OPINION, _public_opinion)
	var gd = _game_data()
	if gd != null and gd.has_method("set_public_opinion"):
		gd.call("set_public_opinion", _public_opinion)

func _atlag_arany() -> float:
	var aktiv = get_active_recipes()
	if aktiv.is_empty():
		return 1.0
	var osszeg = 0.0
	var darab = 0
	for rid in aktiv:
		var alap_ar = _recept_alap_ar(str(rid))
		if alap_ar <= 0:
			continue
		var aktualis = get_recipe_price(str(rid))
		osszeg += float(aktualis) / float(alap_ar)
		darab += 1
	if darab <= 0:
		return 1.0
	return osszeg / float(darab)

func _rendeles_recept_id(order_id: String) -> String:
	var id = str(order_id).strip_edges()
	if id == "":
		return ""
	var konyha = _konyha()
	if konyha != null and konyha.has("_recipes"):
		var rec_any = konyha._recipes
		var rec = rec_any if rec_any is Dictionary else {}
		if rec.has(id):
			return id
		for rid in rec.keys():
			var adat_any = rec.get(rid, {})
			var adat = adat_any if adat_any is Dictionary else {}
			var out_any = adat.get("output", {})
			var out = out_any if out_any is Dictionary else {}
			var out_id = str(out.get("id", adat.get("id", rid))).strip_edges()
			if out_id == id:
				return str(rid)
	return id

func _recept_alap_ar(recipe_id: String) -> int:
	var alap = _recept_alapadat(recipe_id)
	return int(alap.get("sell_price", 0))

func _recept_aktualis_ar(recipe_id: String, order_price: int) -> int:
	var rid = str(recipe_id).strip_edges()
	if rid != "":
		return int(get_recipe_price(rid))
	return int(order_price)
