class_name ScrollInputBlocker extends Control

var _timer:float = 0.0


func _process(delta:float) -> void:
	if Engine.is_editor_hint(): return
	_timer += delta
	if _timer > 0.2:
		self.hide()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if event is not InputEventMouseButton or not event.is_released(): return
	if event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]: return
	self.show()
	_timer = 0
