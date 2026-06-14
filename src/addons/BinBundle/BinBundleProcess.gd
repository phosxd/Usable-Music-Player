## Extension of [SubProcess] to automatically export an embedded executable.
##
## 
## Call [member start] once the Node is ready to run the sub-process.
class_name BinBundleProcess extends SubProcess

## Emitted when an error occurs.
signal bundle_error_revieved(code:BinBundleError, args:Array)

enum BinBundleError {
	## Could not find embedded executable. Name or internal path is incorrect.
	NotFound,
	## Could not change permission of the executable to runable.
	CannotChangePermission,
}

## Name of the executable file, not the path.
## [br]If the path is "executable.linux.x86_64" then the name is "executable".
@export var exe_name:String = ''
## Directory containing the executable inside the virtual (res) file system.
@export var exe_dir_internal:String = 'res://BIN/'
## Directory to export executable to.
@export var exe_dir_external:String = 'user://BIN/'


## Initialize. Must be called before [member start].
func _ready() -> void:
	var file_name:String = exe_name + BinBundleUtil.get_platform_extension()+'.%s' % BinBundleUtil.get_platform_exe_extension()
	if exe_name.is_empty(): file_name = file_name.trim_prefix('.')
	var full_path:String = exe_dir_internal + ('' if exe_dir_internal.ends_with('/') else '/') + file_name
	var full_path_external:String = ProjectSettings.globalize_path(exe_dir_external+file_name)

	# Get binary.
	var bytes:PackedByteArray = FileAccess.get_file_as_bytes(full_path)
	if bytes.is_empty():
		bundle_error_revieved.emit(BinBundleError.NotFound, [])
		return

	# Write binary to disk if existing binary does not exist or byte count does not match.
	# There's probably a security concern here, but who's really gonna slip in a foreign binary with the same byte count.
	if not FileAccess.file_exists(full_path_external) or FileAccess.get_file_as_bytes(full_path_external).size() != bytes.size():
		DirAccess.make_dir_recursive_absolute(exe_dir_external)
		DirAccess.remove_absolute(full_path_external)
		var file := FileAccess.open(full_path_external, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
		# If on Linux, give necessary permissions to run as executable.
		if BinBundleUtil.platform == 'Linux' or BinBundleUtil.platform.ends_with('BSD'):
			var exit_code:int = OS.execute('chmod', ['+x', full_path_external])
			if exit_code != OK:
				bundle_error_revieved.emit(BinBundleError.CannotChangePermission, [exit_code])
				return

	# Set SubProcess properties.
	path = full_path_external
