class_name BinBundleUtil extends Object

static var platform:String = OS.get_name():
	get():
		if platform.is_empty(): return OS.get_name()
		return platform
static var architecture:String = Engine.get_architecture_name():
	get():
		if architecture.is_empty(): return Engine.get_architecture_name()
		return architecture


## Returns platform extension.
## [br]
## [br]- [b]Windows:[/b] [code].windows.{arch}[/code]
## [br]- [b]Linux:[/b] [code].linux.{arch}[/code]
## [br]- [b]MacOS:[/b] [code].mac.{arch}[/code]
## [br][br]"arch" is the CPU architecture as defined in [Engine].get_architecture_name.
static func get_platform_extension() -> String:
	var extension:String = ''
	if platform == 'Linux' or platform.ends_with('BSD'): extension = '.linux'
	elif platform == 'Windows': extension = '.windows'
	elif platform == 'macOS': extension = '.mac'
	else: extension = '.other'

	extension += '.'+architecture
	return extension


static func get_platform_exe_extension() -> String:
	if platform == 'Windows': return 'exe'
	else: return 'bin'


## Iterates on every file & direcotry in the tree, starting from [param root_path].
static func walk_dir(root_path:String, file_callback:Callable, dir_callback:=Callable()) -> void:
	root_path += '' if root_path.ends_with('/') else '/'
	var dir := DirAccess.open(root_path)
	if not dir: return
	dir.list_dir_begin()

	while true:
		var path:String = dir.get_next()
		var is_dir:bool = dir.current_is_dir()
		if path.is_empty(): break
		if is_dir:
			if dir_callback && dir_callback.get_argument_count() == 1: dir_callback.call(path)
			walk_dir(root_path+path, file_callback, dir_callback)
		elif file_callback && file_callback.get_argument_count() == 1:
			file_callback.call(root_path+path)

	dir.list_dir_end()
