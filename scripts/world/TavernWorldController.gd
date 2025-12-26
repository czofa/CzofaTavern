extends Node3D

func _ready() -> void:
	if not is_in_group("world_tavern"):
		add_to_group("world_tavern")
	if not is_in_group("world_build_allowed"):
		add_to_group("world_build_allowed")
