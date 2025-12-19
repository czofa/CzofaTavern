extends Node
class_name HudActionsController

@export var serve_test_button_path: NodePath = ^"/Main/UIRoot/UIRoot/HUDBar/ServeTestButton"

var _serve_test_button: Button = null

func _ready() -> void:
	# Gomb keresése
	_serve_test_button = get_node_or_null(serve_test_button_path)

	if _serve_test_button == null:
		printerr("❌ ServeTestButton nem található az útvonalon: ", serve_test_button_path)
		return

	# Gomb esemény bekötése
	_serve_test_button.pressed.connect(_on_serve_test_pressed)
	print("🟢 ServeTestButton csatlakoztatva.")

func _on_serve_test_pressed() -> void:
	if GuestServingSystem1.has_method("serve_random_guest"):
		GuestServingSystem1.serve_random_guest("Sör") # Teszt ital
	else:
		printerr("❌ GuestServingSystem1 nem tartalmaz 'serve_random_guest' metódust.")
