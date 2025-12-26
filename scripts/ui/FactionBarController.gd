extends HBoxContainer

const FactionConfig = preload("res://scripts/systems/factions/FactionConfig.gd")

@export var frissitesi_intervallum: float = 0.4
@export var periodikus_frissites: bool = true
@export var debug_log_egyszer: bool = true

var _ertek_cimkek: Dictionary = {}
var _utolso_ertekek: Dictionary = {}
var _ido: float = 0.0
var _log_marad: bool = false

func _ready() -> void:
	_build_sorok()
	_connect_bus()
	_frissit_osszes(true, "")
	set_process(true)

func _process(delta: float) -> void:
	if not periodikus_frissites:
		return
	_ido += delta
	if _ido < frissitesi_intervallum:
		return
	_ido = 0.0
	_frissit_osszes(false, "")

func _build_sorok() -> void:
	for child in get_children():
		child.queue_free()
	_ertek_cimkek.clear()
	_utolso_ertekek.clear()
	var entries = _faction_entries()
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id = str(entry.get("id", "")).strip_edges()
		if id == "":
			continue
		var nev = str(entry.get("display_name", id))
		var ikon = str(entry.get("icon", ""))

		var sor = HBoxContainer.new()
		sor.name = id
		sor.add_theme_constant_override("separation", 4)

		var ikon_cimke = Label.new()
		ikon_cimke.text = ikon
		ikon_cimke.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ikon_cimke.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var ertek_cimke = Label.new()
		ertek_cimke.text = "%s: 0" % nev
		ertek_cimke.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ertek_cimke.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ertek_cimke.theme_override_colors/font_color = Color(0, 0, 0, 1)

		sor.add_child(ikon_cimke)
		sor.add_child(ertek_cimke)
		add_child(sor)
		_ertek_cimkek[id] = ertek_cimke

	visible = not _ertek_cimkek.is_empty()

func _frissit_osszes(force: bool, reason: String) -> void:
	var valtozott = false
	var entries = _faction_entries()
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id = str(entry.get("id", "")).strip_edges()
		if id == "":
			continue
		var nev = str(entry.get("display_name", id))
		var value = _get_faction_value(id)
		var cimke = _ertek_cimkek.get(id, null)
		if cimke == null:
			continue
		var szoveg = "%s: %d" % [nev, value]
		if force or cimke.text != szoveg:
			cimke.text = szoveg
		var regi = _utolso_ertekek.get(id, null)
		if regi == null or int(regi) != int(value):
			valtozott = true
		_utolso_ertekek[id] = value

	if valtozott:
		_log_egyszer(reason)

func _log_egyszer(reason: String) -> void:
	if not debug_log_egyszer:
		return
	if _log_marad:
		return
	var reszletek = _osszegzett_ertekek()
	if reason.strip_edges() != "" and reason.begins_with("Encounter:"):
		print("🧾 Frakciósáv frissült encounter után: %s" % reszletek)
		_log_marad = true
		return

func _osszegzett_ertekek() -> String:
	var resz: Array = []
	for entry in _faction_entries():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id = str(entry.get("id", "")).strip_edges()
		if id == "":
			continue
		var nev = str(entry.get("display_name", id))
		var ertek = _get_faction_value(id)
		resz.append("%s=%d" % [nev, ertek])
	return ", ".join(resz)

func _get_faction_value(id: String) -> int:
	if _has_faction_system() and FactionSystem1.has_method("get_faction_value"):
		return int(FactionSystem1.get_faction_value(id))
	if _has_state() and GameState1.has_method("get_faction_value"):
		return int(GameState1.call("get_faction_value", id))
	if _has_state() and GameState1.has_method("get_value"):
		return int(GameState1.call("get_value", id, FactionConfig.DEFAULT_VALUE))
	return FactionConfig.DEFAULT_VALUE

func _faction_entries() -> Array:
	if _has_state() and GameState1.has_method("get_all_factions"):
		var lista = GameState1.call("get_all_factions")
		if typeof(lista) == TYPE_ARRAY:
			return lista
		return []
	if _has_faction_system() and FactionSystem1.has_method("get_factions"):
		return FactionSystem1.get_factions()
	return FactionConfig.FACTIONS

func _connect_bus() -> void:
	var eb = _eb()
	if eb == null or not eb.has_signal("bus_emitted"):
		return
	var cb = Callable(self, "_on_bus")
	if not eb.is_connected("bus_emitted", cb):
		eb.connect("bus_emitted", cb)

func _on_bus(topic: String, payload: Dictionary) -> void:
	match str(topic):
		"faction.changed":
			_frissit_osszes(false, str(payload.get("reason", "")))
		_:
			pass

func _eb() -> Node:
	return get_tree().root.get_node_or_null("EventBus1")

func _has_state() -> bool:
	return typeof(GameState1) != TYPE_NIL and GameState1 != null

func _has_faction_system() -> bool:
	return typeof(FactionSystem1) != TYPE_NIL and FactionSystem1 != null
