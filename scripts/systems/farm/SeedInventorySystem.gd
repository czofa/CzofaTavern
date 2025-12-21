extends Node
class_name SeedInventorySystem
# Autoload: SeedInventorySystem1 -> res://scripts/systems/farm/SeedInventorySystem.gd

const SAVE_PATH := "user://seed_save.json"

var seeds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_state()

func add_seed(seed_id: String, qty: int) -> void:
	var id = str(seed_id).strip_edges()
	var mennyiseg: int = int(qty)
	if id == "" or mennyiseg <= 0:
		return
	var elozo: int = int(seeds.get(id, 0))
	seeds[id] = elozo + mennyiseg
	_save_state()
	_notify("🌱 Mag érkezett: %s x%d" % [id, mennyiseg])

func consume_seed(seed_id: String, qty: int) -> bool:
	var id = str(seed_id).strip_edges()
	var mennyiseg: int = int(qty)
	if id == "" or mennyiseg <= 0:
		return false
	var elerheto: int = int(seeds.get(id, 0))
	if elerheto < mennyiseg:
		return false
	seeds[id] = elerheto - mennyiseg
	if seeds[id] <= 0:
		seeds.erase(id)
	_save_state()
	return true

func get_all() -> Dictionary:
	return seeds.duplicate(true)

func _save_state() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"seeds": seeds}, "  "))
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
		if adat.has("seeds"):
			seeds = adat.get("seeds", {})

func _notify(text: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", text)
