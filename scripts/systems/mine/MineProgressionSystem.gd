extends Node
class_name MineProgressionSystem
# Autoload név: MineProgressionSystem1

const SAVE_PATH: String = "user://mine_save.json"

var current_level: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_save()

func get_level() -> int:
	if current_level < 1:
		current_level = 1
	return current_level

func set_level(lvl: int) -> void:
	var cel: int = int(lvl)
	if cel < 1:
		cel = 1
	if cel == current_level:
		return
	current_level = cel
	_save()

func advance_level() -> void:
	current_level = get_level() + 1
	_save()

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
	var lvl: int = int((parsed as Dictionary).get("level", 1))
	if lvl < 1:
		lvl = 1
	current_level = lvl

func _save() -> void:
	var data: Dictionary = {"level": current_level}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
