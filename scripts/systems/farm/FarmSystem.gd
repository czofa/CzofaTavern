extends Node
class_name FarmSystem
# Autoload: FarmSystem1 -> res://scripts/systems/farm/FarmSystem.gd

const SAVE_PATH := "user://farm_save.json"

var plots: Dictionary = {}
var selected_seed_id: String = ""
var _farm_mod: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	_connect_bus()
	_ensure_input_actions()
	_load_state()

func set_selected_seed(seed_id: String) -> void:
	selected_seed_id = str(seed_id)

func register_plot(global_position: Vector3) -> String:
	var uj_id: String = "plot_%d" % (plots.size() + 1)
	var adat: Dictionary = {
		"id": uj_id,
		"pos": global_position,
		"tilled": false,
		"seed_id": "",
		"stage": 0,
		"water": 0.0,
		"fertilized": false,
		"days_without_water": 0,
		"is_dead": false
	}
	plots[uj_id] = adat
	_save_state()
	return uj_id

func till_plot(plot_id: String) -> void:
	var id = str(plot_id)
	if not plots.has(id):
		return
	var adat: Dictionary = plots.get(id, {})
	adat["tilled"] = true
	plots[id] = adat
	_save_state()

func water_plot(plot_id: String) -> void:
	var id = str(plot_id)
	if not plots.has(id):
		return
	var adat: Dictionary = plots.get(id, {})
	adat["water"] = 1.0
	adat["days_without_water"] = 0
	plots[id] = adat
	_save_state()

func fertilize_plot(plot_id: String) -> void:
	var id = str(plot_id)
	if not plots.has(id):
		return
	var adat: Dictionary = plots.get(id, {})
	adat["fertilized"] = true
	plots[id] = adat
	_save_state()

func plant_seed(plot_id: String, seed_id: String) -> bool:
	var id = str(plot_id)
	var seed = str(seed_id)
	if not plots.has(id) or seed == "":
		return false
	var adat: Dictionary = plots.get(id, {})
	if not bool(adat.get("tilled", false)):
		_notify("❌ A föld nincs felásva.")
		return false
	if bool(adat.get("is_dead", false)):
		_notify("❌ A plot halott, tisztítani kell.")
		return false
	if SeedInventorySystem1 == null:
		_notify("❌ Magraktár nem elérhető.")
		return false
	if not SeedInventorySystem1.consume_seed(seed, 1):
		_notify("❌ Nincs elég mag (%s)." % seed)
		return false
	adat["seed_id"] = seed
	adat["stage"] = 0
	adat["days_without_water"] = 0
	adat["is_dead"] = false
	plots[id] = adat
	selected_seed_id = seed
	_save_state()
	return true

func clear_dead(plot_id: String) -> void:
	var id = str(plot_id)
	if not plots.has(id):
		return
	var adat: Dictionary = plots.get(id, {})
	adat["seed_id"] = ""
	adat["stage"] = 0
	adat["is_dead"] = false
	adat["fertilized"] = false
	adat["days_without_water"] = 0
	plots[id] = adat
	_save_state()

func harvest_plot(plot_id: String) -> void:
	var id = str(plot_id)
	if not plots.has(id):
		return
	var adat: Dictionary = plots.get(id, {})
	if bool(adat.get("is_dead", false)):
		clear_dead(id)
		return
	if not _is_ready_for_harvest(adat):
		_notify("❌ Még nem érett meg a növény.")
		return
	if StockSystem1 != null:
		StockSystem1.add_unbooked("potato", 510, 0)
	_notify("🧺 Betakarítva: burgonya +510 g")
	adat["seed_id"] = ""
	adat["stage"] = 0
	adat["fertilized"] = false
	adat["days_without_water"] = 0
	plots[id] = adat
	_save_state()

func advance_day() -> void:
	for id in plots.keys():
		var adat: Dictionary = plots.get(id, {})
		if str(adat.get("seed_id", "")) == "":
			continue
		if bool(adat.get("is_dead", false)):
			continue
		var viz: float = float(adat.get("water", 0.0))
		if viz <= 0.0:
			var napok: int = int(adat.get("days_without_water", 0))
			napok += 1
			adat["days_without_water"] = napok
			if napok >= 2:
				adat["is_dead"] = true
			plots[id] = adat
			continue
		var gyorsitas: bool = bool(adat.get("fertilized", false))
		var novekedes: int = 1
		if gyorsitas:
			novekedes = 2
		var uj_stage: int = int(adat.get("stage", 0)) + novekedes
		var max_stage: int = _get_max_stage(str(adat.get("seed_id", "")))
		if uj_stage > max_stage:
			uj_stage = max_stage
		adat["stage"] = uj_stage
		viz -= 0.5
		if viz < 0.0:
			viz = 0.0
		adat["water"] = viz
		adat["days_without_water"] = 0
		plots[id] = adat
	_save_state()

func _is_ready_for_harvest(adat: Dictionary) -> bool:
	if str(adat.get("seed_id", "")) == "":
		return false
	if bool(adat.get("is_dead", false)):
		return false
	var stage: int = int(adat.get("stage", 0))
	return stage >= _get_max_stage(str(adat.get("seed_id", "")))

func _get_max_stage(seed_id: String) -> int:
	var id = str(seed_id)
	if id == "":
		return 0
	return 3

func _ensure_input_actions() -> void:
	_add_key_action("ui_toggle_farm_mode", KEY_F)
	_add_mouse_action("farm_action", MOUSE_BUTTON_LEFT)
	_add_mouse_action("farm_cancel", MOUSE_BUTTON_RIGHT)

func _add_key_action(action_name: String, keycode: int) -> void:
	if action_name == "" or keycode <= 0:
		return
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and (existing as InputEventKey).keycode == keycode:
			return
	var ev = InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action_name, ev)

func _add_mouse_action(action_name: String, button: int) -> void:
	if action_name == "" or button == 0:
		return
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventMouseButton and (existing as InputEventMouseButton).button_index == button:
			return
	var ev = InputEventMouseButton.new()
	ev.button_index = button
	ev.button_mask = 0
	InputMap.action_add_event(action_name, ev)

func _connect_bus() -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("bus_emitted"):
		eb.connect("bus_emitted", Callable(self, "_on_bus"))

func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if event.is_action_pressed("ui_toggle_farm_mode"):
		_valt_farm_mod()
		return
	if not _farm_mod:
		return
	if event.is_action_pressed("farm_cancel"):
		_farm_mod = false
		_notify("❌ Farm mód kikapcsolva.")
		return
	if event.is_action_pressed("farm_action"):
		_handle_farm_click()

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"time.new_day":
			advance_day()
		_:
			pass

func _valt_farm_mod() -> void:
	_farm_mod = not _farm_mod
	if _farm_mod:
		_ertesit_farm_mod()
	else:
		_notify("❌ Farm mód kikapcsolva.")

func _ertesit_farm_mod() -> void:
	if not _van_eszkoz("hoe"):
		_notify("⚠️ Hiányzik a kapa – vásárold meg a boltban.")
	_farm_mod = true
	_notify("🌱 Farm mód bekapcsolva. Bal klikk: ás/ültet/öntöz.")
	_megnyit_menu()

func _megnyit_menu() -> void:
	var ui = _keres_ui("PlantingMenu")
	if ui != null and ui.has_method("open"):
		ui.call("open")
	else:
		_notify("ℹ️ Ültetési menü nem található.")

func _keres_ui(name: String) -> Node:
	var root = get_tree().root
	if root == null:
		return null
	return root.find_child(name, true, false)

func _handle_farm_click() -> void:
	var cel = _ray_plot()
	if cel == null:
		_notify("ℹ️ Nem találtam parcellát.")
		return
	var plot = cel as Node
	if plot != null and plot.has_method("get"):
		if plot.has_method("interact"):
			plot.call("interact")
			return
	var pid_any = plot.get("plot_id") if plot != null else ""
	handle_plot_action(str(pid_any))

func handle_plot_action(plot_id: String) -> void:
	var id = str(plot_id)
	if id == "":
		_notify("❌ Hiányzó plot ID.")
		return
	var adat = plots.get(id, {})
	if adat.is_empty():
		_notify("❌ Ismeretlen plot: %s" % id)
		return
	if not bool(adat.get("tilled", false)):
		if not _van_eszkoz("hoe"):
			_notify("❌ Kapa nélkül nem tudsz ásni.")
			return
		till_plot(id)
		_notify("✅ Felásva: %s" % id)
		return
	if str(adat.get("seed_id", "")) == "":
		if selected_seed_id == "":
			_notify("❌ Nincs kiválasztott vetőmag.")
			return
		if not _van_mag(selected_seed_id):
			_notify("❌ Nincs elég mag (%s)." % selected_seed_id)
			return
		if plant_seed(id, selected_seed_id):
			_notify("🌱 Elültetve: %s" % selected_seed_id)
		return
	if float(adat.get("water", 0.0)) < 1.0:
		if not _van_eszkoz("watering_can"):
			_notify("❌ Locsoló nélkül nem tudsz öntözni.")
			return
		water_plot(id)
		_notify("💧 Megöntözve.")
		return
	if _is_ready_for_harvest(adat):
		harvest_plot(id)
		_notify("🧺 Betakarítva.")
		return
	_notify("ℹ️ Nincs további művelet ehhez a plothoz.")

func _van_eszkoz(tool_id: String) -> bool:
	var kulcs = "tool_owned_%s" % tool_id
	var gs = get_tree().root.get_node_or_null("GameState1")
	if gs != null and gs.has_method("get_value"):
		return int(gs.call("get_value", kulcs, 0)) > 0
	return false

func _van_mag(id: String) -> bool:
	if SeedInventorySystem1 == null:
		return false
	return int(SeedInventorySystem1.get_all().get(id, 0)) > 0

func _ray_plot() -> Node:
	var viewport = get_viewport()
	if viewport == null:
		return null
	var kamera = viewport.get_camera_3d()
	if kamera == null:
		return null
	var mouse = viewport.get_mouse_position()
	var from = kamera.project_ray_origin(mouse)
	var irany = kamera.project_ray_normal(mouse)
	var params = PhysicsRayQueryParameters3D.create(from, from + irany * 100.0)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.hit_from_inside = true
	params.collision_mask = 1
	var world = get_world_3d()
	if world == null:
		return null
	var hit = world.direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return null
	return hit.get("collider", null)

func _save_state() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"plots": plots, "selected_seed": selected_seed_id}, "  "))
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
		if adat.has("plots"):
			plots = adat.get("plots", {})
		selected_seed_id = str(adat.get("selected_seed", ""))

func _notify(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
