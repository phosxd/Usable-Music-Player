extends Node

const binary_name:String = 'metadata'
const binary_path_internal:String = 'res://BIN/'
const binary_path_external:String = 'user://bin/'
const version:int = 0

var io_access: FileAccess
var error_access: FileAccess
var pid: int
var thread := Thread.new()


func kill() -> void:
	OS.kill(pid)


func get_audio_meta(path:String, image_out_dir:String='') -> Dictionary:
	send_command('get_audio_meta', [path, image_out_dir])
	var output:String = io_access.get_line()
	if io_access.get_error() != OK: return {}
	var json = JSON.parse_string(output)
	if json is not Dictionary: return {}
	return json


func dump_audio_meta(path:String, image_out_dir:String='') -> Array:
	send_command('dump_audio_meta', [path, image_out_dir])
	var output:String = io_access.get_line()
	var json = JSON.parse_string(output)
	if json is not Array: return []
	return json


func send_command(command:String, args:Array[String]) -> void:
	io_access.store_line(' [&&] '.join([command]+args))


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
	var full_path_external:String = ProjectSettings.globalize_path(binary_path_external+file_name+'.%s' % version)

	# Get binary.
	var bytes:PackedByteArray = FileAccess.get_file_as_bytes(full_path)
	if bytes.is_empty():
		MiniLog.err('Could not find embedded binary "%s" for platform "%s".' % [binary_name, extension], self)
		return

	# Write binary to disk.
	DirAccess.make_dir_recursive_absolute(binary_path_external)
	var file := FileAccess.open(full_path_external, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()
	# Give permission to run.
	var exit_code:int = OS.execute('chmod', ['+x', full_path_external])
	if exit_code != OK:
		MiniLog.err('Could not modify permissions of binary "%s".' % binary_name, self)
		return

	_run(full_path_external)


func _run(path:String) -> void:
	var bridge:Dictionary = OS.execute_with_pipe(path, [])
	if bridge.is_empty():
		MiniLog.err('Unable to run "%s".' % path, self)
		return

	io_access = bridge.stdio
	error_access = bridge.stderr
	pid = bridge.pid
	MiniLog.info('Started as PID "%s".' % pid, self)
