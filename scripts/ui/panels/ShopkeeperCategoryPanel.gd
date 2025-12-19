extends Control

signal category_selected(category_id: String)

@export var category_buttons: Array[NodePath]

var _categories := [
	{"id": "ingredients", "text": "🥕 Alapanyagok"},
	{"id": "recipes", "text": "📖 Receptek"},
	{"id": "seeds", "text": "🌱 Magvak"},
	{"id": "animals", "text": "🐄 Állatok"},
	{"id": "tools", "text": "🪓 Eszközök"},
	{"id": "serveware", "text": "🍽️ Kiszolgálóeszközök"},
	{"id": "construction", "text": "🧱 Építőanyagok"},
	{"id": "sell", "text": "💰 Eladás"}
]

func _ready() -> void:
	for i in category_buttons.size():
		var button_path := category_buttons[i]
		var button := get_node_or_null(button_path)
		if button and i < _categories.size():
			button.text = _categories[i]["text"]
			button.pressed.connect(_on_category_pressed.bind(_categories[i]["id"]))

func _on_category_pressed(category_id: String) -> void:
	emit_signal("category_selected", category_id)
