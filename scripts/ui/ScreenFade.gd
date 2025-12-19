extends ColorRect
class_name ScreenFade

@export var alap_ido: float = 0.25

func fade_out_in(mid_action: Callable, duration: float = 0.25) -> void:
	var ido = duration
	if ido <= 0.0:
		ido = alap_ido
	if ido <= 0.0:
		ido = 0.25

	var tween_out = _create_tween_safe()
	if tween_out == null:
		_call_mid_action(mid_action)
		_reset_alpha()
		return

	tween_out.tween_property(self, "color:a", 1.0, ido)
	await tween_out.finished

	_call_mid_action(mid_action)
	var tree = get_tree()
	if tree != null:
		await tree.process_frame

	var tween_in = _create_tween_safe()
	if tween_in == null:
		_reset_alpha()
		return

	tween_in.tween_property(self, "color:a", 0.0, ido)
	await tween_in.finished

func _create_tween_safe() -> Tween:
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if tree == null:
		return null
	return tree.create_tween()

func _call_mid_action(mid_action: Callable) -> void:
	if mid_action.is_valid():
		mid_action.call()

func _reset_alpha() -> void:
	var c = color
	c.a = 0.0
	color = c
