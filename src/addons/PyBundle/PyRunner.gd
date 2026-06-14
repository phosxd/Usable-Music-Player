## Run a Python script.
##
## Call [member start_entry_point] to start the sub-process with the given Python script path (can be in "res" or anywhere).
## [br]The script will technically be run as a module so logic in a "if __name__ == '__main__'" block will not run.
## [br]You can import any other Python script in the "res" virtual file system just like you normally would for Python scripts.
extends BinBundleProcess

## Emitted after [member start_entry_point] is executed.
signal entry_point_started

## Dictionary in which the key is the path of the Python script & the value is the script itself.
## Useful for scenarios where you want to add an importable script that does not actually have a file.
var extra_scripts:Dictionary[String,String]
## Scripts that will not be importable.
var excluded_scripts:Array[String] = [
	'res://addons/PyBundle/Interpreter/interpreter.py',
]


func _init() -> void:
	exe_name = ''
	exe_dir_internal = 'res://addons/PyBundle/Interpreter/'
	exe_dir_external = 'user://Python/'
	output_poll_interval = 0.05
	error_poll_interval = 0.05


func start_entry_point(entry_point_script_path:String) -> void:
	# Remove old Python scripts on disk.
	BinBundleUtil.walk_dir(exe_dir_external, func(file_path:String) -> void:
		if file_path.get_extension() != 'py': return
		DirAccess.remove_absolute(file_path)
	)
	# Export all Python scripts to disk so they can be imported from within Python.
	BinBundleUtil.walk_dir('res://', func(file_path:String) -> void:
		if file_path.get_extension() != 'py' or file_path in excluded_scripts: return
		var script_data: String
		if file_path in extra_scripts:
			script_data = extra_scripts[file_path]
		elif FileAccess.file_exists(file_path):
			script_data = FileAccess.get_file_as_string(file_path)
		else: return

		var export_path:String = file_path.replace('res://',exe_dir_external)
		var export_dir:String = export_path.get_base_dir()
		var dir_err:Error = DirAccess.make_dir_recursive_absolute(export_dir)
		if dir_err != OK:
			printerr('Unable to create directory: %s' % export_dir)
			return
		var file = FileAccess.open(export_path, FileAccess.WRITE)
		if not file:
			printerr('Unable to write file: %s' % export_path)
			return
		file.store_string(script_data)
		file.close()
	)

	var module_name:String = entry_point_script_path.trim_suffix('.py').trim_prefix('res://').replace('user://',OS.get_user_data_dir()+'/').replace('/','.')
	#var module_path:String = ProjectSettings.globalize_path(entry_point_script_path.replace('res://',exe_dir_external))

	# Start sub-process & execute script.
	start()
	send_input(
		'import %s' % module_name
		+ '\nif hasattr(%s, \'main\'): %s.main()' % [module_name, module_name]
	)
	entry_point_started.emit()
