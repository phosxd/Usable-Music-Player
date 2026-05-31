extends Node

const global_input_poll_interval:float = 0.5

var ignore_input:bool = false
var listen_to_global_input:bool = false
var _timer:float = 0.0


func _ready() -> void:
	pass


func _process(delta:float) -> void:
	_timer += delta
	if _timer >= global_input_poll_interval && listen_to_global_input:
		_timer = 0
		get_global_input()


func _notification(what:int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		listen_to_global_input = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		listen_to_global_input = false


func evaluate_input(event_text:String) -> void:
	if event_text == SessionManager.get_var('keybind_play_pause'):
		PlayerManager.set_playing(not PlayerManager.is_playing)
	if event_text == SessionManager.get_var('keybind_skip_backward'):
		PlayerManager.skip_backward()
	if event_text == SessionManager.get_var('keybind_skip_forward'):
		PlayerManager.skip_forward()


func get_global_input() -> void:
	var global_input:Array = PyInterface.get_global_input()
	for event in global_input:
		if event is not Dictionary: continue
		var action = event.get('action','')
		var key = event.get('key','')
		if action is not String or action != 'press': continue
		if key is not String or key.is_empty(): continue
		evaluate_input(key)


func _input(event:InputEvent) -> void:
	if ignore_input or event.is_released(): return
	var event_text:String = event.as_text()
	evaluate_input(event_text)
