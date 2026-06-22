## Autoload for communicating with the Python interface CLI.
## [br][br]
## Be very careful when running commands on separate threads, it may cause collisions with commands on the main
## [br] causing unpredictable behavior.
extends Node

signal command_freed(command:Array)

const entry_point_python_script:String = 'res://Scripts/Python/Main.py'

var command_queue:Array[Array] = []


func kill() -> void:
	send_command('quit')


## Call a method with thread safetey. Callback will be called with the result of the method.
func thread_safe_call(method_name:String, callback:Callable, ...args) -> void:
	if not has_method(method_name): return
	var method:Callable = get(method_name)
	var result = await method.callv(args)
	if callback: callback.call(result)


func get_audio_meta(paths:PackedStringArray, image_out_dir:String='') -> Array:
	var args: PackedStringArray
	for path:String in paths:
		args.append('(audio) '+path)
	args.append('(img_out) '+image_out_dir)

	# Send command to Python.
	var response:Dictionary = await send_command('get_audio_meta', args)
	var data = response.get('data')
	if data is not Array: data = []
	return data


func get_global_input() -> Array:
	var response:Dictionary = await send_command('get_global_input', [])
	var data = response.get('data')
	if data is not Array: data = []
	return data


func get_mpris_events() -> Array:
	var response:Dictionary = await send_command('get_mpris_events', [])
	var data = response.get('data')
	if data is not Array: data = []
	return data


## Update MPRIS server data.
func update_mpris_data(data:Dictionary) -> void:
	var args := PackedStringArray()
	for key:String in data:
		var value = data[key]
		if value is float or value is int or value is bool: value = ':%s' % value
		args.append('(%s) %s' % [key, value])

	send_command('update_mpris_data', args)



## Sends a command with a random ID then waits for a proper response.
## [br]The response should be a [Dictionary] with 3 fields:
## [br]- "cmd" the name of the command sent.
## [br]- "id" the random assigned ID string.
## [br]- "data" the data returned by the command.
## [br][br]
## In the case the response is invalid, there can be a binary 4th field "malformed" which tells you the response is invalid. 
func send_command(command:String, args:=PackedStringArray()) -> Dictionary:
	# Return placeholder values if called in the incorrect thread.
	if OS.get_main_thread_id() != OS.get_thread_caller_id():
		MiniLog.err('Cannot send commands from outside the main thread, use "call_deferred" instead. Returning placeholder values.', PyInterface)
		return {'cmd':command,'id':'','data':null}
	# Return placeholder values if process is no longer running.
	if not PyRunner.active:
		return {'cmd':command,'id':'','data':null}

	# Assign random Command ID.
	args = args.duplicate()
	var id:String = '%s+%s' % [randf()*10, randi_range(1000,2000)]
	args.append('(CID) '+id)

	# Add to queue.
	var queue_item:Array = [command,args]
	command_queue.append(queue_item)

	# Wait in queue if another command is currently running.
	if command_queue.size() > 1:
		var waiting_behind_command:Array = command_queue[-2]
		while true:
			var queue_command:Array = await command_freed
			if queue_command == waiting_behind_command: break

	# Push command & wait for response.
	PyRunner.send_input(' [&&] '.join([command]+Array(args)))
	var output:String = await wait_for_response()
	var err:Error = PyRunner.io_access.get_error()

	# Remove from queue & emit freed.
	command_queue.erase(queue_item)
	command_freed.emit(queue_item)

	# Check for & print error.
	if err != OK:
		MiniLog.err('Failed to access pipe $~(%s)~$.' % error_string(err), PyInterface)
		return {}

	# Parse output & return it.
	var json = JSON.parse_string(output)
	if json is not Dictionary:
		MiniLog.err('Malformed result from command $i"%s"i$.' % command, PyInterface)
		json = {
		'cmd': command,
		'id': id,
		'data': output,
		'malformed': true,
	}
	return json


func wait_for_response() -> String:
	var line: String
	var time_waited:float = 0.0
	while true:
		if time_waited > 1.0:
			MiniLog.err('Response timed-out.', PyInterface)
			break
		if PyRunner.io_access.get_length() == 0:
			await get_tree().create_timer(0.005).timeout
			time_waited += 0.005
			continue
		line = PyRunner.io_access.get_line()
		break
	return line


func _exit_tree() -> void:
	kill()


func _ready() -> void:
	PyRunner.output_poll_interval = -1
	PyRunner.bundle_error_revieved.connect(func(code:BinBundleProcess.BinBundleError, args:Array) -> void: MiniLog.err('BinBundleProcess error: %s %s' % [code,args], PyInterface))
	PyRunner.error_received.connect(_on_error_received)
	PyRunner.start_entry_point(entry_point_python_script)
	MiniLog.info('Started as PID "%s".' % PyRunner.pid, PyInterface)

	# Send ping every 5 seconds.
	# If 7.5 seconds goes by within Python, then it should self terminate.
	# Ping system is implemented so that if the Godot process crashes or can't access Python anymore, then the Python process wont just stick around waiting.
	while true:
		await get_tree().create_timer(5.0).timeout
		send_command('ping')


func _on_error_received(data:String) -> void:
		# Print error & open console.
		MiniLog.err('Encountered an error, please report it then restart the application. Details below:\n$~%s~$' % data, PyInterface)
		DialogManager.popup_console.call_deferred()
		# Stop Python runner.
		PyRunner.stop()
