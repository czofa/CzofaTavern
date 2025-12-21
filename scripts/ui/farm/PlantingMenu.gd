extends Control

@export var seed_list_path: NodePath
@export var info_label_path: NodePath
@export var close_button_path: NodePath
@export var fertilize_button_path: NodePath

@onready var _seed_list: OptionButton = get_node(seed_list_path)
@onready var _info_label: Label = get_node(info_label_path)
@onready var _close_button: Button = get_node(close_button_path)
@onready var _fertilize_button: Button = get_node(fertilize_button_path)

func _ready() -> void:
	_close_button.pressed.connect(func(): hide())
	_seed_list.item_selected.connect(_on_seed_selected)
	_fertilize_button.pressed.connect(_on_fertilize)
	_refresh_seeds()

func open() -> void:
	_refresh_seeds()
	show()

func _refresh_seeds() -> void:
	_seed_list.clear()
	var magok: Dictionary = {}
	if SeedInventorySystem1 != null:
		magok = SeedInventorySystem1.get_all()
	var ids: Array = magok.keys()
	ids.sort()
	for id in ids:
		var qty: int = int(magok.get(id, 0))
		_seed_list.add_item("%s (%d db)" % [id, qty])
		_seed_list.set_item_metadata(_seed_list.item_count - 1, id)
	if _seed_list.item_count > 0:
		_seed_list.select(0)
		_on_seed_selected(0)
	else:
		_info_label.text = "Nincs mag a készletben."

func _on_seed_selected(index: int) -> void:
	if index < 0:
		return
	var meta = _seed_list.get_item_metadata(index)
	var id = str(meta)
	if FarmSystem1 != null:
		FarmSystem1.set_selected_seed(id)
	_info_label.text = "Mag kiválasztva: %s – kapálj, ültess, majd locsold meg." % id

func _on_fertilize() -> void:
	_info_label.text = "Trágyázás kiválasztva – cél plotnál használd a műveletet."
