extends Node3D
class_name ChickenCoopInstance

@export var coop_id: String = ""

var _regisztralt: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_regisztralj()
	add_to_group("chicken_coop")

func interact() -> void:
	if AnimalSystem1 == null:
		_ertesit("❌ Állat rendszer nem elérhető.")
		return
	if coop_id == "":
		_regisztralj()
	if coop_id == "":
		_ertesit("❌ Ól azonosító hiányzik.")
		return
	_ertesit("ℹ️ Nyisd meg az állatkezelőt, majd töltsd fel az ólat vízzel/takarmánnyal.")

func _regisztralj() -> void:
	if _regisztralt:
		return
	if AnimalSystem1 == null:
		return
	if coop_id == "":
		coop_id = AnimalSystem1.register_coop(global_position)
	if coop_id != "":
		_regisztralt = true

func _ertesit(uzenet: String) -> void:
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_signal("notification_requested"):
		eb.emit_signal("notification_requested", uzenet)
