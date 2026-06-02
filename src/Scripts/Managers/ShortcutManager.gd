extends Node

const global_input_poll_interval:float = 0.5

var ignore_input:bool = false
var listen_to_global_input:bool = false
var _timer:float = 0.0


func _ready() -> void:
	pass


func _process(delta:float) -> void:
	_timer += delta
	if _timer >= global_input_poll_interval:
		_timer = 0
		#get_global_input()


func _notification(what:int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		listen_to_global_input = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		listen_to_global_input = false


func uniform(key:String) -> String:
	var parts = key.split('+',false)
	parts.sort()
	return '+'.join(parts)


func evaluate_input(event_text:String) -> void:
	event_text = uniform(event_text)
	# Media controls.
	if event_text == uniform(SessionManager.get_var('keybind_play_pause')):
		PlayerManager.set_playing(not PlayerManager.is_playing)
	if event_text == uniform(SessionManager.get_var('keybind_skip_backward')):
		PlayerManager.skip_backward()
	if event_text == uniform(SessionManager.get_var('keybind_skip_forward')):
		PlayerManager.skip_forward()
	if event_text == uniform(SessionManager.get_var('keybind_volume_up')):
		PlayerManager.volume += 2.5
	if event_text == uniform(SessionManager.get_var('keybind_volume_down')):
		PlayerManager.volume -= 2.5

	# UI controls.
	if listen_to_global_input: return # If window unfocused, don't do UI controls.
	if event_text == uniform(SessionManager.get_var('keybind_page_backward')):
		SessionManager.main_scene.go_back()
	if event_text == uniform(SessionManager.get_var('keybind_page_forward')):
		SessionManager.main_scene.go_forward()
	elif event_text == uniform(SessionManager.get_var('keybind_toggle_imview')):
		if SessionManager.get_var('last_tab') == 'immersive_view':
			SessionManager.main_scene.go_back()
		else:
			SessionManager.main_scene.set_tab('immersive_view')


func get_global_input() -> void:
	# Process keyboard events.
	var global_input:Array = PyInterface.get_global_input()
	for event in global_input:
		if event is not Dictionary: continue
		var action = event.get('action','')
		var key = event.get('key','')
		if action is not String or action != 'press': continue
		if key is not String or key.is_empty(): continue
		if listen_to_global_input: evaluate_input(key)

	# Process MPRIS events.
	var mpris_events:Array = PyInterface.get_mpris_events()
	for event in mpris_events:
		if event is not Dictionary: continue
		var type = event.get('type')
		var value = event.get('value')
		if type is not String: continue
		# Execute actions.
		match type:
			'set_playing':
				if value == null: PlayerManager.set_playing(not PlayerManager.is_playing)
				elif value is bool: PlayerManager.set_playing(value)


func _input(event:InputEvent) -> void:
	if ignore_input or event.is_released(): return
	var event_text:String = event.as_text()
	evaluate_input(event_text)
