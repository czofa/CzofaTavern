extends Button

@export var travel_manager_path: NodePath = ^"../../../../CoreRoot/TravelTransitionManager"
@export var cel_vilag_path: NodePath = ^"../../WorldRoot/TownWorld"
@export var spawn_jelolo: String = "Spawns/TownEntryFromTavern"
@export var ido_koltseg_perc: int = 60

func _ready() -> void:
	_connect_bus()
	_apply_mode(_aktualis_mod())
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed() -> void:
	var manager = _travel_manager()
	if manager == null:
		hiba_toast("❌ Az utazás vezérlő nem érhető el.")
		return
	if manager.has_method("travel_to"):
		manager.call("travel_to", str(cel_vilag_path), spawn_jelolo, ido_koltseg_perc)
	else:
		hiba_toast("❌ Az utazás vezérlő hibás.")

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null:
		return
	if eb.has_signal("game_mode_changed"):
		var cb = Callable(self, "_on_game_mode_changed")
		if not eb.is_connected("game_mode_changed", cb):
			eb.connect("game_mode_changed", cb)

func _on_game_mode_changed(mod: String) -> void:
	_apply_mode(mod)

func _apply_mode(mod: String) -> void:
	visible = str(mod).to_upper() == "RTS"

func _aktualis_mod() -> String:
	var gk = get_tree().root.get_node_or_null("GameKernel1")
	if gk != null and gk.has_method("get_mode"):
		return str(gk.call("get_mode"))
	return ""

func _travel_manager() -> Node:
	if travel_manager_path != NodePath("") and has_node(travel_manager_path):
		return get_node(travel_manager_path)
	if travel_manager_path != NodePath("") and get_tree() != null and get_tree().root != null:
		var root = get_tree().root
		if root.has_node(travel_manager_path):
			return root.get_node(travel_manager_path)
	return get_tree().root.find_child("TravelTransitionManager", true, false)

func hiba_toast(uzenet: String) -> void:
	var eb = _eb()
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")
