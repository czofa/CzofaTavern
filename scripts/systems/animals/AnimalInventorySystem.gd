extends Node
class_name AnimalInventorySystem
# Autoload: AnimalInventorySystem1 -> res://scripts/systems/animals/AnimalInventorySystem.gd

const SAVE_PATH := "user://animal_inventory_save.json"

var animals: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_state()

func add_animal(type: String, qty: int) -> void:
	var id = str(type).strip_edges()
	var mennyiseg: int = int(qty)
	if id == "" or mennyiseg <= 0:
		return
	animals[id] = int(animals.get(id, 0)) + mennyiseg
	_save_state()
	_notify("🐔 Új állat: %s x%d" % [id, mennyiseg])

func consume_animal(type: String, qty: int) -> bool:
	var id = str(type).strip_edges()
	var mennyiseg: int = int(qty)
	if id == "" or mennyiseg <= 0:
		return false
	var elerheto: int = int(animals.get(id, 0))
	if elerheto < mennyiseg:
		return false
	animals[id] = elerheto - mennyiseg
	if animals[id] <= 0:
		animals.erase(id)
	_save_state()
	return true

func get_all() -> Dictionary:
	return animals.duplicate(true)

func _save_state() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"animals": animals}, "  "))
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
		if adat.has("animals"):
			animals = adat.get("animals", {})

func _notify(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
