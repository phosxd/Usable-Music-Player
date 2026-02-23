class_name FileUtils extends Node


## Iterates on every file & direcotry in the tree, starting from [param root_path].
static func walk_dir(root_path:String, file_callback:Callable, dir_callback:Callable) -> void:
	var dir := DirAccess.open(root_path)
	if not dir: return
	dir.list_dir_begin()
	while true:
		var path:String = dir.get_next()
		if path.is_empty(): break
		if dir.current_is_dir():
			if dir_callback: dir_callback.call(path)
			walk_dir(root_path+'/'+path, file_callback, dir_callback)
		elif file_callback:
			file_callback.call(root_path+'/'+path)
	dir.list_dir_end()
