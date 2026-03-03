extends Node

const minilog_importance := MiniLog.Importance.Core

## Path to the directory hosting CLI binaries.
const cli_path:String = 'CLIs'
## Name of expected CLI binaries.
const clis:Array[String] = [
	'interface',
]
## CLI versions.
const cli_versions:Dictionary[String,int] = {
	'interface': 7,
}
## Runtime absolute paths to the executable binary.
var cli_executable_paths:Dictionary[String,String] = {
	'interface': '',
}


func _ready() -> void:
	var os:String = OS.get_name()
	var arch:String = Engine.get_architecture_name()

	for cli:String in clis:
		var ext: String
		var version:int = cli_versions[cli]
		if os == 'Linux' or os.ends_with('BSD'):
			ext = 'linux'
		elif os == 'Windows':
			ext = 'windows'
		else: ext = ''

		var internal_path:String = 'res://%s/%s.%s_%s' % [cli_path, cli, ext, arch]
		var bytes:PackedByteArray = FileAccess.get_file_as_bytes(internal_path)
		if bytes.is_empty():
			printerr('Could not find embedded CLI executable "%s" for platform "%s".' % [cli, ext+'_'+arch])
			continue

		var path:String = 'res://%s/%s-%s.%s_%s' % [cli_path, cli, version, ext, arch]
		cli_executable_paths.set(cli, path.replace('res://',OS.get_user_data_dir()+'/'))
		DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir()+'/'+cli_path)
		var file := FileAccess.open(cli_executable_paths[cli], FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
		var output = []
		var exit_code:int = OS.execute('chmod', ['+x', cli_executable_paths[cli]], output, true)
		if exit_code != OK:
			printerr('Could not modify permissions of generated CLI executable "%s".' % cli)
			continue


## Executes the given [param cli] & returns an error code or [code]-1[/code] if failed to execute.
## [param output] will be linked to the text ouput of the executable.
func execute(cli:String, arguments:Array[String], output:Array=[]) -> int:
	MiniLog.info('Exeuting CLI "$~%s~$".' % cli, CLI)
	var path:String = cli_executable_paths.get(cli,'')
	if path.is_empty(): return -1

	var err = OS.execute(path, arguments, output)
	return err
