extends Node

const global_input_poll_interval:float = 0.25

var ignore_input:bool = false
var listen_to_global_input:bool = false

var listener_thread := Thread.new()


func _ready() -> void:
	listener_thread.start(_listener)


func _listener() -> void:
	while true:
		await get_tree().create_timer(global_input_poll_interval).timeout
		process_mpris_events()
		# Wait one frame to process global input.
		await get_tree().process_frame
		process_global_input()


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
		PlayerManager.volume_step_up()
	if event_text == uniform(SessionManager.get_var('keybind_volume_down')):
		PlayerManager.volume_step_down()

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


## Get & process global input keyboard events from [PyInterface].
func process_global_input() -> void:
	var global_input:Array = await PyInterface.get_global_input()
	for event in global_input:
		if event is not Dictionary: continue
		var action = event.get('action','')
		var key = event.get('key','')
		if action is not String or action != 'press': continue
		if key is not String or key.is_empty(): continue
		if listen_to_global_input: evaluate_input(key)


## Get & process MPRIS DBus events from [PyInterface].
func process_mpris_events() -> void:
	var mpris_events:Array = await PyInterface.get_mpris_events()
	# Limit to only the most recent 2 events.
	mpris_events.reverse()
	if mpris_events.size() > 2: mpris_events.resize(2)
	mpris_events.reverse()
	# Parse events.
	for event in mpris_events:
		if event is not Dictionary: continue
		var type = event.get('type')
		var value = event.get('value')
		if type is not String: continue
		# Execute actions.
		match type:
			# TODO: fix this haunted action
			'set_playing': # This specific action, & nothing else seems to be the sole reason for occasional permanent stalling. I dont know whats so special, I dont know how to fix it. ??????????? Skipping forward/backward has to do so much more & actually sets playing as well yet somehow doesnt freeze the app? But a simple thing like this does, i dont know idk idk dik idk dikd idkmdn/
				if value == null: PlayerManager.set_playing(not PlayerManager.is_playing)
				elif value is bool: PlayerManager.set_playing(value)
			'skip_backward':
				PlayerManager.skip_backward()
			'skip_forward':
				PlayerManager.skip_forward()
			'add_position':
				if value is float or value is int: PlayerManager.set_track_progress(PlayerManager.track_progress+value)
			'set_position':
				if value is float or value is int: PlayerManager.set_track_progress(value)
			'set_volume':
				if value is float: PlayerManager.volume = value*100.0 # Value is 0.0 to 1.0, convert to a range of 0 to 100.


func _input(event:InputEvent) -> void:
	if ignore_input or event.is_released(): return
	var event_text:String = event.as_text()
	evaluate_input(event_text)


func _notification(what:int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		listen_to_global_input = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		listen_to_global_input = false
