extends Control
class_name EncounterCardUi

@onready var choice_button_1: Button = $VBox/ChoiceButton1
@onready var choice_button_2: Button = $VBox/ChoiceButton2
@onready var label_text: Label = $VBox/EncounterLabel

var encounter_id: String = ""
var current_choice_ids: Array[String] = []

func _ready() -> void:
	choice_button_1.pressed.connect(_on_choice_button_1_pressed)
	choice_button_2.pressed.connect(_on_choice_button_2_pressed)
	visible = false

func show_encounter(encounter_data: Dictionary) -> void:
	encounter_id = str(encounter_data.get("id", ""))
	current_choice_ids.clear()
	visible = true

	label_text.text = str(encounter_data.get("text", ""))

	var choices: Array = encounter_data.get("choices", [])
	if choices.size() > 0 and typeof(choices[0]) == TYPE_DICTIONARY:
		var c1: Dictionary = choices[0]
		choice_button_1.text = str(c1.get("text", ""))
		current_choice_ids.append(str(c1.get("id", "")))
		choice_button_1.visible = true
	else:
		choice_button_1.visible = false

	if choices.size() > 1 and typeof(choices[1]) == TYPE_DICTIONARY:
		var c2: Dictionary = choices[1]
		choice_button_2.text = str(c2.get("text", ""))
		current_choice_ids.append(str(c2.get("id", "")))
		choice_button_2.visible = true
	else:
		choice_button_2.visible = false

	# 🔴 Állítsa meg az időt
	if TimeSystem1:
		TimeSystem1.pause("encounter")

func _on_choice_button_1_pressed() -> void:
	_send_choice(0)

func _on_choice_button_2_pressed() -> void:
	_send_choice(1)

func _send_choice(index: int) -> void:
	if index < 0 or index >= current_choice_ids.size():
		return

	var choice_id = current_choice_ids[index]
	visible = false

	# 🟢 Küldjük vissza az EventBus-ra
	var eb = get_tree().root.get_node_or_null("EventBus1")
	if eb != null and eb.has_method("bus"):
		eb.call("bus", "encounter.apply_effects", {
			"id": encounter_id,
			"choice": choice_id
		})

	# 🟢 Indítsuk újra az időt
	if TimeSystem1:
		TimeSystem1.resume("encounter")
