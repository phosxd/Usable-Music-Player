## Autoload for communicating with the Python interface CLI.
## [br][br]
## Be very careful when running commands on separate threads, it may cause collisions with commands on the main
## [br] causing unpredictable behavior.
extends Node

signal command_freed(command:Array)

const binary_name:String = 'interface'
const binary_path_internal:String = 'res://BIN/'
const binary_path_external:String = 'user://bin/'

var io_access: FileAccess
var error_access: FileAccess
var pid: int

## If [code]true[/code], the PyInterface process is no longer active & cannot recieve any more commands.
var process_ended:bool = false
var command_queue:Array[Array] = []


#func _process(_delta:float) -> void:
	#if Engine.get_process_frames() % 50 != 0: return
	#print(command_queue.size())


func kill() -> void:
	send_command('quit')


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
	if process_ended:
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
	io_access.store_line(' [&&] '.join([command]+Array(args)))
	var output:String = await wait_for_response()
	var err:Error = io_access.get_error()

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
		if io_access.get_length() == 0:
			await get_tree().create_timer(0.01).timeout
			time_waited += 0.01
			continue
		line = io_access.get_line()
		break
	return line


func _exit_tree() -> void:
	kill()


func _ready() -> void:
	var platform:String = OS.get_name()
	var architecture:String = Engine.get_architecture_name()

	var extension:String = ''
	if platform == 'Linux' or platform.ends_with('BSD'):
		extension = '.linux'
	elif platform == 'Windows':
		extension = '.windows'

	extension += '.'+architecture
	var file_name:String = binary_name+extension
	var full_path:String = binary_path_internal+file_name
	var full_path_external:String = ProjectSettings.globalize_path(binary_path_external+file_name)

	# Get binary.
	var bytes:PackedByteArray = FileAccess.get_file_as_bytes(full_path)
	if bytes.is_empty():
		MiniLog.err('Could not find embedded binary "%s" for platform "%s".' % [binary_name, extension], PyInterface)
		return

	# Write binary to disk.
	if not FileAccess.file_exists(full_path_external) or FileAccess.get_file_as_bytes(full_path_external).size() != bytes.size():
		MiniLog.info('Exporting binary.', PyInterface)
		DirAccess.make_dir_recursive_absolute(binary_path_external)
		DirAccess.remove_absolute(full_path_external)
		var file := FileAccess.open(full_path_external, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
		# Give permission to run.
		var exit_code:int = OS.execute('chmod', ['+x', full_path_external])
		if exit_code != OK:
			MiniLog.err('Could not modify permissions of binary "%s".' % binary_name, PyInterface)
			return

	_run(full_path_external)


func _run(path:String) -> void:
	var bridge:Dictionary = OS.execute_with_pipe(path, [], false)
	if bridge.is_empty():
		MiniLog.err('Unable to run "%s".' % path, PyInterface)
		return

	io_access = bridge.stdio
	error_access = bridge.stderr
	pid = bridge.pid
	# Start error listener thread.
	var error_thread := Thread.new()
	error_thread.start(_error_listener)

	MiniLog.info('Started as PID "%s".' % pid, PyInterface)


func _error_listener() -> void:
	# Check for error every 1s.
	while true:
		OS.delay_msec(1_000)
		if error_access.get_length() == 0: continue

		# Get error.
		var error:String = error_access.get_line()
		while error_access.get_length() > 0:
			error += '\n'+error_access.get_line()
		# Print error & open console.
		MiniLog.err('Encountered an error, please report it then restart the application. Details below:\n$~%s~$' % error, PyInterface)
		DialogManager.popup_console.call_deferred()
		# Disallow new commands.
		process_ended = true
