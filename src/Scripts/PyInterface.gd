extends Node

const binary_name:String = 'interface'
const binary_path_internal:String = 'res://BIN/'
const binary_path_external:String = 'user://bin/'

var io_access: FileAccess
var error_access: FileAccess
var pid: int


func kill() -> void:
	OS.kill(pid)


func get_audio_meta(paths:PackedStringArray, image_out_dir:String='') -> Array:
	var args: PackedStringArray
	for path:String in paths:
		args.append('(audio) '+path)
	args.append('(img_out) '+image_out_dir)

	# Send command to Python.
	var response:Dictionary = send_command_and_get_response('get_audio_meta', args)
	var data = response.get('data')
	if data is not Array: data = []
	return data


func get_global_input() -> Array:
	var response:Dictionary = send_command_and_get_response('get_global_input', [])
	var data = response.get('data')
	if data is not Array: data = []
	return data


## Sends a command without expecting a response.
## To get the response, use [member send_command_and_get_response].
func send_command(command:String, args:PackedStringArray) -> void:
	io_access.store_line(' [&&] '.join([command]+Array(args)))


## Sends a command with a random ID then waits for a proper response.
## [br]The response should be a [Dictionary] with 3 fields:
## [br]- "cmd" the name of the command sent.
## [br]- "id" the random assigned ID string.
## [br]- "data" the data returned by the command.
## [br][br]
## In the case the response is invalid, there can be a binary 4th field "malformed" which tells you the response is invalid. 
func send_command_and_get_response(command:String, args:PackedStringArray) -> Dictionary:
	# Assign random Command ID.
	args = args.duplicate()
	var id:String = '%s+%s' % [randf()*10, randi_range(1000,2000)]
	args.append('(CID) '+id)

	# Send command.
	send_command(command, args)

	# Wait for response & return it.
	var output:String = io_access.get_line()
	var json = JSON.parse_string(output)
	if json is not Dictionary: json = {
		'cmd': command,
		'id': id,
		'data': output
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
	MiniLog.info('Started as PID "%s".' % pid, PyInterface)
