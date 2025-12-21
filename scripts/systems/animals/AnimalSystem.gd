extends Node
class_name AnimalSystem
# Autoload: AnimalSystem1 -> res://scripts/systems/animals/AnimalSystem.gd

const SAVE_PATH := "user://animals_save.json"

var coops: Dictionary = {}
var animals: Dictionary = {}
var _vilag_aktiv: bool = false
var _vilag_csucspont: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_bus()
	_load_state()

func register_coop(pos: Vector3) -> String:
	if not _vilag_aktiv:
		_notify("❌ A farm világ nincs aktiválva.")
		return ""
	var uj_id: String = "coop_%d" % (coops.size() + 1)
	var adat: Dictionary = {
		"id": uj_id,
		"pos": pos,
		"capacity": 2,
		"water": 1.0,
		"feed": 1.0,
		"basket": false,
		"animals": [],
		"last_produce_day": 0,
		"produced_eggs": 0,
		"days_without_supply": 0
	}
	coops[uj_id] = adat
	_save_state()
	return uj_id

func add_animal_to_coop(coop_id: String, animal_id: String) -> bool:
	var cid = str(coop_id)
	var aid = str(animal_id)
	if not coops.has(cid) or aid == "":
		return false
	if not _vilag_aktiv:
		_notify("❌ A farm világ inaktív, nem módosítható az ól.")
		return false
	var adat: Dictionary = coops.get(cid, {})
	var lista: Array = adat.get("animals", [])
	if lista.size() >= int(adat.get("capacity", 0)):
		_notify("❌ Nincs szabad hely az ólban.")
		return false
	lista.append(aid)
	adat["animals"] = lista
	coops[cid] = adat
	_save_state()
	return true

func fill_water(coop_id: String, amount: float) -> void:
	var cid = str(coop_id)
	if not coops.has(cid):
		return
	if not _vilag_aktiv:
		_notify("❌ A farm világ inaktív, nem tölthető víz.")
		return
	var adat: Dictionary = coops.get(cid, {})
	var uj = float(adat.get("water", 0.0)) + float(amount)
	if uj > 1.0:
		uj = 1.0
	adat["water"] = uj
	adat["days_without_supply"] = 0
	coops[cid] = adat
	_save_state()

func fill_feed(coop_id: String, amount: float) -> void:
	var cid = str(coop_id)
	if not coops.has(cid):
		return
	if not _vilag_aktiv:
		_notify("❌ A farm világ inaktív, nem tölthető takarmány.")
		return
	var adat: Dictionary = coops.get(cid, {})
	var uj = float(adat.get("feed", 0.0)) + float(amount)
	if uj > 1.0:
		uj = 1.0
	adat["feed"] = uj
	adat["days_without_supply"] = 0
	coops[cid] = adat
	_save_state()

func set_basket(coop_id: String, van: bool) -> void:
	var cid = str(coop_id)
	if not coops.has(cid):
		return
	if not _vilag_aktiv:
		_notify("❌ A farm világ inaktív, a kosár nem kapcsolható.")
		return
	var adat: Dictionary = coops.get(cid, {})
	adat["basket"] = van
	coops[cid] = adat
	_save_state()

func daily_production(current_day: int) -> void:
	for cid in coops.keys():
		var adat: Dictionary = coops.get(cid, {})
		var allatok: Array = adat.get("animals", [])
		if allatok.is_empty():
			continue
		var viz: float = float(adat.get("water", 0.0))
		var kaja: float = float(adat.get("feed", 0.0))
		var kosar: bool = bool(adat.get("basket", false))
		if viz <= 0.0 or kaja <= 0.0 or not kosar:
			var napok: int = int(adat.get("days_without_supply", 0)) + 1
			adat["days_without_supply"] = napok
			coops[cid] = adat
			if napok >= 2:
				_notify("⚠️ Az ólban nincs ellátás: %s" % cid)
			continue
		var base: int = 1
		if allatok.size() >= 2:
			base += 1
		var gramm: int = base * 100
		if StockSystem1 != null:
			StockSystem1.add_unbooked("egg", gramm, 0)
		adat["water"] = max(0.0, viz - 0.25)
		adat["feed"] = max(0.0, kaja - 0.25)
		adat["produced_eggs"] = int(adat.get("produced_eggs", 0)) + base
		adat["last_produce_day"] = current_day
		adat["days_without_supply"] = 0
		coops[cid] = adat
	_save_state()

func _connect_bus() -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("bus_emitted"):
		eb.connect("bus_emitted", Callable(self, "_on_bus"))

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.new_day":
			var nap: int = int(payload.get("day", 0))
			if nap <= 0 and TimeSystem1 != null:
				nap = TimeSystem1.get_day()
			daily_production(nap)
		"animal.buy":
			_handle_animal_buy(payload)
		_:
			pass

func _handle_animal_buy(payload: Dictionary) -> void:
	var tipus = str(payload.get("type", ""))
	var ar: int = int(payload.get("price", 0))
	if tipus == "":
		return
	var penz: int = 0
	if EconomySystem1 != null and EconomySystem1.has_method("get_money"):
		penz = EconomySystem1.get_money()
	if penz < ar and ar > 0:
		_notify("❌ Nincs elég pénz az állathoz.")
		return
	if EconomySystem1 != null:
		EconomySystem1.add_money(-ar, "Állat vásárlás: %s" % tipus)
	if AnimalInventorySystem1 != null:
		AnimalInventorySystem1.add_animal(tipus, 1)
	_notify("✅ Megvásároltad: %s" % tipus)

func _save_state() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"coops": coops, "animals": animals}, "  "))
	file.close()

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		var adat: Dictionary = parsed
		if adat.has("coops"):
			coops = adat.get("coops", {})
		if adat.has("animals"):
			animals = adat.get("animals", {})

func _notify(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)

func set_world_active(aktiv: bool, world_root: Node = null) -> void:
	_vilag_aktiv = aktiv
	_vilag_csucspont = world_root
	_notify("🌍 Állatrendszer világ státusz: %s" % ("aktív" if _vilag_aktiv else "inaktív"))
