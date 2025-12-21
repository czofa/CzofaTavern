extends Node3D
class_name TerritoryManagerNPC

@export var shop_panel_path: NodePath = ^"/root/Main/UIRoot/ShopkeeperIngredientsPanel"
@export var land_controller_path: NodePath = ^"/root/Main/WorldRoot/FarmWorld/FarmLandController"
@export var farm_world_controller_path: NodePath = ^"/root/Main/WorldRoot/FarmWorld"
@export var farm_terulet_ar: int = 15000
@export var shop_id: String = "shop_territory_manager"

var _panel: Control = null
var _land: Node = null
var _farm_ctrl: Node = null
var _warned_panel: bool = false
var _warned_land: bool = false
var _warned_ctrl: bool = false

func _ready() -> void:
	_cache_panel()
	_cache_targets()

func interact() -> void:
	_cache_panel()
	if _panel == null:
		_toast("Bolt: hiba történt (panel nincs betöltve)")
		return
	_alkalmaz_shop_id()
	_megnyit_boltot()

func _megnyit_boltot() -> void:
	if _panel.has_method("open_panel"):
		_panel.call("open_panel")
	else:
		_panel.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_toast("Területmenedzser: válassz a kínálatból.")

func _cache_panel() -> void:
	if _panel != null:
		return
	var panel_node = get_node_or_null(shop_panel_path)
	if panel_node == null:
		if not _warned_panel:
			printerr("❌ TeruletMenedzser: nem található panel: %s" % shop_panel_path)
			_warned_panel = true
		return
	_panel = panel_node
	_panel.visible = false

func _alkalmaz_shop_id() -> void:
	if _panel == null:
		return
	var cel = str(shop_id).strip_edges()
	if cel == "":
		cel = "shop_territory_manager"
	if _panel.has_method("set_shop_id"):
		_panel.call("set_shop_id", cel)

func _cache_targets() -> void:
	if land_controller_path != NodePath(""):
		var land = get_node_or_null(land_controller_path)
		if land != null:
			_land = land
		elif not _warned_land:
			printerr("❌ TeruletMenedzser: hiányzik a FarmLandController: %s" % land_controller_path)
			_warned_land = true
	if farm_world_controller_path != NodePath(""):
		var ctrl = get_node_or_null(farm_world_controller_path)
		if ctrl != null:
			_farm_ctrl = ctrl
		elif not _warned_ctrl:
			printerr("❌ TeruletMenedzser: hiányzik a FarmWorldController: %s" % farm_world_controller_path)
			_warned_ctrl = true

func jelt_farm_megvetel() -> void:
	_allit_game_state_farm()
	_frissit_land_allapot()
	_toast("✅ Farm terület megvéve. A kapun keresztül beléphetsz.")

func _allit_game_state_farm() -> void:
	var gs = _gs()
	if gs != null and gs.has_method("set_value"):
		gs.call("set_value", "farm_land_level", 0, "Farm terület megvásárlása")

func _frissit_land_allapot() -> void:
	if _land != null and _land.has_method("_alkalmaz_szint"):
		_land.call("_alkalmaz_szint")
	if _farm_ctrl != null and _farm_ctrl.has_method("refresh_after_upgrade"):
		_farm_ctrl.call("refresh_after_upgrade")

func _gs() -> Node:
	return get_tree().root.get_node_or_null("GameState1")

func _eb() -> Node:
	var root = get_tree().root
	var eb = root.get_node_or_null("EventBus1")
	if eb != null:
		return eb
	return root.get_node_or_null("EventBus")

func _toast(text: String) -> void:
	var eb = _eb()
	if eb == null:
		return
	if eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
	elif eb.has_method("bus"):
		eb.call("bus", "ui.toast", {"text": text})
