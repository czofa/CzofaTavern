extends Node3D
class_name GuestSpawner

@export var guest_scene: PackedScene
@export var spawn_point_path: NodePath = ^"../TavernNav/SpawnPoint"
@export var target_point_path: NodePath = ^"../TavernNav/TargetPoint"
@export var queue_system_path: NodePath = ^"../GuestQueueSystem"
@export var spawn_interval: float = 6.0
@export var max_guests: int = 4
@export var debug_toast: bool = false

var _spawn_point: Node3D
var _target_point: Node3D
var _queue_system: Node
var _aktiv_vendegek: Array = []
var _ido_meres: float = 0.0
var _rendelesek: Array = []

func _ready() -> void:
	_cache_nodes()
	_epit_rendeles_lista()
	set_process(true)

func _process(delta: float) -> void:
	_takarit_aktiv_lista()

	if guest_scene == null or spawn_interval <= 0.0:
		return
	if _aktiv_vendegek.size() >= max_guests:
		return

	_ido_meres += _jatek_ido_delta(delta)
	var cel_intervallum = spawn_interval
	var vendeg_szorzo = _vendeg_spawn_szorzo()
	if vendeg_szorzo > 0.0:
		cel_intervallum = spawn_interval / vendeg_szorzo
	if _ido_meres < cel_intervallum:
		return

	_ido_meres = 0.0
	_spawn_guest()

func get_active_guests() -> Array:
	_takarit_aktiv_lista()
	return _aktiv_vendegek.duplicate()

func _spawn_guest() -> void:
	var seat_manager = _get_seat_manager()
	var cel_szek: Node3D = null
	if seat_manager != null and seat_manager.has_method("find_free_seat"):
		cel_szek = seat_manager.call("find_free_seat")

	if cel_szek == null:
		_log("[GUEST_SPAWN] Nincs szabad szék, spawn kihagyva.")
		return

	var guest = guest_scene.instantiate() as Node3D
	if guest == null:
		push_error("[GUEST_SPAWN] ❌ Guest prefab nem példányosítható.")
		return

	_regisztral_guest(guest)
	_elhelyez_guest(guest)

	if seat_manager != null and seat_manager.has_method("reserve_seat"):
		seat_manager.call("reserve_seat", cel_szek, guest)

	if guest.has_method("set_seat_target"):
		guest.call("set_seat_target", cel_szek)

	if _queue_system != null and _queue_system.has_method("register_guest"):
		_queue_system.call("register_guest", guest, cel_szek)
	elif guest.has_method("set_target"):
		guest.call("set_target", cel_szek)
	elif guest is Node3D:
		guest.global_position = cel_szek.global_position

	_beallit_rendeles(guest)
	_log("[GUEST] spawn: %s (cél szék: %s)" % [guest.name, str(cel_szek.name)])

func _regisztral_guest(guest: Node3D) -> void:
	guest.name = "Guest_%d" % _aktiv_vendegek.size()
	_aktiv_vendegek.append(guest)
	add_child(guest)

	var cb = Callable(self, "_on_guest_exited").bind(guest)
	if not guest.tree_exited.is_connected(cb):
		guest.tree_exited.connect(cb)

func _elhelyez_guest(guest: Node3D) -> void:
	if _spawn_point != null:
		guest.global_position = _spawn_point.global_position
	elif _target_point != null:
		guest.global_position = _target_point.global_position
	else:
		guest.global_position = global_position

func _beallit_rendeles(guest: Node) -> void:
	var rendeles = _kovetkezo_rendeles()
	if guest.has_method("set_order"):
		guest.call("set_order", rendeles)
	elif guest.has_variable("order"):
		guest.order = rendeles

func _kovetkezo_rendeles() -> Dictionary:
	var rendeles = _valaszt_rendeles(_rendelesek)
	if _rendeles_ures(rendeles):
		var owned_lista = _owned_rendeles_lista()
		rendeles = _valaszt_rendeles(owned_lista)
		if _rendeles_ures(rendeles):
			_log("[ORDER_FIX] fallback used: reason=empty_sellable")
			var beer_ar = _leker_aktualis_ar("beer", 800)
			rendeles = {"id": "beer", "tipus": "ital", "ar": beer_ar}
	return _biztosit_rendeles_adat(rendeles)

func _on_guest_exited(guest: Node) -> void:
	if _aktiv_vendegek.has(guest):
		_aktiv_vendegek.erase(guest)
	_szabadit_szeket(guest)

func _takarit_aktiv_lista() -> void:
	for g in _aktiv_vendegek.duplicate():
		if not is_instance_valid(g):
			_aktiv_vendegek.erase(g)
			_szabadit_szeket(g)

func _cache_nodes() -> void:
	_spawn_point = get_node_or_null(spawn_point_path) as Node3D
	_target_point = get_node_or_null(target_point_path) as Node3D
	_queue_system = get_node_or_null(queue_system_path)

	if _spawn_point == null:
		push_warning("ℹ️ Spawn pont nem található: %s" % spawn_point_path)
	if _target_point == null:
		push_warning("ℹ️ Célpont nem található: %s" % target_point_path)
	if _queue_system == null:
		push_warning("ℹ️ GuestQueueSystem nem található: %s" % queue_system_path)

func _get_seat_manager() -> Node:
	if is_instance_valid(SeatManager1):
		return SeatManager1
	if is_inside_tree():
		var sm = get_node_or_null("/root/SeatManager1")
		if sm != null:
			return sm
	return null

func _jatek_ido_delta(delta: float) -> float:
	var time_node = get_tree().root.get_node_or_null("TimeSystem1")
	if time_node != null and time_node.has_variable("seconds_per_game_minute"):
		var perc_ido = float(time_node.seconds_per_game_minute)
		return delta / max(0.0001, perc_ido)
	return delta

func _vendeg_spawn_szorzo() -> float:
	var alap = 1.0
	var season_node = get_tree().root.get_node_or_null("SeasonSystem1")
	if season_node != null and season_node.has_method("get_season_modifiers"):
		var mod_any = season_node.call("get_season_modifiers")
		var mod = mod_any if mod_any is Dictionary else {}
		var szorzo = float(mod.get("guest_multiplier", 1.0))
		if szorzo > 0.0:
			alap *= szorzo
	if typeof(RecipeTuningSystem1) != TYPE_NIL and RecipeTuningSystem1 != null:
		if RecipeTuningSystem1.has_method("get_demand_multiplier"):
			alap *= float(RecipeTuningSystem1.call("get_demand_multiplier"))
		elif RecipeTuningSystem1.has_method("get_global_popularity_multiplier"):
			alap *= float(RecipeTuningSystem1.call("get_global_popularity_multiplier"))
	return alap

func _log(szoveg: String) -> void:
	print(szoveg)
	if not debug_toast:
		return
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", szoveg)

func _szabadit_szeket(guest: Node) -> void:
	var seat_manager = _get_seat_manager()
	if seat_manager == null:
		print("[SEAT] SeatManager1 nem érhető el, szék nem szabadítható fel")
		return

	if seat_manager.has_method("free_seat_by_guest"):
		seat_manager.call("free_seat_by_guest", guest)
	elif seat_manager.has_method("release_seat"):
		seat_manager.call("release_seat", guest)
	elif seat_manager.has_method("free_seat"):
		seat_manager.call("free_seat", guest)
	elif seat_manager.has_method("unreserve_seat"):
		seat_manager.call("unreserve_seat", guest)

func _epit_rendeles_lista() -> void:
	_rendelesek.clear()
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen != null:
		_biztosit_sor_recept(kitchen)
		_rendelesek = _menu_elemek_receptekbol(kitchen)
	if _rendelesek.is_empty():
		if typeof(RecipeTuningSystem1) == TYPE_NIL or RecipeTuningSystem1 == null:
			_rendelesek.append({"id": "beer", "tipus": "ital", "ar": 800})

func _biztosit_sor_recept(kitchen: Variant) -> void:
	if kitchen == null or not kitchen.has("_recipes"):
		return
	var rec_any = kitchen._recipes
	var recipes: Dictionary = rec_any if rec_any is Dictionary else {}
	if recipes.has("beer"):
		return
	recipes["beer"] = {
		"id": "beer",
		"name": "Sör",
		"type": "drink",
		"ingredients": [],
		"output_portions": 1,
		"sell_price": 800,
		"serve_direct": true,
		"unlocked": true
	}
	kitchen._recipes = recipes
	if kitchen.has("_owned_recipes"):
		var owned_any = kitchen._owned_recipes
		var owned = owned_any if owned_any is Dictionary else {}
		owned["beer"] = true
		kitchen._owned_recipes = owned

func _menu_elemek_receptekbol(kitchen: Variant) -> Array:
	var lista: Array = []
	if kitchen == null or not kitchen.has("_recipes"):
		return lista
	var recipes_any = kitchen._recipes
	var recipes: Dictionary = recipes_any if recipes_any is Dictionary else {}
	var tuning = RecipeTuningSystem1 if typeof(RecipeTuningSystem1) != TYPE_NIL else null
	var aktiv_map: Dictionary = {}
	if tuning != null and tuning.has_method("get_active_recipes"):
		for rid in tuning.call("get_active_recipes"):
			aktiv_map[str(rid)] = true
	var arak: Dictionary = {
		"gulyas": 1200,
		"kolbasz": 900,
		"rantotta": 700,
		"beer": 800
	}
	var mar_lattuk: Dictionary = {}
	for rid in recipes.keys():
		if not aktiv_map.is_empty() and not aktiv_map.has(str(rid)):
			continue
		var adat_any = recipes.get(rid, {})
		var adat: Dictionary = adat_any if adat_any is Dictionary else {}
		var id = _recept_kimenet(adat, rid)
		if id == "":
			continue
		var kulcs = id.to_lower()
		if mar_lattuk.has(kulcs):
			continue
		var tipus = "étel"
		var tipus_forras = str(adat.get("type", "")) if adat.has("type") else ""
		if kulcs == "beer" or tipus_forras.to_lower().find("drink") >= 0:
			tipus = "ital"
		var ar = int(adat.get("sell_price", arak.get(rid, arak.get(kulcs, 900))))
		ar = _leker_aktualis_ar(str(rid), ar)
		mar_lattuk[kulcs] = true
		lista.append({
			"id": id,
			"tipus": tipus,
			"ar": ar
		})
	return lista

func _valaszt_rendeles(lista: Array) -> Dictionary:
	if lista.is_empty():
		return {}
	var elerheto = _elerheto_rendelesek(lista)
	if not elerheto.is_empty():
		var rng2 = RandomNumberGenerator.new()
		rng2.randomize()
		var valasztott2 = elerheto[rng2.randi_range(0, elerheto.size() - 1)]
		return valasztott2 if valasztott2 is Dictionary else {"id": str(valasztott2), "tipus": "", "ar": 0}
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var valasztott = lista[rng.randi_range(0, lista.size() - 1)]
	return valasztott if valasztott is Dictionary else {"id": str(valasztott), "tipus": "", "ar": 0}

func _rendeles_ures(rendeles: Dictionary) -> bool:
	if rendeles.is_empty():
		return true
	return str(rendeles.get("id", "")).strip_edges() == ""

func _owned_rendeles_lista() -> Array:
	var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
	if kitchen == null:
		return []
	var tuning = RecipeTuningSystem1 if typeof(RecipeTuningSystem1) != TYPE_NIL else null
	var owned: Array = []
	if kitchen.has_method("get_owned_recipes"):
		var owned_any = kitchen.call("get_owned_recipes")
		owned = owned_any if owned_any is Array else []
	elif kitchen.has("_owned_recipes"):
		var owned_any2 = kitchen._owned_recipes
		var owned_dict = owned_any2 if owned_any2 is Dictionary else {}
		owned = owned_dict.keys()
	var lista: Array = []
	for rid_any in owned:
		if tuning != null and tuning.has_method("is_recipe_enabled"):
			if not bool(tuning.call("is_recipe_enabled", str(rid_any))):
				continue
		var rendeles = _rendeles_receptbol(kitchen, str(rid_any))
		if not rendeles.is_empty():
			lista.append(rendeles)
	return lista

func _rendeles_receptbol(kitchen: Variant, recipe_id: String) -> Dictionary:
	var rid = str(recipe_id).strip_edges()
	if rid == "":
		return {}
	if kitchen == null or not kitchen.has("_recipes"):
		return {}
	var rec_any = kitchen._recipes
	var recipes: Dictionary = rec_any if rec_any is Dictionary else {}
	var adat_any = recipes.get(rid, {})
	var adat: Dictionary = adat_any if adat_any is Dictionary else {}
	var id = _recept_kimenet(adat, rid)
	if id == "":
		return {}
	var tipus = _becsult_tipus(adat, id)
	var ar = _becsult_ar(adat, rid, id)
	return {
		"id": id,
		"tipus": tipus,
		"ar": ar
	}

func _becsult_tipus(adat: Dictionary, id: String) -> String:
	var kulcs = str(id).to_lower()
	var tipus_forras = str(adat.get("type", "")).to_lower()
	if kulcs == "beer" or tipus_forras.find("drink") >= 0:
		return "ital"
	return "étel"

func _becsult_ar(adat: Dictionary, rid: String, id: String) -> int:
	var alap_ar = int(adat.get("sell_price", 0))
	if alap_ar <= 0:
		var arak: Dictionary = {
			"gulyas": 1200,
			"kolbasz": 900,
			"rantotta": 700,
			"beer": 800
		}
		var kulcs = str(id).to_lower()
		alap_ar = int(arak.get(rid, arak.get(kulcs, 900)))
	return _leker_aktualis_ar(rid, alap_ar)

func _biztosit_rendeles_adat(rendeles: Dictionary) -> Dictionary:
	var id = str(rendeles.get("id", "")).strip_edges()
	if id == "":
		return {"id": "beer", "tipus": "ital", "ar": 800}
	var tipus = str(rendeles.get("tipus", "")).strip_edges()
	var ar = int(rendeles.get("ar", 0))
	if tipus == "" or ar <= 0:
		var kitchen = get_tree().root.get_node_or_null("KitchenSystem1")
		if kitchen != null and kitchen.has("_recipes"):
			var rec_any = kitchen._recipes
			var recipes: Dictionary = rec_any if rec_any is Dictionary else {}
			var adat_any = recipes.get(id, {})
			var adat: Dictionary = adat_any if adat_any is Dictionary else {}
			if tipus == "":
				tipus = _becsult_tipus(adat, id)
			if ar <= 0:
				ar = _becsult_ar(adat, id, id)
	if ar <= 0:
		ar = _leker_aktualis_ar(id, ar)
	if tipus == "":
		tipus = "étel"
	if ar <= 0:
		ar = 500
	return {"id": id, "tipus": tipus, "ar": ar}

func request_alternative_order() -> Dictionary:
	return _kovetkezo_rendeles()

func _elerheto_rendelesek(lista: Array) -> Array:
	if typeof(GuestServingSystem1) == TYPE_NIL or GuestServingSystem1 == null:
		return []
	if not GuestServingSystem1.has_method("get_available_servings"):
		return []
	var elerheto: Array = []
	for rend_any in lista:
		var rend = rend_any if rend_any is Dictionary else {}
		var id = str(rend.get("id", "")).strip_edges()
		if id == "":
			continue
		var db = int(GuestServingSystem1.call("get_available_servings", id))
		if db > 0:
			elerheto.append(rend)
	return elerheto

func _recept_kimenet(adat: Dictionary, rid: String) -> String:
	var output_any = adat.get("output", {})
	var output: Dictionary = output_any if output_any is Dictionary else {}
	var jelolt = String(output.get("id", adat.get("id", rid))).strip_edges()
	return jelolt if jelolt != "" else rid

func _leker_aktualis_ar(recipe_id: String, fallback_ar: int) -> int:
	var tuning = RecipeTuningSystem1 if typeof(RecipeTuningSystem1) != TYPE_NIL else null
	if tuning != null and tuning.has_method("get_effective_price"):
		var ar = int(tuning.call("get_effective_price", recipe_id))
		if ar > 0:
			return ar
	return int(fallback_ar)
