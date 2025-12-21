extends Node
class_name LootInventorySystem
# Autoload név: LootInventorySystem1

const SAVE_PATH: String = "user://loot_save.json"

var _loot: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_save()

func add_loot(item_id: String, qty: int) -> void:
	var id = str(item_id).strip_edges()
	var mennyiseg: int = int(qty)
	if id == "" or mennyiseg <= 0:
		return
	var elozo: int = int(_loot.get(id, 0))
	_loot[id] = elozo + mennyiseg
	_save()

func remove_loot(item_id: String, qty: int) -> bool:
	var id = str(item_id).strip_edges()
	var mennyiseg: int = int(qty)
	if id == "" or mennyiseg <= 0:
		return false
	var jelenlegi: int = int(_loot.get(id, 0))
	if jelenlegi < mennyiseg:
		return false
	_loot[id] = jelenlegi - mennyiseg
	if int(_loot.get(id, 0)) <= 0:
		_loot.erase(id)
	_save()
	return true

func get_all_loot() -> Dictionary:
	return _loot.duplicate()

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if parsed == null:
		return
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_loot = parsed

func _save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_loot))
	file.close()
