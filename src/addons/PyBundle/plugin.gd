@tool
extends EditorPlugin

const pyrunner_path:String = 'res://addons/PyBundle/PyRunner.gd'
const interpreter_script_name:String = 'interpreter.py'
## Add custom build options here.
const build_script_names:Dictionary[String,PackedStringArray] = {
	'linux': [
		'nuitka_build_linux.sh',
	],
	'windows': [
		'nuitka_build_windows.bat',
	],
}
const start_binary_name:String = 'interpreter'
var proj_root:String = ProjectSettings.globalize_path('res://addons/PyBundle/Interpreter/')

var export_plugin:EditorExportPlugin = preload('res://addons/PyBundle/export.gd').new()
var tool_menu_items:PackedStringArray = []


func _enter_tree() -> void:
	add_export_plugin(export_plugin)
	if BinBundleUtil.platform == 'Windows':
		for script_name:String in build_script_names.windows:
			var item_name:String = 'Build Python Interpreter (%s)' % script_name.split('.')[0]
			add_tool_menu_item(item_name, _build_py.bind(script_name))
			tool_menu_items.append(item_name)
	elif BinBundleUtil.platform == 'Linux' or BinBundleUtil.platform.ends_with('BSD'):
		for script_name:String in build_script_names.linux:
			var item_name:String = 'Build Python Interpreter (%s)' % script_name.split('.')[0]
			add_tool_menu_item(item_name, _build_py.bind(script_name))
			tool_menu_items.append(item_name)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	for item:String in tool_menu_items:
		remove_tool_menu_item(item)


func _enable_plugin() -> void:
	add_autoload_singleton('PyRunner', pyrunner_path)
	


func _disable_plugin() -> void:
	remove_autoload_singleton('PyRunner')


func _build_py(script_name:String) -> void:
	print_rich('\n[b]Starting Python build process (%s)...[/b]\n' % script_name.split('.')[0])
	var sub = SubProcess.new()

	var platform:String = OS.get_name()
	if platform == 'Linux' or platform.ends_with('BSD'):
		sub.path = 'bash'
		sub.arguments = [proj_root+script_name]
	elif platform == 'Windows':
		sub.path = proj_root+script_name
	else:
		printerr('Automatic building only supported on Linux or Windows. Sorry not sorry, Mac.')
		return

	sub.output_received.connect(func(data:String) -> void:
		print(data)
	)
	sub.error_received.connect(func(data:String) -> void:
		print_rich('[color=yellow]%s[/color]' % data)
	)

	sub.stopped.connect(func() -> void:
		sub.queue_free()
		# Rename binary.
		var platform_exe_extension:String = BinBundleUtil.get_platform_exe_extension()
		var new_binary_name:String = BinBundleUtil.get_platform_extension().trim_prefix('.')+'.%s' % platform_exe_extension
		DirAccess.rename_absolute(proj_root+start_binary_name+'.%s' % platform_exe_extension, proj_root+new_binary_name)

		if platform == 'Windows':
			print('\nOn Windows, you need to manually remove the left-over directories & files (*.dist, *.build, *.onefile-build, dist, build, *.spec). The only things that should be left are binary/exe files, Python files, batch/shell files, & a markdown file.')

		print_rich('[b]Done.[/b]')
	)

	sub.start()
