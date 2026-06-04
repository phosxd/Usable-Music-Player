## Autoload for communicating with the Python interface CLI.
## [br][br]
## Be very careful when running commands on separate threads, it may cause collisions with commands on the main
## [br] causing unpredictable behavior.
extends Node

const binary_name:String = 'interface'
const binary_path_internal:String = 'res://BIN/'
const binary_path_external:String = 'user://bin/'

var io_access: FileAccess
var error_access: FileAccess
var pid: int

var default_whitelisted_functions:Array[Callable] = [send_command, get_audio_meta, get_global_input, get_mpris_events, update_mpris_data]
## Whitelisted command functions. Remove items to prevent them from running.
## They can still be called but they will only return dummy values.
var whitelisted_functions:Array[Callable] = default_whitelisted_functions.duplicate()

var waiting_for_response:bool = false


func kill() -> void:
	send_command('quit')


func get_audio_meta(paths:PackedStringArray, image_out_dir:String='', callback:=func(_data:Array):pass) -> void:
	if get_audio_meta not in whitelisted_functions: return

	var args: PackedStringArray
	for path:String in paths:
		args.append('(audio) '+path)
	args.append('(img_out) '+image_out_dir)

	# Send command to Python.
	var response:Dictionary = send_command('get_audio_meta', args)
	var data = response.get('data')
	if data is not Array: data = []
	callback.call(data)


func get_global_input() -> Array:
	if get_global_input not in whitelisted_functions: return []

	var response:Dictionary = send_command('get_global_input', [])
	var data = response.get('data')
	if data is not Array: data = []
	return data


func get_mpris_events() -> Array:
	if get_mpris_events not in whitelisted_functions: return []

	var response:Dictionary = send_command('get_mpris_events', [])
	var data = response.get('data')
	if data is not Array: data = []
	return data


## Update MPRIS server data.
func update_mpris_data(data:Dictionary) -> void:
	if update_mpris_data not in whitelisted_functions: return

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
	# Return placeholder values if another command is currently running.
	if waiting_for_response:
		MiniLog.err('Can only send one command at a time, returning placeholder values!', PyInterface)
		return {'cmd':command,'id':'','data':null}

	# Assign random Command ID.
	args = args.duplicate()
	var id:String = '%s+%s' % [randf()*10, randi_range(1000,2000)]
	args.append('(CID) '+id)

	waiting_for_response = true
	io_access.store_line(' [&&] '.join([command]+Array(args)))
	var output:String = io_access.get_line()
	var err:Error = io_access.get_error()
	if err != OK:
		MiniLog.err('Failed to access pipe.', PyInterface)
		return {}
	waiting_for_response = false

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
	var bridge:Dictionary = OS.execute_with_pipe(path, [], true)
	if bridge.is_empty():
		MiniLog.err('Unable to run "%s".' % path, PyInterface)
		return

	io_access = bridge.stdio
	error_access = bridge.stderr
	pid = bridge.pid
	# Start error listener thread.
	var error_thread = Thread.new()
	error_thread.start(_error_listener)

	MiniLog.info('Started as PID "%s".' % pid, PyInterface)


func _error_listener() -> void:
	# Wait for an error.
	var error:String = error_access.get_line()
	# Get the rest of the error.
	while error_access.get_length() > 0:
		error += '\n'+error_access.get_line()
	# Print error & open console.
	MiniLog.err('Shutting down PyInterface. Encountered an error, please report it then restart the application. Details below:\n$~%s~$' % error, PyInterface)
	DialogManager.popup_console.call_deferred()
	# Disallow new commands & kill the interface.
	default_whitelisted_functions.clear()
	whitelisted_functions.clear()
	kill.call_deferred()
