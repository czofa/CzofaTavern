extends Control
class_name InteractionPromptController
# Node: UIRoot.tscn -> InteractionPrompt (Control)

@export var label_path: NodePath = ^"PromptLabel"
var _label: Label = null

func _ready() -> void:
	_label = get_node_or_null(label_path) as Label
	set_prompt(false, "")

func set_prompt(show: bool, text: String) -> void:
	visible = show
	if _label != null:
		_label.text = text
